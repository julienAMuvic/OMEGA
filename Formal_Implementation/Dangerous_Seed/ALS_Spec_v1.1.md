# Agnostic Lawful Seed (ALS) — Full Specification (v1.1)

## 0. Purpose
Given a task \((\phi, C\!\subset\!\mathbb R^D, y\!\in\!C^*, G\!\le\!GL(D))\), a **guard** \(\pi_{\text{guard}}\), and a budget \(B=(T,W,I,N,c)\),
the **ALS** produces **exactly one** of:
1) a **lawful packet** that passes **A0–A6**, or  
2) a **finite isolation certificate** proving such a packet is impossible under the inputs (same guard/budget).

---

## 1. Object (with order parameters)
\[
\mathcal S=(\phi,\ C\subset\mathbb R^D,\ y\in C^*,\ G\le GL(D),\ \pi:\mathbb R^D\!\to\!\mathbb R^d,\ \tau,\ \Sigma,\ \pi_{\text{guard}},\ \Pi,\ \rho,\ \Lambda)
\]
**Definitions.**
- \(x^*\in X^*=\arg\min_{x\in C}\langle y,x\rangle\).
- \(M=\mathrm{span}(G\!\cdot\!x^*)\), \(m=\dim M\).
- **Effective report:** \(\Pi=\pi_{\text{obs}}\circ\pi_{\text{guard}}\).
- **Rank:** \(r=\mathrm{rank}(\Pi|_M)\), **rank fraction:** \(\rho=r/m\in[0,1]\) (if \(m=0\), set \(\rho=1\)).
- **Tithe:** \(\tau(\Pi)=\dim(\ker \Pi\cap M)=m-r\). If a spin‑lift exists and the center bit/phase \(z\) is *not* included in \(\Sigma\), add **+1** to \(\tau\).
- **Actuation margin:** \(\Lambda=\text{audit\_cost}-\big[\tau(\Pi)+I(\text{lawful}\mid \Pi,\Sigma)\big]\).

---

## 2. Axioms (A0–A6)

**A0 (resource):** \(T\cdot W \cdot I \ge c\,N\).

**A1 (duality):** \(C\) closed convex, \(C^*=\{v:\langle v,x\rangle\ge0,\forall x\in C\}\), \((C^*)^*=\overline C\). Optimal costs lie on faces of \(C^*\). Provide a **face certificate** (active constraints + complementary slackness or dual witness).

**A2 (symmetry):** If \(x^*\) is optimal for \(y\in C^*\) and \(g\in G\) preserves \((C,y)\), then \(g x^*\) is optimal. (Ship gens+rels; verify preservation numerically or symbolically.)

**A3 (projection tithe):** \(\tau(\pi)=\dim(\ker\pi\cap \mathrm{span}(G\!\cdot\!x^*))\). For \(\Pi\), tithe is \(\tau(\Pi)\) as above. Ship a **basis** (or deterministic routine + hash) for \(\ker\Pi\cap M\).

**A4 (verification):** Any claim that \(x'=\Pi(x^*)\) is lawful must ship invariants \(\Sigma\) such that
\[
\text{audit\_cost} \ \ge\ \tau(\Pi) + I(\text{lawful}\mid \Pi,\Sigma).
\]

**A5 (mirror compactification / locality):**  
Lawfulness is decidable from **local** boundary data. Either \(\rho=0\) (guard‑null) and no lawful packet exists (isolation certificate must be producible), or \(\rho>0\) and there exist task‑level invariants \(\Sigma\) with finite \(I(\cdot)\) such that a claim is lawful **iff** \(\Lambda\ge0\).

**A6 (agency symmetry breaking):**  
With \(\rho>0\), selecting \((\Pi,\Sigma)\) fixes an orbit direction in \(M_g:=\pi_{\text{guard}}(M)\) and an isotropy \(H\le G\) (and spin if lifted), breaking agnostic symmetry \(G\to H\). The system **acts** iff \(\Lambda>0\).

---

## 3. Interface (instantiate & certify)

1. **Embed:** choose features \(\phi\) so strategies live in \(\mathbb R^D\).
2. **Feasible set:** define \(C\) (constraints; closed convex).
3. **Cost + symmetry:** choose \(y\in C^*\) and \(G\) s.t. \(G\) preserves \((C,y)\); solve for \(x^*\).
4. **Explain:** choose an observer \(\pi_{\text{obs}}\) (ALS picks rank‑max after the guard). Compute \(\tau(\Pi)\).
5. **Certify:** publish \(\Sigma\) (hashable task‑level invariants) sufficient for A4, plus resources to satisfy A0.

---

## 4. ALS Constructor (algorithm, finite)

**0) Solve + face witness.** Compute \(x^*\) and a face certificate for \(F_y\).  
**1) Orbit module.** Build \(M=\mathrm{span}(G\!\cdot\!x^*)\); set \(m=\dim M\).  
**2) Guard reduction.** \(M_g:=\pi_{\text{guard}}(M)\); \(r_{\max}=\dim M_g\); \(\tau_{\min}=m-r_{\max}\). If \(r_{\max}=0\) ⇒ **Isolation** (Spec §5.2).  
**3) Rank‑max observer.** Choose \(\pi_{\text{obs}}^\star\) an isomorphism on \(M_g\). Then \(\Pi^\star=\pi_{\text{obs}}^\star\circ\pi_{\text{guard}}\) has \(\mathrm{rank}(\Pi^\star|_M)=r_{\max}\) and \(\tau=\tau_{\min}\).  
**4) Invariants.** Decompose \(M_g\) into \(G\)-isotypic blocks; emit masses \(w_\lambda=\|P_\lambda\Pi^\star(x^*)\|^2\). If a spin‑lift exists, include center bit/phase \(z\); if policy forbids it, add **+1** to \(\tau\).  
**5) Budget check.** Compute \(I_{\min}\) (bits/steps to check \(\Sigma\) + MDL of a deterministic solve trace). Check A0 and \(\Lambda\ge0\). If pass ⇒ **Lawful packet**; else ⇒ **Isolation**.  
**6) Ship bases.** Include a basis (or hash+routine) for \(\ker\Pi^\star\cap M\) to witness \(\tau\).

