# BenchCap Codex

**Status:** Immutable

This document defines what BenchCap *is* and *is not*. It is not a roadmap, not an implementation guide, and not a feature list. It is the set of invariants that must remain true regardless of platform, implementation details, or future extensions.

BenchCap exists to preserve a way of doing basic research that has been slowly disappearing: real‑time, longitudinal, shared experimental execution with scientific authorship intact.

---

## 1. Purpose

BenchCap exists to support **basic research execution**.

It is designed for environments where:
- experiments evolve iteratively,
- insight emerges during execution,
- timing and sequence matter biologically,
- and scientists must retain local control and responsibility.

BenchCap is **not** a clinical research system. It may support compliance‑driven instruments, but it does not adopt a compliance‑first posture.

The system’s job is to:
- reduce cognitive load at the bench,
- prevent silent errors,
- preserve experimental meaning over time,
- and produce data that remains legible and analyzable outside the system.

---

## 2. The Primary Object: The Execution Grid

The irreducible object in BenchCap is the **time‑indexed execution grid**.

- Rows represent **Action Modules** (what is done).
- Columns represent **Time Nodes** (when it is done).
- Cells represent **execution state** for a specific subject.

The grid is not a view layered on top of data. The grid *is* the experiment.

BenchCap must always allow a human to answer, at a glance:
- What has been done
- What is due
- What has not happened

---

## 3. Time as Structure

Time in BenchCap is **discrete and structural**, not inferential.

- Time Nodes are named positions (e.g., Start, Week 3, Post‑op Day 1).
- All actions bind explicitly to a Time Node.
- Continuous timestamps refine, but do not replace, this structure.

### Timestamps

- Timestamps are first‑class data.
- Capturing time must be low‑friction (e.g., a single “Now” action).
- If an action is not timestamped, it is partially untrue.

---

## 4. Action Modules (Instruments)

An Action Module represents a concrete, bounded action performed on a subject.

Typical properties:
- One or more required fields that represent semantic necessity
- Optional fields (e.g., notes) that never penalize omission
- Derived values colocated with raw measurements
- An explicit completion state

### Completion

- Completion is a **human decision**, not an automatic inference.
- A completed state is a trust boundary.
- False completion is worse than friction.

### Required Fields

- Fields are required only when omission would invalidate meaning.
- Incorrectly required fields are considered usability bugs.

---

## 5. Long Instruments and Compliance

Some Action Modules must be long, rigid, and detailed.

Examples include:
- surgical logs
- compliance or audit records

BenchCap explicitly allows **instrument‑local rigidity**.

However:
- Compliance requirements must not propagate system‑wide.
- Long instruments are local exceptions, not a global design model.

BenchCap must never confuse compliance with intelligence.

---

## 6. Queryability and Export

BenchCap is **export‑first**.

- All data must be flattenable into clear, legible tables.
- Repeat actions must be explicit and enumerable.
- Derived values must be preserved or reproducible.

In‑system querying exists for:
- sanity checks
- gap detection
- situational awareness

BenchCap is not an analysis platform.

Its success is measured by how completely it disappears once data is exported to external tools (R, Excel, Python, etc.).

---

## 7. Authorship and Responsibility

BenchCap assumes the user is a competent scientist.

- Structure may be iterated.
- Instruments may evolve.
- Responsibility is local, not abstracted away.

BenchCap does not protect users from making decisions.
It protects them from losing track of reality.

---

## 8. Platform Commitment: iPad‑First

BenchCap is intended to be built as an **iPad application**.

This implies:
- touch‑first interaction
- use in constrained physical environments (animal rooms, procedure areas)
- fast wake → action → exit cycles
- offline‑tolerant local authority with later synchronization

The iPad is not a convenience choice; it is part of the execution surface.

---

## 9. Explicit Non‑Goals

BenchCap must never:
- become a protocol enforcement system
- require institutional gatekeeping as a default
- optimize for dashboards or analytics
- hide data behind proprietary representations
- punish honest incompleteness

---

## 10. Final Principle

BenchCap exists to preserve **experimental truth over time**.

If a future change improves convenience but weakens:
- trust in completion,
- clarity of timing,
- legibility of exports,
- or scientific authorship,

that change violates this codex.

This document is immutable.

