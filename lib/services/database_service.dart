import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/martyr.dart';
import '../models/injured.dart';
import '../models/prisoner.dart';
import '../constants/app_constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'palestine_martyrs.db');
    
    return await openDatabase(
      path,
      version: 2, // ✅ Incremented version for schema change
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // جدول المستخدمين
    await db.execute('''
      CREATE TABLE ${AppConstants.tableUsers} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        full_name TEXT NOT NULL,
        user_type TEXT NOT NULL,
        phone_number TEXT,
        created_at TEXT NOT NULL,
        last_login TEXT
      )
    ''');

    // جدول الشهداء
    await db.execute('''
      CREATE TABLE ${AppConstants.tableMartyrs} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        nickname TEXT,
        tribe TEXT NOT NULL,
        birth_date TEXT,
        death_date TEXT NOT NULL,
        death_place TEXT NOT NULL,
        cause_of_death TEXT NOT NULL,
        rank_or_position TEXT,
        participation_fronts TEXT,
        family_status TEXT,
        num_children INTEGER,
        contact_family TEXT NOT NULL,
        added_by_user_id TEXT NOT NULL,
        photo_path TEXT,
        cv_file_path TEXT,
        status TEXT NOT NULL DEFAULT '${AppConstants.statusPending}',
        admin_notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // جدول الجرحى
    await db.execute('''
      CREATE TABLE ${AppConstants.tableInjured} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        tribe TEXT NOT NULL,
        injury_date TEXT NOT NULL,
        injury_place TEXT NOT NULL,
        injury_type TEXT NOT NULL,
        injury_description TEXT NOT NULL,
        injury_degree TEXT NOT NULL,
        current_status TEXT NOT NULL,
        hospital_name TEXT,
        contact_family TEXT NOT NULL,
        added_by_user_id TEXT NOT NULL,
        photo_path TEXT,
        cv_file_path TEXT,
        status TEXT NOT NULL DEFAULT '${AppConstants.statusPending}',
        admin_notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // جدول الأسرى
    await db.execute('''
      CREATE TABLE ${AppConstants.tablePrisoners} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        tribe TEXT NOT NULL,
        capture_date TEXT NOT NULL,
        capture_place TEXT NOT NULL,
        captured_by TEXT NOT NULL,
        current_status TEXT NOT NULL,
        release_date TEXT,
        family_contact TEXT NOT NULL,
        detention_place TEXT,
        notes TEXT,
        added_by_user_id TEXT NOT NULL,
        photo_path TEXT,
        cv_file_path TEXT,
        status TEXT NOT NULL DEFAULT '${AppConstants.statusPending}',
        admin_notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // إنشاء مستخدم مسؤول افتراضي
    await db.insert(AppConstants.tableUsers, {
      'username': 'admin',
      'password': 'admin123', // في الإنتاج يجب تشفير كلمة المرور
      'full_name': 'المسؤول العام',
      'user_type': AppConstants.userTypeAdmin,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // دالة upgrade لتحديث قاعدة البيانات
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // تحديث من version 1 إلى version 2
      // تغيير added_by_user_id من INTEGER إلى TEXT
      
      // للأسف SQLite لا يدعم ALTER COLUMN، يجب إعادة إنشاء الجداول
      // لكن لحسن الحظ في المرحلة التجريبية، يمكننا حذف وإعادة إنشاء
      await db.execute('DROP TABLE IF EXISTS ${AppConstants.tableMartyrs}');
      await db.execute('DROP TABLE IF EXISTS ${AppConstants.tableInjured}');
      await db.execute('DROP TABLE IF EXISTS ${AppConstants.tablePrisoners}');
      
      // إعادة إنشاء الجداول بالنظام الجديد
      await db.execute('''
        CREATE TABLE ${AppConstants.tableMartyrs} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          full_name TEXT NOT NULL,
          nickname TEXT,
          tribe TEXT NOT NULL,
          birth_date TEXT,
          death_date TEXT NOT NULL,
          death_place TEXT NOT NULL,
          cause_of_death TEXT NOT NULL,
          rank_or_position TEXT,
          participation_fronts TEXT,
          family_status TEXT,
          num_children INTEGER,
          contact_family TEXT NOT NULL,
          added_by_user_id TEXT NOT NULL,
          photo_path TEXT,
          cv_file_path TEXT,
          status TEXT NOT NULL DEFAULT '${AppConstants.statusPending}',
          admin_notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE ${AppConstants.tableInjured} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          full_name TEXT NOT NULL,
          tribe TEXT NOT NULL,
          injury_date TEXT NOT NULL,
          injury_place TEXT NOT NULL,
          injury_type TEXT NOT NULL,
          injury_description TEXT NOT NULL,
          injury_degree TEXT NOT NULL,
          current_status TEXT NOT NULL,
          hospital_name TEXT,
          contact_family TEXT NOT NULL,
          added_by_user_id TEXT NOT NULL,
          photo_path TEXT,
          cv_file_path TEXT,
          status TEXT NOT NULL DEFAULT '${AppConstants.statusPending}',
          admin_notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE ${AppConstants.tablePrisoners} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          full_name TEXT NOT NULL,
          tribe TEXT NOT NULL,
          capture_date TEXT NOT NULL,
          capture_place TEXT NOT NULL,
          captured_by TEXT NOT NULL,
          current_status TEXT NOT NULL,
          release_date TEXT,
          family_contact TEXT NOT NULL,
          detention_place TEXT,
          notes TEXT,
          added_by_user_id TEXT NOT NULL,
          photo_path TEXT,
          cv_file_path TEXT,
          status TEXT NOT NULL DEFAULT '${AppConstants.statusPending}',
          admin_notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');
    }
  }

  // ===== دوال المستخدمين =====
  
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(AppConstants.tableUsers, user.toMap());
  }

  Future<User?> getUserByCredentials(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableUsers,
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> isUsernameExists(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableUsers,
      where: 'username = ?',
      whereArgs: [username],
    );
    return maps.isNotEmpty;
  }

  Future<void> updateUserLastLogin(int userId) async {
    final db = await database;
    await db.update(
      AppConstants.tableUsers,
      {'last_login': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tableUsers);
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      AppConstants.tableUsers,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser(int userId) async {
    final db = await database;
    await db.delete(
      AppConstants.tableUsers,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ===== دوال الشهداء =====

  Future<int> insertMartyr(Martyr martyr) async {
    final db = await database;
    return await db.insert(AppConstants.tableMartyrs, martyr.toMap());
  }

  Future<List<Martyr>> getAllMartyrs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tableMartyrs);
    return List.generate(maps.length, (i) => Martyr.fromMap(maps[i]));
  }

  Future<List<Martyr>> getMartyrsByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableMartyrs,
      where: 'added_by_user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Martyr.fromMap(maps[i]));
  }

  Future<void> updateMartyrStatus(int id, String status, String? adminNotes) async {
    final db = await database;
    await db.update(
      AppConstants.tableMartyrs,
      {
        'status': status,
        'admin_notes': adminNotes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateMartyr(Martyr martyr) async {
    final db = await database;
    await db.update(
      AppConstants.tableMartyrs,
      martyr.toMap(),
      where: 'id = ?',
      whereArgs: [martyr.id],
    );
  }

  Future<void> deleteMartyr(int id) async {
    final db = await database;
    await db.delete(
      AppConstants.tableMartyrs,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== دوال الجرحى =====

  Future<int> insertInjured(Injured injured) async {
    final db = await database;
    return await db.insert(AppConstants.tableInjured, injured.toMap());
  }

  Future<List<Injured>> getAllInjured() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tableInjured);
    return List.generate(maps.length, (i) => Injured.fromMap(maps[i]));
  }

  Future<List<Injured>> getInjuredByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableInjured,
      where: 'added_by_user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Injured.fromMap(maps[i]));
  }

  Future<void> updateInjuredStatus(int id, String status, String? adminNotes) async {
    final db = await database;
    await db.update(
      AppConstants.tableInjured,
      {
        'status': status,
        'admin_notes': adminNotes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateInjured(Injured injured) async {
    final db = await database;
    await db.update(
      AppConstants.tableInjured,
      injured.toMap(),
      where: 'id = ?',
      whereArgs: [injured.id],
    );
  }

  Future<void> deleteInjured(int id) async {
    final db = await database;
    await db.delete(
      AppConstants.tableInjured,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== دوال الأسرى =====

  Future<int> insertPrisoner(Prisoner prisoner) async {
    final db = await database;
    return await db.insert(AppConstants.tablePrisoners, prisoner.toMap());
  }

  Future<List<Prisoner>> getAllPrisoners() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(AppConstants.tablePrisoners);
    return List.generate(maps.length, (i) => Prisoner.fromMap(maps[i]));
  }

  Future<List<Prisoner>> getPrisonersByUserId(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tablePrisoners,
      where: 'added_by_user_id = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Prisoner.fromMap(maps[i]));
  }

  Future<void> updatePrisonerStatus(int id, String status, String? adminNotes) async {
    final db = await database;
    await db.update(
      AppConstants.tablePrisoners,
      {
        'status': status,
        'admin_notes': adminNotes,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updatePrisoner(Prisoner prisoner) async {
    final db = await database;
    await db.update(
      AppConstants.tablePrisoners,
      prisoner.toMap(),
      where: 'id = ?',
      whereArgs: [prisoner.id],
    );
  }

  Future<void> deletePrisoner(int id) async {
    final db = await database;
    await db.delete(
      AppConstants.tablePrisoners,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== دوال الإحصائيات =====

  Future<Map<String, int>> getStatistics() async {
    final db = await database;

    final martyrsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${AppConstants.tableMartyrs}')) ?? 0;
    
    final injuredCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${AppConstants.tableInjured}')) ?? 0;
    
    final prisonersCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${AppConstants.tablePrisoners}')) ?? 0;

    final pendingCount = Sqflite.firstIntValue(
        await db.rawQuery('''
          SELECT COUNT(*) FROM (
            SELECT id FROM ${AppConstants.tableMartyrs} WHERE status = ?
            UNION ALL
            SELECT id FROM ${AppConstants.tableInjured} WHERE status = ?
            UNION ALL
            SELECT id FROM ${AppConstants.tablePrisoners} WHERE status = ?
          )
        ''', [AppConstants.statusPending, AppConstants.statusPending, AppConstants.statusPending])) ?? 0;

    return {
      'martyrs': martyrsCount,
      'injured': injuredCount,
      'prisoners': prisonersCount,
      'pending': pendingCount,
    };
  }

  // ===== دوال عامة =====

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }
}