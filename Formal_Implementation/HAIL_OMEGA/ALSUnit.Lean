/-- Ultra-minimal ALS∞⁺-lite “unit” model (robust v2, no external deps). -/
namespace ALSUnit

/-- Explicit universes to avoid `Sort _` inference edge cases. -/
universe u v

/-- Tiny equivalence to avoid importing `Std.Data.Equiv`. -/
structure Iso (α : Sort u) (β : Sort v) :=
  (toFun   : α → β)
  (invFun  : β → α)
  (left_inv  : ∀ x, invFun (toFun x) = x)
  (right_inv : ∀ y, toFun (invFun y) = y)

namespace Iso
@[simp] def refl (α : Sort u) : Iso α α :=
{ toFun := id, invFun := id, left_inv := by intro x; rfl, right_inv := by intro y; rfl }
end Iso

-- Carrier & aux types
abbrev α      := PUnit
abbrev Tau    := PUnit
abbrev ObsVal := PUnit
abbrev Subst  := PUnit

-- Operations (collision-safe names)
def U : α := ⟨⟩
def OpenOp (x : α) : α := x
def subst  (_ : Subst) (x : α) : α := x
def nabla  (x : α) : α := x
def tensor (_ _ : α) : α := ⟨⟩
def SigmaOp (x : α) : α := x
def DeltaOp (x : α) : α := x
def cap   (_ _ : α) : α := ⟨⟩
def piOp  (_ : α) : Tau := ⟨⟩
def psiOp (_ : Tau) : α := ⟨⟩
def tauIsoInfty? : Option (Iso Tau PUnit) := some (Iso.refl Tau)

-- Observations
def obs (_ : α) : ObsVal := ⟨⟩
def RP  (x : α) : α := x
def L   (_ : α) : Nat := 0

-- `simp` facts
@[simp] theorem OpenOp_eq (x : α) : OpenOp x = x := rfl
@[simp] theorem subst_eq  (s : Subst) (x : α) : subst s x = x := rfl
@[simp] theorem nabla_eq  (x : α) : nabla x = x := rfl
@[simp] theorem SigmaOp_eq (x : α) : SigmaOp x = x := rfl
@[simp] theorem DeltaOp_eq (x : α) : DeltaOp x = x := rfl
@[simp] theorem RP_eq     (x : α) : RP x = x := rfl
@[simp] theorem piOp_eq   (x : α) : piOp x = ⟨⟩ := rfl
@[simp] theorem psiOp_eq  (t : Tau) : psiOp t = ⟨⟩ := rfl
@[simp] theorem obs_eq    (x : α) : obs x = ⟨⟩ := rfl
@[simp] theorem L_eq      (x : α) : L x = 0 := rfl

-- Constant op helpers
@[simp] theorem tensor_eq (x y : α) : tensor x y = U := rfl
@[simp] theorem cap_eq    (x y : α) : cap x y    = U := rfl
@[simp] theorem tensor_left  (x : α) : tensor U x = U := rfl
@[simp] theorem tensor_right (x : α) : tensor x U = U := rfl
@[simp] theorem cap_left     (x : α) : cap U x    = U := rfl
@[simp] theorem cap_right    (x : α) : cap x U    = U := rfl

-- “Contracts”
@[simp] theorem nabla_idem (x : α) : nabla (nabla x) = nabla x := rfl
@[simp] theorem RP_idem    (x : α) : RP (RP x) = RP x := rfl
@[simp] theorem SigmaOp_idem (x : α) : SigmaOp (SigmaOp x) = SigmaOp x := rfl
@[simp] theorem DeltaOp_idem (x : α) : DeltaOp (DeltaOp x) = DeltaOp x := rfl

theorem L_nabla_le (x : α) : L (nabla x) ≤ L x := by simp

-- Trivial algebraic laws
@[simp] theorem tensor_comm (x y : α) : tensor x y = tensor y x := rfl
@[simp] theorem tensor_assoc (x y z : α) :
  tensor (tensor x y) z = tensor x (tensor y z) := rfl
@[simp] theorem cap_comm (x y : α) : cap x y = cap y x := rfl
@[simp] theorem cap_assoc (x y z : α) :
  cap (cap x y) z = cap x (cap y z) := rfl

-- Composites
@[simp] theorem psi_pi (x : α) : psiOp (piOp x) = U := by simp [U]
@[simp] theorem pi_psi (t : Tau) : piOp (psiOp t) = ⟨⟩ := by simp

-- Option witnesses
@[simp] theorem tauIsoInfty?_isSome : tauIsoInfty?.isSome = true := by simp [tauIsoInfty?]
theorem tauIsoInfty?_some : ∃ e : Iso Tau PUnit, tauIsoInfty? = some e :=
  ⟨Iso.refl Tau, rfl⟩

-- Subsingleton “everything equal” lemma (keep OFF `[simp]`)
theorem all_eq' (x y : α) : x = y := Subsingleton.elim x y

-- Local notation (delete if your editor dislikes Unicode)
local notation "∇ " x:100 => ALSUnit.nabla x
local infixl:70 " ⊗ " => ALSUnit.tensor
local infixl:70 " ∩ " => ALSUnit.cap
local notation "Σ " x:100 => ALSUnit.SigmaOp x
local notation "∆ " x:100 => ALSUnit.DeltaOp x
local notation "π " x:100 => ALSUnit.piOp x
local notation "ψ " t:100 => ALSUnit.psiOp t

-- Sanity check
example : L (∇ (RP (Σ (∆ ((U ⊗ ψ (π U)) ∩ U))))) = 0 := by simp [U]

/-— Optional packaging —-/
structure ALS (α Tau ObsVal Subst : Type) :=
  (U      : α)
  (OpenOp : α → α)
  (subst  : Subst → α → α)
  (nabla  : α → α)
  (tensor : α → α → α)
  (SigmaOp : α → α)
  (DeltaOp : α → α)
  (cap    : α → α → α)
  (piOp   : α → Tau)
  (psiOp  : Tau → α)
  (tauIsoInfty? : Option (Iso Tau PUnit))
  (obs    : α → ObsVal)
  (RP     : α → α)
  (L      : α → Nat)

def unitModel : ALS PUnit PUnit PUnit PUnit :=
{ U := ⟨⟩, OpenOp := id, subst := fun _ x => x, nabla := id,
  tensor := fun _ _ => ⟨⟩, SigmaOp := id, DeltaOp := id, cap := fun _ _ => ⟨⟩,
  piOp := fun _ => ⟨⟩, psiOp := fun _ => ⟨⟩, tauIsoInfty? := some (Iso.refl PUnit),
  obs := fun _ => ⟨⟩, RP := id, L := fun _ => 0 }

end ALSUnit
