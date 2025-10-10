/--
ALSGen13_AuditPretty: pretty-printers and CSV exporters
for the audited, governed 12D policy loop.

Depends on:
- ALSKit.lean
- ALSKitDim.lean
- ALSGen13_12D.lean
- ALSGen13_Governance_Proved.lean
- ALSGen13_AuditedLoop.lean
- ALSGen13_AuditMetrics.lean
-/

import ALSKit
import ALSKitDim
import ALSGen13_12D
import ALSGen13_Governance_Proved
import ALSGen13_AuditedLoop
import ALSGen13_AuditMetrics

namespace ALSGen13_AuditPretty

open ALSKit ALSKitDim
open ALSGen13_12D
open ALSGen13_GovProved
open ALSGen13_Audited
open ALSGen13_AuditMetrics

abbrev State := ConversationState12D

/-- Simple state hash for CSV: combines usage, steps, budget, and facet sum mod 1e9+7. -/
def stateHash (s : State) : Nat :=
  let u := usage s.base.history
  let st := s.base.stepsUsed
  let b := s.base.tokenBudget
  let fsum := sumFacets s.facets
  let m : Nat := 1000000007
  ((u * 1315423911 % m) + (st * 2654435761 % m) + (b * 97 % m) + (fsum + 2654435761) % m) % m

/-- Summary record per the spec. -/
structure AuditSummary where
  total_steps       : Nat
  clean_steps       : Nat
  repair_fallbacks  : Nat
  total_violations  : Nat
  total_L_decrease  : Int
  total_obs_increase : Int
  total_trimmed     : Nat
  total_clamped     : Nat
  clean_rate        : Float
  avg_L_decrease    : Float
  avg_obs_increase  : Float
deriving Repr

/-- Compute the summary from audit + metrics. -/
def summarize (audit : List AuditEvent) (metrics : List MetricsEvent) : AuditSummary :=
  let total_steps := metrics.length
  let clean_steps := audit.countp (fun e => match e with | AuditEvent.stepped_clean .. => true | _ => false)
  let repair_fallbacks := audit.countp (fun e => match e with | AuditEvent.fell_back_to_repair .. => true | _ => false)
  let total_violations := audit.countp (fun e => match e with
    | AuditEvent.pillar_violation .. => true
    | AuditEvent.rail_violation ..   => true
    | _ => false)
  -- Accumulate totals from metrics
  let foldM := metrics.foldl
    (fun (acc : (Int × Int × Nat × Nat)) m =>
      match m with
      | MetricsEvent.clean_delta dL dObs _ _ =>
          let decL := if dL < 0 then Int.neg dL else 0
          let incO := if dObs > 0 then dObs else 0
          (acc.fst + decL, acc.snd + incO, acc.fst.snd?, acc.fst.snd?) -- placeholder to force type errors if misused
      | _ => acc)
    (0, 0, 0, 0)
  -- We can't pattern-assign tuples fields nicely; do second fold explicitly.
  let total_L_decrease := metrics.foldl
    (fun z m => match m with | MetricsEvent.clean_delta dL _ _ _ => z + (if dL < 0 then Int.neg dL else 0) | _ => z) 0
  let total_obs_increase := metrics.foldl
    (fun z m => match m with | MetricsEvent.clean_delta _ dObs _ _ => z + (if dObs > 0 then dObs else 0) | _ => z) 0
  let total_trimmed := metrics.foldl
    (fun z m => match m with | MetricsEvent.repair_delta trimmed _ _ _ _ => z + trimmed | _ => z) 0
  let total_clamped := metrics.foldl
    (fun z m => match m with | MetricsEvent.repair_delta _ total _ _ _ => z + total | _ => z) 0
  let clean_rate : Float :=
    if total_steps = 0 then 0.0 else (Float.ofNat clean_steps) / (Float.ofNat total_steps)
  let avg_L_decrease : Float :=
    if clean_steps = 0 then 0.0 else (Float.ofInt total_L_decrease) / (Float.ofNat clean_steps)
  let avg_obs_increase : Float :=
    if clean_steps = 0 then 0.0 else (Float.ofInt total_obs_increase) / (Float.ofNat clean_steps)
  { total_steps, clean_steps, repair_fallbacks, total_violations
  , total_L_decrease, total_obs_increase, total_trimmed, total_clamped
  , clean_rate, avg_L_decrease, avg_obs_increase }

/-- Human-friendly pretty-printer for the summary. -/
def prettyPrint (audit : List AuditEvent) (metrics : List MetricsEvent) : String :=
  let s := summarize audit metrics
  let pct (x : Float) : String := s!"{x * 100.0}%"
  String.intercalate "\n"
    [ "=== Audit Summary ==="
    , s!"total steps:        {s.total_steps}"
    , s!"clean steps:        {s.clean_steps}"
    , s!"repair fallbacks:   {s.repair_fallbacks}"
    , s!"total violations:   {s.total_violations}"
    , s!"clean rate:         {pct s.clean_rate}"
    , s!"total L decrease:   {s.total_L_decrease}"
    , s!"avg L decrease:     {s.avg_L_decrease}"
    , s!"total obs increase: {s.total_obs_increase}"
    , s!"avg obs increase:   {s.avg_obs_increase}"
    , s!"total trimmed:      {s.total_trimmed}"
    , s!"total clamped:      {s.total_clamped}"
    ]

/-- CSV helpers. -/
def joinCSV (xs : List String) : String :=
  String.intercalate "," xs

def linesCSV (rows : List (List String)) : String :=
  String.intercalate "\n" (rows.map joinCSV)

/-- Render audit events to CSV (step-indexed). -/
def toCSV_audit (audit : List AuditEvent) : String :=
  let header := ["step","event_type","pillar_id","rail_id","state_hash"]
  let rec rows (idx : Nat) (xs : List AuditEvent) : List (List String) :=
    match xs with
    | [] => []
    | e::es =>
      match e with
      | AuditEvent.stepped_clean s s' =>
          [toString idx, "stepped_clean", "", "", toString (stateHash s')] :: rows (idx+1) es
      | AuditEvent.fell_back_to_repair s =>
          [toString idx, "fell_back_to_repair", "", "", toString (stateHash s)] :: rows (idx+1) es
      | AuditEvent.pillar_violation i s' =>
          [toString idx, "pillar_violation", toString i.val, "", toString (stateHash s')] :: rows (idx+1) es
      | AuditEvent.rail_violation j s' =>
          [toString idx, "rail_violation", "", toString j.val, toString (stateHash s')] :: rows (idx+1) es
  linesCSV (header :: rows 0 audit)

/-- Render metrics to CSV (step-indexed). -/
def toCSV_metrics (metrics : List MetricsEvent) : String :=
  let header := ["step","event_type","dL","dObs","usage_before","usage_after","trimmed","clamped_total"]
  let rec rows (idx : Nat) (xs : List MetricsEvent) : List (List String) :=
    match xs with
    | [] => []
    | m::ms =>
      match m with
      | MetricsEvent.clean_delta dL dObs ub ua =>
          [toString idx,"clean_delta",toString dL,toString dObs,toString ub,toString ua,"0","0"] :: rows (idx+1) ms
      | MetricsEvent.repair_delta trimmed total _ ub ua =>
          [toString idx,"repair_delta","0","0",toString ub,toString ua,toString trimmed,toString total] :: rows (idx+1) ms
  linesCSV (header :: rows 0 metrics)

#check summarize
#check prettyPrint
#check toCSV_audit
#check toCSV_metrics

end ALSGen13_AuditPretty
