// ============================================================
// AvatarPreview / 2頭身キャラの簡易プレビュー
// GDD §13.2 キャラクターアートレギュレーション準拠
// 髪型8 / 髪色6 / 目6 / 輪郭4 / 肌色4 の組合せを描画
// ============================================================
import 'package:flutter/material.dart';

class AvatarPreview extends StatelessWidget {
  final int hairId;       // 0-7
  final int hairColorId;  // 0-5
  final int eyeId;        // 0-5
  final int outlineId;    // 0-3
  final int skinId;       // 0-3
  final double size;
  final String mood;      // neutral / happy / sad / angry / surprised

  const AvatarPreview({
    this.hairId = 0,
    this.hairColorId = 0,
    this.eyeId = 0,
    this.outlineId = 0,
    this.skinId = 0,
    this.size = 80,
    this.mood = 'neutral',
    super.key,
  });

  /// 肌色プリセット（4種、GDD §13.2.2）
  static const List<Color> skinColors = [
    Color(0xFFFAC775), // ライト
    Color(0xFFF0997B), // ピーチ
    Color(0xFFF4C0D1), // ローズ
    Color(0xFFB5D4F4), // クール
  ];

  /// 髪色（6種）
  static const List<Color> hairColors = [
    Color(0xFF3C3489), // 黒
    Color(0xFF5F4435), // 茶
    Color(0xFFB89A6F), // 金
    Color(0xFFD3D1C7), // 白
    Color(0xFFC93939), // 赤
    Color(0xFF6F8D8D), // アッシュ
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AvatarPainter(
          hairId: hairId,
          hairColorId: hairColorId,
          eyeId: eyeId,
          outlineId: outlineId,
          skinId: skinId,
          mood: mood,
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final int hairId;
  final int hairColorId;
  final int eyeId;
  final int outlineId;
  final int skinId;
  final String mood;

  _AvatarPainter({
    required this.hairId,
    required this.hairColorId,
    required this.eyeId,
    required this.outlineId,
    required this.skinId,
    required this.mood,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.3;

    // 髪（顔の上半分を覆う楕円、髪型IDで形状を変える）
    final hairPaint = Paint()
      ..color = AvatarPreview.hairColors[hairColorId.clamp(0, 5)]
      ..style = PaintingStyle.fill;
    final hairTopY = cy - r * 0.7;
    final hairWidth = r * 1.3;
    final hairHeight = r * 0.85;
    // 髪型IDで微調整
    final widthMod = 1.0 + (hairId % 3) * 0.05;
    final heightMod = 1.0 + ((hairId ~/ 3) % 3) * 0.05;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, hairTopY),
        width: hairWidth * widthMod,
        height: hairHeight * heightMod,
      ),
      hairPaint,
    );

    // 顔（円、輪郭IDで形状）
    final facePaint = Paint()
      ..color = AvatarPreview.skinColors[skinId.clamp(0, 3)]
      ..style = PaintingStyle.fill;
    final faceWidthFactor = 1.0 + (outlineId * 0.04);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: r * 2 * faceWidthFactor,
        height: r * 2,
      ),
      facePaint,
    );

    // 目（左右、目IDで形状）
    final eyeOffsetX = r * 0.4;
    final eyeY = cy + r * 0.05;
    _drawEyes(canvas, cx, eyeY, eyeOffsetX, r * 0.08);

    // 口
    _drawMouth(canvas, cx, cy + r * 0.4, r * 0.2);
  }

  void _drawEyes(Canvas canvas, double cx, double cy, double offset, double r) {
    final paint = Paint()
      ..color = const Color(0xFF2C2C2A)
      ..style = PaintingStyle.fill;

    if (mood == 'sad') {
      final stroke = Paint()
        ..color = const Color(0xFF2C2C2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      _drawEyeArc(canvas, Offset(cx - offset, cy), r, true, stroke);
      _drawEyeArc(canvas, Offset(cx + offset, cy), r, true, stroke);
    } else if (mood == 'happy') {
      final stroke = Paint()
        ..color = const Color(0xFF2C2C2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      _drawEyeArc(canvas, Offset(cx - offset, cy), r, false, stroke);
      _drawEyeArc(canvas, Offset(cx + offset, cy), r, false, stroke);
    } else if (mood == 'angry') {
      final stroke = Paint()
        ..color = const Color(0xFF2C2C2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawLine(Offset(cx - offset - r, cy - r * 0.5),
          Offset(cx - offset + r, cy + r * 0.5), stroke);
      canvas.drawLine(Offset(cx + offset - r, cy + r * 0.5),
          Offset(cx + offset + r, cy - r * 0.5), stroke);
    } else if (mood == 'surprised') {
      // 大きい丸目
      final ring = Paint()
        ..color = const Color(0xFF2C2C2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(cx - offset, cy), r * 1.2, ring);
      canvas.drawCircle(Offset(cx + offset, cy), r * 1.2, ring);
      canvas.drawCircle(Offset(cx - offset, cy), r * 0.5, paint);
      canvas.drawCircle(Offset(cx + offset, cy), r * 0.5, paint);
    } else {
      // neutral：目IDで形状を変える（丸／楕円／細線）
      switch (eyeId % 3) {
        case 0:
          canvas.drawCircle(Offset(cx - offset, cy), r, paint);
          canvas.drawCircle(Offset(cx + offset, cy), r, paint);
          break;
        case 1:
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx - offset, cy), width: r * 2, height: r * 1.4),
            paint,
          );
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx + offset, cy), width: r * 2, height: r * 1.4),
            paint,
          );
          break;
        case 2:
          final stroke = Paint()
            ..color = const Color(0xFF2C2C2A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawLine(Offset(cx - offset - r, cy), Offset(cx - offset + r, cy), stroke);
          canvas.drawLine(Offset(cx + offset - r, cy), Offset(cx + offset + r, cy), stroke);
          break;
      }
    }
  }

  void _drawEyeArc(Canvas canvas, Offset center, double r, bool downward, Paint stroke) {
    final path = Path();
    if (downward) {
      path.moveTo(center.dx - r, center.dy);
      path.quadraticBezierTo(center.dx, center.dy - r, center.dx + r, center.dy);
    } else {
      path.moveTo(center.dx - r, center.dy);
      path.quadraticBezierTo(center.dx, center.dy + r, center.dx + r, center.dy);
    }
    canvas.drawPath(path, stroke);
  }

  void _drawMouth(Canvas canvas, double cx, double cy, double w) {
    final stroke = Paint()
      ..color = const Color(0xFF993C1D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path();
    if (mood == 'happy') {
      path.moveTo(cx - w / 2, cy - 2);
      path.quadraticBezierTo(cx, cy + 6, cx + w / 2, cy - 2);
    } else if (mood == 'sad') {
      path.moveTo(cx - w / 2, cy + 4);
      path.quadraticBezierTo(cx, cy - 2, cx + w / 2, cy + 4);
    } else if (mood == 'angry') {
      canvas.drawLine(Offset(cx - w / 2, cy + 2), Offset(cx + w / 2, cy + 2), stroke);
      return;
    } else if (mood == 'surprised') {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy + 2), width: w * 0.5, height: w * 0.6),
        stroke,
      );
      return;
    } else {
      path.moveTo(cx - w / 2, cy);
      path.quadraticBezierTo(cx, cy + 2, cx + w / 2, cy);
    }
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_AvatarPainter old) {
    return old.hairId != hairId ||
        old.hairColorId != hairColorId ||
        old.eyeId != eyeId ||
        old.outlineId != outlineId ||
        old.skinId != skinId ||
        old.mood != mood;
  }
}
