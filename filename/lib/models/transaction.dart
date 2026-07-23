/// 出入库记录模型
class AssetTransaction {
  final int? id;
  final int assetId; // 关联资产ID
  final String assetCode; // 资产编号（冗余存储，方便查询）
  final String assetName; // 资产名称（冗余存储）
  final String type; // 操作类型：'out' 出库, 'in' 入库
  final String operator; // 操作人
  final DateTime operateTime; // 操作时间
  final String? remark; // 备注

  AssetTransaction({
    this.id,
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.type,
    this.operator = '',
    DateTime? operateTime,
    this.remark,
  }) : operateTime = operateTime ?? DateTime.now();

  /// 操作类型显示文本
  String get typeText => type == 'out' ? '出库' : '入库';

  /// 从数据库 Map 创建对象
  factory AssetTransaction.fromMap(Map<String, dynamic> map) {
    return AssetTransaction(
      id: map['id'] as int?,
      assetId: map['asset_id'] as int,
      assetCode: map['asset_code'] as String,
      assetName: map['asset_name'] as String,
      type: map['type'] as String,
      operator: (map['operator'] as String?) ?? '',
      operateTime: DateTime.parse(map['operate_time'] as String),
      remark: map['remark'] as String?,
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'asset_id': assetId,
      'asset_code': assetCode,
      'asset_name': assetName,
      'type': type,
      'operator': operator,
      'operate_time': operateTime.toIso8601String(),
      'remark': remark,
    };
  }
}
