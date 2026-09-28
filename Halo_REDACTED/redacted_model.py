"""REDACTED program model, v2.

Extends the draft's Appendix A revenue model with:
  1. live costs for years 2-5, set by the five-mode ladder;
  2. server cost that scales with the active population;
  3. development and marketing costs compounded forward to launch;
  4. Steam's tiered fee computed per case, and two views of the Xbox store fee;
  5. Game Pass entry after year one (Xbox copy cannibalization, Game Pass players);
  6. a reference-class expected value and the preproduction option condition.

All money in $M. Launch-dated: year 1 of live is undiscounted, year t is
discounted by (1+r)^(t-1), matching the draft's PV convention; costs incurred
before launch are compounded forward to the launch date at the same rate.
"""
from dataclasses import dataclass, replace

R = 0.10                       # discount rate
SHARE = [.55, .20, .12, .08, .05]  # share of lifetime copies sold in year t
PRICE = 35.0                   # realized gross price per copy (Helldivers 2)
MIX = {"steam": .50, "ps": .25, "xbox": .25}
DECAY = 0.30                   # annual decline in spend and engagement per owner
EXP_PRICE = 20.0

# ---- Core-scale costs (nominal, from the draft) ----
PREPROD = [(0, 6, 7.0), (6, 12, 11.0), (12, 18, 16.0)]   # tranches (start, end month, $M)
PRODUCTION = (18, 48, 161.0)
MARKETING = [(24, 36, .15), (36, 48, .35), (48, 60, .50)]  # share of $117M by window
MARKETING_TOTAL = 117.0
REUSE_CREDIT = 29.0
LAUNCH_MONTH = 48

# ---- Live operations ----
# Draft: C_live = $51M in year one = 180-person team + $18M servers -> $33M team.
TEAM_COST_PER_HEAD = 33.0 / 180            # $0.183M per live head
MODE_HEADS = {1: 180, 2: 130, 3: 90, 4: 45, 5: 8}
MODE_EXPANSIONS = {1: True, 2: True, 3: True, 4: True, 5: False}
# server cost per active owner by mode: merged fronts and fewer shards cut overhead;
# the archive runs on player-hosted custom servers plus a thin matchmaking layer
MODE_SERVER_FACTOR = {1: 1.00, 2: 0.90, 3: 0.80, 4: 0.60, 5: 0.20}
SERVER_BASE = 18.0                         # $M at Base-case year-one activity
BASE_ACTIVE_Y1 = 8.0 * SHARE[0]            # 4.4M active owners


@dataclass
class Case:
    name: str
    copies: float        # lifetime copies, millions
    spend: float         # gross in-game spend per owner, year one ($)
    attach: float        # expansion attach rate
    xbox_fee: float = 0.0      # 0.0 = consolidated Microsoft view; 0.30 = Activision view
    game_pass: bool = False
    gp_cannibal: float = 0.50  # share of year-2+ Xbox copy sales lost to Game Pass
    gp_players: float = 1.00   # Game Pass players joining in year 2, per Xbox year-one copy
    gp_engage: float = 0.50    # Game Pass player spend and attach, relative to an owner
    ladder: bool = True        # False = Mode 1 for all five years
    dev_extra: float = 0.0     # nominal development added (e.g. agent savings not realized)


def steam_fee(gross):
    """Valve's tiered share on an app's lifetime Steam gross ($M)."""
    return (.30 * min(gross, 10) + .25 * max(0, min(gross, 50) - 10)
            + .20 * max(0, gross - 50)) / gross if gross > 0 else .30


def team(mode):
    return MODE_HEADS[mode] * TEAM_COST_PER_HEAD


def compound(m):
    """Compound a cost at month m (from approval) forward to launch."""
    return (1 + R) ** ((LAUNCH_MONTH - m) / 12)


