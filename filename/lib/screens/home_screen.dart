import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/app_provider.dart';
import '../widgets/stat_card.dart';
import '../screens/asset_list_screen.dart';
import '../screens/asset_form_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/overdue_screen.dart';
import '../screens/transaction_history_screen.dart';
import '../utils/date_formatter.dart';

/// 首页 - 概览页面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final assetProvider = context.read<AssetProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    assetProvider.loadStats();
    assetProvider.loadOverdueAssets();
    transactionProvider.loadTransactions(limit: 5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资产管理'),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 统计卡片区域
              _buildStatsSection(),
              const SizedBox(height: 16),

              // 快速入口
              _buildQuickActions(),
              const SizedBox(height: 16),

              // 超期提醒
              _buildOverdueSection(),

              // 最近出入库记录
              _buildRecentTransactions(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AssetFormScreen(),
            ),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add),
        label: const Text('新增资产'),
      ),
    );
  }

  /// 构建统计卡片区域
  Widget _buildStatsSection() {
    return Consumer<AssetProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 8, bottom: 12),
                child: Text(
                  '数据概览',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  StatCard(
                    title: '总资产数',
                    value: stats['total'] ?? 0,
                    icon: Icons.inventory_2,
                    color: Colors.blue,
                  ),
                  StatCard(
                    title: '在库资产',
                    value: stats['inStock'] ?? 0,
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  StatCard(
                    title: '已领用',
                    value: stats['borrowed'] ?? 0,
                    icon: Icons.assignment_ind,
                    color: Colors.orange,
                  ),
                  StatCard(
                    title: '超期未还',
                    value: stats['overdue'] ?? 0,
                    icon: Icons.warning_amber,
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OverdueScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建快速入口
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '快速操作',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.add_box,
                  label: '新增资产',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssetFormScreen(),
                      ),
                    ).then((_) => _loadData());
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.qr_code_scanner,
                  label: '扫码',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScanScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.arrow_upward,
                  label: '出库',
                  color: Colors.orange,
                  onTap: () {
                    _showCheckoutDialog();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.arrow_downward,
                  label: '入库',
                  color: Colors.green,
                  onTap: () {
                    _showCheckinDialog();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建超期提醒区域
  Widget _buildOverdueSection() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        if (!appProvider.hasOverdueAssets) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            color: Colors.red.shade50,
            elevation: 1,
            child: ListTile(
              leading: const Icon(Icons.warning, color: Colors.red),
              title: Text(
                '超期提醒',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              subtitle: Text(
                '有 ${appProvider.overdueAssets.length} 项资产已超期未还',
                style: TextStyle(color: Colors.red.shade600),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OverdueScreen(),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 构建最近出入库记录
  Widget _buildRecentTransactions() {
    return Consumer<TransactionProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 16, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '最近出入库',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionHistoryScreen(),
                          ),
                        );
                      },
                      child: const Text('查看全部'),
                    ),
                  ],
                ),
              ),
              if (provider.transactions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        '暂无出入库记录',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                ...provider.transactions.map((tx) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      leading: Icon(
                        tx.type == 'out'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: tx.type == 'out' ? Colors.orange : Colors.green,
                      ),
                      title: Text(tx.assetName),
                      subtitle: Text(
                        '${tx.typeText} | ${DateFormatter.formatDateTime(tx.operateTime)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        tx.operator.isEmpty ? '-' : tx.operator,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  /// 出库对话框
  void _showCheckoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('快速出库'),
        content: const Text('请选择要出库的资产，将在出库页面完成操作。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/checkout');
            },
            child: const Text('去出库'),
          ),
        ],
      ),
    );
  }

  /// 入库对话框
  void _showCheckinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('快速入库'),
        content: const Text('请选择要入库的资产，将在入库页面完成操作。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/checkin');
            },
            child: const Text('去入库'),
          ),
        ],
      ),
    );
  }
}

/// 快速操作按钮组件
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
