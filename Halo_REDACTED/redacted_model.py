"""REDACTED program model.

Revenue: copies, in-game spend and paid theater expansions over five live years.
Cost: preproduction, production and marketing compounded forward to launch, plus
five years of live operations run on the five-mode ladder, less the franchise
reuse credit. Two launch editions share the model:

  Battlefront  $50  Strike Ops and 64-player Battlefronts with the Halo vehicle roster
  Theater      $60  adds one Grand Theater region (hundreds of players, ground to orbit)

All money in $M, dated to launch: live year 1 is undiscounted, year t is
discounted by (1+r)^(t-1); costs before launch are compounded forward at r.
"""
from dataclasses import dataclass, replace

R = 0.10                           # discount rate
SHARE = [.55, .20, .12, .08, .05]  # share of lifetime copies sold in year t
REALIZED = 35.0 / 40.0             # realized / list price (Helldivers 2: ~$35 on $40)
MIX = {"steam": .50, "ps": .25, "xbox": .25}
DECAY = 0.30                       # annual decline in spend and engagement per owner
EXP_PRICE = 20.0

# ---- Cost method ----
AGENT_SAVING = 0.058               # conservative agent-assisted scenario
PREPROD = [(0, 6, 7.0), (6, 12, 11.0), (12, 18, 16.0)]      # tranches (start, end month, $M)
PROD_WINDOW = (18, 48)
MARKETING_SHARE = 0.60             # of development
MARKETING = [(24, 36, .15), (36, 48, .35), (48, 60, .50)]    # share of marketing by window
REUSE_SHARE = 0.15                 # of development
LAUNCH_MONTH = 48

# ---- Live operations ----
TEAM_COST_PER_HEAD = 33.0 / 180    # $M per live head-year ($33M for 180 people)
MODE_EXPANSIONS = {1: True, 2: True, 3: True, 4: True, 5: False}
# share of full-war in-game spend and expansion attach each mode retains: fewer
# live fronts and slower content hold fewer players' attention and wallets
MODE_REVENUE_FACTOR = {1: 1.00, 2: 0.92, 3: 0.80, 4: 0.60, 5: 0.30}
# server cost per active owner by mode: merged fronts and fewer shards cut overhead;
# the archive runs on player-hosted custom servers plus a thin matchmaking layer
MODE_SERVER_FACTOR = {1: 1.00, 2: 0.90, 3: 0.80, 4: 0.60, 5: 0.20}
SERVER_RATE = 18.0 / (8.0 * SHARE[0])   # $M per million active owner-years, Theater edition


@dataclass(frozen=True)
class Edition:
    name: str
    list_price: float
    production_heads: int          # average over the 30-month production
    production_cost: float         # nominal $M, from the budget model
    mode_heads: tuple              # live team by mode 1..5
    server_scale: float            # server cost per active owner, relative to Theater

    def production(self):
        return self.production_cost


THEATER = Edition("Theater", 60.0, 260, 161.0, (180, 130, 90, 45, 8), 1.00)
# Battlefront drops the Grand Theater technology and region team (about 40 production
# heads, cost pro rata by headcount), 20 live heads, and a quarter of server cost
BATTLEFRONT = Edition("Battlefront", 50.0, 220, 161.0 * 220 / 260, (160, 115, 80, 40, 8), 0.75)


@dataclass
class Case:
    name: str
    copies: float              # lifetime copies, millions
    spend: float               # gross in-game spend per owner, year one ($)
    attach: float              # expansion attach rate
    edition: Edition = THEATER
    xbox_fee: float = 0.0      # 0.0 = consolidated Microsoft view; 0.30 = Activision view
    game_pass: bool = True
    gp_cannibal: float = 0.50  # share of year-2+ Xbox copy sales lost to Game Pass
    gp_players: float = 1.00   # Game Pass players joining in year 2, per Xbox year-one copy
    gp_engage: float = 0.50    # Game Pass player spend and attach, relative to an owner
    ladder: bool = True        # False = Mode 1 for all five years
    dev_extra: float = 0.0     # nominal development added (e.g. agent savings not realized)


