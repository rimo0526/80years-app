#!/usr/bin/env python3
"""
GameEngine v1.2 (バランス調整後) の sim 結果を Python で予測

実機 dart run の代替として、月次フローを Python で簡易実装し、
v1.2 の調整がもたらす影響を数値で予測する。

調整項目：
  1. ageDecay: 0.02→0.01
  2. extraDecayElder (55+): 0.05→0.03
  3. 健康度自然回復 (30-45歳): +0.5/月
  4. 強み寿命ボーナス: brain+3, social+4, sense+3, luck+5
  5. AI で運強み持ちは月+0.5 で運成長

実行：
  cd .../資本主義ゲーム
  python3 app_flutter/tools/sim_predict.py 1000
"""

import random
import sys
import csv
import json
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EVENTS_JSON = ROOT / "app_flutter" / "assets" / "data" / "events.json"

# ============================================================
# 定数（GameEngine と同期）
# ============================================================
ERA_BASE_LIFESPAN = {'昭和': 72, '平成': 80, '令和': 84, '近未来': 90}
STRENGTH_LIFESPAN_BONUS = {'頭脳': 3, '肉体': 0, 'コミュ': 4, 'センス': 3, '運': 5}
STRENGTH_INITIAL_BONUS = {  # キャラ作成時の能力ボーナス
    '頭脳': {'brain': 15},
    '肉体': {'body': 15},
    'コミュ': {'social': 15},
    'センス': {'sense': 15},
    '運': {'luck': 15},
}

ERAS = list(ERA_BASE_LIFESPAN.keys())
STRENGTHS = list(STRENGTH_LIFESPAN_BONUS.keys())


def expected_lifespan(c):
    """GameEngine.expectedLifespan のPython版（v1.2）"""
    base = ERA_BASE_LIFESPAN[c['era']]
    health_mod = round((c['health'] - 50) / 50 * 15)
    humanity_mod = round(c['humanity'] / 50 * 5)
    strength_mod = STRENGTH_LIFESPAN_BONUS[c['strength']]
    return min(115, max(50, base + health_mod + humanity_mod + strength_mod))


def random_event_effect(events):
    """events.json からランダムに1件選び、簡易効果を返す（健康/資産変動の代理）"""
    if not events or random.random() > 0.05:  # 月5%でイベント発火
        return {}
    e = random.choice(events)
    # choices の最初の効果を擬似パース
    choices = e.get('choices', [])
    if not choices:
        return {}
    text = choices[0].get('effect_text', '')
    eff = {}
    # 簡易：「健康+/-N」「資産+/-N(万|億)」を抜く
    import re
    for m in re.finditer(r'(健康|幸福|資産)([+-])(\d+)([万億]?)', text):
        key, sign, n, unit = m.groups()
        v = int(n) * (1 if sign == '+' else -1)
        if key == '資産':
            v *= 100000000 if unit == '億' else 10000 if unit == '万' else 1
        if key == '健康':
            eff['health'] = eff.get('health', 0) + v
        elif key == '幸福':
            eff['happiness'] = eff.get('happiness', 0) + v
        elif key == '資産':
            eff['asset'] = eff.get('asset', 0) + v
    return eff


