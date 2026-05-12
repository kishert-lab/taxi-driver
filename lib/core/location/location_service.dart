import 'package:geolocator/geolocator.dart';

import '../errors/app_exception.dart';
import '../../shared/models/driver_models.dart';

class LocationService {
  Future<void> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const ValidationException('geolocation service is disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const ValidationException('geolocation permission is not granted');
    }
  }

  Stream<DriverLocation> watchDriverLocation(DriverWorkStatus status) {
    final interval = switch (status) {
      DriverWorkStatus.inTrip ||
      DriverWorkStatus.busy => const Duration(seconds: 3),
      DriverWorkStatus.online ||
      DriverWorkStatus.onWayToClient ||
      DriverWorkStatus.waitingClient => const Duration(seconds: 7),
      _ => const Duration(seconds: 30),
    };

    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        timeLimit: interval,
      ),
    ).map(
      (position) => DriverLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        bearing: position.heading,
        accuracy: position.accuracy,
        status: status,
        timestamp: position.timestamp,
      ),
    );
  }
}
