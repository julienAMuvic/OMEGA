/--
HAIL_Omega: Asymmetry‑Safe Integration (anti over‑farming) for any domain.
Lightweight scaffold to pair with Concord12 / Concord12_HAIL / ALSGen13_12D.
-/

import Concord12
import Concord12_HAIL
import ALSGen13_12D

namespace HAIL_Omega

open Concord12 Concord12_HAIL ALSGen13_12D

abbrev R := Float
abbrev Dim := Fin 12
abbrev Vec := Dim → R
abbrev State := ALSGen13_12D.ConversationState12D
abbrev S := ALSGen13_12D.Gen13_12D

structure Metrics where
  eκ        : R
  bκ        : R
  M         : R
  Ddot      : R
  health    : R
  quotaK    : R
  sanctuary : Bool
deriving Repr

structure Policy where
  tau     : R
  sigma   : R
  theta   : R
  Qk      : R
  epsilon : R
deriving Repr

inductive Action
| Accept
| Throttle
| Fallow
| Quarantine
| RejectSanctuary
deriving Repr, DecidableEq

def decide (pol : Policy) (m : Metrics) : Action :=
  if m.sanctuary then Action.RejectSanctuary
  else if m.M < pol.tau then Action.Throttle
  else if m.Ddot > pol.sigma then Action.Throttle
  else if m.health < pol.theta then Action.Fallow
  else if m.quotaK > pol.Qk then Action.Throttle
  else Action.Accept

def scaleVec (a : R) (x : Vec) : Vec := fun d => a * (x d)

inductive EventΩ (n : Nat)
| accepted    (plan : Concord12.Plan n) (eκ : R)
| throttled   (plan : Concord12.Plan n) (scale : R) (eκ_before : R) (eκ_after : R)
| fallow      (plan : Concord12.Plan n)
| quarantined (plan : Concord12.Plan n)
| rejected_sanctuary (plan : Concord12.Plan n)
deriving Repr

def fairCapacityK (pol : Policy) (m : Metrics) : R :=
  if pol.tau ≤ 0.0 then 0.0 else m.bκ / pol.tau

noncomputable def enforce
  (n : Nat)
  (ctx   : Concord12.BudgetContext n)
  (hail  : Concord12_HAIL.HAIL)
  (pol   : Policy)
  (m     : Metrics)
  (plan  : Concord12.Plan n)
  (s     : State)
  : State × List (EventΩ n) :=
  let action := decide pol m
  match action with
  | Action.Accept =>
      let (s', evs) := Concord12_HAIL.guardPlan (n:=n) ctx hail plan s
      let ePlan := Concord12.kappa ctx.V plan.spend
      (s', [EventΩ.accepted plan ePlan])
  | Action.Throttle =>
      let ePlan := Concord12.kappa ctx.V plan.spend
      let eCap  := fairCapacityK pol m
      let scale :=
        if ePlan ≤ 0.0 then 0.0 else Float.min 1.0 (Float.max 0.0 (eCap / ePlan))
      let plan' : Concord12.Plan n := { who := plan.who, spend := scaleVec scale plan.spend, highImpact := plan.highImpact }
      let (s', _) := Concord12_HAIL.guardPlan (n:=n) ctx hail plan' s
      let eAfter := Concord12.kappa ctx.V plan'.spend
      (s', [EventΩ.throttled plan scale ePlan eAfter])
  | Action.Fallow =>
      let s' := S.RP s
      (s', [EventΩ.fallow plan])
  | Action.Quarantine =>
      let s' := S.RP s
      (s', [EventΩ.quarantined plan])
  | Action.RejectSanctuary =>
      let s' := S.RP s
      (s', [EventΩ.rejected_sanctuary plan])

end HAIL_Omega
