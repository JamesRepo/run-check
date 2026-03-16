# Weather Window Algorithm

## Overview

Given a user's location and desired training frequency, find the N best
weather windows in the next 7 days.

**Implementation:** `lib/services/run_scheduler.dart` — `RunScheduler` class.

---

## Step 1: Fetch Forecast

Fetch the 7-day hourly forecast for the user's location via Open-Meteo.

**Fields per hour (from `HourlyForecast`):**
| Field                    | Unit   | Example |
|--------------------------|--------|---------|
| temperature              | °C     | 18      |
| precipitationProbability | 0–100  | 10      |
| windSpeed                | km/h   | 12      |
| humidity                 | 0–100  | 55      |
| weatherCode              | int    | 0       |

> **Future improvement: use `feels_like` instead of raw temperature.** A
> 10 °C day with 30 km/h wind feels very different from a calm one.
> Feels-like already factors in wind chill and heat index, so it's a
> better proxy for comfort. Not yet available in the data model.

---

## Step 2: Filter Candidate Slots

### 2a. Time-of-day filter

Keep only hours within the user's preferred periods:

| Period    | Hours       |
|-----------|-------------|
| morning   | 05:00–11:59 |
| afternoon | 12:00–17:59 |
| evening   | 18:00–21:00 |

All three periods are included by default. The user can limit to a subset.

### 2b. Sunrise/sunset filter

If `sunData` is provided, also exclude hours before sunrise or after sunset
for that day. This prevents suggesting a 05:00 run in winter when sunrise
is at 08:00.

### 2c. Build multi-hour blocks

If the user wants 1-hour sessions, each hour is a candidate slot. For
longer sessions (e.g. 90 min), use a sliding window over consecutive
filtered hours. The number of hours needed is `ceil(durationMinutes / 60)`.

A window's metrics are the **average** of its constituent hours.

```
For a duration of D hours (D = ceil(runDurationMinutes / 60)):
  For each starting index I in filtered hours:
    window = filtered[I..I+D-1]
    if all hours in window are consecutive (1-hour gaps):
      keep as candidate
    window.metrics = average of constituent hours
```

> **Design note:** The original spec proposed a worst-hour rule (score =
> min of individual hours). The implementation uses averaging instead,
> which produces smoother scoring and avoids a single marginal hour
> tanking an otherwise good window. This could be revisited if users
> report being surprised by conditions mid-run.

---

## Step 3: Score Each Slot

### Formula

```
score = 0.35 * precip_score
      + 0.30 * temp_score
      + 0.20 * wind_score
      + 0.15 * humidity_score
```

Weights are defined in `lib/utils/constants.dart`. All sub-scores are
normalised to **0.0–1.0** (1.0 = perfect conditions).

### Sub-score functions

All sub-score methods are `public static` on `RunScheduler` for easy
unit testing.

#### Temperature

Piecewise linear with an ideal range of **12–18 °C**:

```
         1.0 |     ___________
             |    /           \
         0.0 |___/             \___
             0   12    18   35    (°C)
```

```dart
static double tempScore(double temperature) {
  const idealLow = 12.0;
  const idealHigh = 18.0;
  const absLow = 0.0;   // below 0 °C → 0.0
  const absHigh = 35.0;  // above 35 °C → 0.0

  if (temperature >= idealLow && temperature <= idealHigh) return 1.0;
  if (temperature < absLow || temperature > absHigh) return 0.0;
  if (temperature < idealLow) {
    return (temperature - absLow) / (idealLow - absLow);
  }
  return (absHigh - temperature) / (absHigh - idealHigh);
}
```

#### Precipitation

Simple linear mapping from probability (0–100) to score.

```dart
static double precipScore(double precipitationProbability) {
  return 1.0 - (precipitationProbability / 100).clamp(0.0, 1.0);
}
```

> **Simplification from original spec:** The original formula also
> factored in precipitation amount (mm). The current data model only has
> probability, so this is a straight linear inverse. The mm tiebreaker
> can be added when the model expands.

#### Wind

```dart
static double windScore(double windSpeedKmh) {
  const calm = 10.0;   // 1.0 at ≤ 10 km/h
  const limit = 40.0;  // 0.0 at ≥ 40 km/h

  if (windSpeedKmh <= calm) return 1.0;
  if (windSpeedKmh >= limit) return 0.0;
  return 1.0 - (windSpeedKmh - calm) / (limit - calm);
}
```

