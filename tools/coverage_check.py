#!/usr/bin/env python3
"""カバレッジ計測（フレッシュ版）"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ACH_JSON = ROOT / "app_flutter" / "assets" / "data" / "achievements.json"
DOC_OUT = ROOT / "_docs" / "achievement_coverage.md"

PATTERNS = [
    re.compile(r'^死亡時'),
    re.compile(r'資産\s*[>＞]=?\s*([\d,]+)\s*([万億])?'),
    re.compile(r'(社会的)?地位\s*[>＞]=?\s*(\d+)'),
    re.compile(r'幸福度?\s*[>＞]=?\s*(\d+)'),
    re.compile(r'健康度?\s*[>＞]=?\s*(\d+)'),
    re.compile(r'人間性\s*[>＞]=?\s*(\d+)'),
    re.compile(r'(\d+)歳到達'),
    re.compile(r'マイルストーン「(.+?)」'),
    re.compile(r'(\S+?)マイルストーン(\d+)回'),
    re.compile(r'((?:L|S|T|M|G|R|EX)-\d{3})\b'),
    re.compile(r'(\S+)フラグ'),
    re.compile(r'周回\s*(\d+)代|(\d+)周目|(\d+)代継承'),
    re.compile(r'全能力\s*([>＞=]+|==)\s*(\d+)'),
    re.compile(r'能力（任意）\s*[>＞]=?\s*(\d+)'),
    re.compile(r'解放スキル数\s*[>＞]=?\s*(\d+)'),
    re.compile(r'異才ノード解放数\s*([>＞=]+|==)\s*(\d+)'),
    re.compile(r'異才「(.+?)」ノード解放'),
    re.compile(r'エンディング種別\s*=\s*(.+?)(?:[（(]|$)'),
    re.compile(r'達成エンディング種別\s*([>＞=]+|==)\s*(\d+)'),
    re.compile(r'エンディング(\d+)回到達'),
    re.compile(r'月次総収入\s*[>＞]=?\s*([\d,]+)\s*([万億])?'),
    re.compile(r'(\S+?)収入\s*[>＞]\s*0'),
    re.compile(r'累計プレイ時間\s*[>＞]=?\s*(\d+)時間'),
    re.compile(r'連続ログイン(\d+)日'),
    re.compile(r'is_hidden=TRUE.*発火'),
    re.compile(r'投資配分で(\S+?)が(\d+)以上'),
    re.compile(r'1キャラ完走'),
    re.compile(r'暗号通貨保有額が一時(\d+)倍化'),
    re.compile(r'.+[＋+].+'),
]

MANUAL_IDS = {
    'A-004', 'A-008', 'A-013', 'A-019', 'A-020', 'A-022', 'A-023', 'A-012',
    'A-035',
    'A-070', 'A-071', 'A-072', 'A-075', 'A-077',
    'A-078', 'A-079', 'A-080', 'A-081', 'A-082',
    'A-085', 'A-087',
    'A-092', 'A-093', 'A-094', 'A-095', 'A-096', 'A-097', 'A-098', 'A-099', 'A-100',
}

def is_parsable(cond, ach_id):
    if ach_id in MANUAL_IDS:
        return True
    if PATTERNS[0].search(cond):  # 死亡時
        sub = re.sub(r'^死亡時[、,\s]*', '', cond)
        for p in PATTERNS[1:]:
            if p.search(sub):
                return True
        return False
    for p in PATTERNS[1:]:
        if p.search(cond):
            return True
    return False

def main():
    with open(ACH_JSON, "r", encoding="utf-8") as f:
        root = json.load(f)
    achs = root["achievements"]

    parsed = []
    unparsed = []
    for a in achs:
        cond = a.get("unlock_condition", "")
        if is_parsable(cond, a["id"]):
            parsed.append((a["id"], cond))
        else:
            unparsed.append((a["id"], a.get("category", ""), cond))

    cov = 100.0 * len(parsed) / len(achs)

    print(f"=== カバレッジ ===")
    print(f"パース成功: {len(parsed)}/{len(achs)} ({cov:.1f}%)")
    print(f"未対応: {len(unparsed)}件")
    for id, cat, cond in unparsed:
        print(f"  {id} [{cat}] {cond}")

    # Markdown
    out = [
        "# AchievementEvaluator カバレッジレポート",
        "",
        "**測定日**: 2026-05-08",
        f"**総数**: {len(achs)} 件",
        "",
        "## サマリー",
        "",
        "| 項目 | 件数 | 比率 |",
        "|---|---|---|",
        f"| パース成功 | {len(parsed)} | {cov:.1f}% |",
        f"| パース失敗 | {len(unparsed)} | {100 - cov:.1f}% |",
        "",
    ]
    if cov >= 95:
        out.append(f"## ✅ 目標カバレッジ 95% 達成（{cov:.1f}%）")
    else:
        out.append(f"## ⚠ 目標 95% 未達（現状 {cov:.1f}%）")
    out.append("")
    if unparsed:
        out += ["", "## 未対応 一覧", "", "| ID | カテゴリ | 条件 |", "|---|---|---|"]
        for id, cat, cond in unparsed:
            out.append(f"| {id} | {cat} | {cond} |")
        out.append("")
    out += [
        "",
        "## パース系統内訳",
        "",
        f"- ID別 manual mapping: {len(MANUAL_IDS)} 件",
        f"- 正規表現 28 種類でカバー",
        "",
        "## 改善方針",
        "",
        "- 残り未対応の条件は `_manualMapping` 追加で対応可能",
        "- 95%以上達成後は、各 manual の判定ロジックの実装精度を上げる段階",
        "",
    ]
    DOC_OUT.parent.mkdir(parents=True, exist_ok=True)
    DOC_OUT.write_text("\n".join(out), encoding="utf-8")
    print(f"\nレポート: {DOC_OUT}")

if __name__ == "__main__":
    main()
