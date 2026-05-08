// ============================================================
// GraveShareWidget / 墓標画像生成＆SNS共有
// GDD §11.4 / §15.1.5
//
// 死亡時のエンディング画面で表示。
// 墓標画像を1.91:1（Twitter/Threadsカード）と1:1（Instagram）の2版で
// 生成し、share_plus 経由で OS 共有シートを起動。
// ============================================================
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme.dart';
import '../../domain/models/character.dart';
import '../../core/analytics/analytics_helper.dart';

/// 墓標形状
enum TombShape { rectangle, square }

class GraveShareWidget extends StatefulWidget {
  final Character character;
  final String endingTitle;
  final String? quote;            // 戒名・座右の銘等
  final List<String> achievements; // ハイライト達成（最大3件）

  const GraveShareWidget({
    super.key,
    required this.character,
    required this.endingTitle,
    this.quote,
    this.achievements = const [],
  });

  @override
  State<GraveShareWidget> createState() => _GraveShareWidgetState();
}

class _GraveShareWidgetState extends State<GraveShareWidget> {
  final GlobalKey _rectKey = GlobalKey();
  final GlobalKey _squareKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // プレビュー：1.91:1 横長（Twitter/Threadsカード用）
          _buildPreview(_rectKey, TombShape.rectangle),
          const SizedBox(height: 16),
          // プレビュー：1:1 正方形（Instagram用）
          _buildPreview(_squareKey, TombShape.square),
          const SizedBox(height: 24),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildPreview(GlobalKey key, TombShape shape) {
    final isRect = shape == TombShape.rectangle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AspectRatio(
        aspectRatio: isRect ? 1.91 : 1.0,
        child: RepaintBoundary(
          key: key,
          child: _GraveCanvas(
            character: widget.character,
            endingTitle: widget.endingTitle,
            quote: widget.quote,
            achievements: widget.achievements,
            shape: shape,
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('SNSで共有（横長）'),
              onPressed: _sharing ? null : () => _share(_rectKey, '1.91-1'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Instagram用'),
              onPressed: _sharing ? null : () => _share(_squareKey, '1-1'),
            ),
          ),
        ],
      ),
    );
  }

  /// RepaintBoundary→PNG→share_plus
  Future<void> _share(GlobalKey key, String aspectLabel) async {
    setState(() => _sharing = true);
    try {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final fileName =
          '${widget.character.name}_tomb_$aspectLabel.png';
      final xfile = XFile.fromData(bytes, name: fileName, mimeType: 'image/png');
      await Share.shareXFiles(
        [xfile],
        text:
            '${widget.character.name}（${widget.character.age}歳）の人生が幕を閉じました。\n'
            '#資本主義ゲーム #人生は何度でも',
      );

      // 共有イベントログ
      await AnalyticsHelper.instance
          .logTombShared(platform: 'os_share_sheet');
    } catch (e, stack) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('共有に失敗しました：$e')),
        );
      }
      AnalyticsHelper.instance
          .logError(e, stack, reason: 'tomb_share_failed');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

/// 墓標画像 1枚を Canvas で描画
class _GraveCanvas extends StatelessWidget {
  final Character character;
  final String endingTitle;
  final String? quote;
  final List<String> achievements;
  final TombShape shape;

  const _GraveCanvas({
    required this.character,
    required this.endingTitle,
    required this.quote,
    required this.achievements,
    required this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final isRect = shape == TombShape.rectangle;
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.bgBase,
        border: Border.all(color: AppPalette.border, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 上部：「資」エンブレム
            Container(
              width: isRect ? 60 : 80,
              height: isRect ? 60 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppPalette.textMain, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '資',
                style: TextStyle(
                  fontSize: isRect ? 28 : 36,
                  fontWeight: FontWeight.w300,
                  color: AppPalette.textMain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // キャラ名
            Text(
              character.name,
              style: TextStyle(
                fontSize: isRect ? 18 : 22,
                fontWeight: FontWeight.w500,
                color: AppPalette.textMain,
              ),
            ),
            const SizedBox(height: 4),
            // 享年・時代
            Text(
              '享年 ${character.age}歳 / ${character.era.label}',
              style: TextStyle(
                fontSize: isRect ? 12 : 14,
                color: AppPalette.textSub,
              ),
            ),
            const SizedBox(height: 12),
            // エンディングタイトル（戒名扱い）
            Text(
              endingTitle,
              style: TextStyle(
                fontSize: isRect ? 16 : 18,
                color: AppPalette.goldText,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (quote != null) ...[
              const SizedBox(height: 12),
              Text(
                quote!,
                style: TextStyle(
                  fontSize: isRect ? 11 : 13,
                  fontStyle: FontStyle.italic,
                  color: AppPalette.textSub,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (achievements.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...achievements.take(3).map((a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '🏆 $a',
                      style: TextStyle(
                        fontSize: isRect ? 10 : 12,
                        color: AppPalette.textMain,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),
            ],
            const Spacer(),
            // 下部ロゴ＋ハッシュタグ
            Text(
              '資本主義ゲーム — 人生は何度でも',
              style: TextStyle(
                fontSize: isRect ? 10 : 11,
                color: AppPalette.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
