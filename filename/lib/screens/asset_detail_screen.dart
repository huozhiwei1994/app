import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../screens/asset_form_screen.dart';
import '../utils/date_formatter.dart';

/// 资产详情页面
/// 展示资产完整信息，支持编辑和删除操作
class AssetDetailScreen extends StatelessWidget {
  final Asset asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资产详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AssetFormScreen(asset: asset),
                ),
              );
            },
            tooltip: '编辑',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context),
            tooltip: '删除',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本信息卡片
            _buildSectionCard(
              context,
              '基本信息',
              [
                _InfoRow('资产编号', asset.assetCode),
                _InfoRow('资产名称', asset.name),
                _InfoRow('分类', asset.category),
                _InfoRow('规格型号', asset.model.isEmpty ? '-' : asset.model),
                _InfoRow('条形码/二维码', asset.barcode.isEmpty ? '-' : asset.barcode),
                _InfoRow('存放位置', asset.location.isEmpty ? '-' : asset.location),
              ],
            ),
            const SizedBox(height: 16),

            // 状态信息卡片
            _buildSectionCard(
              context,
              '状态信息',
              [
                _InfoRow('当前状态', asset.status, isStatus: true),
                _InfoRow('领用人', asset.borrower ?? '-'),
                _InfoRow('领用日期', DateFormatter.formatDisplay(asset.borrowDate)),
                _InfoRow('计划归还', DateFormatter.formatDisplay(asset.plannedReturnDate)),
                _InfoRow('实际归还', DateFormatter.formatDisplay(asset.actualReturnDate)),
              ],
            ),
            if (asset.isOverdue) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '该资产已超期！计划归还日期：${DateFormatter.formatDisplay(asset.plannedReturnDate)}',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (asset.remark != null && asset.remark!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionCard(
                context,
                '备注',
                [_InfoRow('', asset.remark!)],
                singleField: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    List<_InfoRow> rows, {
    bool singleField = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!singleField)
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (!singleField) const SizedBox(height: 12),
            ...rows.map((row) => _buildInfoRow(row, context)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(_InfoRow row, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (row.label.isNotEmpty)
            SizedBox(
              width: 80,
              child: Text(
                row.label,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
          Expanded(
            child: row.isStatus
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(row.value).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      row.value,
                      style: TextStyle(
                        color: _getStatusColor(row.value),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : Text(
                    row.value,
                    style: const TextStyle(fontSize: 14),
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除资产"${asset.name}"吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<AssetProvider>().deleteAsset(asset.id!);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('资产已删除')),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除失败，请重试')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool isStatus;

  _InfoRow(this.label, this.value, {this.isStatus = false});
}
