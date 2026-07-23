import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/asset.dart';
import '../services/database_helper.dart';

/// 出入库记录 Provider
class TransactionProvider with ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<AssetTransaction> _transactions = [];
  bool _isLoading = false;

  List<AssetTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  /// 加载所有记录
  Future<void> loadTransactions({int? limit}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = await _db.getAllTransactions(limit: limit);
    } catch (e) {
      debugPrint('加载出入库记录失败: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  /// 执行出库操作
  /// 将资产状态改为"已领用"，并记录出入库日志
  Future<bool> checkOut({
    required Asset asset,
    required String borrower,
    required DateTime borrowDate,
    required DateTime plannedReturnDate,
    required String operator,
    String? remark,
  }) async {
    try {
      // 更新资产状态
      final updatedAsset = asset.copyWith(
        status: '已领用',
        borrower: borrower,
        borrowDate: borrowDate,
        plannedReturnDate: plannedReturnDate,
        actualReturnDate: null,
      );
      await _db.updateAsset(updatedAsset);

      // 记录出入库日志
      final transaction = AssetTransaction(
        assetId: asset.id!,
        assetCode: asset.assetCode,
        assetName: asset.name,
        type: 'out',
        operator: operator,
        remark: remark,
      );
      await _db.insertTransaction(transaction);

      await loadTransactions();
      return true;
    } catch (e) {
      debugPrint('出库操作失败: $e');
      return false;
    }
  }

  /// 执行入库操作
  /// 将资产状态改为"在库"，并记录出入库日志
  Future<bool> checkIn({
    required Asset asset,
    required String operator,
    String? remark,
  }) async {
    try {
      // 更新资产状态
      final updatedAsset = asset.copyWith(
        status: '在库',
        borrower: null,
        borrowDate: null,
        plannedReturnDate: null,
        actualReturnDate: DateTime.now(),
      );
      await _db.updateAsset(updatedAsset);

      // 记录出入库日志
      final transaction = AssetTransaction(
        assetId: asset.id!,
        assetCode: asset.assetCode,
        assetName: asset.name,
        type: 'in',
        operator: operator,
        remark: remark,
      );
      await _db.insertTransaction(transaction);

      await loadTransactions();
      return true;
    } catch (e) {
      debugPrint('入库操作失败: $e');
      return false;
    }
  }

  /// 获取指定资产的出入库记录
  Future<List<AssetTransaction>> getTransactionsByAssetId(int assetId) async {
    return await _db.getTransactionsByAssetId(assetId);
  }
}