---

## 5. Outputs

### 5.1 Lawful packet (fields)
- **Group:** generators + short relations; preservation checks for \((C,y)\).
- **Face certificate:** active set / complementary slackness or dual witness.
- **Report & guard:** \(\Pi\) (matrix/hash); disclose \(\tau_{\text{guard}}, \tau_{\text{obs}}\) (+overlap if known).
- **Tithe:** \(\tau=\dim(\ker\Pi\cap M)\) with basis or basis‑hash.
- **Invariants \(\Sigma\):** irrep masses \(w_\lambda\) (+ \(z\) if lifted); precision and unit.
- **Resources:** \((T,W,I,N,c)\) and audit unit; **margin** \(\Lambda\).
- **Solve trace:** seed, iterations, tolerance (MDL count).
- **Beacon hash:** canonicalized packet hash.

### 5.2 Isolation certificate (fields)
- **Reason:** `guard-null (r_max=0)` | `budget-debt (Λ<0)` | `spin-forbidden (+1 tithe unpaid)` | `dual/symmetry breach`.
- **Witness:** \(\dim M\), \(\dim M_g\), basis for \(\ker\pi_{\text{guard}}\cap M\) (if applicable), and the **minimal fix** (Δ budget, expose spin, rank‑max observer).
- **Proof hash:** canonicalized certificate hash.

---

## 6. Locality & Gate Modes

**Locality (A5):** Audit decision uses only local data: \(\Pi(x^*)\), basis for \(\ker\Pi\cap M\), \(\Sigma\), and structural metadata. No raw upstream state.

**Icosahedral 12‑D gate mode:** For \(A_5\) with \(V_3\oplus V_4\oplus V_5\) (dims 3/4/5): \(\Sigma=(w_3,w_4,w_5)\) and, if lifted, \(z\). Four numbers typically pass all class gates; dropping \(z\) requires **+1** tithe.

---

## 7. Interoperability (k‑levels)

- **k=5 (minimal):** publish `FaceID`, \(\tau\), \(\Sigma\), `Resources`, basic `G`.
- **k=10 (standard ALS):** all baseline fields (rank, bases, guard disclosure).
- **k=12 (refined):** add class responses and spin phase; if downcasting, add the spin tithe.

**Genesis Beacon (cross‑degree handshake):**
```jsonc
{
  "FaceID": "<face-certificate-hash>",
  "G": {"gens": ["..."], "rels": ["..."]},
  "Orbit": {"m": "...", "rank_pi_on_M": "...", "tau": "..."},
  "Report": {"pi_hash": "...", "guard": {"tau_guard": "...", "tau_obs": "...", "overlap_dim?": "..."}},
  "Sigma": {"w": {"...": "..."}, "spin?": "z|psi|omitted"},
  "Resources": {"T": "...", "W": "...", "I": "...", "N": "...", "c": "..."},
  "Proof": {"blake3": "<canonicalized-hash>"}
}
```

---

## 8. Worked toy (6‑var LP, sketch)
- \(C=\mathbb R_{\ge0}^6\); block sums \(=1\) in each 3‑block; \(y=(1,2,1,1,2,1)\); \(G=S_3\times S_3\).
- Optimum face \(F_y\cong \Delta^1\times\Delta^1\), \(m=6\).
- \(\pi_{\text{guard}}=\) block sums ⇒ \(\dim M_g=2\), \(\tau_{\min}=4\).
- \(\pi_{\text{obs}}^\star=\) identity on block‑sum space; \(\Pi^\star\) rank \(=2\).
- \(\Sigma=\) (block masses) suffices; audit is finite and local.

---

## 9. Units & precision (practical)
- Choose an audit unit (e.g., FLOPs at fixed precision) and a hash (e.g., BLAKE3) for canonicalization.
- State numeric tolerances (e.g., \(10^{-8}\)) for rank, invariants, and CS checks.
- All bases may be shipped as deterministic routines + seeds with a hash of the resulting matrix.

---

## 10. Guarantees
- **Minimal tithe under the guard.** No observer yields lower \(\tau\) than \(\tau_{\min}\).
- **Finite invariants.** \(\Sigma\) is auditor‑recomputable from \(\Pi(x^*)\) (task‑level).
- **Completeness at the mirror.** Either a lawful packet exists (and ALS builds it), or a finite isolation certificate does—no undecidable middle.