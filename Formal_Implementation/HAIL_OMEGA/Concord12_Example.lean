/--
Concord12_Example: wiring Concord12 + HAIL with ALS state (toy).
-/

import Concord12
import Concord12_HAIL
import ALSGen13_12D

namespace Concord12_Example

open Concord12 Concord12_HAIL ALSGen13_12D

abbrev n := 2
abbrev R := Float
abbrev Dim := Fin 12
abbrev Vec := Dim → R

def toyE : Endowment := { R := fun _ => 1.0 }

def toyAgentStep (λ : Dim → R) : (Principal n → Vec) :=
  fun i d => (toyE.R d) / (Float.ofNat n)

def demo : IO Unit := do
  let λ0 : Dim → R := fun _ => 1.0
  let (x, λ1) := primalDualStep (n:=n) toyE toyAgentStep (η:=0.1) λ0
  let V := normalizeValuation λ1
  let ctx : BudgetContext n := { V := V, balance := fun _ => 0.5 }
  let p : Plan n := { who := ⟨0, by decide⟩, spend := fun _ => 0.2, highImpact := true }
  let s0 := seed
  let hail : Concord12_HAIL.HAIL := { hasHumanReceipt := True, phiWithinCap := True
                                    , exitPreserved := True, paylinkPresent := True }
  let (s', evs) := Concord12_HAIL.guardPlan (n:=n) ctx hail p s0
  IO.println s!"valuation normalized sum = {V.normalized}"
  IO.println s!"events: {evs}"

#eval demo

end Concord12_Example
