import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_service.dart';
import '../../../core/network/api_error.dart';
import '../data/location_repository.dart';
import '../domain/driver_profile.dart';

const _locationBatchLimit = 50;

class LocationState {
  const LocationState({
    required this.isTracking,
    this.activeOrderId,
    this.lastLocation,
    this.errorMessage,
  });

  const LocationState.idle() : this(isTracking: false);

  final bool isTracking;
  final String? activeOrderId;
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
    : super(const LocationState.idle()) {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (results.contains(ConnectivityResult.none)) {
        return;
      }
      unawaited(flushPendingRoutes());
    });
  }

  final LocationService _service;
  final LocationRepository _repository;
  StreamSubscription<DriverLocationSample>? _subscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _heartbeatTimer;
  DateTime? _lastSentAt;
  var _flushInProgress = false;

  Future<void> start(DriverStatus status) async {
    if (!status.canSendLocation) {
      stop();
      return;
    }

    try {
      await _service.ensurePermission();
      await _subscription?.cancel();
      state = LocationState(
        isTracking: true,
        activeOrderId: null,
        lastLocation: state.lastLocation,
      );
      _subscription = _service.watch(status).listen(_onLocation);
      _startHeartbeat();
      unawaited(flushPendingRoutes());
    } catch (error) {
      state = LocationState(
        isTracking: false,
        activeOrderId: null,
        lastLocation: state.lastLocation,
        errorMessage: '$error',
      );
    }
  }

  Future<void> startTripTracking(String orderId) async {
    try {
      await _service.ensurePermission();
      await _subscription?.cancel();
      state = LocationState(
        isTracking: true,
        activeOrderId: orderId,
        lastLocation: state.lastLocation,
      );
      _subscription = _service.watchTrip().listen(_onLocation);
      _startHeartbeat();
      unawaited(flushPendingRoutes());
    } catch (error) {
      state = LocationState(
        isTracking: false,
        activeOrderId: orderId,
        lastLocation: state.lastLocation,
        errorMessage: '$error',
      );
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _lastSentAt = null;
    state = LocationState(
      isTracking: false,
      lastLocation: state.lastLocation,
      activeOrderId: null,
    );
  }

  Future<DriverLocationSample?> currentLocation() async {
    try {
      final location = await _service.currentLocation();
      state = LocationState(
        isTracking: state.isTracking,
        activeOrderId: state.activeOrderId,
        lastLocation: location,
      );
      return location;
    } catch (error) {
      state = LocationState(
        isTracking: state.isTracking,
        activeOrderId: state.activeOrderId,
        lastLocation: state.lastLocation,
        errorMessage: '$error',
      );
      return null;
    }
  }

  Future<void> sendLastLocationBeforeComplete(String orderId) async {
    final location = await currentLocation();
    if (location == null) {
      return;
    }
    await _sendPresence(location, force: true);
    await _persistAndFlushRoute(orderId, location, force: true);
    await flushPendingRoutes();
  }

  Future<void> flushPendingRoutes() async {
    if (_flushInProgress) {
      return;
    }

    _flushInProgress = true;
    try {
      while (true) {
        final orderId = await _repository.readOldestRouteOrderId();
        if (orderId == null || orderId.isEmpty) {
          return;
        }
        final batch = await _repository.readRoutePoints(
          orderId,
          limit: _locationBatchLimit,
        );
        if (batch.isEmpty) {
          return;
        }
        try {
          await _repository.sendRouteBatch(
            orderId,
            batch.map((item) => item.sample).toList(growable: false),
          );
          await _repository.deleteRoutePoints(
            batch.map((item) => item.id).toList(growable: false),
          );
        } on ApiException catch (error) {
          state = LocationState(
            isTracking: state.isTracking,
            activeOrderId: state.activeOrderId,
            lastLocation: state.lastLocation,
            errorMessage: error.userMessage,
          );
          return;
        }
      }
    } finally {
      _flushInProgress = false;
    }
  }

  Future<void> _onLocation(DriverLocationSample location) async {
    state = LocationState(isTracking: true, lastLocation: location);
    final now = DateTime.now();
    if (_lastSentAt != null && now.difference(_lastSentAt!).inSeconds < 2) {
      return;
    }

    _lastSentAt = now;
    await _sendPresence(location);
    final orderId = state.activeOrderId;
    if (orderId != null && orderId.isNotEmpty) {
      await _persistAndFlushRoute(orderId, location);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(_sendHeartbeat());
    });
  }

  Future<void> _sendHeartbeat() async {
    if (!state.isTracking) {
      return;
    }

    DriverLocationSample? location = state.lastLocation;
    if (location == null) {
      try {
        location = await _service.currentLocation();
      } catch (_) {
        location = null;
      }
    }
    if (location == null) {
      return;
    }

    await _sendPresence(location, force: true);
    final orderId = state.activeOrderId;
    if (orderId != null && orderId.isNotEmpty) {
      await _persistAndFlushRoute(orderId, location, force: true);
    }
  }

  Future<void> _sendPresence(
    DriverLocationSample location, {
    bool force = false,
  }) async {
    try {
      await _repository.send(location);
    } on ApiException catch (error) {
      if (error.isRateLimited && !force) {
        return;
      }
      state = LocationState(
        isTracking: state.isTracking,
        activeOrderId: state.activeOrderId,
        lastLocation: location,
        errorMessage: error.userMessage,
      );
    }
  }

  Future<void> _persistAndFlushRoute(
    String orderId,
    DriverLocationSample location, {
    bool force = false,
  }) async {
    await _repository.enqueueRoutePoint(orderId, location);
    if (force) {
      await flushPendingRoutes();
      return;
    }

    try {
      await flushPendingRoutes();
    } on ApiException catch (error) {
      if (error.isRateLimited) {
        return;
      }
      state = LocationState(
        isTracking: true,
        activeOrderId: orderId,
        lastLocation: location,
        errorMessage: error.userMessage,
      );
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
