# Taxi Driver App

Flutter MVP scaffold for a separate taxi driver mobile application.

## Stack

- Flutter
- BLoC/Cubit
- Dio
- Retrofit dependencies for generated API clients
- Secure Storage
- WebSocket channel
- Geolocator
- Firebase Messaging

## Architecture

The app is split by explicit layers:

- `lib/core` - config, network, storage, WebSocket, location, push, errors
- `lib/features/*/domain` - pure domain entities where a feature needs them
- `lib/features/*/application` - business rules and use cases
- `lib/features/*/data` - repositories and backend API access
- `lib/features/*/presentation` - pages and BLoC/Cubit state
- `lib/shared` - shared models, theme, and widgets

UI widgets do not call HTTP clients directly. Driver line access, order status transitions, and platform commission calculation are implemented outside presentation code.

## Implemented MVP Scaffold

- Phone auth flow with SMS code endpoints and secure token storage
- Driver home screen with map placeholder, WebSocket/GPS indicators, shift controls, order offer, active order, readiness, balance
- Driver readiness policy: verified profile, approved required documents, approved car, GPS permission, balance
- Strict active order state machine
- Platform commission calculation at 1%
- WebSocket client with token-based connection
- Location service with status-based update frequency
- Push token registration service
- Domain tests for shift access, order transitions, and commission

## Backend Configuration

Pass backend URLs at build/run time:

```bash
flutter run --dart-define=API_BASE_URL=https://api.your-domain.com --dart-define=WS_URL=wss://api.your-domain.com/api/v1/driver/ws
```

Default development values point to `https://api.example.com`.

## Verification

```bash
flutter analyze
flutter build apk --debug
flutter test
```

In this local environment `flutter analyze` and Android debug build pass. `flutter test` currently fails before loading the suite because the Flutter test shell closes its local runner HTTP connection.
