import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/asset.dart';
import '../models/transaction.dart';
import '../models/setting.dart';
import '../utils/constants.dart';

/// 数据库操作帮助类（单例模式）
/// 封装所有 SQLite 数据库操作
class DatabaseHelper {
  // 单例实例
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // 数据库对象
  static Database? _database;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConstants.databaseName);
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建 assets 表
    await db.execute('''
      CREATE TABLE ${AppConstants.assetsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        model TEXT DEFAULT '',
        barcode TEXT DEFAULT '',
        status TEXT DEFAULT '在库',
        borrower TEXT,
        borrow_date TEXT,
        planned_return_date TEXT,
        actual_return_date TEXT,
        location TEXT DEFAULT '',
        remark TEXT
      )
    ''');

    // 创建 transactions 表
    await db.execute('''
      CREATE TABLE ${AppConstants.transactionsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_id INTEGER NOT NULL,
        asset_code TEXT NOT NULL,
        asset_name TEXT NOT NULL,
        type TEXT NOT NULL,
        operator TEXT DEFAULT '',
        operate_time TEXT NOT NULL,
        remark TEXT,
        FOREIGN KEY (asset_id) REFERENCES assets(id)
      )
    ''');

    // 创建 settings 表
    await db.execute('''
      CREATE TABLE ${AppConstants.settingsTable} (
        key TEXT PRIMARY KEY,
        value TEXT DEFAULT ''
      )
    ''');
  }

  // ==================== Assets 操作 ====================

  /// 插入资产
  Future<int> insertAsset(Asset asset) async {
    final db = await database;
    return await db.insert(AppConstants.assetsTable, asset.toMap());
  }

  /// 更新资产
  Future<int> updateAsset(Asset asset) async {
    final db = await database;
    return await db.update(
      AppConstants.assetsTable,
      asset.toMap(),
      where: 'id = ?',
      whereArgs: [asset.id],
    );
  }

  /// 删除资产
  Future<int> deleteAsset(int id) async {
    final db = await database;
    return await db.delete(
      AppConstants.assetsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 根据 ID 获取资产
  Future<Asset?> getAssetById(int id) async {
    final db = await database;
    final results = await db.query(
      AppConstants.assetsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Asset.fromMap(results.first);
  }

  /// 根据资产编号获取资产
  Future<Asset?> getAssetByCode(String assetCode) async {
    final db = await database;
    final results = await db.query(
      AppConstants.assetsTable,
      where: 'asset_code = ?',
      whereArgs: [assetCode],
    );
    if (results.isEmpty) return null;
    return Asset.fromMap(results.first);
  }

  /// 检查资产编号是否已存在
  Future<bool> assetCodeExists(String assetCode, {int? excludeId}) async {
    final db = await database;
    String where = 'asset_code = ?';
    List<dynamic> whereArgs = [assetCode];
    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    final results = await db.query(
      AppConstants.assetsTable,
      where: where,
      whereArgs: whereArgs,
    );
    return results.isNotEmpty;
  }

  /// 获取所有资产（支持筛选）
  Future<List<Asset>> getAllAssets({
    String? keyword,
    String? category,
    String? status,
  }) async {
    final db = await database;
    String? where;
    List<dynamic> whereArgs = [];

    final conditions = <String>[];
    if (keyword != null && keyword.isNotEmpty) {
      conditions.add('(name LIKE ? OR asset_code LIKE ?)');
      whereArgs.addAll(['%$keyword%', '%$keyword%']);
    }
    if (category != null && category.isNotEmpty) {
      conditions.add('category = ?');
      whereArgs.add(category);
    }
    if (status != null && status.isNotEmpty) {
      conditions.add('status = ?');
      whereArgs.add(status);
    }
    if (conditions.isNotEmpty) {
      where = conditions.join(' AND ');
    }

    final results = await db.query(
      AppConstants.assetsTable,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );
    return results.map((map) => Asset.fromMap(map)).toList();
  }

  /// 获取超期资产列表
  Future<List<Asset>> getOverdueAssets() async {
    final db = await database;
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final results = await db.query(
      AppConstants.assetsTable,
      where: "status = '已领用' AND planned_return_date IS NOT NULL AND planned_return_date < ?",
      whereArgs: [today],
      orderBy: 'planned_return_date ASC',
    );
    return results.map((map) => Asset.fromMap(map)).toList();
  }

  /// 统计资产数量
  Future<Map<String, int>> getAssetStats() async {
    final db = await database;
    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${AppConstants.assetsTable}'),
    ) ?? 0;
    final inStock = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM ${AppConstants.assetsTable} WHERE status = '在库'"),
    ) ?? 0;
    final borrowed = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM ${AppConstants.assetsTable} WHERE status = '已领用'"),
    ) ?? 0;

    // 超期数
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final overdue = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM ${AppConstants.assetsTable} WHERE status = '已领用' AND planned_return_date IS NOT NULL AND planned_return_date < ?",
        [today],
      ),
    ) ?? 0;

    return {
      'total': total,
      'inStock': inStock,
      'borrowed': borrowed,
      'overdue': overdue,
    };
  }

  /// 获取在库资产列表（出库选择用）
  Future<List<Asset>> getInStockAssets() async {
    final db = await database;
    final results = await db.query(
      AppConstants.assetsTable,
      where: "status = '在库'",
      orderBy: 'name ASC',
    );
    return results.map((map) => Asset.fromMap(map)).toList();
  }

  /// 获取已领用/维修中资产列表（入库选择用）
  Future<List<Asset>> getReturnableAssets() async {
    final db = await database;
    final results = await db.query(
      AppConstants.assetsTable,
      where: "status = '已领用' OR status = '维修中'",
      orderBy: 'name ASC',
    );
    return results.map((map) => Asset.fromMap(map)).toList();
  }

  // ==================== Transactions 操作 ====================

  /// 插入出入库记录
  Future<int> insertTransaction(AssetTransaction transaction) async {
    final db = await database;
    return await db.insert(AppConstants.transactionsTable, transaction.toMap());
  }

  /// 获取所有出入库记录（时间倒序）
  Future<List<AssetTransaction>> getAllTransactions({int? limit}) async {
    final db = await database;
    final results = await db.query(
      AppConstants.transactionsTable,
      orderBy: 'operate_time DESC',
      limit: limit,
    );
    return results.map((map) => AssetTransaction.fromMap(map)).toList();
  }

  /// 获取指定资产的出入库记录
  Future<List<AssetTransaction>> getTransactionsByAssetId(int assetId) async {
    final db = await database;
    final results = await db.query(
      AppConstants.transactionsTable,
      where: 'asset_id = ?',
      whereArgs: [assetId],
      orderBy: 'operate_time DESC',
    );
    return results.map((map) => AssetTransaction.fromMap(map)).toList();
  }

  // ==================== Settings 操作 ====================

  /// 获取设置值
  Future<String> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      AppConstants.settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (results.isEmpty) return '';
    return results.first['value'] as String? ?? '';
  }

  /// 保存设置值
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      AppConstants.settingsTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 获取所有设置
  Future<List<Setting>> getAllSettings() async {
    final db = await database;
    final results = await db.query(AppConstants.settingsTable);
    return results.map((map) => Setting.fromMap(map)).toList();
  }
}
