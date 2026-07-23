import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/app_provider.dart';
import '../utils/date_formatter.dart';

/// 入库操作页面
/// 选择已领用或维修中资产 → 填写实际归还日期 → 状态变为"在库"
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  Asset? _selectedAsset;
  late TextEditingController _remarkController;
  bool _isProcessing = false;
  List<Asset> _returnableAssets = [];

  @override
  void initState() {
    super.initState();
    _remarkController = TextEditingController();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final assets = await context.read<AssetProvider>().getReturnableAssets();
    setState(() => _returnableAssets = assets);
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资产入库'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 资产选择
            const Text(
              '选择待入库资产 *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (_returnableAssets.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('暂无待入库资产')),
                ),
              )
            else
              DropdownButtonFormField<Asset>(
                value: _selectedAsset,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.inventory_2),
                  border: OutlineInputBorder(),
                  hintText: '请选择资产',
                ),
                items: _returnableAssets.map((asset) {
                  return DropdownMenuItem(
                    value: asset,
                    child: Text(
                      '${asset.name} (${asset.assetCode}) - ${asset.status}',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedAsset = value);
                },
              ),
            const SizedBox(height: 16),

            // 选中资产信息
            if (_selectedAsset != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '当前状态: ${_selectedAsset!.status}',
                        style: TextStyle(
                          color: _selectedAsset!.status == '已领用'
                              ? Colors.orange
                              : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_selectedAsset!.borrower != null &&
                          _selectedAsset!.borrower!.isNotEmpty)
                        Text('领用人: ${_selectedAsset!.borrower}'),
                      if (_selectedAsset!.borrowDate != null)
                        Text('领用日期: ${DateFormatter.formatDisplay(_selectedAsset!.borrowDate)}'),
                      if (_selectedAsset!.plannedReturnDate != null)
                        Text(
                          '计划归还: ${DateFormatter.formatDisplay(_selectedAsset!.plannedReturnDate)}',
                          style: TextStyle(
                            color: _selectedAsset!.isOverdue ? Colors.red : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 备注
            TextFormField(
              controller: _remarkController,
              decoration: const InputDecoration(
                labelText: '备注',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // 确认入库按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedAsset == null ? null : _confirmCheckin,
                child: _isProcessing
                    ? const CircularProgressIndicator()
                    : const Text('确认入库', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCheckin() async {
    if (_selectedAsset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择资产')),
      );
      return;
    }

    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认入库'),
        content: Text(
          '确定要将"${_selectedAsset!.name}"入库吗？\n入库后状态将变为"在库"。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    final success = await context.read<TransactionProvider>().checkIn(
      asset: _selectedAsset!,
      operator: context.read<AppProvider>().defaultOperator,
      remark: _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('入库成功'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('入库失败，请重试')),
        );
      }
    }
  }
}
