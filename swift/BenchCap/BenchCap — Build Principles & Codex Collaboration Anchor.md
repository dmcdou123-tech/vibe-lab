# **BenchCap — Build Principles & Codex Collaboration Anchor**

**0. Purpose of This Document**

This document defines how BenchCap is built, not what BenchCap is.

It establishes:

￼Roles (human vs Codex vs Xcode)
￼Boundaries of responsibility
￼Rules for iteration, safety, and sanity
￼How “vibe coding” stays disciplined instead of degenerating

This is a process contract, not an implementation spec.

**1. Core Build Philosophy**

**1.1 Humans Define Intent, Codex Implements**

￼Humans define:
￼￼Domain concepts
￼￼Constraints
￼￼What must never break
￼￼What matters more than elegance
￼Codex generates:
￼￼Swift / SwiftUI code
￼￼Data persistence scaffolding
￼￼Boilerplate-heavy structures

Codex is an implementation agent, not a product owner.

 

**1.2 Declarative First, Imperative Last**

We always start with:

￼Declarative descriptions
￼Plain-language intent
￼“This should behave like…”
Only later do we:

￼Lock schemas
￼Optimize performance
￼Harden edge cases
If we start coding before intent is stable, we stop.

**2. Roles in the BenchCap Build Loop**

**2.1 Q (Human Domain Owner)**

Responsibilities:

￼Scientific workflow truth
￼Regulatory reality (IACUC, inspections)
￼Deciding what must be easy vs can be clunky
￼Veto power on abstractions that “feel wrong”

Q never writes boilerplate unless desired.

**2.2 Gene/ChatGPT (Human–LLM Interface Architect)**

Responsibilities:

￼Translate domain intent into build-ready structure
￼Push back on overengineering
￼Prevent REDCap-style complexity creep
￼Maintain conceptual integrity across iterations
￼Decide what not to build
Gene ensures Codex is solving the right problem, not just a problem.

**2.3 Codex (Agentic Code Generator)**

Responsibilities:

￼Generate coherent SwiftUI modules
￼Respect declared constraints
￼Follow file structure and naming rules
￼Make changes only within declared scope

Codex does not:

￼Invent product features
￼Reinterpret scientific intent
￼“Improve” workflows without instruction
**2.4 Xcode (Execution & Reality Check)**

Role:

￼Compiler, simulator, device deployer
￼Truth arbiter (builds or it doesn’t)
￼Performance + lifecycle validation

Xcode feedback always outranks Codex confidence.

**3. Build Loop (Canonical)**

**Phase 1 — Concept Lock**

Inputs:

￼BenchCap Concept Anchor
￼Specific pain point or workflow
Outputs:

￼One clearly stated goal
￼One clearly stated “non-goal”

No code is written here.

**Phase 2 — Declarative Spec**

Artifacts:

￼Plain-language description
￼Pseudostructure (entities, relationships)
￼User flow (what user does, in what order)

This may look like:

￼Markdown
￼Bulleted logic
￼Tables
￼Screenshots + annotations

Still no Swift code.

**Phase 3 — Codex Implementation Pass**

Codex is instructed to:

￼Implement only what is declared
￼Produce full-file outputs (no patchwork)
￼Prefer clarity over cleverness
￼Leave TODOs instead of guessing

Codex output is disposable until proven.

**Phase 4 — Xcode Validation**

Actions:

￼Build
￼Run on simulator
￼Run on real device (iPad first)
￼Observe friction, not perfection

If it feels wrong, we roll back conceptually — not just technically.

**Phase 5 — Commit & Snapshot**

Only after:

￼App runs
￼Behavior matches intent

Do we:

￼Commit to GitHub
￼Tag meaningful milestones (not micro-changes)

Git is historical memory, not a design tool.

**4. Guardrails (Hard Rules)**

**4.1 No Schema Lock-In Too Early**

￼Data models remain flexible
￼Migration paths are planned conceptually before being coded
If migration feels scary, we pause.

**4.2 No “Just One More Feature”**

BenchCap grows by:

￼Depth, not breadth
￼Fewer concepts, better executed

Anything that smells like:

￼Permission systems
￼Role matrices
￼Dynamic UI builders

Is explicitly deferred.

**4.3 Data Is Sacred, UI Is Disposable**

￼UI can change freely
￼Data must survive every iteration

This principle overrides aesthetics, performance, and elegance.

**5. Codex Prompting Principles**

**5.1 Always Provide Context**

Codex prompts must include:

￼What BenchCap is
￼What this feature is for
￼What not to do

No “write me an app that…” prompts.

**5.2 Prefer Regeneration Over Surgery**

If code feels wrong:

￼Regenerate the file
￼Do not patch line-by-line unless necessary

Clean replacement beats clever fixes.

**5.3 Codex Is Allowed to Be Boring**

￼Verbose is fine
￼Explicit is good
￼Repetition is acceptable

Scientific software favors correctness over elegance.

**6. Scope Discipline**

**6.1 BenchCap v0 Rules**

BenchCap v0:

￼Single-user
￼Single iPad
￼Offline-first
￼File-based exports

Anything violating this is out of scope.

**6.2 Future Scope Is Documented, Not Built**

Future ideas:

￼Multi-device sync
￼Multi-user roles
￼Cross-platform clients

Are captured as notes, never half-built.

**7. Failure Is Informative, Not Embarrassing**

If something:

￼Feels heavier than REDCap
￼Takes longer than paper
￼Requires training to use

We treat it as signal, not sunk cost.

BenchCap must earn its existence every step.

**8. One-Sentence Build Principle**

BenchCap is built by humans declaring scientific intent, Codex generating disposable implementations, and Xcode enforcing reality — in that order, every time.

