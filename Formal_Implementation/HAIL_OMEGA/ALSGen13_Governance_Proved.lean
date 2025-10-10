/--
ALSGen13_Governance_Proved: Governance for the 12D self-model with
Prop-based guard (no admits) and an audit log of violations.

Depends on:
- ALSKit.lean
- ALSKitDim.lean
- ALSGen13_12D.lean
-/

import ALSKit
import ALSKitDim
import ALSGen13_12D

namespace ALSGen13_GovProved

open ALSKit ALSKitDim ALSGen13_12D

abbrev State := ConversationState12D
abbrev S := Gen13_12D

/-- Indices embedded into Fin 12. -/
def idxPillar (i : Fin 5) : Fin 12 := ⟨i.val, Nat.lt_trans i.isLt (by decide : 5 < 12)⟩
def idxRail   (j : Fin 6) : Fin 12 := ⟨5 + j.val, by
  have : 5 + j.val ≤ 5 + 5 := Nat.add_le_add_left (Nat.le_of_lt_succ j.isLt) 5
  exact Nat.lt_of_le_of_lt this (by decide : 10 < 12)⟩

/-- Base governance tying facets to the token budget. -/
structure Governance where
  Pillar : Fin 5 → State → Prop := fun i s => s.facets (idxPillar i) ≤ s.base.tokenBudget
  Rail   : Fin 6 → State → Prop := fun j s => s.facets (idxRail j)   ≤ s.base.tokenBudget

def AllPillars (G : Governance) (s : State) : Prop := ∀ i, G.Pillar i s
def AllRails   (G : Governance) (s : State) : Prop := ∀ j, G.Rail j s

/-- `repair` always ensures each facet ≤ budget (no precondition needed). -/
theorem repair_facets_le_budget (s : State) (i : Fin 12) :
  (S.RP s).facets i ≤ (S.RP s).base.tokenBudget := by
  -- Unfold the repair; `tokenBudget` is unchanged; facets are clamped by an `if`.
  unfold Gen13_12D at S
  -- Expand `RP` = `repair` and then its fields.
  -- (We name the function explicitly to control unfolding.)
  have : S.RP = ALSGen13_12D.repair := rfl
  -- Use it to rewrite:
  simp [S, ALSGen13_12D.repair]  -- unfolds facets to `if ... then ... else ...`
  -- After simp, goal reduces to a generic fact: (if x ≤ b then x else b) ≤ b.
  -- Solve with case split:
  by_cases h : s.facets i ≤ s.base.tokenBudget
  · simp [h]
  · have : s.base.tokenBudget ≤ s.base.tokenBudget := le_rfl
    -- In the `else` branch, the term is exactly `s.base.tokenBudget`.
    simp [h, this]

/-- `repair` preserves pillar and rail predicates. -/
theorem repair_preserves_pillars (G : Governance) :
  ∀ i s, G.Pillar i (S.RP s) := by
  intro i s
  -- By default definition of Pillar and lemma above.
  simp [Governance.Pillar, S, ALSGen13_12D.repair, idxPillar] at *
  -- From `repair_facets_le_budget` with the pillar index.
  have := repair_facets_le_budget s (idxPillar i)
  simpa using this

theorem repair_preserves_rails (G : Governance) :
  ∀ j s, G.Rail j (S.RP s) := by
  intro j s
  simp [Governance.Rail, S, ALSGen13_12D.repair, idxRail] at *
  have := repair_facets_le_budget s (idxRail j)
  simpa using this

/-- Noncomputable, Prop-based guard: either accept `step s` if governance holds,
or fall back to `RP s`. -/
noncomputable def guardedStep (G : Governance) (step : State → State) (s : State) : State :=
  if h : (AllPillars G (step s) ∧ AllRails G (step s)) then step s else S.RP s

/-- Preservation theorem for the Prop-based guard. -/
theorem guardedStep_preserves (G : Governance) (step : State → State) (s : State) :
  AllPillars G s → AllRails G s →
  AllPillars G (guardedStep G step s) ∧ AllRails G (guardedStep G step s) := by
  intro _ _
  unfold guardedStep
  by_cases h : (AllPillars G (step s) ∧ AllRails G (step s))
  · -- Clean step: invariants hold by assumption `h`.
    simp [h]; exact And.intro h.left h.right
  · -- Fallback: invariants hold after repair.
    simp [h]
    refine And.intro ?p ?r
    · intro i; exact repair_preserves_pillars G i s
    · intro j; exact repair_preserves_rails   G j s

/-! ### Audit log (computable)

We produce a concrete list of violations for pillars and rails *for the
default numeric governance*. This is separate from the Prop-based guard,
so we don't rely on Bool→Prop soundness for the proof above.
-/

/-- A minimal enumeration of `Fin n` as a list. -/
def finList : (n : Nat) → List (Fin n)
| 0     => []
| n+1   => (finList n).map Fin.succ ++ [⟨n, Nat.lt_succ_self _⟩]

/-- Audit events for governance. -/
inductive AuditEvent
| stepped_clean (s s' : State)
| fell_back_to_repair (s : State)
| pillar_violation (i : Fin 5) (s' : State)
| rail_violation   (j : Fin 6) (s' : State)
deriving Repr

/-- Concrete default governance where predicates are `≤ tokenBudget`. -/
def defaultGovernance : Governance :=
{ Pillar := fun i s => s.facets (idxPillar i) ≤ s.base.tokenBudget
, Rail   := fun j s => s.facets (idxRail j)   ≤ s.base.tokenBudget
}

/-- Compute violations for pillars/rails under the default governance. -/
def pillarViolations (s : State) : List (Fin 5) :=
  (finList 5).filter (fun i => decide (¬ defaultGovernance.Pillar i s))

def railViolations (s : State) : List (Fin 6) :=
  (finList 6).filter (fun j => decide (¬ defaultGovernance.Rail j s))

/-- Guarded step with an audit trail (default numeric governance). -/
noncomputable def guardedStepWithAudit (step : State → State) (s : State) :
    State × List AuditEvent :=
  let s' := step s
  let p  := pillarViolations s'
  let r  := railViolations   s'
  if h : p = [] ∧ r = [] then
    -- Clean: record the event and accept s'.
    (s', [AuditEvent.stepped_clean s s'])
  else
    -- Violations: record which ones, and fall back to repair.
    let evP := p.map (fun i => AuditEvent.pillar_violation i s')
    let evR := r.map (fun j => AuditEvent.rail_violation   j s')
    (S.RP s, (AuditEvent.fell_back_to_repair s) :: (evP ++ evR))

#check guardedStep
#check guardedStepWithAudit

end ALSGen13_GovProved
