# 企业资产管理 (Asset Manager)

基于 Flutter 3.x + Dart 3.x 的企业资产管理移动应用。

## 功能特性

- **资产信息管理**：支持资产的新增、编辑、删除、查询，涵盖办公设备、IT设备、家具、车辆等分类
- **条形码/二维码扫描**：使用 mobile_scanner 插件实现扫码录入
- **出入库管理**：完整的出库/入库流程，自动记录操作日志
- **超期提醒**：自动检测超期未归还资产，首页高亮提醒
- **首页概览**：统计卡片 + 快速入口 + 最近操作记录

## 技术栈

- Flutter 3.x / Dart 3.x
- sqflite + path_provider（本地数据库）
- Provider（状态管理）
- mobile_scanner（条码/二维码扫描）
- intl（日期格式化）
- uuid（编号自动生成）

## 项目结构

```
lib/
├── main.dart                  # 应用入口
├── models/                    # 数据模型
│   ├── asset.dart
│   ├── transaction.dart
│   └── setting.dart
├── services/                  # 服务层
│   └── database_helper.dart   # 数据库操作（单例）
├── providers/                 # 状态管理
│   ├── asset_provider.dart
│   ├── transaction_provider.dart
│   └── app_provider.dart
├── screens/                   # 页面
│   ├── home_screen.dart
│   ├── asset_list_screen.dart
│   ├── asset_detail_screen.dart
│   ├── asset_form_screen.dart
│   ├── transaction_history_screen.dart
│   ├── scan_screen.dart
│   ├── overdue_screen.dart
│   └── settings_screen.dart
├── widgets/                   # 公共组件
│   ├── stat_card.dart
│   └── asset_list_item.dart
└── utils/                     # 工具类
    ├── constants.dart
    └── date_formatter.dart
```

## 如何运行

1. 确保已安装 Flutter SDK 3.x
2. 进入项目目录：`cd asset_manager`
3. 安装依赖：`flutter pub get`
4. 运行应用：
   - Android: `flutter run`（连接 Android 设备或启动模拟器）
   - iOS: `flutter run`（需 macOS + Xcode + 连接 iOS 设备或模拟器）

## 权限配置

### Android
在 `android/app/src/main/AndroidManifest.xml` 中添加：
```xml
<!-- 相机权限（扫码功能需要） -->
<uses-permission android:name="android.permission.CAMERA" />
```

在 `android/app/build.gradle` 中确保：
```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

### iOS
在 `ios/Runner/Info.plist` 中添加：
```xml
<!-- 相机权限（扫码功能需要） -->
<key>NSCameraUsageDescription</key>
<string>需要访问相机以扫描条码/二维码</string>
```

## 数据库设计

- **assets 表**：存储所有资产信息
- **transactions 表**：出入库操作记录，关联 asset_id
- **settings 表**：用户偏好设置

## 测试

```bash
flutter test
```
