# AI楽曲クリエイティブブリーフ — 資本主義ゲーム

GDD §14 サウンド設計 / §17.5 AI楽曲制作方針 準拠。
Suno AI（または Udio / MusicGen 等）で生成する 12曲の制作仕様書。

最終更新：2026-05-08
担当：ユーザー（実生成）／ Claude（プロンプト作成）

---

## 全体方針

- **総曲数**：12曲（4時代 × 3版）
- **長さ**：各 1分30秒〜2分30秒（ループ前提）
- **フォーマット**：MP3 320kbps（最終はOgg Vorbis 192kbpsへ圧縮）
- **生成方法**：Suno AI を主。プロンプト + ジャンルタグ + リファレンス
- **権利**：Suno の利用規約に従い、生成物の商用利用権を確保（有料プランで保証される）
- **コスト感**：Suno Pro $10/月 × 1ヶ月で十分試行可能

---

## ファイル命名規則

```
assets/sounds/bgm/
├── title.mp3                          ※全時代共通
├── era_showa_normal.mp3
├── era_heisei_normal.mp3
├── era_reiwa_normal.mp3
├── era_future_normal.mp3
├── era_showa_event.mp3
├── era_heisei_event.mp3
├── era_reiwa_event.mp3
├── era_future_event.mp3
├── ending_normal.mp3
├── ending_tragedy.mp3
└── ending_great.mp3
```

12 = 1 タイトル + 4×2 ゲーム中 + 3 エンディング

---

## 1. タイトル画面 BGM

### `title.mp3`

```
[タグ]
piano, ambient, slow, melancholic, hopeful, instrumental, japanese aesthetic

[プロンプト]
A gentle piano solo with subtle string pad in the background. Slow tempo
(60-70 BPM). Melancholic but hopeful melody, like watching old photo albums.
Faint music box in the high register. 1-2 minute loop. No lyrics.
The mood should evoke "looking back at a life that hasn't started yet."

[長さ] 1m30s
[ループ] yes (smooth crossfade between end and start)
[強度] PP〜MP（静か）
[使用画面] タイトル画面（人生は何度でも） / メニュー画面
```

---

## 2. 通常月BGM（4時代）

ゲーム中の大半の時間で流れる。聴き疲れしない・控えめなトラック。

### `era_showa_normal.mp3` — 昭和（1960-）

```
[タグ]
showa pop, vintage japanese, light orchestra, brass, retro, optimistic

[プロンプト]
Light Showa-era Japanese pop instrumental. Brass section (trumpet, sax) with
gentle vibraphone, walking bass, soft drums (brushes). 80-100 BPM. Mood:
post-war optimism, going to work in a new high-rise office, "Japan as #1"
energy. Like a 1970s NHK morning drama theme. No lyrics. 2-minute loop.

[長さ] 2m
[ループ] yes
[強度] MP〜MF
[備考] 高度成長期の高揚感、サラリーマンの朝
```

### `era_heisei_normal.mp3` — 平成（1985-）

```
[タグ]
city pop, 1990s, j-pop, soft synth, calm, nostalgic, urban

[プロンプト]
City pop instrumental in the style of Tatsuro Yamashita's "Plastic Love"
era. Soft synth pads, slap bass, electric piano (Rhodes), drum machine.
95-105 BPM. Mood: nostalgic, urban, slightly melancholic. Like riding a
train through Tokyo at dusk in 1995. No lyrics. 2-minute loop.

[長さ] 2m
[ループ] yes
[強度] MP
[備考] バブル後期〜失われた10年の透明感
```

### `era_reiwa_normal.mp3` — 令和（2010-）

```
[タグ]
lo-fi hip hop, chill, study beats, modern, ambient, headphone-friendly

[プロンプト]
Lo-fi hip hop instrumental. Chillhop drum beats (boom-bap with vinyl crackle),
mellow electric piano, ambient synth pads, occasional shaker. 70-80 BPM.
Mood: cafe study session, working from home, scrolling smartphone in bed.
No lyrics. 2-minute loop.

[長さ] 2m
[ループ] yes
[強度] MP
[備考] スマホ時代・在宅ワーク
```

### `era_future_normal.mp3` — 近未来（2040-）

