import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/di/injection.dart';
import '../../../domain/repositories/config_repository.dart';
import '../../../l10n/app_localizations.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController? _controller;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _lastScannedCode;
  bool _isTorchOn = false;
  double _zoomLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      formats: [BarcodeFormat.qrCode],
      autoStart: true,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleQrCode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    // Prevent processing the same QR code multiple times
    if (qrData == _lastScannedCode) return;
    _lastScannedCode = qrData;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      debugPrint('QR code scanned: $qrData');

      final configRepository = getIt<ConfigRepository>();
      final success = await configRepository.saveConfigFromQrCode(qrData);

      if (!mounted) return;

      if (success) {
        debugPrint('Configuration saved successfully');
        // Check if we can pop (there's a previous route)
        if (Navigator.canPop(context)) {
          // Normal flow: pop back to previous screen
          Navigator.of(context).pop(true);
        } else {
          // Reset flow: no previous routes, navigate to login
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      } else {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _errorMessage = l10n.invalidQrCodeFormat;
          _isProcessing = false;
          _lastScannedCode = null; // Allow retry
        });
      }
    } catch (e) {
      debugPrint('Error processing QR code: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() {
          _errorMessage = '${l10n.failedToProcessQrCode}: $e';
          _isProcessing = false;
          _lastScannedCode = null; // Allow retry
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.scanQrCodeTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          // QR Scanner View
          if (_controller != null)
            MobileScanner(controller: _controller, onDetect: _handleQrCode),

          // Scanner overlay with cutout
          CustomPaint(painter: ScannerOverlayPainter(), child: Container()),

          // Instructions at the top
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    l10n.pointCameraAtQr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.configurationScannedAutomatically,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _errorMessage = null;
                    _lastScannedCode = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap to retry',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      l10n.processingConfiguration,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom controls: Zoom and Flash
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      const Icon(Icons.zoom_out, color: Colors.white, size: 24),
                      Expanded(
                        child: Slider(
                          value: _zoomLevel,
                          min: 0.0,
                          max: 1.0,
                          activeColor: Colors.green,
                          inactiveColor: Colors.white38,
                          onChanged: (value) {
                            setState(() {
                              _zoomLevel = value;
                            });
                            _controller?.setZoomScale(value);
                          },
                        ),
                      ),
                      const Icon(Icons.zoom_in, color: Colors.white, size: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Flash toggle button
                IconButton(
                  onPressed: () async {
                    await _controller?.toggleTorch();
                    setState(() {
                      _isTorchOn = !_isTorchOn;
                    });
                  },
                  icon: Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: _isTorchOn ? Colors.yellow : Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for scanner overlay with cutout
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutSize = size.width * 0.8;
    final cutoutLeft = (size.width - cutoutSize) / 2;
    final cutoutTop = (size.height - cutoutSize) / 2;

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutSize, cutoutSize),
          const Radius.circular(20),
        ),
      );

    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, paint);

    // Draw border around cutout
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutSize, cutoutSize),
        const Radius.circular(20),
      ),
      borderPaint,
    );

    // Draw corner accents
    final accentPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const accentLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop + accentLength),
      Offset(cutoutLeft, cutoutTop),
      accentPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop),
      Offset(cutoutLeft + accentLength, cutoutTop),
      accentPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(cutoutLeft + cutoutSize - accentLength, cutoutTop),
      Offset(cutoutLeft + cutoutSize, cutoutTop),
      accentPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft + cutoutSize, cutoutTop),
      Offset(cutoutLeft + cutoutSize, cutoutTop + accentLength),
      accentPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop + cutoutSize - accentLength),
      Offset(cutoutLeft, cutoutTop + cutoutSize),
      accentPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft, cutoutTop + cutoutSize),
      Offset(cutoutLeft + accentLength, cutoutTop + cutoutSize),
      accentPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(cutoutLeft + cutoutSize - accentLength, cutoutTop + cutoutSize),
      Offset(cutoutLeft + cutoutSize, cutoutTop + cutoutSize),
      accentPaint,
    );
    canvas.drawLine(
      Offset(cutoutLeft + cutoutSize, cutoutTop + cutoutSize - accentLength),
      Offset(cutoutLeft + cutoutSize, cutoutTop + cutoutSize),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
