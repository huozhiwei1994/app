// 应用常量定义
class AppConstants {
  // 资产分类
  static const List<String> assetCategories = [
    '办公设备',
    'IT设备',
    '家具',
    '车辆',
    '其他',
  ];

  // 资产状态
  static const List<String> assetStatuses = [
    '在库',
    '已领用',
    '维修中',
    '报废',
  ];

  // 数据库名称
  static const String databaseName = 'asset_manager.db';

  // 数据库版本
  static const int databaseVersion = 1;

  // 表名
  static const String assetsTable = 'assets';
  static const String transactionsTable = 'transactions';
  static const String settingsTable = 'settings';

  // 操作类型
  static const String operationOut = 'out';
  static const String operationIn = 'in';
}