def spread(start, end, amount):
    """Launch-dated value of an amount spread evenly across months [start, end)."""
    months = end - start
    out = 0.0
    for m in range(start, end):
        mid = m + 0.5
        if mid < LAUNCH_MONTH:
            out += amount / months * compound(mid)
        else:  # post-launch: inside live year 1 (undiscounted) or later
            out += amount / months / (1 + R) ** int((mid - LAUNCH_MONTH) // 12)
    return out


def build_costs(c: Case):
    dev_extra = c.dev_extra
    mkt_total = MARKETING_TOTAL + 0.60 * dev_extra
    nominal = {
        "Preproduction": sum(a for _, _, a in PREPROD),
        "Production": PRODUCTION[2] + dev_extra,
        "Marketing": mkt_total,
    }
    dated = {
        "Preproduction": sum(spread(s, e, a) for s, e, a in PREPROD),
        "Production": spread(PRODUCTION[0], PRODUCTION[1], PRODUCTION[2] + dev_extra),
        "Marketing": sum(spread(s, e, w * mkt_total) for s, e, w in MARKETING),
    }
    return nominal, dated


def run(c: Case):
    # copies by platform and year, after Game Pass cannibalization
    years = range(1, 6)
    copies = []
    for t in years:
        base = SHARE[t - 1] * c.copies
        x = base * MIX["xbox"]
        if c.game_pass and t >= 2:
            x *= (1 - c.gp_cannibal)
        copies.append({"steam": base * MIX["steam"], "ps": base * MIX["ps"], "xbox": x})

    gp = [0.0] * 5
    if c.game_pass:
        for t in range(1, 5):  # join in year 2, stay in the population
            gp[t] = c.gp_players * copies[0]["xbox"]  # constant pool from year 2

    # first pass: gross revenue to size Steam's tier
    owners, eff = [], []
    cum = 0.0
    for t in years:
        cum += sum(copies[t - 1].values())
        owners.append(cum)
        eff.append(cum + c.gp_engage * gp[t - 1])
    steam_share_rev = MIX["steam"]
    steam_gross = (sum(cp["steam"] for cp in copies) * PRICE
                   + sum(eff[t - 1] * c.spend * (1 - DECAY) ** (t - 1) for t in years) * steam_share_rev
                   + sum(eff[t - 1] * c.attach * EXP_PRICE for t in years if t >= 2) * steam_share_rev)
    fs = steam_fee(steam_gross)
    fee = {"steam": fs, "ps": .30, "xbox": c.xbox_fee}
    blended = sum(MIX[p] * fee[p] for p in MIX)
    f = 1 - blended

    rows, pv_rev, pv_live = [], 0.0, 0.0
    for t in years:
        disc = (1 + R) ** (t - 1)
        copy_rev = sum(copies[t - 1][p] * PRICE * (1 - fee[p]) for p in MIX)
        e = eff[t - 1]
        active = e * (1 - DECAY) ** (t - 1)
        servers_full = SERVER_BASE * active / BASE_ACTIVE_Y1

        def cost(mode):
            return team(mode) + servers_full * MODE_SERVER_FACTOR[mode]
        spend_rev = e * c.spend * (1 - DECAY) ** (t - 1) * f

        def live_rev(mode):
            exp = e * c.attach * EXP_PRICE * f if (t >= 2 and MODE_EXPANSIONS[mode]) else 0.0
            return spend_rev + exp

        if t == 1 or not c.ladder:
            mode = 1
        else:
            mode = 5
            for m in (1, 2, 3, 4):
                if cost(m) <= live_rev(m):
                    mode = m
                    break
        lr = live_rev(mode)
        lc = cost(mode)
        rows.append(dict(t=t, owners=owners[t - 1], gp=gp[t - 1], active=active, mode=mode,
                         copy_rev=copy_rev, live_rev=lr, live_cost=lc,
                         breakeven_owners=lc / ((c.spend * (1 - DECAY) ** (t - 1) * f)
                                                + (c.attach * EXP_PRICE * f if t >= 2 else 0)) ))
        pv_rev += (copy_rev + lr) / disc
        pv_live += lc / disc

    nominal, dated = build_costs(c)
    pv_build = sum(dated.values())
    pv_cost = pv_build + pv_live
    npv = pv_rev - pv_cost + REUSE_CREDIT
    return dict(case=c, rows=rows, f=f, steam_fee=fs, pv_rev=pv_rev, pv_live=pv_live,
                nominal=nominal, dated=dated, pv_build=pv_build, pv_cost=pv_cost,
                attributed=pv_cost - REUSE_CREDIT, npv=npv,
                multiple=pv_rev / (pv_cost - REUSE_CREDIT))


def draft_pv(copies, spend, attach):
    """The draft's Appendix A formula, unchanged, for reconciliation."""
    n, f = 28.60, .82
    o, tot = 0.0, 0.0
    for t in range(1, 6):
        o += SHARE[t - 1] * copies
        v = SHARE[t - 1] * copies * n + o * spend * (1 - DECAY) ** (t - 1) * f
        v += o * attach * EXP_PRICE * f if t >= 2 else 0
        tot += v / (1 + R) ** (t - 1)
    return tot


def solve_copies(template: Case, target_multiple):
    lo, hi = 0.5, 80.0
    for _ in range(80):
        mid = (lo + hi) / 2
        r = run(replace(template, copies=mid))
        if r["multiple"] < target_multiple:
            lo = mid
        else:
            hi = mid
    return hi


CASES = {
    "Failure":   Case("Failure", 1.0, 3.0, 0.05),
    "Downside":  Case("Downside", 3.0, 4.0, 0.10),
    "Base":      Case("Base", 8.0, 8.0, 0.20),
    "Breakout":  Case("Breakout", 15.4, 15.0, 0.30),   # mean of HD2, ARC Raiders, DRG
    "Target":    Case("Target", 20.0, 15.0, 0.30),
}

# Reference classes from Appendix C
REF_ALL = {"Failure": 8 / 14, "Downside": 2 / 14, "Base": 1 / 14, "Breakout": 3 / 14}
# Titles matching the draft's winners' pattern: squad-built, $30-60, one core loop
# (Helldivers 2, ARC Raiders, Deep Rock Galactic, Space Marine 2, Remnant 2, Marathon, Payday 3)
REF_PATTERN = {"Failure": 1 / 7, "Downside": 2 / 7, "Base": 1 / 7, "Breakout": 3 / 7}


def m(x):
    return f"{x:,.0f}"


def report():
    out = []
    P = out.append

    P("## Reconciliation with the draft's Appendix A\n")
    P("| Case | Draft PV ($M) | Draft PV per copy ($) |")
    P("| --- | --- | --- |")
    for k in ("Downside", "Base", "Target"):
        c = CASES[k]
        d = draft_pv(c.copies, c.spend, c.attach)
        P(f"| {k} | {m(d)} | {d / c.copies:.2f} |")

    P("\n## Program cost, Core scale, Base case, consolidated view, mode ladder\n")
    r = run(replace(CASES["Base"], game_pass=True))
    P("| $ millions | Nominal | Dated to launch at 10% |")
    P("| --- | --- | --- |")
    for k in ("Preproduction", "Production", "Marketing"):
        P(f"| {k} | {m(r['nominal'][k])} | {m(r['dated'][k])} |")
    P(f"| Build and launch subtotal | {m(sum(r['nominal'].values()))} | {m(r['pv_build'])} |")
    nom_live = sum(x['live_cost'] for x in r['rows'])
    P(f"| Live operations, years 1-5 | {m(nom_live)} | {m(r['pv_live'])} |")
    P(f"| Franchise reuse credit | -{m(REUSE_CREDIT)} | -{m(REUSE_CREDIT)} |")
    P(f"| Program cost attributed to REDACTED | {m(sum(r['nominal'].values()) + nom_live - REUSE_CREDIT)} | {m(r['attributed'])} |")

    for view, xf in (("consolidated Microsoft view (Xbox store fee 0%)", 0.0),
                     ("Activision view (Xbox store fee 30%)", 0.30)):
        P(f"\n## Returns by case, {view}, Game Pass after year one, mode ladder\n")
        P("| Case | Copies | Steam fee | Net share f | Net per copy | PV revenue | PV program cost | NPV | Multiple |")
        P("| --- | --- | --- | --- | --- | --- | --- | --- | --- |")
        for k, c in CASES.items():
            rr = run(replace(c, xbox_fee=xf, game_pass=True))
            npc = PRICE * rr["f"]
            P(f"| {k} | {c.copies:g}M | {rr['steam_fee']:.1%} | {rr['f']:.3f} | ${npc:.2f} | {m(rr['pv_rev'])} | "
              f"{m(rr['attributed'])} | {m(rr['npv'])} | {rr['multiple']:.2f}x |")

    P("\n## Live operations by year, Base case, consolidated, Game Pass, ladder\n")
    P("| Year | Owners (M) | Game Pass players (M) | Active (M) | Mode | Live revenue | Live cost | Break-even owners (M) |")
    P("| --- | --- | --- | --- | --- | --- | --- | --- |")
    for x in r["rows"]:
        P(f"| {x['t']} | {x['owners']:.2f} | {x['gp']:.2f} | {x['active']:.2f} | {x['mode']} | {m(x['live_rev'])} | {m(x['live_cost'])} | {x['breakeven_owners']:.2f} |")

    P("\n## Mode by year across cases (consolidated, Game Pass, ladder)\n")
    P("| Case | Y1 | Y2 | Y3 | Y4 | Y5 | PV live cost | PV live cost, Mode 1 fixed |")
    P("| --- | --- | --- | --- | --- | --- | --- | --- |")
    for k, c in CASES.items():
        a = run(replace(c, game_pass=True))
        b = run(replace(c, game_pass=True, ladder=False))
        P(f"| {k} | " + " | ".join(str(x['mode']) for x in a['rows']) + f" | {m(a['pv_live'])} | {m(b['pv_live'])} |")

    P("\n## Sensitivities, Base case, consolidated\n")
    P("| Variant | PV revenue | PV program cost | NPV | Multiple |")
    P("| --- | --- | --- | --- | --- |")
    variants = [
        ("As modeled (Game Pass, ladder)", replace(CASES["Base"], game_pass=True)),
        ("No Game Pass", CASES["Base"]),
        ("Mode 1 held all five years", replace(CASES["Base"], game_pass=True, ladder=False)),
        ("Agent savings not realized (+$12M dev, +$7M marketing)", replace(CASES["Base"], game_pass=True, dev_extra=12.0)),
        ("Activision view (Xbox fee 30%)", replace(CASES["Base"], game_pass=True, xbox_fee=0.30)),
    ]
    for label, c in variants:
        rr = run(c)
        P(f"| {label} | {m(rr['pv_rev'])} | {m(rr['attributed'])} | {m(rr['npv'])} | {rr['multiple']:.2f}x |")

    P("\n## Copies needed (Base-case spend and attach, consolidated, Game Pass, ladder)\n")
    P("| Threshold | Draft | v2 consolidated | v2 Activision view |")
    P("| --- | --- | --- | --- |")
    base = replace(CASES["Base"], game_pass=True)
    act = replace(base, xbox_fee=0.30)
    P(f"| Payback (1.0x) | 7.1M | {solve_copies(base, 1.0):.1f}M | {solve_copies(act, 1.0):.1f}M |")
    P(f"| 1.5x return | 10.6M | {solve_copies(base, 1.5):.1f}M | {solve_copies(act, 1.5):.1f}M |")
    tgt = replace(CASES["Target"], game_pass=True)
    P(f"| Payback at Target-case spend and attach | - | {solve_copies(tgt, 1.0):.1f}M | {solve_copies(replace(tgt, xbox_fee=.3), 1.0):.1f}M |")
    P(f"| 1.5x at Target-case spend and attach | - | {solve_copies(tgt, 1.5):.1f}M | {solve_copies(replace(tgt, xbox_fee=.3), 1.5):.1f}M |")

    P("\n## Reference-class expected value (consolidated, Game Pass, ladder)\n")
    npv = {k: run(replace(c, game_pass=True))["npv"] for k, c in CASES.items()}
    pre_dated = run(replace(CASES["Base"], game_pass=True))["dated"]["Preproduction"]
    for label, ref in (("All 14 comparables", REF_ALL), ("7 titles on the winners' pattern", REF_PATTERN)):
        ev = sum(p * npv[k] for k, p in ref.items())
        # production-stage NPV excludes preproduction, which is sunk at Gate 3
        ev_prod = sum(p * (npv[k] + pre_dated) for k, p in ref.items())
        P(f"- **{label}:** " + ", ".join(f"{k} {p:.0%}" for k, p in ref.items())
          + f" -> E[NPV] = ${m(ev)}M; E[NPV of production | Gate 3] = ${m(ev_prod)}M.")
    P("\n## Preproduction option: required gate quality\n")
    P("Good = Breakout; bad = every other case. eta = P(pass Gate 3 | good), eps = P(pass Gate 3 | bad).\n")
    P("| Reference class | P(good) | E[production NPV / good] | E[production NPV / bad] | Max eps at eta = 0.8 | Max eps at eta = 0.6 |")
    P("| --- | --- | --- | --- | --- | --- |")
    for label, ref in (("All 14 comparables", REF_ALL), ("Winners' pattern (7)", REF_PATTERN)):
        pg = ref["Breakout"]
        g = npv["Breakout"] + pre_dated
        bad = {k: p for k, p in ref.items() if k != "Breakout"}
        pb = sum(bad.values())
        b = sum(p * (npv[k] + pre_dated) for k, p in bad.items()) / pb
        cells = []
        for eta in (0.8, 0.6):
            eps = (pg * eta * g - pre_dated) / (pb * -b)
            cells.append(f"{max(0, min(1, eps)):.2f}")
        P(f"| {label} | {pg:.2f} | {m(g)} | {m(b)} | " + " | ".join(cells) + " |")
    P(f"\nCase NPVs used: " + ", ".join(f"{k} ${m(v)}M" for k, v in npv.items())
      + f". Preproduction dated to launch: ${m(pre_dated)}M.")
    P("\n## Copies needed to pay back, by year-one spend per owner and attach rate (consolidated, Game Pass, ladder)\n")
    atts = (0.10, 0.20, 0.30)
    P("| Spend per owner, year one | " + " | ".join(f"Attach {a:.0%}" for a in atts) + " |")
    P("| --- | --- | --- | --- |")
    for sp in (4, 8, 12, 15, 20):
        P(f"| ${sp} | " + " | ".join(f"{solve_copies(Case('g', 8, sp, a, game_pass=True), 1.0):.1f}M" for a in atts) + " |")
    return "\n".join(out)


if __name__ == "__main__":
    print(report())
