import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/date_formatter.dart';

/// 出入库记录历史页面
/// 按时间倒序显示所有出入库操作记录
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _filterType = ''; // '' 全部, 'out' 出库, 'in' 入库

  @override
  void initState() {
    super.initState();
    context.read<TransactionProvider>().loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('出入库记录'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filterType = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '', child: Text('全部记录')),
              const PopupMenuItem(value: 'out', child: Text('仅出库')),
              const PopupMenuItem(value: 'in', child: Text('仅入库')),
            ],
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = _filterType.isEmpty
              ? provider.transactions
              : provider.transactions.where((t) => t.type == _filterType).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    '暂无出入库记录',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadTransactions();
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final tx = filtered[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: tx.type == 'out'
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      child: Icon(
                        tx.type == 'out'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: tx.type == 'out' ? Colors.orange : Colors.green,
                      ),
                    ),
                    title: Text(
                      tx.assetName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '编号: ${tx.assetCode}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          DateFormatter.formatDateTime(tx.operateTime),
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (tx.remark != null && tx.remark!.isNotEmpty)
                          Text(
                            '备注: ${tx.remark}',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: tx.type == 'out'
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tx.typeText,
                            style: TextStyle(
                              fontSize: 12,
                              color: tx.type == 'out' ? Colors.orange : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (tx.operator.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            tx.operator,
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
