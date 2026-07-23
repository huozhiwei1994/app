import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/asset_provider.dart';
import '../models/asset.dart';
import '../widgets/asset_list_item.dart';
import '../utils/constants.dart';
import '../screens/asset_detail_screen.dart';
import '../screens/asset_form_screen.dart';

/// 资产列表页面
/// 支持按名称、编号、分类、状态筛选和搜索
class AssetListScreen extends StatefulWidget {
  const AssetListScreen({super.key});

  @override
  State<AssetListScreen> createState() => _AssetListScreenState();
}

class _AssetListScreenState extends State<AssetListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';
  String _selectedStatus = '';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  void _loadAssets() {
    context.read<AssetProvider>().loadAssets(
      keyword: _searchController.text,
      category: _selectedCategory,
      status: _selectedStatus,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资产列表'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
            tooltip: '筛选',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(_showFilters ? 120 : 60),
          child: Column(
            children: [
              // 搜索框
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索资产名称或编号...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadAssets();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    isDense: true,
                  ),
                  onChanged: (_) => _loadAssets(),
                ),
              ),
              // 筛选条件
              if (_showFilters)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory.isEmpty ? null : _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: '分类',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('全部分类')),
                            ...AppConstants.assetCategories.map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedCategory = value ?? '');
                            _loadAssets();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus.isEmpty ? null : _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: '状态',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('全部状态')),
                            ...AppConstants.assetStatuses.map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedStatus = value ?? '');
                            _loadAssets();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      body: Consumer<AssetProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.assets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    '暂无资产数据',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击右下角按钮添加资产',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _loadAssets(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.assets.length,
              itemBuilder: (context, index) {
                final asset = provider.assets[index];
                return AssetListItem(
                  asset: asset,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssetDetailScreen(asset: asset),
                      ),
                    ).then((_) => _loadAssets());
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssetFormScreen()),
          ).then((_) => _loadAssets());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
