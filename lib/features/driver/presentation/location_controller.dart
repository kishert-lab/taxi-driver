import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../../core/network/api_error.dart';
import '../data/location_repository.dart';
import '../domain/driver_profile.dart';

const _locationBatchLimit = 50;

class LocationState {
  const LocationState({
    required this.isTracking,
    this.lastLocation,
    this.errorMessage,
  });

  const LocationState.idle() : this(isTracking: false);

  final bool isTracking;
  final DriverLocationSample? lastLocation;
  final String? errorMessage;
}

final locationControllerProvider =
    StateNotifierProvider<LocationController, LocationState>((ref) {
      return LocationController(
        ref.watch(locationServiceProvider),
        ref.watch(locationRepositoryProvider),
      );
    });

class LocationController extends StateNotifier<LocationState> {
  LocationController(this._service, this._repository)
    : super(const LocationState.idle());

  final LocationService _service;
  final LocationRepository _repository;
  StreamSubscription<DriverLocationSample>? _subscription;
  DateTime? _lastSentAt;
  final List<DriverLocationSample> _pendingLocations = [];

  Future<void> start(DriverStatus status) async {
    if (!status.canSendLocation) {
      stop();
      return;
    }

    try {
      await _service.ensurePermission();
      await _subscription?.cancel();
      state = LocationState(isTracking: true, lastLocation: state.lastLocation);
      _subscription = _service.watch(status).listen(_onLocation);
    } catch (error) {
      state = LocationState(
        isTracking: false,
        lastLocation: state.lastLocation,
        errorMessage: '$error',
      );
    }
  }

  Future<void> startTripTracking() async {
    try {
      await _service.ensurePermission();
      await _subscription?.cancel();
      state = LocationState(isTracking: true, lastLocation: state.lastLocation);
      _subscription = _service.watchTrip().listen(_onLocation);
    } catch (error) {
      state = LocationState(
        isTracking: false,
        lastLocation: state.lastLocation,
        errorMessage: '$error',
      );
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _lastSentAt = null;
    state = LocationState(isTracking: false, lastLocation: state.lastLocation);
  }

  Future<DriverLocationSample?> currentLocation() async {
    try {
      final location = await _service.currentLocation();
      state = LocationState(
        isTracking: state.isTracking,
        lastLocation: location,
      );
      return location;
    } catch (error) {
      state = LocationState(
        isTracking: state.isTracking,
        lastLocation: state.lastLocation,
        errorMessage: '$error',
      );
      return null;
    }
  }

  Future<void> sendLastLocationBeforeComplete() async {
    final location = await currentLocation();
    if (location == null) {
      return;
    }
    await _sendOrQueue(location);
    await flushPendingLocations();
  }

  Future<void> flushPendingLocations() async {
    if (_pendingLocations.isEmpty) {
      return;
    }

    final batch = _pendingLocations.take(_locationBatchLimit).toList();
    try {
      await _repository.sendBatch(batch);
      _pendingLocations.removeRange(0, batch.length);
    } on ApiException catch (error) {
      state = LocationState(
        isTracking: state.isTracking,
        lastLocation: state.lastLocation,
        errorMessage: error.userMessage,
      );
    }
  }

  Future<void> _onLocation(DriverLocationSample location) async {
    state = LocationState(isTracking: true, lastLocation: location);
    final now = DateTime.now();
    if (_lastSentAt != null && now.difference(_lastSentAt!).inSeconds < 2) {
      return;
    }

    _lastSentAt = now;
    await _sendOrQueue(location);
    await flushPendingLocations();
  }

  Future<void> _sendOrQueue(DriverLocationSample location) async {
    try {
      if (_pendingLocations.isNotEmpty) {
        _pendingLocations.add(location);
        return;
      }
      await _repository.send(location);
    } on ApiException catch (error) {
      if (error.isRateLimited) {
        return;
      }
      _pendingLocations.add(location);
      state = LocationState(
        isTracking: true,
        lastLocation: location,
        errorMessage: error.userMessage,
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
