# Weather Window Algorithm

## Overview

Given a user's location, activity type, and desired training frequency, find
the N best weather windows in the next 7 days.

---

## Step 1: Fetch Forecast

Fetch the 7-day hourly forecast for the user's location.

**Required fields per hour:**
| Field              | Unit   | Example |
|--------------------|--------|---------|
| temperature        | °C     | 18      |
| feels_like         | °C     | 16      |
| precipitation_prob | 0–1    | 0.1     |
| precipitation_mm   | mm     | 0.0     |
| wind_speed         | km/h   | 12      |
| wind_gust          | km/h   | 20      |
| humidity           | 0–1    | 0.55    |
| uv_index           | 0–11+  | 4       |
| condition_code     | string | "clear" |

> **Improvement: use `feels_like` instead of raw temperature.** A 10°C day
> with 30 km/h wind feels very different from a calm one. Feels-like already
> factors in wind chill and heat index, so it's a better proxy for comfort.

---

## Step 2: Filter Candidate Slots

### 2a. Hard filters (reject immediately)

These conditions make outdoor exercise unsafe or miserable regardless of score.
Reject any hour where:

| Condition               | Threshold          |
|-------------------------|--------------------|
| Thunderstorm / ice      | condition_code     |
| Precipitation prob      | > 0.80             |
| Wind gust               | > 50 km/h          |
| Feels-like temperature  | < -10°C or > 38°C  |

Filtering these out first avoids wasting scoring on slots nobody should use.

### 2b. Time window filter

Keep only hours within the user's preferred window.

- Default: 06:00–21:00
- Could refine with sunrise/sunset data so you never suggest a 06:00 run in
  winter when sunrise is at 08:00.

### 2c. Build multi-hour blocks

If the user wants 1-hour sessions, each hour is a candidate slot. For longer
sessions (e.g. 90 min cycling), use a sliding window and score based on the
**worst hour** in the block — a run is only as good as the worst weather you
hit during it.

```
For a duration of D hours:
  For each starting hour H where H+D is still in the time window:
    slot = hours[H..H+D-1]
    slot.score = min(score(hour) for hour in slot)  // worst-hour rule
```

---

## Step 3: Score Each Slot

### Formula

```
score = w1 * temp_score
      + w2 * precip_score
      + w3 * wind_score
      + w4 * humidity_score
```

All sub-scores are normalised to **0.0–1.0** (1.0 = perfect conditions).

### Sub-score functions

#### Temperature (using feels_like)

Piecewise linear with an ideal range. Different per activity:

```
Running ideal:  8–18°C  (you warm up fast)
Cycling ideal: 12–22°C  (wind chill from speed)

         1.0 |     ___________
             |    /           \
         0.0 |___/             \___
             -5   8    18   35    (°C, running)
```

```dart
double tempScore(double feelsLike, {bool isCycling = false}) {
  final idealLow  = isCycling ? 12.0 : 8.0;
  final idealHigh = isCycling ? 22.0 : 18.0;
  final absLow    = isCycling ? 0.0  : -5.0;
  final absHigh   = isCycling ? 35.0 : 35.0;

  if (feelsLike >= idealLow && feelsLike <= idealHigh) return 1.0;
  if (feelsLike < absLow || feelsLike > absHigh) return 0.0;
  if (feelsLike < idealLow) {
    return (feelsLike - absLow) / (idealLow - absLow);
  }
  return (absHigh - feelsLike) / (absHigh - idealHigh);
}
```

#### Precipitation

Precipitation probability is the strongest negative signal. Use a steep curve
so anything above ~40% drops sharply.

```dart
double precipScore(double prob, double mm) {
  // Probability dominates, but actual mm is a tiebreaker
  final probScore = 1.0 - prob.clamp(0.0, 1.0);
  final mmPenalty = (mm / 5.0).clamp(0.0, 1.0); // 5mm+ = full penalty
  return (probScore * 0.8) + ((1.0 - mmPenalty) * 0.2);
}
```

#### Wind

