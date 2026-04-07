# Minneapolis Weather App

A Flutter mobile app that displays current, hourly, and 7-day weather forecasts for Minneapolis, MN.

Uses the [Open-Meteo API](https://open-meteo.com/) — free, no API key required.

## Features

- Current temperature, feels-like, humidity, wind speed, and UV index
- 24-hour hourly forecast with scrollable cards
- 7-day daily forecast with highs and lows
- Pull-to-refresh
- Dark-themed, mobile-optimized UI

## Prerequisites

- Flutter SDK (3.10+)
- Xcode (for iOS) or Android Studio (for Android)

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run

# Build for release
flutter build ios
flutter build apk
```

## Project Structure

```
lib/
├── main.dart                          # App entry point and theme
├── models/
│   ├── weather_data.dart              # Data models for API response
│   └── wmo_codes.dart                 # WMO weather code mappings
├── screens/
│   └── weather_screen.dart            # Main weather screen
├── services/
│   └── weather_service.dart           # Open-Meteo API client
└── widgets/
    ├── current_weather_card.dart       # Current conditions display
    ├── hourly_forecast_section.dart    # Horizontal hourly scroll
    └── daily_forecast_section.dart     # 7-day forecast list
```