> **Simplification from original spec:** The original formula also used
> wind gust data and had cycling-specific thresholds. The current data
> model only has `windSpeed`, so gusts are not factored in yet.

#### Humidity

Humidity values are percentages (0–100).

```dart
static double humidityScore(double humidity) {
  const comfortHigh = 60.0;  // 1.0 at ≤ 60%
  const ceiling = 90.0;      // 0.0 at ≥ 90%

  if (humidity <= comfortHigh) return 1.0;
  if (humidity >= ceiling) return 0.0;
  return 1.0 - (humidity - comfortHigh) / (ceiling - comfortHigh);
}
```

### Weights

| Weight | Value | Rationale                             |
|--------|-------|---------------------------------------|
| w1     | 0.35  | Precipitation — top reason to skip    |
| w2     | 0.30  | Temperature — comfort                 |
| w3     | 0.20  | Wind — noticeable but tolerable       |
| w4     | 0.15  | Humidity — mostly a summer factor     |

> Weights sum to 1.0 and are defined in `lib/utils/constants.dart`.
> Could later let users adjust these via a "what bothers you most?"
> preference screen. Activity-specific weights (running vs cycling)
> are a future enhancement.

---

## Step 4: Select Top N Windows (Spacing)

Naive "pick the top N scores" will cluster slots on the same sunny
morning. We need to space them out.

### Greedy spaced selection

```
Algorithm: GreedySpacedSelect(slots, n, minGapHours = 12)
  1. Sort slots by score descending.
  2. selected = []
  3. For each slot in sorted order:
       a. If selected.length == n, stop.
       b. If no slot in selected is within 12 hours of this slot:
            Add to selected.
  4. Return selected sorted chronologically.
```

### Gap logic

- Fixed minimum gap: **12 hours**.
- If fewer than N slots can be found with the gap, return whatever was
  selected (don't crash or pad).

> **Simplification from original spec:** The original algorithm used a
> 20-hour initial gap with progressive relaxation (20 → 16 → 12 → 8).
> The fixed 12-hour gap is simpler and still prevents morning/morning
> clustering on the same day while allowing morning + evening on the
> same day when weather is good.

### Edge cases

- **`numberOfRuns <= 0`** → return empty list.
- **Empty `forecasts`** → return empty list.
- **`runDurationMinutes` longer than available consecutive hours** →
  those incomplete windows are skipped.
- **Fewer than N good slots exist** → return what's available.
- **All slots have terrible scores** → still return the least-bad
  options (no minimum score threshold).
- **Ties** → broken by sort order (earlier slots tend to appear first).

---

## Suggested Improvements (Not Yet Implemented)

### 1. Activity-specific scoring
Different ideal ranges and weights for running vs cycling. The original
spec had per-activity temperature ranges, wind thresholds, and humidity
ceilings. Implement when the UI supports activity selection.

### 2. Hard filters
Reject hours with thunderstorms, extreme temperatures (< -10 °C or
\> 38 °C), high wind gusts (> 50 km/h), or precipitation probability
\> 80 % before scoring. Currently these are handled by low scores.

### 3. UV awareness
For long sessions (60 min+), flag slots with UV index >= 6 with a sun
warning. Don't penalise the score but surface it in the UI.

### 4. "Golden hour" bonus
Give a small bonus (+0.05) to early morning and evening slots when
temperature is high. Running at 07:00 in summer is much better than
14:00 even if the hourly numbers look similar.

### 5. Day-type awareness
If the user links a calendar or marks rest days, skip those. Otherwise,
lightly prefer weekends for longer sessions.

### 6. Confidence decay
Weather forecasts are less accurate further out. Apply a small confidence
multiplier that decays over the 7-day window:

```
confidence = 1.0 - (0.03 * hoursFromNow)
adjusted_score = score * confidence
```

This naturally favours nearer-term slots when scores are close.

### 7. Minimum score threshold
Don't recommend a slot scoring below 0.3. If the week is that bad, tell
the user honestly. Currently disabled — the algorithm always returns the
best available slots regardless of absolute quality.

### 8. Progressive gap relaxation
Start with a 20-hour gap and relax to 16 → 12 → 8 if N slots can't be
found. Currently uses a fixed 12-hour gap.

### 9. Feels-like temperature
Use feels-like temperature instead of raw temperature for scoring. Needs
the API response and data model to include this field.

### 10. Precipitation amount
Factor in expected precipitation amount (mm) as a tiebreaker alongside
probability. Needs the data model to include this field.
