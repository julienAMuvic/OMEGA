/--
`ALSKit`: a tiny, dependency-free scaffold for building locally independent solvers
with clean "plug-in" ports (pure and monadic).

Drop-in friendly:
- no external packages
- clear separation of *signature* and optional *laws*
- trivial `PUnit` instances for smoke tests
-/

namespace ALSKit

/-- Keep universe control explicit to avoid `Sort _` inference surprises. -/
universe u v w s

/-- A minimal isomorphism type (so we avoid importing extra libs). -/
structure Iso (α : Sort u) (β : Sort v) : Sort (max u v) where
  toFun     : α → β
  invFun    : β → α
  left_inv  : ∀ x, invFun (toFun x) = x
  right_inv : ∀ y, toFun (invFun y) = y

namespace Iso

@[simp] def refl (α : Sort u) : Iso α α :=
{ toFun := id, invFun := id, left_inv := by intro x; rfl, right_inv := by intro x; rfl }

@[simp] theorem left_inv_apply {α β} (f : Iso α β) (x : α) :
    f.invFun (f.toFun x) = x := f.left_inv x

@[simp] theorem right_inv_apply {α β} (f : Iso α β) (y : β) :
    f.toFun (f.invFun y) = y := f.right_inv y

end Iso

/-! ## Pure signature

`ALS` is the *pure* (non-effectful) interface. Think of these as your "ports".
You can later impose laws over an instance via `ALSLaws`.
-/

structure ALS (α : Sort u) (Tau : Sort v) (Obs : Sort w) (Subst : Sort s)
    : Sort (max u v w s) where
  /-- distinguished element (can play the role of a default state) -/
  U       : α
  /-- opening / normalization -/
  OpenOp  : α → α
  /-- environment update / substitution -/
  subst   : Subst → α → α
  /-- structural step -/
  nabla   : α → α
  /-- binary combinator (composition / product) -/
  tensor  : α → α → α
  /-- unary combinators -/
  SigmaOp : α → α
  DeltaOp : α → α
  /-- symmetric cap / meet -/
  cap     : α → α → α
  /-- encode / expose -/
  piOp    : α → Tau
  /-- decode / absorb -/
  psiOp   : Tau → α
  /-- advertise when `Tau` is terminal (or equivalent to unit) -/
  tauIsoInfty? : Option (Iso Tau PUnit)
  /-- observations / telemetry -/
  obs     : α → Obs
  /-- one-step reduction / rewriting -/
  RP      : α → α
  /-- size / potential used for well-founded reasoning -/
  L       : α → Nat

/-- Optional axioms/laws an implementation may satisfy. Keep these lightweight;
they are easy to prove for the `PUnit` model and guide nontrivial instances. -/
structure ALSLaws {α : Sort u} {Tau : Sort v} {Obs : Sort w} {Subst : Sort s}
    (S : ALS α Tau Obs Subst) : Prop where
  tensor_assoc :
    ∀ a b c, S.tensor (S.tensor a b) c = S.tensor a (S.tensor b c)
  cap_comm :
    ∀ a b, S.cap a b = S.cap b a
  psi_pi_section :
    ∀ a, S.psiOp (S.piOp a) = a
  L_nonincreasing :
    ∀ a, S.L (S.RP a) ≤ S.L a

/-! ## Monadic signature

Some backends are effectful (RPC/IO). `ALSm` lets you keep the same ports in a monad.
A pure `ALS` can be lifted via `ALSm.ofPure`.
-/

structure ALSm (m : Type → Type) [Monad m]
    (α Tau Obs Subst : Type) : Type where
  U       : α
  OpenOp  : α → m α
  subst   : Subst → α → m α
  nabla   : α → m α
  tensor  : α → α → m α
  SigmaOp : α → m α
  DeltaOp : α → m α
  cap     : α → α → m α
  piOp    : α → m Tau
  psiOp   : Tau → m α
  tauIsoInfty? : Option (Iso Tau PUnit)
  obs     : α → m Obs
  RP      : α → m α
  L       : α → m Nat

namespace ALSm

/-- Lift a pure `ALS` into any monad using `pure`. -/
def ofPure {m} [Monad m]
    {α Tau Obs Subst}
    (S : ALS α Tau Obs Subst) : ALSm m α Tau Obs Subst :=
{ U := S.U
, OpenOp := fun a => pure (S.OpenOp a)
, subst := fun σ a => pure (S.subst σ a)
, nabla := fun a => pure (S.nabla a)
, tensor := fun a b => pure (S.tensor a b)
, SigmaOp := fun a => pure (S.SigmaOp a)
, DeltaOp := fun a => pure (S.DeltaOp a)
, cap := fun a b => pure (S.cap a b)
, piOp := fun a => pure (S.piOp a)
, psiOp := fun t => pure (S.psiOp t)
, tauIsoInfty? := S.tauIsoInfty?
, obs := fun a => pure (S.obs a)
, RP := fun a => pure (S.RP a)
, L := fun a => pure (S.L a)
}

end ALSm

/-! ## Trivial "unit" instances (smoke tests)

Everything collapses to `PUnit`. These compile instantly and keep refactors honest.
-/

/-- The terminal pure instance. -/
def unitModel : ALS PUnit PUnit PUnit PUnit :=
{ U := ⟨⟩
, OpenOp := id
, subst := fun _ x => x
, nabla := id
, tensor := fun _ _ => ⟨⟩
, SigmaOp := id
, DeltaOp := id
, cap := fun _ _ => ⟨⟩
, piOp := fun _ => ⟨⟩
, psiOp := fun _ => ⟨⟩
, tauIsoInfty? := some (Iso.refl PUnit)
, obs := fun _ => ⟨⟩
, RP := id
, L := fun _ => 0
}

/-- The unit model satisfies the exemplar laws trivially. -/
theorem unitModel_laws : ALSLaws unitModel := by
  refine
  { tensor_assoc := ?ta
  , cap_comm := ?cc
  , psi_pi_section := ?sec
  , L_nonincreasing := ?mono
  }
  all_goals
    intro
    -- everything is definitionally equal in `PUnit`
    rfl

/-- Any monad version obtained from `unitModel`. -/
def unitModelM (m : Type → Type) [Monad m] :
    ALSm m PUnit PUnit PUnit PUnit := ALSm.ofPure unitModel

/-! ## Tiny simp support -/

@[simp] theorem punit_tensor {S : ALS PUnit τ ο σ}
    (a b : PUnit) : S.tensor a b = ⟨⟩ := rfl

@[simp] theorem unitModel_tensor (a b : PUnit) :
    unitModel.tensor a b = ⟨⟩ := rfl

/-! ## Example usage

```
import ALSKit

open ALSKit

#check unitModel
#check unitModelM Id

def trivialRun : PUnit :=
  let s := unitModel
  have : s.RP s.U = s.U := rfl
  PUnit.unit
```
-/

end ALSKit
