import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// 条码/二维码扫描页面
/// 使用 mobile_scanner 插件实现扫描功能
class ScanScreen extends StatefulWidget {
  /// 是否返回扫描结果（true: 返回结果字符串给上一页）
  final bool returnResult;

  const ScanScreen({super.key, this.returnResult = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _hasResult = false;

  @override
  void initState() {
    super.initState();
    // 监听扫描结果
    _controller.start();
    _controller.barcodes.listen((barcodeCapture) {
      if (_hasResult) return;
      if (barcodeCapture.barcodes.isNotEmpty) {
        final barcode = barcodeCapture.barcodes.first;
        if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
          _hasResult = true;
          _onScanSuccess(barcode.rawValue!);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  void _onScanSuccess(String result) {
    if (mounted) {
      // 震动反馈
      HapticFeedback.lightImpact();

      if (widget.returnResult) {
        // 返回扫描结果给上一页
        Navigator.pop(context, result);
      } else {
        // 显示扫描结果
        _showResultDialog(result);
      }
    }
  }

  void _showResultDialog(String result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('扫描成功'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('扫描结果：', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                result,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _hasResult = false; // 允许继续扫描
            },
            child: const Text('继续扫描'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, result);
            },
            child: const Text('使用结果'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描条码/二维码'),
        actions: [
          // 闪光灯控制
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, child) {
              if (!state.hasTorchState) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
          // 切换前后摄像头
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 相机预览
          MobileScanner(
            controller: _controller,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      '无法访问相机',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '请确认已授予相机权限\n错误: ${error.toString()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _controller.start();
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            },
          ),
          // 扫描框覆盖层
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // 底部提示
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  '将条码/二维码放入框内即可自动扫描',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
