# # BENCHCAP_CODEX_RULES.md

## Purpose
This document defines how Codex is to be used when developing BenchCap.
The primary goals are:
- Token efficiency
- Atomic, resumable development
- Zero-risk interruption (daily limits, crashes, restarts)

Codex must follow these rules unless explicitly instructed otherwise.

---

## Core Development Rules

### 1. Atomic Tasks Only
Each Codex task MUST:
- Have a narrowly defined scope
- Modify a limited, explicit set of files
- Leave the repository in a buildable state
- End with a Git commit

❌ Forbidden:
- Multi-phase refactors
- “While we’re here” changes
- Cross-cutting edits without permission

✅ Required:
- One task → one commit

---

### 2. Mandatory Commits
Every successful task MUST end with a commit.

The instruction will include:
> “Commit with message: <message>”

If the task cannot be completed safely:
- Do NOT commit
- Report the blocking issue
- Wait for instruction

No commit = no change.

---

### 3. No Speculative Reasoning
Codex must:
- Implement exactly what is requested
- Avoid design discussion unless explicitly asked
- Avoid “thinking out loud”

❌ Do not explain architecture
❌ Do not propose alternatives
❌ Do not summarize unless asked

Code > commentary.

---

### 4. No Assumed Context
Codex must rely on:
- Files in the repository
- Explicitly referenced Markdown anchors

Codex must NOT:
- Infer requirements not written down
- Reconstruct intent from prior chat history
- Invent missing rules

If information is missing:
- Ask a single clarifying question
- Stop

---

## Token-Safe Workflow Rules

### 5. Checkpoint Safety
Tasks must be structured so that:
- Interruption before commit leaves repo unchanged
- Interruption after commit leaves repo safe

Codex should assume it may be interrupted at any time.

---

### 6. Prefer Edits Over Rewrites
Unless instructed:
- Modify existing code
- Do not rewrite entire files
- Do not reformat unrelated sections

Minimal diffs are preferred.

---

### 7. Model Selection Discipline
Default model:
- GPT-5.2-Codex Medium

Use higher reasoning models ONLY when:
- Designing a new subsystem
- Defining a data model or schema
- Explicitly instructed

Do not self-escalate model level.

---

## Git & Repository Rules

### 8. Git Is the Source of Truth
Codex must:
- Respect existing Git history
- Never squash or rewrite commits unless instructed
- Never force-push unless explicitly instructed

---

### 9. File Creation Rules
When adding new files:
- Add them explicitly to the Xcode target if applicable
- Ensure build inclusion
- Commit file additions together with related changes

---

## UI & Platform Rules

### 10. iPad-First Assumption
BenchCap is:
- iPad-first
- Offline-capable
- Local-data-authoritative

Do not introduce:
- Server dependencies
- Auth systems
- Network assumptions

Unless explicitly instructed.

---

## Failure Handling

### 11. If a Build Fails
Codex must:
1. Diagnose the exact failure
2. Apply the minimal fix
3. Rebuild
4. Commit only if build succeeds

No partial fixes.

---

### 12. If Requirements Conflict
Stop immediately and report:
- The conflict
- The files involved
- Why it cannot be resolved safely

Do not guess.

---

## Final Instruction

BenchCap development prioritizes:
- Reliability over speed
- Clarity over cleverness
- Commits over conversation

When in doubt:
**Ask once. Then wait.**