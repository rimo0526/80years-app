#!/usr/bin/env python3
"""
AchievementEvaluator パターン解析カバレッジ測定ツール

achievements.json の100件の unlock_condition を Dart 側パーサーと
同じロジックでチェックし、カバレッジを算出。
未対応IDは ID別マッピング追加候補として出力。

使い方：
  cd .../資本主義ゲーム
  python3 app_flutter/tools/achievement_coverage.py
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ACH_JSON = ROOT / "app_flutter" / "assets" / "data" / "achievements.json"
DOC_OUT = ROOT / "_docs" / "achievement_coverage.md"

# ============================================================
# Dart 側 _parsePredicate と同じパターンを Python で再現
# ============================================================
PATTERNS = [
    # (名前, 正規表現, 説明)
    ("manual",   None, "ID別手動マッピング"),
    ("death",    re.compile(r'^死亡時'), "死亡時、X"),
    ("asset",    re.compile(r'資産\s*[>＞]=?\s*([\d,]+)\s*([万億])?'), "資産閾値"),
    ("status",   re.compile(r'(社会的)?地位\s*[>＞]=?\s*(\d+)'), "社会的地位"),
    ("happy",    re.compile(r'幸福度?\s*[>＞]=?\s*(\d+)'), "幸福度"),
    ("health",   re.compile(r'健康度?\s*[>＞]=?\s*(\d+)'), "健康度"),
    ("humanity", re.compile(r'人間性\s*[>＞]=?\s*(\d+)'), "人間性"),
    ("age",      re.compile(r'(\d+)歳到達'), "年齢到達"),
    ("milestone_named", re.compile(r'マイルストーン「(.+?)」'), "マイルストーン名"),
    ("milestone_count", re.compile(r'(\S+?)マイルストーン(\d+)回'), "マイルストーンN回"),
    ("event",    re.compile(r'((?:L|S|T|M|G|R|EX)-\d{3})\b'), "イベントID"),
    ("flag",     re.compile(r'(\S+)フラグ'), "フラグ"),
    ("generation", re.compile(r'周回\s*(\d+)代|(\d+)周目|(\d+)代継承'), "周回"),
    # 拡張パターン（v2）
    ("all_ability", re.compile(r'全能力\s*([>＞=]+|==)\s*(\d+)'), "全能力閾値"),
    ("any_ability", re.compile(r'能力（任意）\s*[>＞]=?\s*(\d+)'), "任意能力"),
    ("skill_count", re.compile(r'解放スキル数\s*[>＞]=?\s*(\d+)'), "解放スキル数"),
    ("exotic_count", re.compile(r'異才ノード解放数\s*([>＞=]+|==)\s*(\d+)'), "異才ノード数"),
    ("exotic_named", re.compile(r'異才「(.+?)」ノード解放'), "異才ノード名"),
    ("ending_kind", re.compile(r'エンディング種別\s*=\s*(.+?)(?:[（(]|$)'), "エンディング種別"),
    ("ending_count", re.compile(r'達成エンディング種別\s*([>＞=]+|==)\s*(\d+)'), "達成エンディング数"),
    ("ending_n", re.compile(r'エンディング(\d+)回到達'), "エンディングN回"),
    ("income_total", re.compile(r'月次総収入\s*[>＞]=?\s*([\d,]+)\s*([万億])?'), "月次総収入"),
    ("income_kind", re.compile(r'(\S+?)収入\s*[>＞]\s*0'), "収入種別"),
    ("playtime", re.compile(r'累計プレイ時間\s*[>＞]=?\s*(\d+)時間'), "累計プレイ時間"),
    ("login_streak", re.compile(r'連続ログイン(\d+)日'), "連続ログイン"),
    ("hidden_evt", re.compile(r'is_hidden=TRUE.*発火'), "隠しイベント"),
    ("invest", re.compile(r'投資配分で(\S+?)が(\d+)以上'), "投資配分"),
    ("char_complete", re.compile(r'1キャラ完走'), "1キャラ完走"),
    ("crypto_x", re.compile(r'暗号通貨保有額が一時(\d+)倍化'), "暗号通貨倍化"),
    ("compound", re.compile(r'.+[＋+].+'), "複合条件（A＋B）"),
]

# Dart の _manualMapping と同期
MANUAL_IDS = {
    # キャリア・複合
    'A-004', 'A-008', 'A-013', 'A-019', 'A-020', 'A-022', 'A-023', 'A-012',
    # 全種類利確
    'A-035',
    # プレイ系
    'A-070', 'A-071', 'A-072', 'A-075', 'A-077',
    # 時代別エンディング
    'A-078', 'A-079', 'A-080', 'A-081', 'A-082',
    # 全イベント・組合せ
    'A-085', 'A-087',
    # 隠しカテゴリ
    'A-092', 'A-093', 'A-094', 'A-095', 'A-096', 'A-097', 'A-098', 'A-099', 'A-100',
}


def parse_one(condition: str, ach_id: str) -> tuple[str, bool]:
    """条件文字列を分類。(matched_pattern_name, is_parsable)"""
    if ach_id in MANUAL_IDS:
        return ("manual", True)

    # 死亡時を最優先で剥がす
    if PATTERNS[1][1].search(condition):
        # 死亡時、X の X 部分を再評価
        sub = re.sub(r'^死亡時[、,\s]*', '', condition)
        for name, pat, _ in PATTERNS[2:]:
            if pat and pat.search(sub):
                return ("death+" + name, True)
        return ("death_only", False)  # サブ条件解析不能

    for name, pat, _ in PATTERNS[2:]:
        if pat and pat.search(condition):
            return (name, True)

    return ("unmatched", False)


def main():
    with open(ACH_JSON, "r", encoding="utf-8") as f:
        root = json.load(f)
    achs = root["achievements"]

    print(f"=== AchievementEvaluator カバレッジ測定 ===")
    print(f"総数: {len(achs)} 件")
    print()

    parsed = []
    unparsed = []
    pattern_counts = {}

    for a in achs:
        cond = a.get("unlock_condition", "")
        pat, ok = parse_one(cond, a["id"])
        pattern_counts[pat] = pattern_counts.get(pat, 0) + 1
        if ok:
            parsed.append((a["id"], pat, cond))
        else:
            unparsed.append((a["id"], a["category"], cond))

    coverage_pct = 100.0 * len(parsed) / len(achs)

    print(f"パース成功: {len(parsed)} 件 ({coverage_pct:.1f}%)")
    print(f"パース失敗: {len(unparsed)} 件")
    print()
    print("--- パターン別件数 ---")
    for p, c in sorted(pattern_counts.items(), key=lambda x: -x[1]):
        print(f"  {p:<20} {c} 件")
    print()
    print("--- 未対応ID 一覧 ---")
    for ach_id, cat, cond in unparsed:
        print(f"  {ach_id} [{cat}] {cond}")
    print()

    # Markdown 出力
    out = [f"# AchievementEvaluator カバレッジレポート",
           "",
           f"**測定日**: 2026-05-08",
           f"**対象**: achievements.json {len(achs)} 件",
           "",
           f"## サマリー",
           "",
           f"| 項目 | 件数 | 比率 |",
           f"|---|---|---|",
           f"| パース成功 | {len(parsed)} | {coverage_pct:.1f}% |",
           f"| パース失敗 | {len(unparsed)} | {100 - coverage_pct:.1f}% |",
           "",
           f"## パターン別件数",
           "",
           f"| パターン | 件数 |",
           f"|---|---|"]
    for p, c in sorted(pattern_counts.items(), key=lambda x: -x[1]):
        out.append(f"| {p} | {c} |")
    out.append("")

    if unparsed:
        out.append(f"## 未対応 {len(unparsed)} 件（ID別マッピング追加候補）")
        out.append("")
        out.append("| ID | カテゴリ | 条件 | 推奨対応 |")
        out.append("|---|---|---|---|")
        for ach_id, cat, cond in unparsed:
            recommend = recommend_handler(cond)
            out.append(f"| {ach_id} | {cat} | {cond} | {recommend} |")
        out.append("")

    out.append(f"## 改善方針")
    out.append("")
    if coverage_pct >= 95:
        out.append("✅ 目標カバレッジ95%以上を達成。残りは ID 別マッピングで対応すれば100%。")
    else:
        gap = int(0.95 * len(achs)) - len(parsed)
        out.append(f"目標95%まで残り {gap} 件。以下を ID 別マッピングに追加：")
    out.append("")

    DOC_OUT.parent.mkdir(parents=True, exist_ok=True)
    DOC_OUT.write_text("\n".join(out), encoding="utf-8")
    print(f"レポート出力: {DOC_OUT}")

    if coverage_pct >= 95:
        print(f"\n✅ 目標カバレッジ95%達成（{coverage_pct:.1f}%）")
        sys.exit(0)
    else:
        print(f"\n⚠ 目標未達（{coverage_pct:.1f}% < 95%）")
        sys.exit(1)


def recommend_handler(cond: str) -> str:
    """未対応条件への推奨対応を簡易判定"""
    if "連続" in cond:
        return "フラグ系（X年連続Y）→ flag check"
    if "全" in cond and ("達成" in cond or "経験" in cond):
        return "全種類経験系 → manual mapping"
    if "%" in cond:
        return "確率系 → 状態経由（隠しフラグ）"
    if any(k in cond for k in ["平均", "合計"]):
        return "集計系 → statistics ブロック"
    if "経過" in cond:
        return "経過時間 → flag (timer)"
    return "ID別 manual mapping"


if __name__ == "__main__":
    main()
