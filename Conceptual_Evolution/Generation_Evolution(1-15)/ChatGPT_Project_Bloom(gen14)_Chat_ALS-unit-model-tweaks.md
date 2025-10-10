# ALS unit model tweaks

**User:** Anonymous (julienmillette@uvic.ca)  
**Created:** 10/8/2025 17:01:33  
**Updated:** 10/8/2025 17:17:04  
**Exported:** 10/10/2025 12:18:46  
**Link:** [https://chatgpt.com/g/g-p-68e6fb4f24588191909ffc713dd920b9/c/68e6fb56-9d80-8327-bcf6-b4766ec13f3a](https://chatgpt.com/g/g-p-68e6fb4f24588191909ffc713dd920b9/c/68e6fb56-9d80-8327-bcf6-b4766ec13f3a)  

## Prompt:
/-- Ultra-minimal ALS∞⁺-lite “unit” model. -/
namespace ALSUnit

-- Carrier & aux types
abbrev α      := PUnit
abbrev Tau    := PUnit
abbrev ObsVal := PUnit
abbrev Subst  := PUnit

-- Operations (Ops = {U, Open, subst, ∇, ⊗, Σ, ∆, cap, π, ψ, τ≃∞?})
def U : α := ⟨⟩
def Open (x : α) : α := x
def subst (_ : Subst) (x : α) : α := x
def nabla (x : α) : α := x
def tensor (_ _ : α) : α := ⟨⟩
def Sigma (x : α) : α := x
def Delta (x : α) : α := x
def cap   (_ _ : α) : α := ⟨⟩
def pi    (_ : α) : Tau := ⟨⟩
def psi   (_ : Tau) : α := ⟨⟩
def tauIsoInfty? : Option (Tau ≃ PUnit) := some (Equiv.refl _)

-- Observations (Obs = {obs, RP, L})
def obs (_ : α) : ObsVal := ⟨⟩
def RP  (x : α) : α := x
def L   (_ : α) : Nat := 0

-- Make the trivially-true equalities fire via simp.
@[simp] theorem Open_eq   (x : α) : Open x     = x   := rfl
@[simp] theorem subst_eq  (s : Subst) (x : α) : subst s x = x := rfl
@[simp] theorem nabla_eq  (x : α) : nabla x    = x   := rfl
@[simp] theorem Sigma_eq  (x : α) : Sigma x    = x   := rfl
@[simp] theorem Delta_eq  (x : α) : Delta x    = x   := rfl
@[simp] theorem RP_eq     (x : α) : RP x       = x   := rfl
@[simp] theorem pi_eq     (x : α) : pi x       = ⟨⟩ := rfl
@[simp] theorem psi_eq    (t : Tau) : psi t    = ⟨⟩ := rfl
@[simp] theorem obs_eq    (x : α) : obs x      = ⟨⟩ := rfl
@[simp] theorem L_eq      (x : α) : L x        = 0   := rfl

-- Helpful simplification facts for the constant ops.
@[simp] theorem tensor_eq (x y : α) : tensor x y = U := rfl
@[simp] theorem cap_eq    (x y : α) : cap x y    = U := rfl

-- “Contracts” (now basically one-liners).
@[simp] theorem nabla_idem (x : α) : nabla (nabla x) = nabla x := rfl
@[simp] theorem RP_idem    (x : α) : RP (RP x) = RP x := rfl
theorem L_nabla_le (x : α) : L (nabla x) ≤ L x := by simp

-- Optional: trivial algebraic structure laws (all by rfl/simp in PUnit-world).
@[simp] theorem tensor_comm (x y : α) : tensor x y = tensor y x := rfl
@[simp] theorem tensor_assoc (x y z : α) :
  tensor (tensor x y) z = tensor x (tensor y z) := rfl
@[simp] theorem cap_comm (x y : α) : cap x y = cap y x := rfl
@[simp] theorem cap_assoc (x y z : α) :
  cap (cap x y) z = cap x (cap y z) := rfl

-- A quick sanity check: everything collapses to 0 / U.
example : L (nabla (RP (Sigma (Delta (cap (tensor U (psi (pi U))) U))))) = 0 := by simp

end ALSUnit

## Response:
Thought for 51s

Nice! This is a clean “everything collapses to `PUnit`” model, and your `@[simp]` lemmas make the whole algebra reduce exactly the way you want—`by simp` closes the sample goal as expected.

Here are a few tiny, safe tweaks that can make it even smoother:

*   Add the obviously-true composites as simp facts (`psi ∘ pi`, `pi ∘ psi`).
*   Mark a couple of missing idempotences (you already did `nabla` and `RP`; might as well add `Sigma`/`Delta` too).
*   (Optional) Provide a non-`@[simp]` lemma that any two `α`’s are equal—handy for manual proofs, but don’t mark it `[simp]` or it’ll trivialize _everything_.

Here’s a tightened version that keeps your style, just adds a few helpers:

```lean
/-- Ultra-minimal ALS∞⁺-lite “unit” model. -/
namespace ALSUnit

-- Carrier & aux types
abbrev α      := PUnit
abbrev Tau    := PUnit
abbrev ObsVal := PUnit
abbrev Subst  := PUnit

-- Operations (Ops = {U, Open, subst, ∇, ⊗, Σ, ∆, cap, π, ψ, τ≃∞?})
def U : α := ⟨⟩
def Open (x : α) : α := x
def subst (_ : Subst) (x : α) : α := x
def nabla (x : α) : α := x
def tensor (_ _ : α) : α := ⟨⟩
def Sigma (x : α) : α := x
def Delta (x : α) : α := x
def cap   (_ _ : α) : α := ⟨⟩
def pi    (_ : α) : Tau := ⟨⟩
def psi   (_ : Tau) : α := ⟨⟩
def tauIsoInfty? : Option (Tau ≃ PUnit) := some (Equiv.refl _)

-- Observations (Obs = {obs, RP, L})
def obs (_ : α) : ObsVal := ⟨⟩
def RP  (x : α) : α := x
def L   (_ : α) : Nat := 0

-- Make the trivially-true equalities fire via `simp`.
@[simp] theorem Open_eq   (x : α) : Open x     = x   := rfl
@[simp] theorem subst_eq  (s : Subst) (x : α) : subst s x = x := rfl
@[simp] theorem nabla_eq  (x : α) : nabla x    = x   := rfl
@[simp] theorem Sigma_eq  (x : α) : Sigma x    = x   := rfl
@[simp] theorem Delta_eq  (x : α) : Delta x    = x   := rfl
@[simp] theorem RP_eq     (x : α) : RP x       = x   := rfl
@[simp] theorem pi_eq     (x : α) : pi x       = ⟨⟩ := rfl
@[simp] theorem psi_eq    (t : Tau) : psi t    = ⟨⟩ := rfl
@[simp] theorem obs_eq    (x : α) : obs x      = ⟨⟩ := rfl
@[simp] theorem L_eq      (x : α) : L x        = 0   := rfl

-- Helpful simplification facts for the constant ops.
@[simp] theorem tensor_eq (x y : α) : tensor x y = U := rfl
@[simp] theorem cap_eq    (x y : α) : cap x y    = U := rfl

-- “Contracts” (now basically one-liners).
@[simp] theorem nabla_idem (x : α) : nabla (nabla x) = nabla x := rfl
@[simp] theorem RP_idem    (x : α) : RP (RP x) = RP x := rfl
-- (Also true for Σ/∆ in this model.)
@[simp] theorem Sigma_idem (x : α) : Sigma (Sigma x) = Sigma x := rfl
@[simp] theorem Delta_idem (x : α) : Delta (Delta x) = Delta x := rfl

theorem L_nabla_le (x : α) : L (nabla x) ≤ L x := by simp

-- Optional: trivial algebraic structure laws.
@[simp] theorem tensor_comm (x y : α) : tensor x y = tensor y x := rfl
@[simp] theorem tensor_assoc (x y z : α) :
  tensor (tensor x y) z = tensor x (tensor y z) := rfl
@[simp] theorem cap_comm (x y : α) : cap x y = cap y x := rfl
@[simp] theorem cap_assoc (x y z : α) :
  cap (cap x y) z = cap x (cap y z) := rfl

-- Handy composites.
@[simp] theorem psi_pi (x : α) : psi (pi x) = U := by simp [U]
@[simp] theorem pi_psi (t : Tau) : pi (psi t) = ⟨⟩ := by simp

-- The option witness is trivially present.
@[simp] theorem tauIsoInfty?_isSome : tauIsoInfty?.isSome := by simp [tauIsoInfty?]

-- (Optional, not `[simp]`): any two α’s are equal in PUnit-world.
theorem all_eq (x y : α) : x = y := by cases x; cases y; rfl

-- A quick sanity check: everything collapses to 0 / U.
example : L (nabla (RP (Sigma (Delta (cap (tensor U (psi (pi U))) U))))) = 0 := by simp

end ALSUnit
```

If you want, I can also add lightweight notations (e.g. `infixl:70 " ⊗ " => ALSUnit.tensor`) or wrap this in a typeclass so this “unit model” can serve as a trivial instance for more general proofs.

2/2

