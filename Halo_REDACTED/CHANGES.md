# Working notes (not part of the proposal)

## Files

- `Halo_REDACTED_Harvest_v1.md`: the original proposal, unchanged.
- `Halo_REDACTED_Harvest_v4.md`: the current proposal.
- `redacted_model.py`: the program model. Running `python3 redacted_model.py` regenerates `model_output.md`.
- `model_output.md`: every table the proposal's figures come from.

## Current revision

- **Correction trail removed.** No draft labels, no reconciliation with earlier versions, and no "the draft's" references in the proposal. The model reports only current figures.
- **Two editions.**
  - Battlefront edition, $50: Strike Ops, 64-player Battlefronts with the Halo vehicle roster, Invasions, Eras I–IV, Map and Mission Forge.
  - Theater edition, $60: adds one Grand Theater region.
  - Grand Theaters are optional, decided at Gate 2 by a technical test and an early price test. If they fail, they become a post-launch expansion.
  - Battlefronts and Invasions are positioned as the substantive extension of the Helldivers formula. Space Marine 2 ($60) is added as the price comparable.
- **Engine: Unreal Engine 5,** on Halo Studios' Project Foundry pipeline that shipped Halo: Campaign Evolved (July 28, 2026). Evidence cited:
  - ARC Raiders is built on Unreal Engine 5.
  - Squad runs 100-player combined arms on Unreal Engine 5.5.
  - Call of Duty uses a proprietary engine.
  - Activision has not named an engine for the Master Chief game, so the reuse credit is split: assets carry to any engine, while engine work and tools carry only if that game also uses Unreal Engine 5.
- **Mode ladder changes.**
  - Each mode now retains a share of spend and expansion attach (ρ).
  - The ladder picks the mode with the best live margin. Without ρ, a fuller mode only added cost, which made the copies-needed grid non-monotonic.
- **Price indifference analysis added:**
  - $50 vs $40: the $50 price holds its value unless it loses more than 14–15% of copies.
  - $60 Theater vs $50 Battlefront: the $10 step only pays for Grand Theaters, so the Theater edition has to sell at least as many copies (0–2% loss absorbable).

## Headline figures (Microsoft view)

| | Battlefront $50 | Theater $60 |
| --- | --- | --- |
| Development through launch | $170M | $195M |
| Program cost, Base, dated | $365M | $422M |
| Base NPV (8M copies) | −$1M, 1.00× | −$8M, 0.98× |
| Breakout NPV (15.4M) | $560M, 2.14× | $574M, 2.03× |
| Target NPV (20M) | $849M, 2.65× | $881M, 2.45× |
| Copies to pay back, Base / Target spend | 8.0M / 6.2M | 8.2M / 6.6M |

## Assumptions to confirm or replace

1. **Copies held equal across prices** in every case. Price elasticity is the demand study's job; the price-indifference table gives the tolerance.
2. **Realized price** is 87.5% of list at $50 and $60, the same ratio as Helldivers 2 at $40.
3. **Battlefront edition cost:** production 220 people, cost pro rata ($136M); live team 160 / 115 / 80 / 40 / 8 by mode; servers at 75% of the Theater rate per active owner.
4. **Mode revenue retention ρ:** 1.00 / 0.92 / 0.80 / 0.60 / 0.30. The Base case runs Mode 4 from year two because of these values; Breakout holds Mode 1.
5. **Mode team sizes (Theater):** 180 / 130 / 90 / 45 / 8. Server factors: 1.0 / 0.9 / 0.8 / 0.6 / 0.2.
6. **Server rate:** $4.09 per active owner-year for Theater, $3.07 for Battlefront.
7. **Engagement decay** equals the 30% spend decay.
8. **Marketing timing:** 15% in months 24–36, 35% in months 36–48, 50% in the launch year.
9. **Game Pass:** Xbox copies after year one are halved; Game Pass players equal Xbox's year-one buyers, and they spend and attach at half rate; no subscription value is credited.
10. **Failure case:** 1M copies, $3 spend per owner, 5% attach.
11. **Team structure:** Foundation / REDACTED / Master Chief teams, with Chief preproduction starting around month 24.

## v4 edits (applied)

- Insomniac-derived figures replaced: lead-studio rate from BLS (Seattle-area software developer mean wage grossed up at the ~70% private-industry wage share); contingency tied to Gate 3's 10% band plus the unconfirmed 5.8% agent saving; budget comparison rebuilt on Helldivers 2's team, Concord and Activision's own court-filed Call of Duty costs.
- Factual fixes: ARC Raiders launched on all three platforms; Gears of War: E-Day (Oct 6, 2026, Horde Siege) acknowledged in the portfolio and as Microsoft's own Unreal Engine 5 production; DMZ's return in Modern Warfare 4; Space Marine 2's 6v6 PvP; Theater breakout consolidates in years four and five.
- Master Chief team: Activision has already begun assembling it; REDACTED's lead team is separate and shares only the Foundation group.
- Added: planning case and Marathon comparison, year-five live margins, revenue-retention sensitivity, Spartan rule, orchestrator definition, seven-week seasons.
- Gates: Gate 1 head-to-head against Helldivers 2; Gate 2 price test tied to the 2% indifference; Gate 3 four-week closed test (40% week-four retention), $50 vs $40 intent within 14%, positive expected NPV replacing the median test.
- Tone: Master Chief section trimmed; Infinite's Steam decline and the "military industrial" phrase removed; "overpowered" rephrased.

## Still open

- Chart updates below.
- Gate 3 retention target (40% of week-one players in week four) is a proposed threshold; the outcomes study should calibrate it against comparables' public player curves.

## Charts to update

- Lifetime copies chart: payback lines at 8.0M and 6.2M (Battlefront edition).
- War simulation diagram: Strike Ops and Battlefronts, with Grand Theaters as the optional scale.
- Returns sheet: NPV by case and edition.
- Risk map: 12 risks.
- Budget sheet: both editions.