def run_one(index, era, strength, gender, events, rng):
    """1キャラ80年（960ヶ月）プレイ"""
    # キャラ初期化
    c = {
        'era': era,
        'strength': strength,
        'gender': gender,
        'age': 0,
        'health': 100,
        'happiness': 50,
        'humanity': 0,
        'asset': 50000,
        'brain': 10, 'body': 10, 'social': 10, 'sense': 10, 'luck': 10,
    }
    for k, v in STRENGTH_INITIAL_BONUS[strength].items():
        c[k] += v
    peak = {k: c[k] for k in ['brain', 'body', 'social', 'sense', 'luck']}

    death_cause = '生存（80歳完走）'
    events_fired = 0

    for month in range(960):
        c['age'] = month // 12

        # アクション効果（簡易AI）
        if c['age'] >= 6:
            if rng.random() < 0.2:
                c['health'] = min(100, c['health'] + 3)
                c['happiness'] = min(100, c['happiness'] + 2)
            else:
                if strength == '頭脳':
                    c['brain'] = min(100, c['brain'] + 1)
                elif strength == '肉体':
                    c['body'] = min(100, c['body'] + 1)
                    c['health'] = min(100, c['health'] + 1)
                elif strength == 'コミュ':
                    c['social'] = min(100, c['social'] + 1)
                    c['happiness'] = min(100, c['happiness'] + 1)
                elif strength == 'センス':
                    c['sense'] = min(100, c['sense'] + 1)
                    c['happiness'] = min(100, c['happiness'] + 2)
                elif strength == '運':
                    if month % 2 == 0:
                        c['luck'] = min(100, c['luck'] + 1)
                    c['humanity'] = min(50, c['humanity'] + 1)

        # イベント効果
        eff = random_event_effect(events)
        if eff:
            events_fired += 1
            c['health'] = max(0, min(100, c['health'] + eff.get('health', 0)))
            c['happiness'] = max(0, min(100, c['happiness'] + eff.get('happiness', 0)))
            c['asset'] = max(0, c['asset'] + eff.get('asset', 0))

        # 月次健康度減衰（v1.2: 0.02→0.01）
        age_decay = round(0.01 * c['age'])
        elder_decay = round(0.03 * c['age']) if c['age'] >= 55 else 0
        c['health'] = max(0, c['health'] - age_decay - elder_decay)

        # 健康度自然回復（30-45歳, v1.2 NEW）
        if 30 <= c['age'] <= 45 and month % 2 == 0:
            c['health'] = min(100, c['health'] + 1)

        # ピーク追跡
        for k in peak:
            if c[k] > peak[k]:
                peak[k] = c[k]

        # 死亡判定
        if c['health'] <= 0:
            death_cause = '病死'
            break

        lifespan = expected_lifespan(c)
        ratio = c['age'] / lifespan
        year_mortal = 0.005
        if ratio >= 1.3: year_mortal = 0.9
        elif ratio >= 1.2: year_mortal = 0.7
        elif ratio >= 1.1: year_mortal = 0.4
        elif ratio >= 1.0: year_mortal = 0.2
        elif ratio >= 0.8: year_mortal = 0.05
        elif ratio >= 0.6: year_mortal = 0.01

        month_mortal = 1 - (1 - year_mortal) ** (1 / 12)
        if rng.random() < month_mortal:
            death_cause = '寿命' if ratio >= 1.0 else '老衰'
            break

        # 月+1
        c['age'] = (month + 1) // 12

    return {
        'char_id': f'sim_{index}',
        'era': era,
        'strength': strength,
        'gender': gender,
        'final_age': c['age'],
        'final_health': c['health'],
        'final_asset': c['asset'],
        'final_happiness': c['happiness'],
        'final_humanity': c['humanity'],
        'peak_brain': peak['brain'],
        'peak_body': peak['body'],
        'peak_social': peak['social'],
        'peak_sense': peak['sense'],
        'peak_luck': peak['luck'],
        'death_cause': death_cause,
        'reached_age_80': 1 if c['age'] >= 80 else 0,
        'events_fired': events_fired,
    }


def main():
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
    out_csv = sys.argv[2] if len(sys.argv) > 2 else 'sim_predict.csv'

    rng = random.Random(42)
    events = []
    if EVENTS_JSON.exists():
        with open(EVENTS_JSON, 'r', encoding='utf-8') as f:
            data = json.load(f)
        events = data.get('events', [])
        print(f'Loaded {len(events)} events')
    else:
        print('events.json なし、イベント発火0で実行')

    print(f'Predicting v3 for {count} chars (v1.2 GameEngine)...')
    results = []
    for i in range(count):
        era = rng.choice(ERAS)
        strength = rng.choice(STRENGTHS)
        gender = rng.choice(['男', '女'])
        results.append(run_one(i, era, strength, gender, events, rng))

    # CSV
    with open(out_csv, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=results[0].keys())
        writer.writeheader()
        writer.writerows(results)
    print(f'CSV: {out_csv}')

    # サマリー
    total = len(results)
    reached80 = sum(1 for r in results if r['reached_age_80'])
    avg_age = sum(r['final_age'] for r in results) / total
    causes = Counter(r['death_cause'] for r in results)
    avg_events = sum(r['events_fired'] for r in results) / total

    print()
    print('=== Summary ===')
    print(f'Total: {total}')
    print(f'Reached 80: {reached80} ({100*reached80/total:.1f}%)')
    print(f'Avg lifespan: {avg_age:.1f}')
    print(f'Avg events fired: {avg_events:.1f}')
    print(f'Death causes:')
    for c, n in causes.most_common():
        print(f'  {c}: {n} ({100*n/total:.1f}%)')

    print()
    print('Avg lifespan by era:')
    for era in ERAS:
        rs = [r for r in results if r['era'] == era]
        if rs:
            print(f'  {era}: {sum(r["final_age"] for r in rs) / len(rs):.1f}')

    print()
    print('Avg lifespan by strength:')
    for st in STRENGTHS:
        rs = [r for r in results if r['strength'] == st]
        if rs:
            print(f'  {st}: {sum(r["final_age"] for r in rs) / len(rs):.1f}')

    # 80歳到達 強み別
    print()
    print('80歳到達 強み別:')
    s_cnt = Counter(r['strength'] for r in results if r['reached_age_80'])
    s_total = Counter(r['strength'] for r in results)
    for st in STRENGTHS:
        n = s_cnt.get(st, 0)
        d = s_total.get(st, 1)
        print(f'  {st}: {n}/{d} ({100*n/d:.1f}%)')

    # 運の天井
    print()
    print('運の peak:')
    luck_vals = [r['peak_luck'] for r in results]
    print(f'  min={min(luck_vals)} max={max(luck_vals)} avg={sum(luck_vals)/len(luck_vals):.1f}')


if __name__ == '__main__':
    main()