```
[タグ]
ambient electronic, futuristic, synthwave, cyberpunk-light, contemplative

[プロンプト]
Ambient electronic instrumental. Soft analog synth pads, granular textures,
occasional 808 sub-bass, glitchy percussion. 90-100 BPM. Mood: walking
through a neon-lit city in 2040, AI assistant whispers in your ear, but
the streets are quiet because everyone works from home. Subtle melancholy
beneath the futurism. No lyrics. 2-minute loop.

[長さ] 2m
[ループ] yes
[強度] MP〜PP
[備考] サイバーパンク的だが孤独感もある
```

---

## 3. ライフイベントBGM（4時代）

イベントモーダル発火中、決断を迫られる場面で短時間鳴る。緊張感あり。

### `era_showa_event.mp3`

```
[タグ]
showa drama, orchestral, suspense, brass, strings

[プロンプト]
Dramatic orchestral cue. Strings tremolo, brass swells, timpani rolls.
Tempo varies (60-110 BPM). Mood: a samurai drama climax, a salaryman's
career-defining moment. Builds tension over 30 seconds, peaks, releases.
1m30s loop with clear midpoint accent.

[長さ] 1m30s
[ループ] yes
[強度] MF〜F
```

### `era_heisei_event.mp3`

```
[タグ]
1990s drama OST, piano, strings, emotional, japanese ballad

[プロンプト]
Emotional piano-led cue with string section. Like Joe Hisaishi's "Spirited
Away" but more contemporary. 70-90 BPM. Mood: a heartfelt confession, a
career change, a friend's wedding. Builds emotion over 1 minute, swells,
resolves. 1m30s loop.

[長さ] 1m30s
[ループ] yes
[強度] MP〜F
```

### `era_reiwa_event.mp3`

```
[タグ]
modern cinematic, hybrid orchestra, electronic, tense

[プロンプト]
Modern hybrid cinematic cue. Pulsing synth bass, layered strings, electronic
percussion. 100-120 BPM. Mood: a startup pitch, a viral moment, a major
life decision in the smartphone era. Tension builds, breaks, resolves.
1m30s loop.

[長さ] 1m30s
[ループ] yes
[強度] MF〜F
```

### `era_future_event.mp3`

```
[タグ]
sci-fi orchestral, hybrid, ethereal, climactic

[プロンプト]
Sci-fi orchestral hybrid. Ethereal female choir (no words), modular synths,
hybrid percussion. 80-110 BPM. Mood: standing on the edge of a major
technological / personal threshold. Builds slowly, climaxes, resolves with
ambiguity. 1m30s loop.

[長さ] 1m30s
[ループ] yes
[強度] MP〜F
```

---

## 4. エンディングBGM（3バリアント）

死亡演出 → エンディング画面で流れる。GDD §11 のエンディング14分類を3グループに集約：

### `ending_normal.mp3` — 平凡な人生・凡庸エンド

```
[タグ]
piano solo, gentle, quiet, contemplative, minimal

[プロンプト]
Quiet piano solo, simple melody. 60-70 BPM. Single piano, no other
instruments. Mood: the end of an ordinary life, a quiet farewell. Sparse
notes, lots of space between phrases. 2-minute loop.

[長さ] 2m
[ループ] yes
[強度] PP〜MP
[使用エンディング] 標準死／長寿全う／凡庸 など
```

### `ending_tragedy.mp3` — 早世・悲劇エンド

```
[タグ]
solo cello, sorrowful, slow, minor key, tragic

[プロンプト]
Solo cello with subtle string pad. Slow tempo (50-60 BPM). Minor key.
Mood: a life cut short too soon, regret, but with dignity. The cello
sings a lament. No drums. 2-minute loop.

[長さ] 2m
[ループ] yes
[強度] PP〜MP
[使用エンディング] 早世／事故死／病死 など
```

### `ending_great.mp3` — 偉業・覚醒エンド

```
[タグ]
orchestral, triumphant, hopeful, full orchestra, japanese aesthetic

[プロンプト]
Triumphant orchestral piece. Full orchestra: strings, brass, timpani,
choir (no words, vowels only). 80-100 BPM. Major key with subtle minor
moments. Mood: a life well-lived, a legacy, "the credits roll on a
masterpiece." 2-minute loop.

[長さ] 2m
[ループ] yes
[強度] MF〜FF
[使用エンディング] 大富豪／聖人／覚醒覚醒／伝説 など
```

