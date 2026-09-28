# Draft 2 changes and open decisions

## Files

- `Halo_REDACTED_Harvest_v1.md` — draft 1, unchanged.
- `Halo_REDACTED_Harvest_v2.md` — draft 2.
- `redacted_model.py` — program model; `python3 redacted_model.py` regenerates `model_output.md`.
- `model_output.md` — every table the draft 2 figures come from.

## Financial model

| Change | Effect on Base case (8M copies) |
| --- | --- |
| Live years 2–5 added, with the five-mode ladder and servers scaled to active population | Program cost $334M → $446M; 1.13× → 0.85× |
| Development and marketing compounded forward to launch at 10% | $446M → $483M; 0.85× → 0.78× |
| Game Pass after year one; Steam's tier computed per case | PV revenue $379M → $371M; 0.78× → 0.77× |
| Xbox store fee shown in two views (Microsoft 0%, Activision 30%) | Activision view 0.70× |
| Breakout case added (mean of Helldivers 2, ARC Raiders, Deep Rock Galactic: 15.4M) | NPV $380M, 1.66× |
| Failure case added (1M copies) for the reference-class weighting | NPV −$333M |

Headline movements: payback 7.1M → 11.8M copies (Base spend) / 8.4M (Target spend); 1.5× line 10.6M → 19.5M / 13.6M; Target 3.7× → 2.0×.

New analysis: the copies-to-pay-back grid by spend and attach; reference-class expected NPV (−$157M all 14, +$20M winners' pattern); the gate-quality condition for the preproduction option (η, ε).

## Text

- Executive summary: "$195M production" corrected (production is $161M; $195M is development including preproduction); numbers table rebuilt; "Master Cheeks" and sex-scene detail moved out of the summary (kept in the body); the right-tail framing and spend-per-owner lever added.
- Campaign Evolved: now reported as ~3.3M players (1.2M sold + 2.1M Game Pass); no longer used as evidence of fatigue. ODST remains the Chief-free precedent.
- Broken bold markup fixed ("It holds up when players leave and expands when they come back").
- Mode ladder turned into a table with team size and server factor per mode.
- Self-funding condition rewritten with mode costs and a year-by-year Base table.
- New paragraph: Halo Foundation / REDACTED / Master Chief team structure and sequencing.
- Business model: net per copy in both views; Game Pass assumptions stated.
- Headcounts labeled as averages (preproduction ~86 implied by tranches; production average 260, peak 330).
- Helldivers 2 105-person team: inline citation added (Yahoo article verified: "105 at release in February 2024").
- Gates: Gate 2 adds the Grand Theater fallback and a measured agent-savings criterion; Gate 3 adds a closed external test and a demand model placing the median outcome at NPV ≥ 0. Preproduction studies go from seven to eight (spend per owner added).
- Risk table: rows added for spend per owner and for scope and schedule; team capacity now covers the Master Chief game.
- Appendix A: full v2 formulas (revenue, dated cost, mode ladder, NPV) and a reconciliation waterfall from draft 1.
- Appendix B: agent-savings measurement note.
- Appendix C: "winners' pattern" column and case mapping.
- Appendix E: rewritten as a coupled linear system with an eigenvalue condition (surge vs. see-saw).

## Assumptions of mine you should confirm or replace

1. **Mode ladder parameters:** team sizes 180 / 130 / 90 / 45 / 8, server factors 1.0 / 0.9 / 0.8 / 0.6 / 0.2.
2. **Server rate** $4.09 per active owner-year, calibrated from draft 1's $18M at Base year-one activity. This makes Target-case year-one servers ~$45M.
3. **Engagement decay** equal to the 30% spend decay.
4. **Marketing timing:** 15% months 24–36, 35% months 36–48, 50% launch year.
5. **Game Pass:** 50% of year-2+ Xbox copies lost; Game Pass players equal to Xbox year-one buyers; they spend and attach at half an owner's rate; no subscription value credited.
6. **Failure case:** 1M copies, $3 spend, 5% attach.
7. **Team structure** (Foundation / REDACTED / Master Chief, Chief preproduction at month 24, Chief launch ≥ 1 year after REDACTED). This is a structural choice, not a model output.
8. **Gate 3 criterion "median outcome at NPV ≥ 0":** this is a demanding bar given Base is −$114M; the alternative is to state the criterion as an η/ε target for the gates.

## Charts to update

- Lifetime copies chart: replace the single 10.6M REDACTED line with payback lines at 11.8M and 8.4M.
- Ceiling sheet chart → Returns sheet (NPV by case, program cost including live years).
- Risk map: 8 → 10 risks.
- Budget sheet caption: live years one to five.
