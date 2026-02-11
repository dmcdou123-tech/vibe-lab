# BenchCap — Concept Anchor

## Overview
BenchCap is a lightweight, iPad‑first electronic lab notebook and data‑capture system inspired by REDCap, designed specifically for **basic and preclinical research** (e.g., rodent studies) where PHI is not present and flexibility, speed, and usability matter more than enterprise clinical constraints.

BenchCap is **not** an attempt to replace REDCap for clinical research. It exists because REDCap has become operationally inaccessible for many basic science labs due to governance, permissions, and project‑build friction.

---

## Background: REDCap Context
REDCap (Research Electronic Data Capture) was developed at Vanderbilt and supported by the NIH. It is widely used for clinical and translational research due to its audit trails, role‑based access, and compliance features.

Early REDCap was flexible and researcher‑driven. Over time, institutional governance tightened:
- Project creation restricted
- Schema changes locked behind admins
- Heavy compliance even for non‑PHI data
- High friction for instrument and longitudinal setup

For basic research labs, this has resulted in **loss of autonomy** and a return to paper notebooks or ad‑hoc spreadsheets.

References:
- https://en.wikipedia.org/wiki/REDCap
- https://projectredcap.org

---

## Problem Statement
BenchCap exists to solve the following pain points:

1. **Paper regression**
   - Labs reverting to paper due to tool friction
   - Data fragmentation and transcription errors

2. **Project build fatigue**
   - REDCap instruments and calculated fields are slow and error‑prone to create
   - Longitudinal and repeated‑measure setups are cognitively expensive

3. **Loss of researcher control**
   - Researchers can no longer safely iterate on schemas
   - Even basic changes require admin intervention

4. **Mismatch of rigor**
   - Clinical‑grade constraints applied to animal studies with no PHI

---

## Core Design Principles
- iPad‑first, touch‑native UX
- Offline‑first with explicit sync
- Researcher‑owned schemas
- Safe iteration and rollback
- Minimal ceremony, maximum clarity

---

## Core Concepts

### Records
- Each animal or experimental unit has a Record ID
- Simple numeric or alphanumeric IDs (e.g., 4‑digit integers)

### Instruments
- Structured data entry forms (weights, glucose, surgery logs)
- Reusable across projects and “arms”

### Longitudinal Structure
- Timeline‑based daily or session‑based workflows
- Clear visibility into what was completed on each day

### Repeated Instances
- High‑frequency measurements (e.g., glucose clamps)
- Timestamped entries tied to a session start time

---

## Data Safety & Sync
- Primary storage can be local to the iPad
- Explicit, user‑visible sync to:
  - OneDrive / network‑mounted folders
  - Enterprise‑backed redundant storage
- Sync model prioritizes **data durability**, not real‑time collaboration

---

## Export / Import & Versioning
A key BenchCap feature:

- Full export of:
  - Project schema
  - Instruments
  - All data
- Ability to:
  - Modify schema or app version
  - Reinstall or upgrade BenchCap
  - Re‑import data into revised structure
- Preserves historical review inside the app

This mirrors (but simplifies) REDCap’s data dictionary workflow, without Excel‑level pain.

---

## Compliance & Reporting Focus
BenchCap explicitly supports:
- Survival vs non‑survival surgery tracking
- Post‑operative monitoring logs
- Analgesia administration records
- Semi‑annual inspection readiness

Built‑in summaries should answer:
- How many survival surgeries?
- Were required monitoring steps completed?
- Were analgesic protocols followed?

Without requiring manual report construction.

---

## What BenchCap Is Not
- Not a clinical trial platform
- Not HIPAA‑targeted
- Not multi‑site collaborative by default
- Not schema‑locked

---

## Long‑Horizon Vision
- Schema creation via natural language (“vibe‑code instruments”)
- Codex‑assisted project and instrument generation
- Schema diffing and safe migrations
- Focused, opinionated defaults for animal research

---

## Immediate Scope
- Single‑iPad deployment
- Single‑lab usage
- Replace paper notebooks
- Restore researcher joy and control

---

## Tone & Ethos
BenchCap is:
- Practical
- Slightly irreverent
- Researcher‑centric
- Built by scientists, for scientists

(Yes, the logo is a rat in a red cap.)
