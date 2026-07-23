import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';
import '../models/asset.dart';

/// 全局应用 Provider - 管理应用级别状态
/// 包含初始化逻辑、超期检查、全局设置等
class AppProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  bool _isInitialized = false;
  String _defaultOperator = '';
  List<Asset> _overdueAssets = [];

  bool get isInitialized => _isInitialized;
  String get defaultOperator => _defaultOperator;
  List<Asset> get overdueAssets => _overdueAssets;
  bool get hasOverdueAssets => _overdueAssets.isNotEmpty;

  /// 应用初始化
  /// 加载设置、检查超期资产
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 加载默认操作人
      _defaultOperator = await _db.getSetting('default_operator');

      // 检查超期资产
      await checkOverdueAssets();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('应用初始化失败: $e');
    }
  }

  /// 检查超期资产
  Future<void> checkOverdueAssets() async {
    try {
      _overdueAssets = await _db.getOverdueAssets();
      notifyListeners();
    } catch (e) {
      debugPrint('检查超期资产失败: $e');
    }
  }

  /// 更新默认操作人
  Future<void> updateDefaultOperator(String operator) async {
    try {
      _defaultOperator = operator;
      await _db.saveSetting('default_operator', operator);
      notifyListeners();
    } catch (e) {
      debugPrint('保存默认操作人失败: $e');
    }
  }
}
