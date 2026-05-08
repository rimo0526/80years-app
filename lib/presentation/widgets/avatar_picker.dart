// ============================================================
// AvatarPicker / 顔パーツ組合せUI
// GDD §4.3 顔カスタマイズ仕様
// 髪型8×髪色6×目6×輪郭4×肌色4＝4,608通り
// ============================================================
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'avatar_preview.dart';

class AvatarPickerValue {
  final int hairId;
  final int hairColorId;
  final int eyeId;
  final int outlineId;
  final int skinId;

  const AvatarPickerValue({
    this.hairId = 0,
    this.hairColorId = 0,
    this.eyeId = 0,
    this.outlineId = 0,
    this.skinId = 0,
  });

  AvatarPickerValue copyWith({
    int? hairId,
    int? hairColorId,
    int? eyeId,
    int? outlineId,
    int? skinId,
  }) {
    return AvatarPickerValue(
      hairId: hairId ?? this.hairId,
      hairColorId: hairColorId ?? this.hairColorId,
      eyeId: eyeId ?? this.eyeId,
      outlineId: outlineId ?? this.outlineId,
      skinId: skinId ?? this.skinId,
    );
  }
}

class AvatarPicker extends StatelessWidget {
  final AvatarPickerValue value;
  final ValueChanged<AvatarPickerValue> onChanged;
  final VoidCallback? onRandomize;

  const AvatarPicker({
    required this.value,
    required this.onChanged,
    this.onRandomize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // プレビュー
        Center(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.bgSub,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppPalette.border, width: 0.5),
            ),
            child: AvatarPreview(
              hairId: value.hairId,
              hairColorId: value.hairColorId,
              eyeId: value.eyeId,
              outlineId: value.outlineId,
              skinId: value.skinId,
              size: 140,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (onRandomize != null)
          Center(
            child: TextButton.icon(
              onPressed: onRandomize,
              icon: const Icon(Icons.shuffle, size: 16),
              label: const Text('ランダム'),
            ),
          ),
        const SizedBox(height: 8),

        // パーツ別カルーセル
        _PartCarousel(
          label: '髪型',
          current: value.hairId,
          max: 8,
          onChanged: (v) => onChanged(value.copyWith(hairId: v)),
        ),
        _PartCarousel(
          label: '髪色',
          current: value.hairColorId,
          max: 6,
          onChanged: (v) => onChanged(value.copyWith(hairColorId: v)),
        ),
        _PartCarousel(
          label: '目',
          current: value.eyeId,
          max: 6,
          onChanged: (v) => onChanged(value.copyWith(eyeId: v)),
        ),
        _PartCarousel(
          label: '輪郭',
          current: value.outlineId,
          max: 4,
          onChanged: (v) => onChanged(value.copyWith(outlineId: v)),
        ),
        _PartCarousel(
          label: '肌色',
          current: value.skinId,
          max: 4,
          onChanged: (v) => onChanged(value.copyWith(skinId: v)),
        ),
      ],
    );
  }
}

class _PartCarousel extends StatelessWidget {
  final String label;
  final int current;
  final int max;
  final ValueChanged<int> onChanged;

  const _PartCarousel({
    required this.label,
    required this.current,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppPalette.textSub),
            ),
          ),
          IconButton(
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            onPressed: () => onChanged((current - 1 + max) % max),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppPalette.bgInner,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppPalette.border, width: 0.5),
              ),
              child: Text('${current + 1} / $max',
                  style: const TextStyle(fontSize: 13)),
            ),
          ),
          IconButton(
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            onPressed: () => onChanged((current + 1) % max),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
