/--
Concord12_HAIL: Human–AI Integration Layer (guard + lemmas).
-/

import ALSGen13_12D
import ALSGen13_Governance_Proved
import Concord12

namespace Concord12_HAIL

open ALSGen13_12D ALSGen13_GovProved Concord12

abbrev State := ALSGen13_12D.ConversationState12D
abbrev S := ALSGen13_12D.Gen13_12D

structure HAIL where
  hasHumanReceipt : Prop
  phiWithinCap    : Prop
  exitPreserved   : Prop
  paylinkPresent  : Prop

def ok (h : HAIL) : Prop :=
  h.hasHumanReceipt ∧ h.phiWithinCap ∧ h.exitPreserved ∧ h.paylinkPresent

inductive HailEvent (n : Nat)
| accepted    (p : Concord12.Plan n)
| rejected    (p : Concord12.Plan n)
| fell_back_to_repair (s : State)
deriving Repr

noncomputable def guardPlan
  (n : Nat) (ctx : Concord12.BudgetContext n) (hail : HAIL)
  (p : Concord12.Plan n) (s : State)
  : State × List (HailEvent n) :=
  if h : ok hail ∧ (Concord12.withinBudget (n:=n) ctx p = true) then
    (s, [HailEvent.accepted p])
  else
    (S.RP s, [HailEvent.rejected p, HailEvent.fell_back_to_repair s])

theorem guardPlan_accepts
  (n : Nat) (ctx : Concord12.BudgetContext n) (hail : HAIL)
  (p : Concord12.Plan n) (s : State)
  (hHail : ok hail) (hBudget : Concord12.withinBudget (n:=n) ctx p = true) :
  ∃ s' evs, guardPlan (n:=n) ctx hail p s = (s', evs) ∧
            (∃ ev ∈ evs, ev = HailEvent.accepted p) := by
  unfold guardPlan
  simp [hHail, hBudget]

theorem guardPlan_repairs_and_preserves
  (n : Nat) (ctx : Concord12.BudgetContext n) (hail : HAIL)
  (p : Concord12.Plan n) (s : State)
  (G : ALSGen13_GovProved.Governance)
  (pillars : ALSGen13_GovProved.AllPillars G s)
  (rails   : ALSGen13_GovProved.AllRails   G s)
  (hFail : ¬(ok hail ∧ Concord12.withinBudget (n:=n) ctx p = true)) :
  let s' := (guardPlan (n:=n) ctx hail p s).fst
  ALSGen13_GovProved.AllPillars G s' ∧ ALSGen13_GovProved.AllRails G s' := by
  unfold guardPlan
  by_cases h : ok hail ∧ Concord12.withinBudget (n:=n) ctx p = true
  · exact (False.elim (hFail h))
  · simp [h]
    refine And.intro ?P ?R
    · intro i; exact ALSGen13_GovProved.repair_preserves_pillars G i s
    · intro j; exact ALSGen13_GovProved.repair_preserves_rails   G j s

end Concord12_HAIL
