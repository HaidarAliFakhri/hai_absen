import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  String? lastScanned;

  // Laser Animation
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation =
        Tween<double>(begin: 0, end: 220).animate(_laserController);
  }

  @override
  void dispose() {
    controller.dispose();
    _laserController.dispose();
    super.dispose();
  }

  void _handleScan(String code) async {
    if (lastScanned == code) return;

    lastScanned = code;

    HapticFeedback.mediumImpact(); // Getar ala Shopee

    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.pop(context, code); // kirim hasil ke Dashboard
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanSize = 240.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // CAMERA VIEW
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null) {
                _handleScan(barcode.rawValue!);
              }
            },
          ),

          // BACK BUTTON
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // TORCH SWITCH
          Positioned(
            top: 40,
            right: 20,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.flash_on, color: Colors.white),
                onPressed: () => controller.toggleTorch(),
              ),
            ),
          ),

          // CAMERA SWITCH
          Positioned(
            top: 110,
            right: 20,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
                onPressed: () => controller.switchCamera(),
              ),
            ),
          ),

          // CENTER OVERLAY SCAN AREA
          Center(
            child: Stack(
              children: [
                Container(
                  width: scanSize,
                  height: scanSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white70, width: 3),
                  ),
                ),

                // LASER LINE
                Positioned(
                  top: _laserAnimation.value,
                  child: Container(
                    width: scanSize,
                    height: 2,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),

          // SCAN INSTRUCTION
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              "Arahkan QR ke dalam area kotak",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
