import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../location/location_service.dart';
import '../../features/orders/domain/driver_order.dart';

class QueuedOrderRoutePoint {
  const QueuedOrderRoutePoint({
    required this.id,
    required this.orderId,
    required this.sample,
  });

  final int id;
  final String orderId;
  final DriverLocationSample sample;
}

class DriverLocationOutboxStore {
  static const _databaseName = 'taxi_driver.db';
  static const _databaseVersion = 2;
  static const _tableName = 'driver_route_outbox';

  Database? _database;

  Future<int> enqueueRoutePoint(
    String orderId,
    DriverLocationSample sample,
  ) async {
    final database = await _openDatabase();
    return database.insert(_tableName, {
      'order_id': orderId,
      'latitude': sample.coordinates.latitude,
      'longitude': sample.coordinates.longitude,
      'heading': sample.heading,
      'speed_mps': sample.speedMetersPerSecond,
      'accuracy_meters': sample.accuracyMeters,
      'recorded_at': sample.recordedAt.toUtc().toIso8601String(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<String?> readOldestRouteOrderId() async {
    final database = await _openDatabase();
    final rows = await database.query(
      _tableName,
      columns: const ['order_id'],
      orderBy: 'id ASC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['order_id'] as String?;
  }

  Future<List<QueuedOrderRoutePoint>> readRoutePoints(
    String orderId, {
    required int limit,
  }) async {
    final database = await _openDatabase();
    final rows = await database.query(
      _tableName,
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'id ASC',
      limit: limit,
    );
    return rows.map(_mapRow).toList(growable: false);
  }

  Future<void> deleteByIds(List<int> ids) async {
    if (ids.isEmpty) {
      return;
    }

    final database = await _openDatabase();
    final placeholders = List.filled(ids.length, '?').join(',');
    await database.delete(
      _tableName,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  Future<void> clear() async {
    final database = await _openDatabase();
    await database.delete(_tableName);
  }

  Future<Database> _openDatabase() async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final databasesPath = await getDatabasesPath();
    final path = '$databasesPath${Platform.pathSeparator}$_databaseName';
    final database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, _) async => _createSchema(db),
      onUpgrade: (db, _, __) async {
        await db.execute('DROP TABLE IF EXISTS $_tableName');
        await _createSchema(db);
      },
    );
    _database = database;
    return database;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        heading INTEGER,
        speed_mps REAL,
        accuracy_meters REAL,
        recorded_at TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_driver_route_outbox_order_id_id ON $_tableName(order_id, id)',
    );
  }

  QueuedOrderRoutePoint _mapRow(Map<String, Object?> row) {
    return QueuedOrderRoutePoint(
      id: row['id'] as int,
      orderId: row['order_id'] as String,
      sample: DriverLocationSample(
        coordinates: Coordinates(
          latitude: row['latitude'] as double,
          longitude: row['longitude'] as double,
        ),
        recordedAt: DateTime.parse(row['recorded_at'] as String).toUtc(),
        heading: row['heading'] as int?,
        speedMetersPerSecond: row['speed_mps'] as double?,
        accuracyMeters: row['accuracy_meters'] as double?,
      ),
    );
  }
}

final driverLocationOutboxStoreProvider = Provider<DriverLocationOutboxStore>(
  (ref) => DriverLocationOutboxStore(),
);
