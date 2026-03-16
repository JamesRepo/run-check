# Manual Test Checklist

Verify the end-to-end flow on a device or simulator before release.

## Happy path

- [ ] Cold launch → location detected → select 3 runs → see 3 results
- [ ] Change to morning-only in settings → re-run → results only show morning slots
- [ ] Change duration to 90 min → re-run → verify slot windows are wider
- [ ] Switch to °F in settings → results show Fahrenheit temperatures
- [ ] Enable cyclist mode toggle → verify it persists after relaunch

## Location

- [ ] Deny location permission → manual search fallback works
- [ ] Location detection error → bottom sheet stays open with error message
- [ ] Search for an invalid city name → error shown, sheet stays open for retry

## Offline / cache

- [ ] Airplane mode → stale data banner appears with cached results
- [ ] Airplane mode with no cache → error snackbar, button re-enables
- [ ] Fetch once, enable airplane mode, fetch again → cached data with stale banner

## Results screen

- [ ] Tap refresh on results screen → data updates
- [ ] Pull-to-refresh on results screen → data updates
- [ ] Select 7 runs → verify spacing constraint produces sensible distribution
- [ ] Algorithm returns zero slots → empty state shown (not spinner)

## Deep link / navigation

- [ ] Deep link to `/results` with no prior search → redirects to home
- [ ] Navigate home → results → back → lands on home screen
- [ ] Navigate home → settings → back → lands on home screen
