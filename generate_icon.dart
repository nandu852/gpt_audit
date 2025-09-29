import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await generateAppIcon();
}

Future<void> generateAppIcon() async {
  const size = 1024.0;
  
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Background
  final backgroundPaint = Paint()
    ..shader = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(size, size),
      [const Color(0xFF2196F3), const Color(0xFF1976D2)],
    );
  canvas.drawRect(Rect.fromLTWH(0, 0, size, size), backgroundPaint);
  
  // White circle
  final circlePaint = Paint()..color = Colors.white;
  canvas.drawCircle(Offset(size / 2, size / 2), size * 0.4, circlePaint);
  
  // Icon
  final iconPaint = Paint()
    ..color = const Color(0xFF2196F3)
    ..style = PaintingStyle.fill;
  
  // Draw project icon (folder with checkmark)
  final folderPath = Path()
    ..moveTo(size * 0.25, size * 0.35)
    ..lineTo(size * 0.25, size * 0.7)
    ..lineTo(size * 0.75, size * 0.7)
    ..lineTo(size * 0.75, size * 0.45)
    ..lineTo(size * 0.6, size * 0.45)
    ..lineTo(size * 0.5, size * 0.35)
    ..close();
  canvas.drawPath(folderPath, iconPaint);
  
  // Checkmark
  final checkPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.08
    ..strokeCap = StrokeCap.round;
  
  final checkPath = Path()
    ..moveTo(size * 0.4, size * 0.5)
    ..lineTo(size * 0.5, size * 0.6)
    ..lineTo(size * 0.65, size * 0.45);
  canvas.drawPath(checkPath, checkPaint);
  
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  
  final file = File('app_icon.png');
  await file.writeAsBytes(byteData!.buffer.asUint8List());
  
  print('App icon generated: app_icon.png');
}

