"""AI Playtest: Random Bot Python wrapper（Phase C v0.1）

Dart 側の random_bot.dart を呼び出し、結果サマリを集約する薄いラッパ。
将来的に Claude API でログ分析・バランス調整提案する基盤。

使い方:
  python tools/ai_playtest/random_bot.py
  python tools/ai_playtest/random_bot.py --sessions=100 --max-turns=960
  python tools/ai_playtest/random_bot.py --analyze-only --date 2026-05-09  # 既存ログのみ集計
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import date
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP_ROOT = HERE.parent.parent
LOGS_DIR = HERE / "logs"


def run_dart_bot(sessions: int, max_turns: int, seed: int | None, verbose: bool) -> int:
    """Dart 側の random_bot.dart を呼び出す。"""
    cmd = [
        "dart",
        "run",
        "tools/ai_playtest/random_bot.dart",
        f"--sessions={sessions}",
        f"--max-turns={max_turns}",
    ]
    if seed is not None:
        cmd.append(f"--seed={seed}")
    if verbose:
        cmd.append("--verbose")

    print(f"[ai_playtest:py] cwd={APP_ROOT}")
    print(f"[ai_playtest:py] cmd={' '.join(cmd)}")
    return subprocess.call(cmd, cwd=str(APP_ROOT))


def analyze_logs(target_date: str) -> dict:
    """指定日のログを集計してサマリを出力。"""
    date_dir = LOGS_DIR / target_date
    if not date_dir.exists():
        raise FileNotFoundError(f"no logs for {target_date}: {date_dir}")

    sessions = sorted(date_dir.glob("session_*.json"))
    summary_file = date_dir / "_summary.json"

    if not sessions:
        return {"date": target_date, "session_count": 0}

    aggregate = {
        "date": target_date,
        "session_count": len(sessions),
        "ok_count": 0,
        "error_count": 0,
        "avg_final_turn": 0,
        "avg_final_age": 0,
        "min_final_age": None,
        "max_final_age": None,
        "errors": [],
    }

    final_turns = []
    final_ages = []

    for s in sessions:
        try:
            data = json.loads(s.read_text(encoding="utf-8"))
        except Exception as e:
            aggregate["error_count"] += 1
            aggregate["errors"].append({"session": s.name, "parse_error": str(e)})
            continue

        if data.get("error"):
            aggregate["error_count"] += 1
            aggregate["errors"].append({
                "session": data.get("session_id"),
                "error": (data.get("error") or "").split("\n")[0],
            })
        else:
            aggregate["ok_count"] += 1

        result = data.get("result") or {}
        ft = result.get("final_turn")
        fa = result.get("final_age")
        if ft is not None:
            final_turns.append(ft)
        if fa is not None:
            final_ages.append(fa)
            if aggregate["min_final_age"] is None or fa < aggregate["min_final_age"]:
                aggregate["min_final_age"] = fa
            if aggregate["max_final_age"] is None or fa > aggregate["max_final_age"]:
                aggregate["max_final_age"] = fa

    if final_turns:
        aggregate["avg_final_turn"] = sum(final_turns) // len(final_turns)
    if final_ages:
        aggregate["avg_final_age"] = sum(final_ages) / len(final_ages)

    return aggregate


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--sessions", type=int, default=10)
    p.add_argument("--max-turns", type=int, default=960)
    p.add_argument("--seed", type=int, default=None)
    p.add_argument("--verbose", action="store_true")
    p.add_argument("--analyze-only", action="store_true",
                   help="Dart bot を実行せず、既存ログの集計のみ")
    p.add_argument("--date", default=date.today().isoformat(),
                   help="集計対象日（YYYY-MM-DD、default: today）")
    args = p.parse_args()

    if not args.analyze_only:
        rc = run_dart_bot(args.sessions, args.max_turns, args.seed, args.verbose)
        if rc != 0:
            print(f"[ai_playtest:py] dart bot returned exit {rc}", file=sys.stderr)
            # 集計は続行（エラーセッションも分析対象）

    print("\n[ai_playtest:py] aggregating...")
    try:
        agg = analyze_logs(args.date)
    except FileNotFoundError as e:
        print(f"[ai_playtest:py] {e}", file=sys.stderr)
        sys.exit(2)

    print(json.dumps(agg, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
