import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/route_stop.dart';
import '../models/seat_availability.dart';
import '../models/train.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = join(dbPath, 'trainsmurf.db');

    // Copy the prebuilt database from assets on first run.
    if (!await databaseExists(dbFilePath)) {
      try {
        await _copyPreloadedDatabase(dbFilePath);
      } catch (_) {
        // If copying fails, onCreate below will build schema and seed dummy data.
      }
    }

    return openDatabase(
      dbFilePath,
      version: 1,
      onCreate: _onCreate,
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    await _ensureUsersTable(db);
  }

  Future<void> _copyPreloadedDatabase(String dbFilePath) async {
    final data = await rootBundle.load('lib/assets/train_data.db');
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    await Directory(dirname(dbFilePath)).create(recursive: true);
    final file = File(dbFilePath);
    await file.writeAsBytes(bytes, flush: true);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Train table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Train (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        train_no TEXT NOT NULL,
        train_name TEXT NOT NULL,
        source TEXT NOT NULL,
        destination TEXT NOT NULL,
        departure TEXT NOT NULL,
        arrival TEXT NOT NULL
      )
    ''');

    // Route table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Route (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        train_no TEXT NOT NULL,
        station_name TEXT NOT NULL,
        arrival TEXT NOT NULL,
        departure TEXT NOT NULL,
        stop_number INTEGER NOT NULL
      )
    ''');

    // SeatAvailability table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS SeatAvailability (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        train_no TEXT NOT NULL,
        date TEXT NOT NULL,
        sleeper INTEGER NOT NULL,
        ac3 INTEGER NOT NULL,
        ac2 INTEGER NOT NULL,
        ac1 INTEGER NOT NULL
      )
    ''');

    await _ensureUsersTable(db);

    await _insertDummyData(db);
  }

  Future<void> _ensureUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');
  }

  Future<void> _insertDummyData(Database db) async {
    final existing = await db.rawQuery('SELECT COUNT(*) AS c FROM Train');
    final count = (existing.first['c'] as int?) ?? 0;
    if (count > 0) {
      return;
    }

    final trains = <Train>[
      Train(
        trainNo: '12951',
        trainName: 'Mumbai Rajdhani Express',
        source: 'Mumbai Central',
        destination: 'New Delhi',
        departure: '17:00',
        arrival: '08:35',
      ),
      Train(
        trainNo: '12002',
        trainName: 'Bhopal Shatabdi Express',
        source: 'New Delhi',
        destination: 'Bhopal Jn',
        departure: '06:00',
        arrival: '14:25',
      ),
      Train(
        trainNo: '12213',
        trainName: 'Yeshvantpur Duronto Express',
        source: 'Yesvantpur Jn',
        destination: 'Delhi Sarai Rohilla',
        departure: '23:40',
        arrival: '05:00',
      ),
      Train(
        trainNo: '22436',
        trainName: 'Vande Bharat Express',
        source: 'New Delhi',
        destination: 'Varanasi Jn',
        departure: '06:00',
        arrival: '14:00',
      ),
      Train(
        trainNo: '12628',
        trainName: 'Karnataka Express',
        source: 'New Delhi',
        destination: 'KSR Bengaluru',
        departure: '19:20',
        arrival: '11:40',
      ),
      Train(
        trainNo: '12302',
        trainName: 'Howrah Rajdhani Express',
        source: 'New Delhi',
        destination: 'Howrah Jn',
        departure: '16:50',
        arrival: '10:05',
      ),
      Train(
        trainNo: '12009',
        trainName: 'Shatabdi Express',
        source: 'Mumbai Central',
        destination: 'Ahmedabad Jn',
        departure: '06:25',
        arrival: '12:45',
      ),
      Train(
        trainNo: '22222',
        trainName: 'CSMT Vande Bharat',
        source: 'Mumbai CSMT',
        destination: 'Madgaon Jn',
        departure: '05:25',
        arrival: '13:15',
      ),
    ];

    for (final train in trains) {
      await db.insert('Train', train.toMap());
    }

    final routes = <RouteStop>[
      // 12951
      RouteStop(trainNo: '12951', stationName: 'Mumbai Central', arrival: 'START', departure: '17:00', stopNumber: 1),
      RouteStop(trainNo: '12951', stationName: 'Vadodara Jn', arrival: '21:25', departure: '21:35', stopNumber: 2),
      RouteStop(trainNo: '12951', stationName: 'Kota Jn', arrival: '03:05', departure: '03:15', stopNumber: 3),
      RouteStop(trainNo: '12951', stationName: 'New Delhi', arrival: '08:35', departure: 'END', stopNumber: 4),

      // 12002
      RouteStop(trainNo: '12002', stationName: 'New Delhi', arrival: 'START', departure: '06:00', stopNumber: 1),
      RouteStop(trainNo: '12002', stationName: 'Agra Cantt', arrival: '08:02', departure: '08:05', stopNumber: 2),
      RouteStop(trainNo: '12002', stationName: 'Jhansi Jn', arrival: '10:43', departure: '10:45', stopNumber: 3),
      RouteStop(trainNo: '12002', stationName: 'Bhopal Jn', arrival: '14:25', departure: 'END', stopNumber: 4),

      // 22436
      RouteStop(trainNo: '22436', stationName: 'New Delhi', arrival: 'START', departure: '06:00', stopNumber: 1),
      RouteStop(trainNo: '22436', stationName: 'Kanpur Central', arrival: '10:08', departure: '10:10', stopNumber: 2),
      RouteStop(trainNo: '22436', stationName: 'Prayagraj Jn', arrival: '12:02', departure: '12:04', stopNumber: 3),
      RouteStop(trainNo: '22436', stationName: 'Varanasi Jn', arrival: '14:00', departure: 'END', stopNumber: 4),

      // 12628
      RouteStop(trainNo: '12628', stationName: 'New Delhi', arrival: 'START', departure: '19:20', stopNumber: 1),
      RouteStop(trainNo: '12628', stationName: 'Agra Cantt', arrival: '21:08', departure: '21:10', stopNumber: 2),
      RouteStop(trainNo: '12628', stationName: 'Bhopal Jn', arrival: '06:00', departure: '06:10', stopNumber: 3),
      RouteStop(trainNo: '12628', stationName: 'KSR Bengaluru', arrival: '11:40', departure: 'END', stopNumber: 4),

      // 12302
      RouteStop(trainNo: '12302', stationName: 'New Delhi', arrival: 'START', departure: '16:50', stopNumber: 1),
      RouteStop(trainNo: '12302', stationName: 'Gaya Jn', arrival: '03:45', departure: '03:50', stopNumber: 2),
      RouteStop(trainNo: '12302', stationName: 'Dhanbad Jn', arrival: '06:10', departure: '06:15', stopNumber: 3),
      RouteStop(trainNo: '12302', stationName: 'Howrah Jn', arrival: '10:05', departure: 'END', stopNumber: 4),

      // 12009
      RouteStop(trainNo: '12009', stationName: 'Mumbai Central', arrival: 'START', departure: '06:25', stopNumber: 1),
      RouteStop(trainNo: '12009', stationName: 'Borivali', arrival: '06:48', departure: '06:50', stopNumber: 2),
      RouteStop(trainNo: '12009', stationName: 'Surat', arrival: '09:15', departure: '09:17', stopNumber: 3),
      RouteStop(trainNo: '12009', stationName: 'Ahmedabad Jn', arrival: '12:45', departure: 'END', stopNumber: 4),

      // 22222
      RouteStop(trainNo: '22222', stationName: 'Mumbai CSMT', arrival: 'START', departure: '05:25', stopNumber: 1),
      RouteStop(trainNo: '22222', stationName: 'Ratnagiri', arrival: '10:20', departure: '10:22', stopNumber: 2),
      RouteStop(trainNo: '22222', stationName: 'Kudal', arrival: '11:38', departure: '11:40', stopNumber: 3),
      RouteStop(trainNo: '22222', stationName: 'Madgaon Jn', arrival: '13:15', departure: 'END', stopNumber: 4),

      // 12213
      RouteStop(trainNo: '12213', stationName: 'Yesvantpur Jn', arrival: 'START', departure: '23:40', stopNumber: 1),
      RouteStop(trainNo: '12213', stationName: 'Secunderabad Jn', arrival: '12:10', departure: '12:20', stopNumber: 2),
      RouteStop(trainNo: '12213', stationName: 'Nagpur', arrival: '22:35', departure: '22:40', stopNumber: 3),
      RouteStop(trainNo: '12213', stationName: 'Delhi Sarai Rohilla', arrival: '05:00', departure: 'END', stopNumber: 4),
    ];

    for (final route in routes) {
      await db.insert('Route', route.toMap());
    }

    final dates = [
      '2026-03-17',
      '2026-03-18',
      '2026-03-19',
      '2026-03-20',
      '2026-03-21',
    ];

    final seatRows = <SeatAvailability>[];
    for (final train in trains) {
      for (var i = 0; i < dates.length; i++) {
        seatRows.add(
          SeatAvailability(
            trainNo: train.trainNo,
            date: dates[i],
            sleeper: 90 - (i * 7),
            ac3: 60 - (i * 5),
            ac2: 35 - (i * 3),
            ac1: 12 - i,
          ),
        );
      }
    }

    for (final seat in seatRows) {
      await db.insert('SeatAvailability', seat.toMap());
    }
  }

  Future<List<Train>> searchTrains({
    required String source,
    required String destination,
    String? trainNo,
  }) async {
    final db = await database;

    final whereClauses = <String>[
      'LOWER(source) LIKE ?',
      'LOWER(destination) LIKE ?',
    ];
    final whereArgs = <dynamic>[
      '%${source.toLowerCase()}%',
      '%${destination.toLowerCase()}%',
    ];

    if (trainNo != null && trainNo.trim().isNotEmpty) {
      whereClauses.add('train_no = ?');
      whereArgs.add(trainNo.trim());
    }

    final result = await db.query(
      'Train',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'train_name ASC',
    );

    return result.map((e) => Train.fromMap(e)).toList();
  }

  // Smart search:
  // 1) Exact match on train number when provided
  // 2) Otherwise destination LIKE search
  Future<List<Train>> searchTrainsSmart({
    String? destination,
    String? trainNo,
  }) async {
    final db = await database;

    final cleanTrainNo = (trainNo ?? '').trim();
    final cleanDestination = (destination ?? '').trim();

    if (cleanTrainNo.isNotEmpty) {
      final result = await db.query(
        'Train',
        where: 'train_no = ?',
        whereArgs: [cleanTrainNo],
        orderBy: 'train_name ASC',
      );
      return result.map((e) => Train.fromMap(e)).toList();
    }

    if (cleanDestination.isNotEmpty) {
      final result = await db.query(
        'Train',
        where: 'LOWER(destination) LIKE ?',
        whereArgs: ['%${cleanDestination.toLowerCase()}%'],
        orderBy: 'train_name ASC',
      );
      return result.map((e) => Train.fromMap(e)).toList();
    }

    return [];
  }

  Future<List<String>> getDestinationSuggestions(String input) async {
    final db = await database;
    final cleanInput = input.trim().toLowerCase();
    if (cleanInput.isEmpty) return [];

    final result = await db.rawQuery(
      '''
      SELECT DISTINCT destination
      FROM Train
      WHERE LOWER(destination) LIKE ?
      ORDER BY destination ASC
      LIMIT 8
      ''',
      ['%$cleanInput%'],
    );

    return result
        .map((row) => (row['destination'] ?? '').toString())
        .where((v) => v.isNotEmpty)
        .toList();
  }

  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();

    final existing = await db.query(
      'Users',
      where: 'LOWER(email) = ?',
      whereArgs: [cleanEmail],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return false;
    }

    await db.insert('Users', {
      'name': name.trim(),
      'email': cleanEmail,
      'password': password,
    });
    return true;
  }

  Future<Map<String, dynamic>?> validateUser({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();

    final result = await db.query(
      'Users',
      where: 'LOWER(email) = ? AND password = ?',
      whereArgs: [cleanEmail, password],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();

    final result = await db.query(
      'Users',
      where: 'LOWER(email) = ?',
      whereArgs: [cleanEmail],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final db = await database;
    final cleanEmail = email.trim().toLowerCase();

    final updated = await db.update(
      'Users',
      {'password': newPassword},
      where: 'LOWER(email) = ?',
      whereArgs: [cleanEmail],
    );

    return updated > 0;
  }

  Future<SeatAvailability?> getSeatAvailability(String trainNo, String date) async {
    final db = await database;
    final result = await db.query(
      'SeatAvailability',
      where: 'train_no = ? AND date = ?',
      whereArgs: [trainNo, date],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return SeatAvailability.fromMap(result.first);
  }

  Future<List<RouteStop>> getRouteByTrainNo(String trainNo) async {
    final db = await database;
    final result = await db.query(
      'Route',
      where: 'train_no = ?',
      whereArgs: [trainNo],
      orderBy: 'stop_number ASC',
    );

    return result.map((e) => RouteStop.fromMap(e)).toList();
  }

  Future<void> decreaseSeatsSlightlyForSimulation() async {
    final db = await database;

    final rows = await db.query('SeatAvailability');
    for (final row in rows) {
      final id = row['id'] as int;
      int sleeper = row['sleeper'] as int;
      int ac3 = row['ac3'] as int;
      int ac2 = row['ac2'] as int;
      int ac1 = row['ac1'] as int;

      if (sleeper > 0) sleeper -= 1;
      if (ac3 > 0) ac3 -= 1;
      if (ac2 > 0) ac2 -= 1;
      if (ac1 > 0) ac1 -= 1;

      await db.update(
        'SeatAvailability',
        {
          'sleeper': sleeper,
          'ac3': ac3,
          'ac2': ac2,
          'ac1': ac1,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
