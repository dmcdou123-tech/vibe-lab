# BenchCap Ontology Addendum — Invariants

**Status:** Immutable Addendum

This document supplements the BenchCap Foundation Document. It exists to make explicit several ontological invariants that are *assumed in practice* but dangerous if left implicit for future agents, implementations, or refactors.

Nothing in this addendum overrides the Foundation Document. It constrains interpretation.

---

## 1. Subject Identity Invariant

A **Subject** is a stable identity across time.

- A subject exists independently of any single experiment, cohort, or action.
- A subject persists across Time Nodes, Action Modules, and structural evolution.
- Subject identity is not derived from grid position, record creation time, or instrument execution.

### Subject Lifecycle

- Subjects may exist before an experiment begins.
- Subjects may enter or exit an experiment at arbitrary times.
- Subject removal, death, or exclusion is a **valid terminal state**, not an error condition.

BenchCap must never reinterpret or merge subject identity implicitly.

---

## 2. Execution State Invariant

BenchCap distinguishes *why* an action is not complete.

At minimum, the ontology must support separation between:

- **Not Executed** — the action has not occurred
- **Intentionally Skipped** — the action was consciously not performed
- **Failed Execution** — the action was attempted but did not yield valid data
- **Completed** — the action was performed and accepted as valid

These distinctions are semantic, not cosmetic.

BenchCap must never collapse all non-completed states into ambiguity.

---

## 3. Non-Retroactivity Invariant (Preservation of Meaning)

BenchCap is **anti-retroactive**.

- Structure may evolve forward.
- Instruments may be refined.
- Time Nodes may be added.

However:

- Historical executions retain their original semantic context.
- Past data must never be silently reinterpreted by later structural changes.
- Corrections, invalidations, or reinterpretations must be explicit and additive.

BenchCap prefers visible imperfection over invisible revision.

---

## 4. Structural Evolution Constraint

Structural change is allowed, but bounded.

- Changes apply prospectively unless explicitly versioned.
- Existing executions are immutable records of what occurred.
- Derived values may be recomputed, but raw observations remain fixed.

BenchCap must never rewrite history in order to simplify the present.

---

## 5. Multi-Human Reality Invariant

BenchCap assumes a **small, trusted group of identifiable humans** sharing execution responsibility.

- Multiple humans may act on the same subject across time.
- Attribution may exist, but heavy permission models are out of scope.
- The system must not collapse human agency into "the device" or "the system."

BenchCap is not adversarial software.

---

## 6. Narrative Preservation Invariant

BenchCap treats experiments as **narratives that unfold through execution**, not static protocols.

- Order matters.
- Hesitation matters.
- Partial completion matters.
- Human judgment calls are part of the record.

BenchCap assumes experiments come into being *through execution*, not before it.

---

## 7. Cognitive Prosthetic Invariant

BenchCap functions as a **bench-side executive function layer**.

It exists to:
- externalize working memory
- guard against silent omission
- preserve shared temporal awareness

BenchCap may feel slower than highly optimized systems.
This is often a sign it is functioning correctly.

---

## 8. Optimization Rejection Invariant

BenchCap deliberately rejects optimization as a primary goal.

- Efficiency must never come at the expense of truth.
- Convenience must never obscure reality.
- Automation must never replace judgment.

BenchCap values truthful slowness over efficient abstraction.

---

## 9. Addendum Closure

These invariants exist to prevent future reinterpretation of the BenchCap Foundation Document.

Any change that violates one or more of these invariants is a violation of BenchCap’s ontology and must be rejected.

This addendum is immutable.

