// ============================================================
// 設定データ / GDD §18.3.5 settings ブロック準拠
// ============================================================

class AudioSettings {
  final int bgmVolume;
  final int seVolume;

  const AudioSettings({this.bgmVolume = 70, this.seVolume = 80});

  Map<String, dynamic> toJson() => {
        'bgm_volume': bgmVolume,
        'se_volume': seVolume,
      };

  factory AudioSettings.fromJson(Map<String, dynamic> j) => AudioSettings(
        bgmVolume: (j['bgm_volume'] ?? 70) as int,
        seVolume: (j['se_volume'] ?? 80) as int,
      );
}

class DisplaySettings {
  final String speed;       // slow / normal / fast
  final String hudMode;     // standard / simple
  final String fontSize;    // small / default / large / xlarge
  final bool animationReduced;
  final bool flashSuppressed;

  const DisplaySettings({
    this.speed = 'normal',
    this.hudMode = 'standard',
    this.fontSize = 'default',
    this.animationReduced = false,
    this.flashSuppressed = false,
  });

  Map<String, dynamic> toJson() => {
        'speed': speed,
        'hud_mode': hudMode,
        'font_size': fontSize,
        'animation_reduced': animationReduced,
        'flash_suppressed': flashSuppressed,
      };

  factory DisplaySettings.fromJson(Map<String, dynamic> j) => DisplaySettings(
        speed: (j['speed'] ?? 'normal') as String,
        hudMode: (j['hud_mode'] ?? 'standard') as String,
        fontSize: (j['font_size'] ?? 'default') as String,
        animationReduced: (j['animation_reduced'] ?? false) as bool,
        flashSuppressed: (j['flash_suppressed'] ?? false) as bool,
      );
}

class AccessibilitySettings {
  final String handed;     // left / right / both
  final bool voiceover;

  const AccessibilitySettings({this.handed = 'right', this.voiceover = false});

  Map<String, dynamic> toJson() => {
        'handed': handed,
        'voiceover': voiceover,
      };

  factory AccessibilitySettings.fromJson(Map<String, dynamic> j) =>
      AccessibilitySettings(
        handed: (j['handed'] ?? 'right') as String,
        voiceover: (j['voiceover'] ?? false) as bool,
      );
}

/// 同意管理（GDD §17.2.6 簡易CMP）
class ConsentSettings {
  final bool? attGranted;
  final bool analyticsOptin;
  final bool adsPersonalization;
  final bool crashReportOptin;
  final String? policyAcceptedAt; // ISO 8601

  const ConsentSettings({
    this.attGranted,
    this.analyticsOptin = false,
    this.adsPersonalization = false,
    this.crashReportOptin = false,
    this.policyAcceptedAt,
  });

  Map<String, dynamic> toJson() => {
        'att_granted': attGranted,
        'analytics_optin': analyticsOptin,
        'ads_personalization': adsPersonalization,
        'crash_report_optin': crashReportOptin,
        'policy_accepted_at': policyAcceptedAt,
      };

  factory ConsentSettings.fromJson(Map<String, dynamic> j) => ConsentSettings(
        attGranted: j['att_granted'] as bool?,
        analyticsOptin: (j['analytics_optin'] ?? false) as bool,
        adsPersonalization: (j['ads_personalization'] ?? false) as bool,
        crashReportOptin: (j['crash_report_optin'] ?? false) as bool,
        policyAcceptedAt: j['policy_accepted_at'] as String?,
      );
}

class SettingsData {
  final AudioSettings audio;
  final DisplaySettings display;
  final AccessibilitySettings accessibility;
  final ConsentSettings consent;

  const SettingsData({
    this.audio = const AudioSettings(),
    this.display = const DisplaySettings(),
    this.accessibility = const AccessibilitySettings(),
    this.consent = const ConsentSettings(),
  });

  Map<String, dynamic> toJson() => {
        'audio': audio.toJson(),
        'display': display.toJson(),
        'accessibility': accessibility.toJson(),
        'consent': consent.toJson(),
      };

  factory SettingsData.fromJson(Map<String, dynamic> j) => SettingsData(
        audio: AudioSettings.fromJson(
            (j['audio'] as Map?)?.cast<String, dynamic>() ?? {}),
        display: DisplaySettings.fromJson(
            (j['display'] as Map?)?.cast<String, dynamic>() ?? {}),
        accessibility: AccessibilitySettings.fromJson(
            (j['accessibility'] as Map?)?.cast<String, dynamic>() ?? {}),
        consent: ConsentSettings.fromJson(
            (j['consent'] as Map?)?.cast<String, dynamic>() ?? {}),
      );
}
