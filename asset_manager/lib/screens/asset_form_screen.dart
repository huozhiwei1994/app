import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/asset.dart';
import '../providers/asset_provider.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../screens/scan_screen.dart';

/// 资产新增/编辑表单页面
class AssetFormScreen extends StatefulWidget {
  final Asset? asset; // 如果传入 asset 则为编辑模式

  const AssetFormScreen({super.key, this.asset});

  @override
  State<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends State<AssetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _modelController;
  late TextEditingController _barcodeController;
  late TextEditingController _locationController;
  late TextEditingController _remarkController;
  String _selectedCategory = AppConstants.assetCategories.first;
  String _selectedStatus = AppConstants.assetStatuses.first;
  bool _isSaving = false;

  bool get _isEditing => widget.asset != null;

  @override
  void initState() {
    super.initState();
    final a = widget.asset;
    _codeController = TextEditingController(text: a?.assetCode ?? '');
    _nameController = TextEditingController(text: a?.name ?? '');
    _modelController = TextEditingController(text: a?.model ?? '');
    _barcodeController = TextEditingController(text: a?.barcode ?? '');
    _locationController = TextEditingController(text: a?.location ?? '');
    _remarkController = TextEditingController(text: a?.remark ?? '');
    if (a != null) {
      _selectedCategory = a.category;
      _selectedStatus = a.status;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _modelController.dispose();
    _barcodeController.dispose();
    _locationController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  /// 自动生成资产编号
  void _generateCode() {
    const uuid = Uuid();
    final code = 'AST-${uuid.v4().substring(0, 8).toUpperCase()}';
    _codeController.text = code;
  }

  /// 扫码回调
  void _onScanResult(String result) {
    // 尝试解析扫码结果（JSON 格式支持自动填充）
    // 否则直接填入条形码字段
    setState(() {
      _barcodeController.text = result;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('扫码成功: $result'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑资产' : '新增资产'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveAsset,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 资产编号
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: '资产编号 *',
                  hintText: '手动输入或点击自动生成',
                  prefixIcon: const Icon(Icons.tag),
                  suffixIcon: TextButton(
                    onPressed: _generateCode,
                    child: const Text('自动生成'),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入资产编号';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 资产名称
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '资产名称 *',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入资产名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 分类
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: '分类 *',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.assetCategories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (value) {
                  if (value != null) _selectedCategory = value;
                },
              ),
              const SizedBox(height: 16),

              // 规格型号
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: '规格型号',
                  prefixIcon: Icon(Icons.settings),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 条形码/二维码 + 扫码按钮
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: '条形码/二维码内容',
                        prefixIcon: Icon(Icons.qr_code),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () async {
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScanScreen(returnResult: true),
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        _onScanResult(result);
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: '扫描条码/二维码',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 状态（编辑时显示）
              if (_isEditing) ...[
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: '状态',
                    prefixIcon: Icon(Icons.info_outline),
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.assetStatuses.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) _selectedStatus = value;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // 存放位置
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: '存放位置',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
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
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAsset,
                  child: _isSaving
                      ? const CircularProgressIndicator()
                      : Text(_isEditing ? '更新资产' : '保存资产'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 保存资产
  Future<void> _saveAsset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<AssetProvider>();

    // 检查编号是否重复
    final isAvailable = await provider.isAssetCodeAvailable(
      _codeController.text.trim(),
      excludeId: widget.asset?.id,
    );
    if (!isAvailable) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('资产编号已存在，请使用其他编号')),
        );
      }
      return;
    }

    if (_isEditing) {
      // 更新
      final updatedAsset = widget.asset!.copyWith(
        assetCode: _codeController.text.trim(),
        name: _nameController.text.trim(),
        category: _selectedCategory,
        model: _modelController.text.trim(),
        barcode: _barcodeController.text.trim(),
        status: _selectedStatus,
        location: _locationController.text.trim(),
        remark: _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
      );
      final success = await provider.updateAsset(updatedAsset);
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('资产更新成功')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('更新失败，请重试')),
          );
        }
      }
    } else {
      // 新增
      final newAsset = Asset(
        assetCode: _codeController.text.trim(),
        name: _nameController.text.trim(),
        category: _selectedCategory,
        model: _modelController.text.trim(),
        barcode: _barcodeController.text.trim(),
        status: '在库',
        location: _locationController.text.trim(),
        remark: _remarkController.text.trim().isEmpty ? null : _remarkController.text.trim(),
      );
      final success = await provider.addAsset(newAsset);
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('资产添加成功')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('添加失败，请重试')),
          );
        }
      }
    }
  }
}
