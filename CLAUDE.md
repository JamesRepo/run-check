# Run Check

## Project Overview
A Flutter mobile app that helps runners and cyclists find optimal weather windows for training. Users specify how many times per week they want to train, and the app recommends the best time slots based on weather conditions.

## Tech Stack
- Flutter (Dart)
- Target platforms: Android, iOS, Web
- Linting: very_good_analysis

## Project Structure
```
lib/
  main.dart       — App entry point
  screens/        — Full-page views
  widgets/        — Reusable UI components
  models/         — Data classes and domain objects
  services/       — API clients, business logic, local storage
test/             — Widget and unit tests
```

## Commands
- `flutter pub get` — Install dependencies
- `flutter run` — Run the app
- `flutter test` — Run all tests
- `flutter analyze` — Run linter
- `flutter build apk|ios|web` — Build for a platform

## Conventions
- Follow very_good_analysis lint rules
- Use single quotes for strings
- Use trailing commas for widget trees
- Keep widgets small and composable — extract to `widgets/` when reused
- Business logic belongs in `services/`, not in widget code
- Use `const` constructors wherever possible

## Key Domain Concepts
- Users are runners or cyclists
- Users set a weekly training frequency (e.g. 3 times per week)
- The app fetches weather forecast data and ranks upcoming time windows by conditions favorable for outdoor exercise (temperature, precipitation, wind)
- "Best window" factors: low chance of rain, moderate temperature, low wind speed
