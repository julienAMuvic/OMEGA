/--
ALSGen13_AuditMetrics: extends the audited loop with *metrics*:
- ΔL, Δobs on clean steps
- trimmed history bytes (proxy), facet clamp amounts on repair
- returns both the `AuditEvent` list and a `MetricsEvent` list

Depends on:
- ALSKit.lean
- ALSKitDim.lean
- ALSGen13_12D.lean
- ALSGen13_Governance_Proved.lean
- ALSGen13_AuditedLoop.lean
-/

import ALSKit
import ALSKitDim
import ALSGen13_12D
import ALSGen13_Governance_Proved
import ALSGen13_AuditedLoop

namespace ALSGen13_AuditMetrics

open ALSKit ALSKitDim ALSGen13_12D ALSGen13_GovProved ALSGen13_Audited

abbrev State := ALSGen13_12D.ConversationState12D
abbrev S := ALSGen13_12D.Gen13_12D

/-- Metric events for transparency. -/
inductive MetricsEvent
| clean_delta
    (dL : Int) (dObs : Int)
    (usage_before : Nat) (usage_after : Nat)
| repair_delta
    (trimmed : Nat)
    (clamped_total : Nat)
    (clamped_details : List (Fin 12 × Nat))
    (usage_before : Nat) (usage_after : Nat)
deriving Repr

/-- Convert Nat difference to Int delta. -/
def deltaNat (a b : Nat) : Int := (Int.ofNat a) - (Int.ofNat b)

/-- Excess over budget for a given facet in `s`. -/
def facetExcess (s : State) (i : Fin 12) : Nat :=
  let x := s.facets i
  let b := s.base.tokenBudget
  if h : x ≤ b then 0 else x - b

/-- Enumerate all facet excesses as (index, amount) for positives only. -/
def facetClampDetails (s : State) : List (Fin 12 × Nat) :=
  (ALSGen13_GovProved.finList 12).filterMap (fun i =>
    let e := facetExcess s i
    if e = 0 then none else some (i, e))

/-- Sum of second components in a list of pairs. -/
def sum2 (xs : List (α × Nat)) : Nat := xs.foldl (fun acc p => acc + p.snd) 0

/-- A single audited+metric step. Mirrors `guardedStepWithAudit`. -/
noncomputable def stepWithMetrics (s : State) :
    State × List AuditEvent × List MetricsEvent :=
  let (s', evs) := ALSGen13_GovProved.guardedStepWithAudit ALSGen13_12D.step s
  let L_before   := ALSGen13_12D.workload s
  let L_after    := ALSGen13_12D.workload s'
  let Obs_before := ALSGen13_12D.observe s
  let Obs_after  := ALSGen13_12D.observe s'
  -- Decide if we repaired (by checking for the repair event)
  let repaired := evs.any (fun e => match e with
    | AuditEvent.fell_back_to_repair _ => true
    | _ => false)
  if repaired then
    let trimmed := ALSGen13_12D.usage s.base.history - ALSGen13_12D.usage s'.base.history
    let clampDetails := facetClampDetails s
    let clampTotal := sum2 clampDetails
    (s', evs, [MetricsEvent.repair_delta trimmed clampTotal clampDetails
               (ALSGen13_12D.usage s.base.history) (ALSGen13_12D.usage s'.base.history)])
  else
    (s', evs, [MetricsEvent.clean_delta
                (deltaNat L_after L_before) (deltaNat Obs_after Obs_before)
                (ALSGen13_12D.usage s.base.history) (ALSGen13_12D.usage s'.base.history)])

/-- Run `fuel` steps; return final state, audit events, and metrics. -/
noncomputable def auditedPolicyLoopWithMetrics
  (fuel : Nat) (initial : State) :
  State × List AuditEvent × List MetricsEvent :=
  let rec loop : Nat → State → List AuditEvent → List MetricsEvent →
                 State × List AuditEvent × List MetricsEvent
  | 0,     s, evs, mets => (s, evs, mets)
  | n+1,   s, evs, mets =>
      let (s', evs', mets') := stepWithMetrics s
      loop n s' (evs ++ evs') (mets ++ mets')
  loop fuel initial [] []

#check auditedPolicyLoopWithMetrics

end ALSGen13_AuditMetrics
