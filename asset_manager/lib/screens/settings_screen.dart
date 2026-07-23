import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/asset_provider.dart';
import '../providers/transaction_provider.dart';

/// 设置页面（"我的"页面）
/// 包含默认操作人设置、数据统计、关于信息等
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _operatorController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _operatorController = TextEditingController(
      text: context.read<AppProvider>().defaultOperator,
    );
  }

  @override
  void dispose() {
    _operatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 默认操作人设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '默认操作人',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '设置默认操作人后，出入库操作时将自动填入',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _operatorController,
                    decoration: const InputDecoration(
                      labelText: '操作人姓名',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveOperator,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 数据统计
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '数据统计',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Consumer<AssetProvider>(
                    builder: (context, provider, _) {
                      final stats = provider.stats;
                      return Column(
                        children: [
                          _StatRow('总资产数', '${stats['total'] ?? 0}', Icons.inventory_2),
                          _StatRow('在库资产', '${stats['inStock'] ?? 0}', Icons.check_circle),
                          _StatRow('已领用', '${stats['borrowed'] ?? 0}', Icons.assignment_ind),
                          _StatRow('超期未还', '${stats['overdue'] ?? 0}', Icons.warning),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 快捷操作
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.blue),
                  title: const Text('刷新所有数据'),
                  subtitle: const Text('重新加载统计和超期检查'),
                  onTap: () async {
                    await context.read<AssetProvider>().loadStats();
                    await context.read<AssetProvider>().loadOverdueAssets();
                    await context.read<AppProvider>().checkOverdueAssets();
                    await context.read<TransactionProvider>().loadTransactions();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('数据已刷新')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 关于
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.grey),
                  title: const Text('关于'),
                  subtitle: const Text('企业资产管理 v1.0.0'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: '企业资产管理',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2024 Asset Manager',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveOperator() async {
    setState(() => _isSaving = true);
    await context.read<AppProvider>().updateDefaultOperator(
      _operatorController.text.trim(),
    );
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('默认操作人已保存')),
      );
    }
  }
}

/// 统计行组件
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
