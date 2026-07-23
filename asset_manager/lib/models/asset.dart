/// 资产信息模型
class Asset {
  final int? id;
  final String assetCode; // 资产编号（唯一）
  final String name; // 资产名称
  final String category; // 分类
  final String model; // 规格型号
  final String barcode; // 条形码/二维码内容
  final String status; // 当前状态
  final String? borrower; // 领用人
  final DateTime? borrowDate; // 领用日期
  final DateTime? plannedReturnDate; // 计划归还日期
  final DateTime? actualReturnDate; // 实际归还日期
  final String location; // 存放位置
  final String? remark; // 备注

  Asset({
    this.id,
    required this.assetCode,
    required this.name,
    required this.category,
    this.model = '',
    this.barcode = '',
    this.status = '在库',
    this.borrower,
    this.borrowDate,
    this.plannedReturnDate,
    this.actualReturnDate,
    this.location = '',
    this.remark,
  });

  /// 从数据库 Map 创建 Asset 对象
  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] as int?,
      assetCode: map['asset_code'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      model: (map['model'] as String?) ?? '',
      barcode: (map['barcode'] as String?) ?? '',
      status: (map['status'] as String?) ?? '在库',
      borrower: map['borrower'] as String?,
      borrowDate: map['borrow_date'] != null
          ? DateTime.parse(map['borrow_date'] as String)
          : null,
      plannedReturnDate: map['planned_return_date'] != null
          ? DateTime.parse(map['planned_return_date'] as String)
          : null,
      actualReturnDate: map['actual_return_date'] != null
          ? DateTime.parse(map['actual_return_date'] as String)
          : null,
      location: (map['location'] as String?) ?? '',
      remark: map['remark'] as String?,
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'asset_code': assetCode,
      'name': name,
      'category': category,
      'model': model,
      'barcode': barcode,
      'status': status,
      'borrower': borrower,
      'borrow_date': borrowDate != null
          ? '${borrowDate!.year}-${borrowDate!.month.toString().padLeft(2, '0')}-${borrowDate!.day.toString().padLeft(2, '0')}'
          : null,
      'planned_return_date': plannedReturnDate != null
          ? '${plannedReturnDate!.year}-${plannedReturnDate!.month.toString().padLeft(2, '0')}-${plannedReturnDate!.day.toString().padLeft(2, '0')}'
          : null,
      'actual_return_date': actualReturnDate != null
          ? '${actualReturnDate!.year}-${actualReturnDate!.month.toString().padLeft(2, '0')}-${actualReturnDate!.day.toString().padLeft(2, '0')}'
          : null,
      'location': location,
      'remark': remark,
    };
  }

  /// 复制并修改
  Asset copyWith({
    int? id,
    String? assetCode,
    String? name,
    String? category,
    String? model,
    String? barcode,
    String? status,
    String? borrower,
    DateTime? borrowDate,
    DateTime? plannedReturnDate,
    DateTime? actualReturnDate,
    String? location,
    String? remark,
  }) {
    return Asset(
      id: id ?? this.id,
      assetCode: assetCode ?? this.assetCode,
      name: name ?? this.name,
      category: category ?? this.category,
      model: model ?? this.model,
      barcode: barcode ?? this.barcode,
      status: status ?? this.status,
      borrower: borrower ?? this.borrower,
      borrowDate: borrowDate ?? this.borrowDate,
      plannedReturnDate: plannedReturnDate ?? this.plannedReturnDate,
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
      location: location ?? this.location,
      remark: remark ?? this.remark,
    );
  }

  /// 是否超期
  bool get isOverdue {
    if (plannedReturnDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return plannedReturnDate!.isBefore(today);
  }
}