```dart
double windScore(double speedKmh, double gustKmh, {bool isCycling = false}) {
  // Cyclists are more affected by wind
  final threshold = isCycling ? 20.0 : 30.0;
  final gustThreshold = isCycling ? 35.0 : 45.0;
  final speedScore = 1.0 - (speedKmh / threshold).clamp(0.0, 1.0);
  final gustScore  = 1.0 - (gustKmh / gustThreshold).clamp(0.0, 1.0);
  return speedScore * 0.7 + gustScore * 0.3;
}
```

#### Humidity

High humidity makes running miserable, less so for cycling (airflow).

```dart
double humidityScore(double humidity, {bool isCycling = false}) {
  // Ideal: 30–60%. Above 80% is bad, especially for running.
  if (humidity <= 0.6) return 1.0;
  final ceiling = isCycling ? 0.90 : 0.85;
  return 1.0 - ((humidity - 0.6) / (ceiling - 0.6)).clamp(0.0, 1.0);
}
```

### Default weights

| Weight | Running | Cycling | Rationale                              |
|--------|---------|---------|----------------------------------------|
| w1     | 0.25    | 0.20    | Temperature matters but is tolerable   |
| w2     | 0.40    | 0.35    | Rain is the top reason people skip     |
| w3     | 0.15    | 0.30    | Wind is a bigger deal on a bike        |
| w4     | 0.20    | 0.15    | Humidity affects runners more           |

> Weights should sum to 1.0. Could later let users adjust these via a
> "what bothers you most?" preference screen.

---

## Step 4: Select Top N Windows (Spacing)

Naive "pick the top N scores" will cluster slots on the same sunny morning.
We need to space them out.

### Greedy spaced selection

```
Algorithm: GreedySpacedSelect(slots, n, minGapHours)
  1. Sort slots by score descending.
  2. selected = []
  3. For each slot in sorted order:
       a. If selected.length == n, stop.
       b. If no slot in selected is within minGapHours of this slot:
            Add to selected.
  4. Return selected sorted chronologically.
```

### Gap logic

- Default minimum gap: **20 hours** (ensures different days or well-separated
  morning/evening on the same day)
- If N slots can't be found with 20h gap, relax progressively:
  20h → 16h → 12h → 8h. This handles weeks with bad weather where you have
  to double up.

```dart
List<Slot> selectSpaced(List<Slot> slots, int n, {int initialGap = 20}) {
  var gap = initialGap;
  while (gap >= 8) {
    final result = _greedySelect(slots, n, gap);
    if (result.length == n) return result;
    gap -= 4;
  }
  // Fallback: just take the best N we could find
  return _greedySelect(slots, n, 0).take(n).toList();
}
```

### Edge cases

- **Fewer than N good slots exist**: Return what you have with a message like
  "Only found 2 good windows this week — the rest of the forecast looks rough."
- **All slots below a minimum threshold**: Warn the user rather than suggesting
  a terrible slot. Suggested minimum score: **0.3**.
- **Ties**: Break ties by preferring the earlier slot (gives the user more
  planning time).

---

## Suggested Improvements Beyond the Original Spec

### 1. UV awareness
For long sessions (60min+), flag slots with UV index >= 6 with a sun warning.
Don't penalise the score (people can wear sunscreen) but surface it in the UI.

### 2. "Golden hour" bonus
Give a small bonus (+0.05) to early morning and evening slots when temperature
is high. Running at 07:00 in summer is much better than 14:00 even if the
hourly numbers look similar.

### 3. Day-type awareness
If the user links a calendar or marks rest days, skip those. Otherwise, lightly
prefer weekends for longer sessions (e.g. a long run) since users likely have
more flexibility.

### 4. Confidence decay
Weather forecasts are less accurate further out. Apply a small confidence
multiplier that decays over the 7-day window:

```
confidence = 1.0 - (0.03 * hoursFromNow)
adjusted_score = score * confidence
```

This naturally favours nearer-term slots when scores are close, which is
appropriate since those forecasts are more trustworthy.

### 5. Minimum score threshold
Don't recommend a slot scoring below 0.3. If the week is that bad, tell the
user honestly. A "no good windows found" is more useful than suggesting a run
in sideways rain.
