import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/asset_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/asset_list_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/checkin_screen.dart';

/// 应用入口
/// 使用 Provider 进行全局状态管理
/// 底部导航栏 4 个标签：首页、资产列表、出入库记录、我的
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AssetManagerApp());
}

class AssetManagerApp extends StatelessWidget {
  const AssetManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AssetProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: '企业资产管理',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
          ),
          cardTheme: CardTheme(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const MainScreen(),
        routes: {
          '/checkout': (_) => const CheckoutScreen(),
          '/checkin': (_) => const CheckinScreen(),
        },
      ),
    );
  }
}

/// 主页面 - 底部导航栏容器
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 四个标签页
  final List<Widget> _pages = [
    const HomeScreen(),
    const AssetListScreen(),
    const TransactionHistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 应用启动时初始化（检查超期、加载设置等）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().initialize();
      context.read<AssetProvider>().loadStats();
      context.read<AssetProvider>().loadOverdueAssets();
      context.read<TransactionProvider>().loadTransactions(limit: 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: context.watch<AppProvider>().hasOverdueAssets,
              label: Text(
                '${context.watch<AppProvider>().overdueAssets.length}',
                style: const TextStyle(fontSize: 10),
              ),
              child: const Icon(Icons.home_outlined),
            ),
            selectedIcon: const Icon(Icons.home),
            label: '首页',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '资产列表',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '出入库记录',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
