import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/app_provider.dart';
import '../utils/date_formatter.dart';

/// 出库操作页面
/// 选择在库资产 → 填写领用人、领用日期、计划归还日期 → 状态变为"已领用"
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Asset? _selectedAsset;
  late TextEditingController _borrowerController;
  late TextEditingController _remarkController;
  DateTime _borrowDate = DateTime.now();
  DateTime _plannedReturnDate = DateTime.now().add(const Duration(days: 30));
  bool _isProcessing = false;
  List<Asset> _inStockAssets = [];

  @override
  void initState() {
    super.initState();
    _borrowerController = TextEditingController(
      text: context.read<AppProvider>().defaultOperator,
    );
    _remarkController = TextEditingController();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final assets = await context.read<AssetProvider>().getInStockAssets();
    setState(() => _inStockAssets = assets);
  }

  @override
  void dispose() {
    _borrowerController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required bool isBorrow}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isBorrow ? _borrowDate : _plannedReturnDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isBorrow) {
          _borrowDate = picked;
        } else {
          _plannedReturnDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资产出库'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 资产选择
            const Text(
              '选择在库资产 *',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (_inStockAssets.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('暂无在库资产')),
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
                items: _inStockAssets.map((asset) {
                  return DropdownMenuItem(
                    value: asset,
                    child: Text('${asset.name} (${asset.assetCode})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedAsset = value);
                },
              ),
            const SizedBox(height: 16),

            // 领用人
            TextFormField(
              controller: _borrowerController,
              decoration: const InputDecoration(
                labelText: '领用人 *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入领用人';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 领用日期
            _buildDateField(
              label: '领用日期 *',
              value: DateFormatter.formatDisplay(_borrowDate),
              onTap: () => _selectDate(context, isBorrow: true),
            ),
            const SizedBox(height: 16),

            // 计划归还日期
            _buildDateField(
              label: '计划归还日期 *',
              value: DateFormatter.formatDisplay(_plannedReturnDate),
              onTap: () => _selectDate(context, isBorrow: false),
            ),
            const SizedBox(height: 16),

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

            // 确认出库按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedAsset == null ? null : _confirmCheckout,
                child: _isProcessing
                    ? const CircularProgressIndicator()
                    : const Text('确认出库', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: const OutlineInputBorder(),
        ),
        child: Text(value),
      ),
    );
  }

  void _confirmCheckout() async {
    if (_selectedAsset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择资产')),
      );
      return;
    }
    if (_borrowerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入领用人')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final success = await context.read<TransactionProvider>().checkOut(
      asset: _selectedAsset!,
      borrower: _borrowerController.text.trim(),
      borrowDate: _borrowDate,
      plannedReturnDate: _plannedReturnDate,
      operator: context.read<AppProvider>().defaultOperator,
      remark: _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('出库成功'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('出库失败，请重试')),
        );
      }
    }
  }
}
