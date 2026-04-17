# Plan — Execute the PLANNING prompt in `plan/claude_prompt.txt`

## Context

The user opened `plan/claude_prompt.txt` — a long meta-prompt that puts Claude into **planning mode** for a 4-student Symbolic-AI Prolog RoboCup project (deadline Sun 19 Apr 2026, ~56h left). The meta-prompt has two deliverables:

1. **A `docs/project-context.md` file** (11 mandated sections) that becomes the single source of truth reused by every future subagent — the token-efficiency lever for the rest of the project.
2. **A 16-item planning response** to the chat (items 1–5 now, 6–16 as the plan matures).

**What's already done in the repo** (found via Explore):
- `plan/project-partition.md` (265 lines) — the full backlog T0.1–T7.3 with architecture, dependency graph, acceptance criteria. Architecture is **locked**: FSM + STRIPS + CSP, 2×3 players, 100×50 discrete field, single `robocup.pl`, PLUnit tests, alternating-or-random turns.
- `.claude/agents/*.md` — 5 subagents (prolog-coder, symbolic-ai-architect, prolog-test-engineer, prolog-reviewer, report-writer).
- `memory/context.md` — 17-line partial report notes (reference only).
- Floyd PDFs + rubric PDF in `project-requirements/`.

**What's missing (this plan creates it)**:
- `docs/project-context.md` — does not exist.
- No `robocup.pl` yet (created later by T0.2).
- No `tests/` yet.

**Known cosmetic issue to flag, not fix here**: `plan/project-partition.md` uses Mac paths (`/Users/book/...`). The real workspace is `c:\Users\dimik\Workspace\robocupproj\`. Subagents must translate. I'll record this in the project-context as a known paper-cut, not edit partition.md (that doc is locked).

---

## Approach (recommended — skipping alternatives per plan-mode guidance)

One file gets created; no code generated; team decisions surfaced, not locked.

### Step 1 — Create `docs/project-context.md` (~150 lines)

The 11 sections mandated by the meta-prompt, populated from `plan/project-partition.md` + agents:

1. **Project goal** — 5-10 lines: simplified RoboCup Prolog sim, `run_simulation(N)`, 2×3 teams, Symbolic-AI showcase (FSM+STRIPS+CSP), 5-page report.
2. **Locked decisions** — copy from partition.md §"Decisions already made" + architecture block.
3. **Non-goals** — no GUI, no networking, no real RoboCup protocol, no ML, no pathfinding, no multiple files beyond the tiny test.
4. **Architecture overview** — the 8-section layering of `robocup.pl` (reference, don't re-render the ASCII diagram; link to partition.md).
5. **Canonical data representation** — `field/1`, `goal_position/2`, dynamic `ball/1`, `player(Team, Role, Position, Stamina)`, `score/2`, `possession/1`, `turn/1`, `current_state/3`, etc. — table form.
6. **Shared predicate contracts** — exact signatures + one-line semantics for every cross-section predicate (`setup_world/0`, `tick_fsm/2`, `applicable/2`, `apply_effects/1`, `do_action/1`, `simulate_round/0`, `run_simulation/1`, `check_goal/0`, `print_state/0`).
7. **File/section ownership** — maps each partition.md task (T0.2…T7.3) to a single file region so parallel subagents don't collide. Table: Task → File → Section → Agent type.
8. **Current phase / backlog status** — "Phase 0 ready to dispatch; nothing built yet; next = T0.1 (report-writer) ∥ T0.2 (prolog-coder)."
9. **Open decisions still needing team approval** — exactly these four, each with Option A / Option B / my recommendation:
   - **D1 Turn order** — alternating (recommended: deterministic, easier viva) vs random.
   - **D2 CSP scope** — formation-only at setup (recommended: keeps CSP tiny and defensible) vs broader.
   - **D3 Possession granularity** — team-level (recommended: simpler) vs player-level (partition.md currently says `possession(Team,Role)` — flag inconsistency).
   - **D4 Turn-order location of the decision** — lock D1 in Phase 4 (T4.3) vs now.
10. **Verification commands** — the `swipl -s robocup.pl -g ...` lines from partition.md §Verification, plus `swipl -g "consult('tests/test_robocup.pl'), run_tests, halt"`.
11. **Viva-critical justification points** — 10 bullets mapping each decision to "why this and not something fancier" (for the oral defense).

Plus one short section **"Known paper-cuts"** at the bottom: path mismatch between partition.md (Mac) and actual workspace (Windows); the `possession/1` vs `possession(Team,Role)` inconsistency between partition.md §Architecture and §T4.5.

### Step 2 — Deliver the 16-item planning response inline (not a file)

The meta-prompt asks for the 16-item structure **as my response to the user**, not as a file. I'll produce it directly in my next turn after plan approval, referencing `docs/project-context.md` and `plan/project-partition.md` instead of duplicating their content (token-efficiency rule from the meta-prompt).

Items 1–5 get full treatment (immediate deliverable). Items 6–16 point at the partition.md tasks they already map to (work-split in partition.md already covers most of items 9–10; testing/viva/report covered by T6.1/T7.1; risks surfaced as decisions D1–D4).

### Step 3 — Surface decisions, don't lock them

End my response with the four open decisions (D1–D4) flagged for team confirmation. Per the meta-prompt's "TEAM COLLABORATION RULE": present 2 options each, recommend one, don't choose silently.

---

## Critical files

**Creating** (1 file):
- `docs/project-context.md` — new, ~150 lines.

**Reading only** (already done during planning):
- [plan/project-partition.md](plan/project-partition.md) — backlog and architecture (source of truth for content).
- [plan/claude_prompt.txt](plan/claude_prompt.txt) — the meta-prompt defining required output shape.
- [.claude/agents/](.claude/agents/) — subagent roles referenced in §7.
- [memory/context.md](memory/context.md) — sanity check for report notes (nothing to import).

**Not touched** (explicit):
- `plan/project-partition.md` — locked; only flag inconsistencies, don't edit.
- `robocup.pl` — doesn't exist; T0.2 creates it.
- Any agent definitions.

---

## Reused artifacts (no reinvention)

- Architecture diagram, data shapes, predicate contracts → **cite partition.md §Architecture / §Phase 1–5**, don't recopy.
- Task list, dependency graph → **cite partition.md §Feature backlog / §Dependency graph**.
- Agent roles → **cite `.claude/agents/*.md`**.

The whole point of `docs/project-context.md` per the meta-prompt is to be the *short* index that lets future subagent prompts stay compact. It should summarize and point, not duplicate.

---

## Verification (after the file is written)

1. **Length check** — `docs/project-context.md` is ≤ 200 lines (meta-prompt: "short, practical, highly maintained").
2. **Coverage check** — all 11 required sections present; grep for each section heading.
3. **Consistency check** — every shared predicate listed in §6 matches a signature in `plan/project-partition.md`. If any predicate appears in one doc but not the other, flag it in "Known paper-cuts".
4. **Cold-start check** — a fresh subagent reading *only* `docs/project-context.md` + the task body `T0.2` from `plan/project-partition.md` can produce the skeleton without extra context. (Mental simulation — the skeleton needs: filename, section banner format, dynamic declarations. All three appear in the context file.)
5. **Open-decisions check** — D1–D4 are each a clear decision with 2 options and a recommendation; none silently resolved.
6. **Deliverable round-trip** — my 16-item chat response references `docs/project-context.md` + `plan/project-partition.md` rather than repeating their content (token-efficiency rule).

No code execution needed at this stage — this is planning output only. Implementation verification (loading `robocup.pl`, running `run_simulation/1`, PLUnit) happens at later phases per partition.md §Verification.