def steam_fee(gross):
    """Valve's tiered share on an app's lifetime Steam gross ($M)."""
    return (.30 * min(gross, 10) + .25 * max(0, min(gross, 50) - 10)
            + .20 * max(0, gross - 50)) / gross if gross > 0 else .30


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
        else:
            out += amount / months / (1 + R) ** int((mid - LAUNCH_MONTH) // 12)
    return out


def build_costs(c: Case):
    e = c.edition
    preprod = sum(a for _, _, a in PREPROD)
    production = e.production() + c.dev_extra
    development = preprod + production
    marketing = MARKETING_SHARE * development
    nominal = {"Preproduction": preprod, "Production": production, "Marketing": marketing}
    dated = {
        "Preproduction": sum(spread(s, t, a) for s, t, a in PREPROD),
        "Production": spread(*PROD_WINDOW, production),
        "Marketing": sum(spread(s, t, w * marketing) for s, t, w in MARKETING),
    }
    return nominal, dated, REUSE_SHARE * development


def run(c: Case):
    e = c.edition
    price = e.list_price * REALIZED
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
        for t in range(1, 5):          # Game Pass players join in year 2 and stay
            gp[t] = c.gp_players * copies[0]["xbox"]

    owners, eff, cum = [], [], 0.0
    for t in years:
        cum += sum(copies[t - 1].values())
        owners.append(cum)
        eff.append(cum + c.gp_engage * gp[t - 1])

    steam_gross = (sum(cp["steam"] for cp in copies) * price
                   + MIX["steam"] * sum(eff[t - 1] * c.spend * (1 - DECAY) ** (t - 1) for t in years)
                   + MIX["steam"] * sum(eff[t - 1] * c.attach * EXP_PRICE for t in years if t >= 2))
    fee = {"steam": steam_fee(steam_gross), "ps": .30, "xbox": c.xbox_fee}
    f = 1 - sum(MIX[p] * fee[p] for p in MIX)

    def team(mode):
        return e.mode_heads[mode - 1] * TEAM_COST_PER_HEAD

    rows, pv_rev, pv_live = [], 0.0, 0.0
    for t in years:
        disc = (1 + R) ** (t - 1)
        copy_rev = sum(copies[t - 1][p] * price * (1 - fee[p]) for p in MIX)
        n = eff[t - 1]
        active = n * (1 - DECAY) ** (t - 1)
        servers_full = SERVER_RATE * e.server_scale * active
        spend_rev = n * c.spend * (1 - DECAY) ** (t - 1) * f

        def live_rev(mode):
            exp = n * c.attach * EXP_PRICE * f if (t >= 2 and MODE_EXPANSIONS[mode]) else 0.0
            return (spend_rev + exp) * MODE_REVENUE_FACTOR[mode]

        def cost(mode):
            return team(mode) + servers_full * MODE_SERVER_FACTOR[mode]

        if t == 1 or not c.ladder:
            mode = 1
        else:
            # run the mode with the best live margin; ties go to the fuller war
            mode = max((1, 2, 3, 4, 5), key=lambda m: (live_rev(m) - cost(m), -m))
        lr, lc = live_rev(mode), cost(mode)
        per_owner = (c.spend * (1 - DECAY) ** (t - 1) * f
                     + (c.attach * EXP_PRICE * f if (t >= 2 and MODE_EXPANSIONS[mode]) else 0)) * MODE_REVENUE_FACTOR[mode]
        rows.append(dict(t=t, owners=owners[t - 1], gp=gp[t - 1], active=active, mode=mode,
                         copy_rev=copy_rev, live_rev=lr, live_cost=lc, breakeven_owners=lc / per_owner))
        pv_rev += (copy_rev + lr) / disc
        pv_live += lc / disc

    nominal, dated, reuse = build_costs(c)
    pv_build = sum(dated.values())
    attributed = pv_build + pv_live - reuse
    return dict(case=c, rows=rows, f=f, steam_fee=fee["steam"], net_per_copy=price * (1 - sum(MIX[p] * fee[p] for p in MIX)),
                pv_rev=pv_rev, pv_live=pv_live, nominal=nominal, dated=dated, reuse=reuse,
                pv_build=pv_build, attributed=attributed, npv=pv_rev - attributed,
                multiple=pv_rev / attributed)


def solve_copies(template: Case, target_multiple):
    lo, hi = 0.3, 80.0
    for _ in range(80):
        mid = (lo + hi) / 2
        if run(replace(template, copies=mid))["multiple"] < target_multiple:
            lo = mid
        else:
            hi = mid
    return hi


CASES = {
    "Failure":  Case("Failure", 1.0, 3.0, 0.05),
    "Downside": Case("Downside", 3.0, 4.0, 0.10),
    "Base":     Case("Base", 8.0, 8.0, 0.20),
    "Breakout": Case("Breakout", 15.4, 15.0, 0.30),   # mean of Helldivers 2, ARC Raiders, DRG
    "Target":   Case("Target", 20.0, 15.0, 0.30),
}

# Reference classes from Appendix C
REF_ALL = {"Failure": 8 / 14, "Downside": 2 / 14, "Base": 1 / 14, "Breakout": 3 / 14}
REF_PATTERN = {"Failure": 1 / 7, "Downside": 2 / 7, "Base": 1 / 7, "Breakout": 3 / 7}

EDITIONS = (BATTLEFRONT, THEATER)


def m(x):
    return f"{x:,.0f}"


def report():
    out = []
    P = out.append

    P("## Budget by edition (nominal, $M)\n")
    P("| | Battlefront ($50) | Theater ($60) |")
    P("| --- | --- | --- |")
    rs = {e.name: run(replace(CASES["Base"], edition=e)) for e in EDITIONS}
    for k in ("Preproduction", "Production", "Marketing"):
        P(f"| {k} | " + " | ".join(m(rs[e.name]['nominal'][k]) for e in EDITIONS) + " |")
    P("| Development through launch | " + " | ".join(m(rs[e.name]['nominal']['Preproduction'] + rs[e.name]['nominal']['Production']) for e in EDITIONS) + " |")
    P("| First live year, Base case | " + " | ".join(m(rs[e.name]['rows'][0]['live_cost']) for e in EDITIONS) + " |")
    P("| Launch plus first live year | " + " | ".join(m(sum(rs[e.name]['nominal'].values()) + rs[e.name]['rows'][0]['live_cost']) for e in EDITIONS) + " |")
    P("| Franchise reuse credit | " + " | ".join(f"-{m(rs[e.name]['reuse'])}" for e in EDITIONS) + " |")

    P("\n## Program cost, Base case, dated to launch ($M)\n")
    P("| | Battlefront nominal | Battlefront dated | Theater nominal | Theater dated |")
    P("| --- | --- | --- | --- | --- |")
    for k in ("Preproduction", "Production", "Marketing"):
        P(f"| {k} | " + " | ".join(f"{m(rs[e.name]['nominal'][k])} | {m(rs[e.name]['dated'][k])}" for e in EDITIONS) + " |")
    P("| Live operations, years 1-5 | " + " | ".join(f"{m(sum(x['live_cost'] for x in rs[e.name]['rows']))} | {m(rs[e.name]['pv_live'])}" for e in EDITIONS) + " |")
    P("| Franchise reuse credit | " + " | ".join(f"-{m(rs[e.name]['reuse'])} | -{m(rs[e.name]['reuse'])}" for e in EDITIONS) + " |")
    P("| Program cost | " + " | ".join(f"{m(sum(rs[e.name]['nominal'].values()) + sum(x['live_cost'] for x in rs[e.name]['rows']) - rs[e.name]['reuse'])} | {m(rs[e.name]['attributed'])}" for e in EDITIONS) + " |")

    for view, xf in (("Microsoft view (Xbox store fee 0%)", 0.0), ("Activision view (Xbox store fee 30%)", 0.30)):
        P(f"\n## Returns by case, {view}\n")
        P("| Case | Copies | Edition | Net per copy | PV revenue | Program cost | NPV | Multiple |")
        P("| --- | --- | --- | --- | --- | --- | --- | --- |")
        for k, c in CASES.items():
            for e in EDITIONS:
                r = run(replace(c, edition=e, xbox_fee=xf))
                P(f"| {k} | {c.copies:g}M | {e.name} | ${r['net_per_copy']:.2f} | {m(r['pv_rev'])} | {m(r['attributed'])} | {m(r['npv'])} | {r['multiple']:.2f}x |")

    for e in EDITIONS:
        r = run(replace(CASES["Base"], edition=e))
        P(f"\n## Live operations by year, Base case, {e.name} edition\n")
        P("| Year | Owners (M) | Game Pass players (M) | Active (M) | Mode | Live revenue | Live cost | Break-even owners (M) |")
        P("| --- | --- | --- | --- | --- | --- | --- | --- |")
        for x in r["rows"]:
            P(f"| {x['t']} | {x['owners']:.2f} | {x['gp']:.2f} | {x['active']:.2f} | {x['mode']} | {m(x['live_rev'])} | {m(x['live_cost'])} | {x['breakeven_owners']:.2f} |")

    P("\n## Mode by year and live cost (PV, $M)\n")
    P("| Case | Edition | Y1 | Y2 | Y3 | Y4 | Y5 | PV live cost | PV live cost, Mode 1 held |")
    P("| --- | --- | --- | --- | --- | --- | --- | --- | --- |")
    for k, c in CASES.items():
        for e in EDITIONS:
            a = run(replace(c, edition=e))
            b = run(replace(c, edition=e, ladder=False))
            P(f"| {k} | {e.name} | " + " | ".join(str(x['mode']) for x in a['rows']) + f" | {m(a['pv_live'])} | {m(b['pv_live'])} |")

    P("\n## Sensitivities, Base case (NPV $M / multiple)\n")
    P("| Variant | Battlefront | Theater |")
    P("| --- | --- | --- |")
    variants = [
        ("As modeled", {}),
        ("No Game Pass", {"game_pass": False}),
        ("Mode 1 held all five years", {"ladder": False}),
        ("Agent savings not realized", {"dev_extra": None}),
        ("Activision view (Xbox fee 30%)", {"xbox_fee": 0.30}),
    ]
    for label, kw in variants:
        cells = []
        for e in EDITIONS:
            kw2 = dict(kw)
            if "dev_extra" in kw2:
                kw2["dev_extra"] = e.production() * AGENT_SAVING / (1 - AGENT_SAVING) + 34 * AGENT_SAVING
            r = run(replace(CASES["Base"], edition=e, **kw2))
            cells.append(f"{m(r['npv'])} / {r['multiple']:.2f}x")
        P(f"| {label} | " + " | ".join(cells) + " |")

    P("\n## Copies needed\n")
    P("| Threshold | Spend | Battlefront, Microsoft | Theater, Microsoft | Battlefront, Activision | Theater, Activision |")
    P("| --- | --- | --- | --- | --- | --- |")
    for mult in (1.0, 1.5):
        for label, c in (("Base", CASES["Base"]), ("Target", CASES["Target"])):
            cells = [f"{solve_copies(replace(c, edition=e, xbox_fee=xf), mult):.1f}M" for xf in (0.0, 0.30) for e in EDITIONS]
            P(f"| {mult:.1f}x | {label} | " + " | ".join(cells) + " |")

    P("\n## Copies needed to pay back, by spend per owner and attach (Microsoft view)\n")
    atts = (0.10, 0.20, 0.30)
    for e in EDITIONS:
        P(f"\n{e.name} edition\n")
        P("| Spend per owner, year one | " + " | ".join(f"Attach {a:.0%}" for a in atts) + " |")
        P("| --- | --- | --- | --- |")
        for sp in (4, 8, 12, 15, 20):
            P(f"| ${sp} | " + " | ".join(f"{solve_copies(Case('g', 8, sp, a, edition=e), 1.0):.1f}M" for a in atts) + " |")

    P("\n## Price indifference (Base spend and attach, Microsoft view)\n")
    P("Copies the higher price can sell and still match the NPV of the lower price at the stated copies.\n")
    P("| Comparison | At 8M copies | At 15.4M copies | Copy loss the higher price can absorb |")
    P("| --- | --- | --- | --- |")
    bf40 = replace(BATTLEFRONT, name="Battlefront at $40", list_price=40.0)
    pairs = (("$50 Battlefront vs $40 Battlefront", bf40, BATTLEFRONT),
             ("$60 Theater vs $50 Battlefront", BATTLEFRONT, THEATER))
    for label, lo_e, hi_e in pairs:
        cells = []
        for n0 in (8.0, 15.4):
            target = run(replace(CASES["Base"], copies=n0, edition=lo_e))["npv"]
            a, b = 0.3, n0
            for _ in range(80):
                mid = (a + b) / 2
                if run(replace(CASES["Base"], copies=mid, edition=hi_e))["npv"] < target:
                    a = mid
                else:
                    b = mid
            cells.append((b, 1 - b / n0))
        P(f"| {label} | {cells[0][0]:.1f}M | {cells[1][0]:.1f}M | {cells[0][1]:.0%} / {cells[1][1]:.0%} |")

    P("\n## Reference-class expected value and the preproduction option (Microsoft view)\n")
    for e in EDITIONS:
        npv = {k: run(replace(c, edition=e))["npv"] for k, c in CASES.items()}
        pre = run(replace(CASES["Base"], edition=e))["dated"]["Preproduction"]
        P(f"\n{e.name} edition. Case NPVs: " + ", ".join(f"{k} {m(v)}" for k, v in npv.items()) + f". Preproduction dated: {m(pre)}.\n")
        P("| Reference class | E[NPV] | P(breakout) | E[production NPV / breakout] | E[production NPV / other] | Max eps, eta 0.8 | Max eps, eta 0.6 |")
        P("| --- | --- | --- | --- | --- | --- | --- |")
        for label, ref in (("All 14 comparables", REF_ALL), ("Winners' pattern (7)", REF_PATTERN)):
            ev = sum(p * npv[k] for k, p in ref.items())
            pg = ref["Breakout"]
            g = npv["Breakout"] + pre
            bad = {k: p for k, p in ref.items() if k != "Breakout"}
            pb = sum(bad.values())
            b = sum(p * (npv[k] + pre) for k, p in bad.items()) / pb
            eps = [max(0, min(1, (pg * eta * g - pre) / (pb * -b))) for eta in (0.8, 0.6)]
            P(f"| {label} | {m(ev)} | {pg:.2f} | {m(g)} | {m(b)} | {eps[0]:.2f} | {eps[1]:.2f} |")
    return "\n".join(out)


if __name__ == "__main__":
    print(report())
