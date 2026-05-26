import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

import '../../features/driver/domain/driver_profile.dart';
import '../../features/orders/domain/driver_order.dart';

class DriverLocationSample {
  const DriverLocationSample({
    required this.coordinates,
    this.heading,
    this.speedMetersPerSecond,
    this.accuracyMeters,
  });

  final Coordinates coordinates;
  final int? heading;
  final double? speedMetersPerSecond;
  final double? accuracyMeters;

  Map<String, dynamic> toJson() {
    return {
      'location': coordinates.toJson(),
      if (heading != null) 'heading': heading,
      if (speedMetersPerSecond != null) 'speed_mps': speedMetersPerSecond,
      if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
    };
  }
}

class LocationService {
  Future<void> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException('Служба геолокации выключена.');
    }

    final permission = await permissions.Permission.locationWhenInUse.request();
    if (!permission.isGranted) {
      throw const LocationException('Нет разрешения на геолокацию.');
    }
  }

  Future<DriverLocationSample> currentLocation() async {
    await ensurePermission();
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return _map(position);
  }

  Stream<DriverLocationSample> watch(DriverStatus status) {
    if (!status.canSendLocation) {
      return const Stream.empty();
    }
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map(_map);
  }

  DriverLocationSample _map(Position position) {
    return DriverLocationSample(
      coordinates: Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      heading: position.heading < 0
          ? null
          : position.heading.round().clamp(0, 359),
      speedMetersPerSecond: position.speed < 0 ? null : position.speed,
      accuracyMeters: position.accuracy < 0 ? null : position.accuracy,
    );
  }
}

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);
