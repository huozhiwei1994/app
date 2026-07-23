import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../widgets/asset_list_item.dart';
import '../screens/asset_detail_screen.dart';

/// 超期资产页面
/// 显示所有已超期未归还的资产列表
class OverdueScreen extends StatefulWidget {
  const OverdueScreen({super.key});

  @override
  State<OverdueScreen> createState() => _OverdueScreenState();
}

class _OverdueScreenState extends State<OverdueScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AssetProvider>().loadOverdueAssets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('超期未还资产'),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AssetProvider>(
        builder: (context, provider, _) {
          if (provider.overdueAssets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green[200]),
                  const SizedBox(height: 16),
                  Text(
                    '没有超期资产',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '所有已领用资产均在计划归还日期内',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadOverdueAssets();
            },
            child: Column(
              children: [
                // 超期数量提示
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.red.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '共 ${provider.overdueAssets.length} 项资产已超期未还',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.overdueAssets.length,
                    itemBuilder: (context, index) {
                      final asset = provider.overdueAssets[index];
                      return AssetListItem(
                        asset: asset,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssetDetailScreen(asset: asset),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
