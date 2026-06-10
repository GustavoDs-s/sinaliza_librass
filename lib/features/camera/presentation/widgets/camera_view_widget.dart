import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraViewWidget extends StatelessWidget {
  final CameraController controller;
  final bool isAutoMode;
  final int autoCountdown;
  final VoidCallback onCapture;

  const CameraViewWidget({
    super.key,
    required this.controller,
    required this.isAutoMode,
    required this.autoCountdown,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(3.14159),
            child: CameraPreview(controller),
          ),
          CustomPaint(painter: _GuideBoxPainter(color: Colors.white.withOpacity(0.4))),
          if (isAutoMode)
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8,
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('Auto ${autoCountdown}s',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
          if (!isAutoMode)
            Positioned(
              bottom: 16, left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onCapture,
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400, width: 2)),
                      child: const Icon(Icons.camera_alt_rounded, size: 28, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GuideBoxPainter extends CustomPainter {
  final Color color;
  _GuideBoxPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final double w = size.width * 0.7;
    final double h = size.height * 0.6;
    final double left = (size.width - w) / 2;
    final double top = (size.height - h) / 2;
    const double cornerLen = 20;

    final path = Path();
    path.moveTo(left + 8, top); path.lineTo(left + 8 + cornerLen, top);
    path.moveTo(left, top + 8); path.lineTo(left, top + 8 + cornerLen);
    path.moveTo(left + w - 8 - cornerLen, top); path.lineTo(left + w - 8, top);
    path.moveTo(left + w, top + 8); path.lineTo(left + w, top + 8 + cornerLen);
    path.moveTo(left + w, top + h - 8 - cornerLen); path.lineTo(left + w, top + h - 8);
    path.moveTo(left + w - 8 - cornerLen, top + h); path.lineTo(left + w - 8, top + h);
    path.moveTo(left, top + h - 8 - cornerLen); path.lineTo(left, top + h - 8);
    path.moveTo(left + 8, top + h); path.lineTo(left + 8 + cornerLen, top + h);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GuideBoxPainter old) => old.color != color;
}
