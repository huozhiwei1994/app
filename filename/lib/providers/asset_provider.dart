import 'package:flutter/foundation.dart';
import '../models/asset.dart';
import '../services/database_helper.dart';

/// 资产 Provider - 管理资产数据的增删改查和状态
class AssetProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Asset> _assets = [];
  List<Asset> _overdueAssets = [];
  Map<String, int> _stats = {};
  bool _isLoading = false;

  // Getters
  List<Asset> get assets => _assets;
  List<Asset> get overdueAssets => _overdueAssets;
  Map<String, int> get stats => _stats;
  bool get isLoading => _isLoading;

  /// 加载所有资产（支持筛选）
  Future<void> loadAssets({
    String? keyword,
    String? category,
    String? status,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _assets = await _db.getAllAssets(
        keyword: keyword,
        category: category,
        status: status,
      );
    } catch (e) {
      debugPrint('加载资产列表失败: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// 加载超期资产
  Future<void> loadOverdueAssets() async {
    try {
      _overdueAssets = await _db.getOverdueAssets();
      notifyListeners();
    } catch (e) {
      debugPrint('加载超期资产失败: $e');
    }
  }

  /// 加载统计数据
  Future<void> loadStats() async {
    try {
      _stats = await _db.getAssetStats();
      notifyListeners();
    } catch (e) {
      debugPrint('加载统计数据失败: $e');
    }
  }

  /// 新增资产
  Future<bool> addAsset(Asset asset) async {
    try {
      // 检查编号是否重复
      final exists = await _db.assetCodeExists(asset.assetCode);
      if (exists) return false;

      await _db.insertAsset(asset);
      await loadAssets();
      await loadStats();
      return true;
    } catch (e) {
      debugPrint('新增资产失败: $e');
      return false;
    }
  }

  /// 更新资产
  Future<bool> updateAsset(Asset asset) async {
    try {
      // 检查编号是否与其他资产重复
      final exists = await _db.assetCodeExists(
        asset.assetCode,
        excludeId: asset.id,
      );
      if (exists) return false;

      await _db.updateAsset(asset);
      await loadAssets();
      await loadStats();
      return true;
    } catch (e) {
      debugPrint('更新资产失败: $e');
      return false;
    }
  }

  /// 删除资产
  Future<bool> deleteAsset(int id) async {
    try {
      await _db.deleteAsset(id);
      await loadAssets();
      await loadStats();
      return true;
    } catch (e) {
      debugPrint('删除资产失败: $e');
      return false;
    }
  }

  /// 获取在库资产
  Future<List<Asset>> getInStockAssets() async {
    return await _db.getInStockAssets();
  }

  /// 获取可归还资产
  Future<List<Asset>> getReturnableAssets() async {
    return await _db.getReturnableAssets();
  }

  /// 根据 ID 获取资产
  Future<Asset?> getAssetById(int id) async {
    return await _db.getAssetById(id);
  }

  /// 检查编号是否可用
  Future<bool> isAssetCodeAvailable(String code, {int? excludeId}) async {
    return !(await _db.assetCodeExists(code, excludeId: excludeId));
  }
}
