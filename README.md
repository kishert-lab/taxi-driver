# Taxi Driver

Production-oriented Flutter application for taxi drivers working with `taxi-platform`.

## Backend

Default configuration is in [lib/core/config/app_config.dart](lib/core/config/app_config.dart):

```text
BASE_URL=http://192.168.0.50:8080/api/v1
WS_URL=ws://192.168.0.50:8080/api/v1/ws
```

Override at build/run time:

```bash
flutter run \
  --dart-define=BASE_URL=http://192.168.0.50:8080/api/v1 \
  --dart-define=WS_URL=ws://192.168.0.50:8080/api/v1/ws
```

## Features

- Login by phone and password.
- Secure token storage with `flutter_secure_storage`.
- Dio API client with Bearer auth, automatic refresh on `401`, and one retry.
- Typed parsing for backend success/error envelopes.
- Driver profile, online/offline status, current order, order history, balance and transactions.
- WebSocket connection after login with reconnect/backoff.
- WS events: `sync.required`, `order.offer`, offer cancelled/expired, accepted/cancelled.
- Location permission and high-accuracy tracking while online/busy.
- Location update throttle: no more than one update per two seconds.
- `429 RATE_LIMITED` location updates are skipped silently.
- Russian operational UI with dashboard, orders, balance and profile tabs.

## Architecture

```text
lib/
  app/                  app, router, theme
  core/
    config/             backend URLs
    network/            Dio, auth interceptor, API errors
    storage/            secure token storage
    ws/                 WebSocket client and message envelope
    location/           permissions and geolocation
  features/
    auth/               login and auth state
    driver/             profile, status and location controllers
    orders/             current order, history and order offer UI
    balance/            balance and transactions
    profile/            profile screen
```

State management: Riverpod.

All API calls go through repositories. Widgets only render state and dispatch commands.

## Backend Notes

If backend returns `NOT_IMPLEMENTED` or HTTP `501`, the app shows:

```text
Функция пока недоступна на сервере.
```

For `/driver/online`, `DRIVER_NOT_AVAILABLE` is shown as:

```text
Вы не можете выйти на линию. Проверьте статус проверки документов и автомобиля.
```

## Run

```bash
flutter pub get
flutter analyze
flutter run
```

## Test

```bash
flutter test
```
