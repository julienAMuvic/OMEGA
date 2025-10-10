/--
`ALSKitDim`: dimension-indexed extension for `ALSKit`.
It shows how to "unfold" the same laws/ports over an `n`-dimensional state
(`Fin n → β`), and provide instances for all `n ≤ 12`.

No external deps; relies only on `ALSKit.lean`.
-/

import ALSKit

namespace ALSKitDim

open ALSKit

/-- A point in `n` dimensions over coordinates of type `β`. -/
abbrev Point (β : Type u) (n : Nat) := Fin n → β

/-- Minimal coordinate-wise ops we need to define a useful `ALS`. -/
structure Ops (β : Type u) where
  combine : β → β → β     -- used by `tensor`
  cap     : β → β → β     -- used by `cap`
  unit    : β             -- used by `U` (default element)

/-- Optional laws for `Ops` that lift to `ALSLaws` pointwise. -/
structure OpsLaws {β} (ops : Ops β) : Prop where
  combine_assoc : ∀ x y z, ops.combine (ops.combine x y) z = ops.combine x (ops.combine y z)
  cap_comm      : ∀ x y,   ops.cap x y = ops.cap y x

/--
A pure `ALS` over `Point β n`, with `Tau = α` so `piOp`/`psiOp` are identities,
and trivial `obs/RP/L`. All operations are pointwise, driven by `Ops`.
-/
def pointALS {β : Type u} (ops : Ops β) (n : Nat) :
    ALS (Point β n) (Point β n) PUnit PUnit :=
{ U := fun _ => ops.unit
, OpenOp := id
, subst := fun _ a => a
, nabla := id
, tensor := fun a b i => ops.combine (a i) (b i)
, SigmaOp := id
, DeltaOp := id
, cap := fun a b i => ops.cap (a i) (b i)
, piOp := id
, psiOp := id
, tauIsoInfty? := none
, obs := fun _ => ⟨⟩
, RP := id
, L := fun _ => 0
}

/-- The dimension-indexed instance satisfies lifted laws whenever the ops do. -/
theorem pointALS_laws {β} (ops : Ops β) (L : OpsLaws ops) (n : Nat) :
    ALSLaws (pointALS ops n) := by
  refine
  { tensor_assoc := ?ta
  , cap_comm := ?cc
  , psi_pi_section := ?sec
  , L_nonincreasing := ?mono
  }
  · -- tensor associativity is pointwise
    intro a b c
    apply funext; intro i
    simpa using L.combine_assoc (a i) (b i) (c i)
  · -- cap commutativity is pointwise
    intro a b
    apply funext; intro i
    simpa using L.cap_comm (a i) (b i)
  · -- pi/psi are identities
    intro a; rfl
  · -- L is constant 0, so nonincreasing holds
    intro a; simp

/-- For *any* dimension `n ≤ 12`, provide an `ALS` instance. -/
def upto12 {β} (ops : Ops β) :
    (n : Nat) → n ≤ 12 → ALS (Point β n) (Point β n) PUnit PUnit
| n, _ => pointALS ops n

/-- And the corresponding laws for all `n ≤ 12`. -/
theorem upto12_laws {β} (ops : Ops β) (h : OpsLaws ops) :
    ∀ {n} (_ : n ≤ 12), ALSLaws (upto12 ops n ‹n ≤ 12›)
| n, _ => pointALS_laws ops h n

/-! ### Example

Instantiate with booleans:
- `combine := And`
- `cap := Or`
- `unit := True` (the default element for all coordinates)

Then you get a 12D-capable solver family *without* extra libraries.
-/

def BoolOps : Ops Bool :=
{ combine := And
, cap := Or
, unit := True
}

theorem BoolOps_laws : OpsLaws BoolOps := by
  refine
  { combine_assoc := ?a
  , cap_comm := ?c
  }
  all_goals
    intro; simp [BoolOps, And.assoc, Or.comm]

/-- Example: the 7D instance (works for any `n ≤ 12` via `upto12`). -/
def ALS7D : ALS (Point Bool 7) (Point Bool 7) PUnit PUnit := upto12 BoolOps 7 (by decide)

/-- Sanity-check a pointwise operation compiles. -/
example (a b c : Point Bool 7) :
    ALS7D.tensor (ALS7D.tensor a b) c = ALS7D.tensor a (ALS7D.tensor b c) := by
  -- Follows from lifted associativity
  have laws := upto12_laws BoolOps BoolOps_laws (n := 7) (by decide)
  simpa using laws.tensor_assoc a b c

end ALSKitDim
