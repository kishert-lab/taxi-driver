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
flutter run --dart-define=API_BASE_URL=http://192.168.0.50:8083 --dart-define=WS_URL=ws://192.168.0.50:8083/api/v1/ws
```

Default development values point to `http://192.168.0.50:8083` and `ws://192.168.0.50:8083/api/v1/ws`.

Local Swagger was used as the source of truth:

```text
http://192.168.0.50:8083/swagger/index.html
```

Implemented client paths now match the backend routes:

- `POST /api/v1/auth/login`
- `POST /api/v1/auth/verify-code`
- `POST /api/v1/auth/refresh`
- `GET/PATCH /api/v1/driver/profile`
- `POST /api/v1/driver/online`
- `POST /api/v1/driver/offline`
- `POST /api/v1/driver/location`
- `POST /api/v1/driver/location/batch`
- `GET /api/v1/driver/orders/current`
- `GET /api/v1/driver/orders/history`
- `POST /api/v1/driver/orders/{id}/accept`
- `POST /api/v1/driver/orders/{id}/reject`
- `POST /api/v1/driver/orders/{id}/arrived`
- `POST /api/v1/driver/orders/{id}/start`
- `POST /api/v1/driver/orders/{id}/complete`
- `GET /api/v1/driver/balance`
- `GET /api/v1/driver/transactions`

The current Swagger does not expose a push-token endpoint, so push registration remains isolated in `PushNotificationService` until the backend route is added.

## Verification

```bash
flutter analyze
flutter build apk --debug
flutter test
```

In this local environment `flutter analyze` and Android debug build pass. `flutter test` currently fails before loading the suite because the Flutter test shell closes its local runner HTTP connection.
