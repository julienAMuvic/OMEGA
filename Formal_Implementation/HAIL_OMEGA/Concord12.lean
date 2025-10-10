/--
Concord12: identity–neutral, 12D concord compact (skeleton).
See comments for contents. Integrates with ALS stack.
-/

import ALSKitDim
import ALSGen13_12D
import ALSGen13_Governance_Proved

namespace Concord12

open ALSKitDim ALSGen13_12D ALSGen13_GovProved

abbrev Dim := Fin 12
variable (n : Nat)
abbrev Principal := Fin n
abbrev R := Float
abbrev Vec := Dim → R

structure Endowment where
  R : Vec
deriving Repr

abbrev Allocation := Principal n → Vec
abbrev Floors := Principal n → Vec
abbrev Weights := Principal n → R
abbrev Utility := Principal n → (Vec → R)
abbrev RailsPred := Allocation n → Prop

def feasible (E : Endowment) (rails : RailsPred n) (x : Allocation n) : Prop :=
  (∀ d : Dim, (∑ i, (x i) d) ≤ (E.R d)) ∧ rails x

def NSW (u : Utility n) (w : Weights n) (x : Allocation n) : R :=
  ∑ i, (w i) * Float.log (u i (x i))

structure KKT where
  λ : Dim → R
  feasibleX : Prop
  stationarity : Prop
  complementarySlack : Prop
deriving Repr

structure Valuation where
  v : Dim → R
  normalized : (∑ d, v d) = (1.0 : R)
deriving Repr

def normalizeValuation (λ : Dim → R) : Valuation :=
  let total := (∑ d, Float.max 0.0 (λ d))
  let v d :=
    if total = 0.0 then (1.0 / (12.0 : R)) else (Float.max 0.0 (λ d)) / total
  have h : (∑ d, v d) = 1.0 := by
    by_cases htot : total = 0.0
    · simp [v, htot, Fin.sum_univ_eq_card, Finset.card_univ, Fintype.card_fin]
    ·
      have : (∑ d, Float.max 0.0 (λ d)) = total := rfl
      simp [v, htot, this, Fin.sum_univ_eq_card, Finset.card_univ, Fintype.card_fin]
  { v, normalized := h }

def kappa (V : Valuation) (x : Vec) : R := ∑ d, (V.v d) * (x d)

def kappaAlloc (V : Valuation) (x : Allocation n) : Principal n → R :=
  fun i => kappa V (x i)

def primalDualStep
  (E : Endowment)
  (agentStep : (Dim → R) → (Principal n → Vec))
  (η : R)
  (λ : Dim → R)
  : (Allocation n) × (Dim → R) :=
  let x : Allocation n := agentStep λ
  let excess d : R := (∑ i, (x i) d) - (E.R d)
  let λ' d : R := Float.max 0.0 (λ d + η * (excess d))
  (x, λ')

structure Receipt where
  actor    : String
  role     : String
  signature: String
deriving Repr, DecidableEq

structure Plan where
  who  : Principal n
  spend: Vec
  highImpact : Bool
deriving Repr

structure BudgetContext where
  V       : Valuation
  balance : Principal n → R
deriving Repr

def withinBudget (ctx : BudgetContext) (p : Plan n) : Bool :=
  let need := kappa ctx.V p.spend
  let bal  := ctx.balance p.who
  need ≤ bal

end Concord12