---

## 5. 効果音（SE）— 補助的

GDD §14.3 に従い、最低限のSEを別途用意。Suno は楽曲生成主体なので、SEは別ツール（例：Soundly / freesound.org）から調達推奨。

| SE名 | 用途 | 長さ |
|---|---|---|
| `se_select.mp3` | ボタンタップ | 0.1s |
| `se_confirm.mp3` | 決定／月次進行 | 0.3s |
| `se_event.mp3` | イベント発火 | 0.5s |
| `se_levelup.mp3` | スキル解放 | 0.8s |
| `se_death.mp3` | 死亡演出 | 1.5s |
| `se_achievement.mp3` | 実績解放 | 1.0s |

これらは Suno でなく、freesound.org でCC0素材を選んで加工が現実的。

---

## 6. 制作スケジュール

| ステップ | 期間 | 担当 |
|---|---|---|
| 1. プロンプト調整 | 30分 | Claude（このファイル） |
| 2. Suno で各曲 5-10 バリエーション生成 | 各曲30分×12 = 6時間 | ユーザー |
| 3. ベスト1つを選定 | 1時間 | ユーザー |
| 4. 必要に応じて部分修正（mid-section再生成等） | 2時間 | ユーザー |
| 5. ループ加工（Audacity等） | 2時間 | ユーザー |
| 6. 音量正規化（-14 LUFS） | 1時間 | ユーザー |
| 7. Ogg Vorbis 192kbps 圧縮 | 30分 | スクリプト |
| 8. assets/sounds/bgm/ に配置 | 5分 | ユーザー |
| 9. pubspec.yaml に登録 | 5分 | Claude |
| 10. AudioService 経由で再生実装 | 4時間 | Claude |

合計：ユーザー側 約12時間、Claude側 約5時間。

---

## 7. 予算感

| 項目 | コスト |
|---|---|
| Suno Pro 1ヶ月 | $10（≒¥1,500） |
| 必要に応じて2ヶ月目 | +$10 |
| 合計楽曲制作費 | **$10〜20（¥1,500〜3,000）** |

GDD §14.4 の「外注比 90% 減」目標を達成（従来の作曲家委託なら20〜50万円相当）。

---

## 8. ライセンス確認

Suno の利用規約（2026-05時点）：
- Pro / Premier プラン契約者は商用利用OK
- 生成物の著作権はユーザーに帰属（Sunoは非排他的ライセンスを保持）
- AdSense・AdMob・Google Play・App Store での利用可能

→ 問題なし。

---

## 9. 代替ツール

Suno が使えない・気に入らない場合：

| ツール | 強み | 弱み |
|---|---|---|
| **Udio** | 音質高、長尺対応 | $10/月、商用利用条件確認要 |
| **MusicGen (Meta)** | OSS、無料、ローカル実行可能 | UI なし、Python必須、品質バラツキ |
| **AIVA** | クラシック特化、楽譜出力可 | 月額高め（$33〜） |
| **Stable Audio** | 高音質、Stability AI製 | 商用利用は$11.99/月以上 |

Suno → Udio → MusicGen の順で試行推奨。

---

## 10. 完了チェックリスト

12曲生成・配置完了時のチェック：

- [ ] 12曲すべて assets/sounds/bgm/ に配置
- [ ] 各曲のループ点が滑らか（ノイズ・クリックなし）
- [ ] 音量レベル統一（-14 LUFS 基準、±2 LUFS以内）
- [ ] pubspec.yaml の assets セクションに登録
- [ ] Flutter で各曲が再生できる（DevTools / 実機確認）
- [ ] 設定画面のBGM音量スライダーで増減可能
- [ ] BGMオフ設定で全曲ミュートされる
- [ ] 時代切替時に滑らかにクロスフェード（500ms程度）
- [ ] イベント終了時にメインBGMに復帰
- [ ] エンディング遷移時に死亡演出SE→ending_xxx.mp3

---

## 連絡先

質問があれば：
- Suno コミュニティ：https://discord.gg/suno-ai
- Email：ri.mo.950526@gmail.com
