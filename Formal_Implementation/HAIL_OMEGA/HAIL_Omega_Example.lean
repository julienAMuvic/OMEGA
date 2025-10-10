/--
HAIL_Omega_Example: minimal demo of policy + metrics → enforcement.
Note: This is illustrative; replace toy values with real metrics.
-/

import Concord12
import Concord12_HAIL
import HAIL_Omega
import ALSGen13_12D

namespace HAIL_Omega_Example

open Concord12 Concord12_HAIL HAIL_Omega ALSGen13_12D

abbrev n := 2
abbrev R := Float
abbrev Dim := Fin 12
abbrev Vec := Dim → R

def toyV : Valuation :=
  let v : Dim → R := fun _ => 1.0 / 12.0
  { v := v, normalized := by
      -- We assert ∑ v d = 1.0 for uniform over 12 dims (skeleton placeholder).
      admit }

def toyCtx : BudgetContext n := { V := toyV, balance := fun _ => 1.0 }

def toyPlan : Plan n :=
  { who := ⟨0, by decide⟩, spend := fun _ => 0.1, highImpact := true }

def toyHail : HAIL :=
  { hasHumanReceipt := True, phiWithinCap := True, exitPreserved := True, paylinkPresent := True }

def pol : HAIL_Omega.Policy :=
  { tau := 1.0, sigma := 0.0, theta := 0.5, Qk := 1.0, epsilon := 1e-9 }

def mAccept : HAIL_Omega.Metrics :=
  { eκ := 0.5, bκ := 0.6, M := 0.6 / 0.5, Ddot := -0.01, health := 0.8, quotaK := 0.3, sanctuary := False }

def mThrottle : HAIL_Omega.Metrics :=
  { eκ := 0.6, bκ := 0.3, M := 0.3 / 0.6, Ddot := 0.02, health := 0.7, quotaK := 0.2, sanctuary := False }

def mFallow : HAIL_Omega.Metrics :=
  { eκ := 0.2, bκ := 0.2, M := 1.0, Ddot := 0.0, health := 0.3, quotaK := 0.1, sanctuary := False }

def mReject : HAIL_Omega.Metrics :=
  { eκ := 0.1, bκ := 0.5, M := 5.0, Ddot := 0.0, health := 0.9, quotaK := 0.1, sanctuary := True }

def demo : IO Unit := do
  let s0 := seed
  let (s1, ev1) := HAIL_Omega.enforce (n:=n) toyCtx toyHail pol mAccept toyPlan s0
  IO.println s!"ACCEPT → {ev1}"
  let (s2, ev2) := HAIL_Omega.enforce (n:=n) toyCtx toyHail pol mThrottle toyPlan s1
  IO.println s!"THROTTLE → {ev2}"
  let (s3, ev3) := HAIL_Omega.enforce (n:=n) toyCtx toyHail pol mFallow toyPlan s2
  IO.println s!"FALLOW → {ev3}"
  let (_, ev4) := HAIL_Omega.enforce (n:=n) toyCtx toyHail pol mReject toyPlan s3
  IO.println s!"REJECT_SANCTUARY → {ev4}"

#eval demo

end HAIL_Omega_Example
