import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../utils/date_formatter.dart';

/// 资产列表项组件
class AssetListItem extends StatelessWidget {
  final Asset asset;
  final VoidCallback? onTap;

  const AssetListItem({
    super.key,
    required this.asset,
    this.onTap,
  });

  /// 根据状态返回对应颜色
  Color _getStatusColor() {
    switch (asset.status) {
      case '在库':
        return Colors.green;
      case '已领用':
        return asset.isOverdue ? Colors.red : Colors.blue;
      case '维修中':
        return Colors.orange;
      case '报废':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 根据分类返回对应图标
  IconData _getCategoryIcon() {
    switch (asset.category) {
      case '办公设备':
        return Icons.print;
      case 'IT设备':
        return Icons.computer;
      case '家具':
        return Icons.chair;
      case '车辆':
        return Icons.directions_car;
      case '其他':
        return Icons.inventory_2;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getStatusColor().withOpacity(0.1),
          child: Icon(_getCategoryIcon(), color: _getStatusColor()),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              asset.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '编号: ${asset.assetCode}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (asset.borrower != null && asset.borrower!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '领用人: ${asset.borrower}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (asset.isOverdue)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '已超期! 计划归还: ${DateFormatter.formatDisplay(asset.plannedReturnDate)}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            asset.status,
            style: TextStyle(
              fontSize: 12,
              color: _getStatusColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
