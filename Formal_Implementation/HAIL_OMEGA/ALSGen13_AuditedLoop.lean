/--
ALSGen13_AuditedLoop: integrates the proved governance audit with the
12D policy step, producing a full audited loop.

Depends on:
- ALSKit.lean
- ALSKitDim.lean
- ALSGen13_12D.lean
- ALSGen13_Governance_Proved.lean
-/

import ALSGen13_12D
import ALSGen13_Governance_Proved

namespace ALSGen13_Audited

open ALSGen13_12D ALSGen13_GovProved

/-- Run `fuel` steps; every step is audited via `guardedStepWithAudit`.
Returns the final state and the concatenated audit trail. -/
noncomputable def auditedPolicyLoop
  (fuel : Nat) (initial : State) : State × List AuditEvent :=
  let rec loop : Nat → State → List AuditEvent → State × List AuditEvent
  | 0,     s, evs => (s, evs)
  | n+1,   s, evs =>
      let (s', evs') := guardedStepWithAudit step s
      loop n s' (evs ++ evs')
  loop fuel initial []

#check auditedPolicyLoop

end ALSGen13_Audited
