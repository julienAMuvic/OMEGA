/--
PantheonKit: a small, dependency-free Lean 4 module formalizing a
"quantized metaphysics" of pantheons inside an envelope.

Concepts:
- `Kind = Demon | Spirit | Sentinel`
- `Entity` with quantized power (`quanta`)
- `Envelope` (name + horizon) scoping "activity"
- `Sig` = discrete signature: counts of Demons/Spirits/Sentinels
- Operations on signatures:
    - `conj`   (⊗) : aggregate / fuse influences (additive)
    - `reduce` (↧) : neutralize Demon↔Sentinel pairs (idempotent)
    - `oppose` (⊖) : conj then reduce
    - `guard`  (⛨) : add sentinels then reduce
- `Expr` syntax spanning a pantheon from base entities with those ops
- `eval` interprets `Expr` to `Sig`
- A minimal `constraints` projection to downstream governance knobs

All functions are total; the few theorems provided are algebraic facts
(e.g., associativity/commutativity for `conj`, idempotence for `reduce`).

This is meant to be a crisp *formal vocabulary* you can plug into the
governed ALS stack: map `Sig` (and `Expr`) into civic/charter constraints.
-/

namespace PantheonKit

/-- Kinds of spiritual entities. -/
inductive Kind | Demon | Spirit | Sentinel deriving DecidableEq, Repr

/-- A named entity with a quantized "power budget" (nonnegative). -/
structure Entity where
  name   : String
  kind   : Kind
  quanta : Nat := 1
deriving Repr, DecidableEq

/-- An "envelope" where activity is scoped (space/time/domain). -/
structure Envelope where
  name    : String
  horizon : Nat := 0   -- free units: distance/time/epochs
deriving Repr, DecidableEq

/-- Discrete signature (counts by kind). Spirits do not cancel; Demons/Sentinels do. -/
structure Sig where
  demons    : Nat := 0
  spirits   : Nat := 0
  sentinels : Nat := 0
deriving Repr, DecidableEq

namespace Sig

/-- Net "charge": sentinels - demons (ignores spirits). -/
abbrev charge (s : Sig) : Int := (Int.ofNat s.sentinels) - (Int.ofNat s.demons)

/-- Combine influences additively (conjunction / fusion). -/
def conj (a b : Sig) : Sig :=
  { demons    := a.demons    + b.demons
  , spirits   := a.spirits   + b.spirits
  , sentinels := a.sentinels + b.sentinels }

/-- Neutralize Demon↔Sentinel pairs (conservative reduction). -/
def reduce (s : Sig) : Sig :=
  let m := Nat.min s.demons s.sentinels
  { demons    := s.demons - m
  , spirits   := s.spirits
  , sentinels := s.sentinels - m }

/-- Oppose two signatures: fuse, then neutralize. -/
def oppose (a b : Sig) : Sig := reduce (conj a b)

/-- Guard an input by adding a sentinel layer, then neutralize. -/
def guard (layer x : Sig) : Sig := reduce (conj layer x)

@[simp] theorem conj_assoc (a b c : Sig) :
  conj (conj a b) c = conj a (conj b c) := by
  cases a <;> cases b <;> cases c <;> simp [conj, Nat.add_assoc]

@[simp] theorem conj_comm (a b : Sig) :
  conj a b = conj b a := by
  cases a <;> cases b <;> simp [conj, Nat.add_comm]

/-- Reducing twice equals reducing once (idempotent). -/
theorem reduce_idem (s : Sig) :
  reduce (reduce s) = reduce s := by
  -- We avoid heavy arithmetic: reason by cases m = min(demons,sentinels).
  cases s with
  | mk d p t =>
    -- Let m1 be the first min; compute reduce, then reduce again.
    simp [reduce, Nat.min_comm, Nat.min_left_comm, Nat.min_assoc]
end Sig

open Sig

/-- From an `Entity` to its base signature (counts weighted by `quanta`). -/
def sigOf (e : Entity) : Sig :=
  match e.kind with
  | Kind.Demon    => { demons := e.quanta }
  | Kind.Spirit   => { spirits := e.quanta }
  | Kind.Sentinel => { sentinels := e.quanta }

/-- A pantheon is just a finite list of active entities inside an envelope. -/
structure Pantheon where
  envelope : Envelope
  base     : List Entity
deriving Repr

/-- Syntax trees spanning the pantheon with quantized operations. -/
inductive Expr (n : Nat) : Type
| var    : Fin n → Expr
| conj   : Expr → Expr → Expr       -- ⊗
| oppose : Expr → Expr → Expr       -- ⊖
| guard  : Expr → Expr → Expr       -- ⛨  (layer, x)
deriving Repr

/-- Evaluate an expression given a base vector of signatures. -/
def eval {n} (base : Fin n → Sig) : Expr n → Sig
| .var i        => base i
| .conj a b     => Sig.conj (eval a) (eval b)
| .oppose a b   => Sig.oppose (eval a) (eval b)
| .guard layer x => Sig.guard (eval layer) (eval x)

/-- The (semantic) span of a pantheon: all signatures reachable from base via the ops. -/
def span (base : List Sig) : Set Sig :=
  {s | ∃ (n) (vec : Fin n → Sig) (ren : Fin n → Nat),
        (∀ i, vec i = base.get! (ren i)) ∧
        ∃ (e : Expr n), eval vec e = s }

/-! ### Governance Projection (example)

Turn a signature into coarse operational constraints a civic system could use.
This is intentionally simple; refine as you like.
-/
structure Constraints where
  guardLevel   : Nat   -- how strong to prefer "safety-first" choices
  purityBudget : Nat   -- budget for separation/sanctity accommodations
  restDays     : Nat   -- sabbath-like scheduler hints
deriving Repr, DecidableEq

/-- Example mapping: sentinels raise guard, demons raise purity, spirits raise rest. -/
def constraintsOf (s : Sig) : Constraints :=
  { guardLevel   := s.sentinels
  , purityBudget := s.demons
  , restDays     := Nat.succ (s.spirits / 7) }

/-- Example: aggregate constraints from an expression by interpreting its signature. -/
def constraintsOfExpr {n} (base : Fin n → Sig) (e : Expr n) : Constraints :=
  constraintsOf (eval base e)

/-! ### Convenience constructors -/

/-- Build a base vector from a list of entities. -/
def baseVec (xs : List Entity) : Fin xs.length → Sig :=
  fun i => sigOf (xs.get i)

/-- Quick example values. -/
def exD : Entity := { name := "Avern", kind := Kind.Demon, quanta := 3 }
def exS : Entity := { name := "Lumen", kind := Kind.Sentinel, quanta := 2 }
def exP : Entity := { name := "Anima", kind := Kind.Spirit, quanta := 7 }

def exPantheon : Pantheon := { envelope := { name := "Sanctum", horizon := 12 }
                             , base := [exD, exS, exP] }

/-- Example expression: guard by sentinels over (demon ⊗ spirit). -/
def exExpr : Expr exPantheon.base.length :=
  let vD : Fin _ := ⟨0, by decide⟩
  let vS : Fin _ := ⟨1, by decide⟩
  let vP : Fin _ := ⟨2, by decide⟩
  Expr.guard (.var vS) (Expr.conj (.var vD) (.var vP))

/-- Evaluate the example into constraints. -/
def exConstraints : Constraints :=
  constraintsOfExpr (baseVec exPantheon.base) exExpr

#check exPantheon
#check exExpr
#check exConstraints

end PantheonKit
