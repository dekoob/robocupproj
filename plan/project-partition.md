# RoboCup Symbolic-AI Prolog — Project Partition & Feature Backlog

## Context

**What**: Group course project: implement a simplified RoboCup soccer simulation in SWI-Prolog, showcasing Symbolic AI (not the sub-symbolic CBR approach described in the Floyd papers). Single file `robocup.pl` + 5-page report (WORD+PDF).

**Why**: Evaluated on proficiency in Symbolic AI + Logic Programming. The rubric rewards explicit use of course-taught techniques (GPS, STRIPS, FSM, CSP, Tic-Tac-Toe, 8-Puzzle, Sudoku…). The Floyd papers outline the *benchmark domain*; we implement a *symbolic-AI rendition* of it.

**When**: Deadline is 12:00 midnight Sunday 19 April 2026. Today is 17 April — **~56 hours remaining**.

**Who**: Team of 4 students + Claude subagents for delegated coding. Every student must be able to explain the code and defend choices in a viva.

**Outcome expected**: A working `swipl` program where `?- run_simulation(N).` runs `N` rounds between two 3-player teams with role-based behavior, stamina, possession, goal detection, scoring, position reset, and pauses — with the code organized around three named Symbolic-AI techniques so the report rationale writes itself.

**Guiding philosophy** (from `plan/claude_prompt.txt`): simplest correct solution, fastest path to a clean submission, straightforward Prolog that students can explain, readability over elegance, course-relevant symbolic AI concepts over advanced engineering. Actively avoid AI-generated overdesign.

---

## Requirement distillation

### MUST HAVE (rubric-critical, no submission without these)
- `robocup.pl` loads cleanly in SWI-Prolog 9.x
- Symbolic representation of field, players, ball, goals, roles
- Roles: goalkeeper, defender, forward (per team, 2 teams × 3 players)
- Role-based behavior (FSM)
- Movement, kicking, catching, scoring
- Stamina decreases on movement
- Goal detection + score update + position reset
- Fair turn handling (alternating)
- Small pause between rounds for readability
- Possession model gating `kick` / `catch`
- `?- run_simulation(N).` entry point
- 5-page report (human-written prose)
- Every team member can explain every predicate in a viva

### SHOULD HAVE (strong viva / rubric bonus)
- CSP for initial formation (tiny, `clpfd`-based, one-shot)
- STRIPS-style action schema (preconditions + effects; no planner)
- PLUnit test harness with ≥4 scripted scenarios
- Metrics counters (goals, kicks, catches) + `print_summary/0`
- Scripted opening that guarantees ≥1 goal in `run_simulation(10)`
- `docs/project-context.md` as shared-context source-of-truth
- `docs/viva_answers.md` pre-drafted Q&A bank

### NICE TO HAVE (only if time remains ≥8h at phase-6 checkpoint)
- Second evaluation scenario (different opening)
- Per-role transition table printed by a `print_fsm/1` helper
- Short `docs/viva_explanations.md` post-implementation walkthrough

### DO NOT BUILD (out of scope — reject if a subagent proposes them)
- GUI / graphical rendering
- Full RoboCup networking or client-server protocol
- Full sensor message parsing (`see`, `sense_body`)
- Machine learning or case-based reasoning
- Probabilistic reasoning
- Forward-search planner / GPS means-ends engine
- Detailed pathfinding (A*, Dijkstra)
- Opponent-strategy modeling beyond simple role rules
- Multi-file module hierarchy
- Advanced libraries beyond `clpfd`, `random`, `lists`
- Real-time (non-round-based) simulation
- Continuous physics

---

## Decision checkpoints requiring team approval

These were previously locked silently. Re-opened so the team can ratify before code starts. Recommendation given per item; mark ✅ to lock.

| # | Decision | Option A | Option B | Recommendation | Reason |
|---|---|---|---|---|---|
| D1 | Starting point | Full rewrite of `robocup.pl` | Refactor existing `project` file | **A** (full rewrite) | Existing file is partial, coherence > reuse given 56h |
| D2 | Symbolic techniques | FSM + STRIPS + CSP (3 techniques) | FSM + STRIPS only (drop CSP; use fixed positions) | **A** (3 techniques) | CSP is cheap if kept tiny; one more rubric hit |
| D3 | CSP implementation | `clpfd` with `labeling/2` | Hard-coded fixed positions | **A**, with **B as fallback** if clpfd debugging > 1h | clpfd makes the report stronger; fallback protects the deadline |
| D4 | Turn order | Alternating (`team1 → team2`) | Randomized (`random_member/2`) | **A** (alternating) | Deterministic → easier viva, easier tests |
| D5 | Possession model | Player-level (`possession(Team,Role)`) | Team-level (`possession(Team)`) | **A** (player-level) | Enables pass/catch/kick preconditions cleanly |
| D6 | Demo scenario | Deterministic scripted opening → guaranteed goal | Fully emergent (random-ish) | **A** (scripted) | Protects the viva demo |
| D7 | Test harness | PLUnit file (`tests/test_robocup.pl`) | Manual scripted queries in README | **A** (PLUnit) | Matches course norms; ~1h to set up |
| D8 | Report prose source | Human-written from bullet outline | Subagent draft then human edit | **A** (human-written) | AI-detection safety |

**Action**: team chats ✅/✏️/❌ per row before Phase 1 starts.

---

## Team-of-4 work split

Each student owns a section band of `robocup.pl` plus one support artefact. Subagents assist inside those bands but the human owner reviews, merges, and defends in viva.

| Person | Owns code sections | Owns docs | Viva questions they field |
|---|---|---|---|
| **P1** — World model | §1 Static facts, §2 Dynamic world model, §8 Simulator entry points | `docs/project-context.md`, `README.md` | Knowledge representation, dynamic predicates, simulation loop |
| **P2** — Behavior | §3 CSP, §4 FSM | `docs/viva_answers.md` (FSM + CSP rows) | Why FSM, why CSP, state tables |
| **P3** — Action + rules | §5 STRIPS, §6 role behaviors, §7 dynamics | `docs/viva_answers.md` (STRIPS + rules rows) | STRIPS preconditions/effects, stamina, goal detection |
| **P4** — Integration | Cross-section glue, merge coordination, `tests/test_robocup.pl` | `docs/report-outline.md`, `docs/floyd-*-summary.md` | Overall integration, tests, evaluation, limitations |

Integration windows: end of each phase, P4 runs the full smoke test and merges worktrees.

---

## Architecture

Single file `robocup.pl` organized in clearly labeled sections so parallel subagents can own distinct regions. Layered so each Symbolic-AI technique maps onto one layer:

```
┌─────────────────────────────────────────────────────────┐
│ Section 1. Static knowledge (facts)                     │
│   field/1, goal_position/2, kick_range/1, catch_range/1 │
├─────────────────────────────────────────────────────────┤
│ Section 2. Dynamic world model (assert/retract)         │
│   ball/1, player/4, score/2, possession/1, turn/1       │
├─────────────────────────────────────────────────────────┤
│ Section 3. CSP layer — initial formation                │
│   place_teams/0 with zone + spacing constraints         │
├─────────────────────────────────────────────────────────┤
│ Section 4. FSM layer — per-role state machines          │
│   state/3 (Team, Role, State), transition/4, tick_fsm/2 │
├─────────────────────────────────────────────────────────┤
│ Section 5. STRIPS layer — action schema                 │
│   action(Name, Preconds, Effects), applicable/2, apply/2│
│   Actions: move, kick, catch, pass                      │
├─────────────────────────────────────────────────────────┤
│ Section 6. Role behaviors (glue FSM → STRIPS)           │
│   act_goalkeeper/1, act_defender/1, act_forward/1       │
├─────────────────────────────────────────────────────────┤
│ Section 7. Dynamics & rules of the game                 │
│   stamina depletion, goal detection, reset, scoring     │
├─────────────────────────────────────────────────────────┤
│ Section 8. Simulator entry points                       │
│   simulate_round/0, run_simulation/1, print_state/0     │
└─────────────────────────────────────────────────────────┘
```

**Why this layering works**:
- CSP is used **once** at setup → self-contained, small.
- FSM **produces intents** ("chase the ball", "guard goal") based on sensed world.
- STRIPS **executes intents** by finding an applicable action whose preconditions hold, then applying effects. No planner — the FSM picks the next action each tick.
- Role behaviors are thin glue: FSM state → STRIPS action selection.
- Dynamics + simulator are orthogonal book-keeping.

**Acceptance criterion for the whole program**: `?- run_simulation(10).` runs 10 rounds, prints per-round world state, detects at least one goal in a deterministic scripted scenario, and terminates cleanly with a final score.

---

## Critical files

- `/Users/book/Documents/proj/robocup/robocup.pl` — **the submission** (to be created)
- `/Users/book/Documents/proj/robocup/docs/project-context.md` — **single source of truth** for subagents (created first, kept short)
- `/Users/book/Documents/proj/robocup/docs/report-outline.md` — report skeleton for humans to flesh out
- `/Users/book/Documents/proj/robocup/docs/viva_answers.md` — pre-drafted Q&A bank
- `/Users/book/Documents/proj/robocup/docs/floyd-2008-summary.md` — 1-page MD summary of Floyd 2008 for team reference
- `/Users/book/Documents/proj/robocup/docs/floyd-2012-summary.md` — 1-page MD summary of Floyd 2012
- `/Users/book/Documents/proj/robocup/docs/viva_explanations.md` — post-implementation walkthrough (NICE-TO-HAVE)
- `/Users/book/Documents/proj/robocup/README.md` — how to run: `swipl -s robocup.pl` then `?- run_simulation(10).`
- `/Users/book/Documents/proj/robocup/tests/test_robocup.pl` — PLUnit test harness

**Reference only** (don't edit, read for context):
- `/Users/book/Documents/proj/robocup/project` — partial earlier attempt
- `/Users/book/Documents/proj/robocup/memory/context.md` — partial report draft
- `/Users/book/Documents/proj/robocup/project-requirements/Symbolic_AI_group_project.pdf` — rubric
- `/Users/book/Documents/proj/robocup/project-requirements/materials/Michael_Floyd_RoboCup_*.pdf` — background

---

## Feature backlog

Tasks are self-contained (each includes the file path, what-to-change, and acceptance criteria) so a subagent can be dispatched with just the task body. Tasks are grouped into phases; each phase is a sync point. Within a phase, tasks marked **‖ parallel** can run concurrently using git worktrees; tasks marked **⇢ sequential** must run in listed order (they touch the same section).

### Phase 0 — Context + skeleton (blocking, ~1.5 hours)

**T0.0 — Create `docs/project-context.md`** ⇢ first (blocks every subagent)
- Output: `docs/project-context.md` — concise single source of truth reused by every subagent prompt to save tokens.
- Required contents: (1) project goal in 5–10 lines, (2) locked decisions (D1–D8 once team ratifies), (3) non-goals (DO-NOT-BUILD list above), (4) architecture diagram, (5) canonical data representation (`player(Team,Role,pos(X,Y),Stamina)` etc.), (6) shared predicate contracts, (7) file/section ownership table, (8) current phase/backlog status pointer, (9) open decisions, (10) verification commands, (11) viva-critical justification points.
- Acceptance: file ≤150 lines, every subagent prompt can include `Read docs/project-context.md first` instead of restating context.

**T0.1 — Convert Floyd PDFs to 1-page MD summaries** ‖ parallel
- Output: `docs/floyd-2008-summary.md`, `docs/floyd-2012-summary.md`
- Scope: For each PDF, produce ≤1 page of markdown covering (a) RoboCup architecture (server/clients/monitor, 100ms cycle, actions: dash/turn/kick/catch), (b) which aspects we deliberately simplify in our symbolic version, (c) which example teams (Sprinter/Tracker/Krislet/NoSwarm/CMUnited) inspire our role behaviors.
- Acceptance: both files exist, each ≤1 page, no copy-paste of PDF prose.

**T0.2 — Create `robocup.pl` skeleton + section markers + dynamic declarations** ⇢ after T0.0 (blocks everything else)
- Output: `robocup.pl` with `% === Section N. <title> ===` banners matching the 8 sections above, plus `:- dynamic` declarations for every dynamic predicate used anywhere in the codebase (declared once, centrally, to kill the dep cycle):
  - `:- dynamic ball/1.`
  - `:- dynamic player/4.` — `player(Team, Role, pos(X,Y), Stamina)`
  - `:- dynamic score/2.`
  - `:- dynamic possession/2.` — `possession(Team, Role)` or `possession(none, none)`
  - `:- dynamic turn/1.`
  - `:- dynamic current_state/3.` — `current_state(Team, Role, State)`
  - `:- dynamic metric/3.` — optional counters
- Module-level comments only; no predicate bodies yet.
- Acceptance: `swipl -s robocup.pl` loads without warnings; `listing.` shows all dynamic predicates; no predicate used later is undeclared.

### Phase 1 — Static core + CSP (after T0.2, ~2 hours)

**T1.1 — Static facts + sensor helpers (Section 1)** ⇢ sequential (blocks CSP)
- File: `robocup.pl`, Section 1.
- Content: `field(size(100,50))`, `goal_position(team1, rect(0,20,0,30))`, `goal_position(team2, rect(100,20,100,30))`, `kick_range(10)`, `catch_range(2)`, `move_step(1)`, `stamina_init(4000)`, `stamina_cost_move(10)`, `stamina_cost_kick(20)`.
- Sensor helpers (also Section 1): `ball_close/2`, `in_kick_range/2`, `in_catch_range/2`, `ball_in_own_half/1`, `has_possession/2`, `can_shoot/1`, `can_pass/2`. These read `player/4`, `ball/1`, `possession/2` — no mutation.
- Acceptance: `?- field(F), kick_range(K).` returns bindings. `?- has_possession/2` defined even if nothing currently holds possession.

**T1.2 — CSP initial formation (Section 3)** ⇢ after T1.1
- File: `robocup.pl`, Section 3. **Showcase: CSP** — use `library(clpfd)`.
- Predicate: `place_teams/0` (joint placement of both teams so cross-team constraints can be stated). Constraints:
  - goalkeepers within own penalty zone,
  - defenders in own half,
  - forwards past own team's midline (i.e. near opposing half),
  - pairwise Manhattan distance ≥ 15 within a team,
  - cross-team: no player on the center spot (50,25),
  - all within field bounds.
- Labeling: `labeling([ff], Vars)` — pick first solution; document the heuristic choice in the section header comment.
- Export: `setup_world/0` that retracts all dynamic facts, asserts ball at (50,25), calls `place_teams/0`, sets `score(team1,0)`, `score(team2,0)`, `possession(none,none)`, `turn(team1)`, and `current_state(Team,Role,InitialState)` for all 6 player-role slots.
- Acceptance: `?- setup_world.` is deterministic and `?- findall(P, player(team1,_,P,_), Ps).` returns 3 positions satisfying the constraints above. Report-ready: the CSP is described as "domain = field cells; constraints = role-zones + min spacing + center-spot exclusion; labeling = first-fail".
- **Fallback (D3)**: if clpfd debugging exceeds 1h, swap to hard-coded positions: `player(team1, goalkeeper, pos(5,25), 4000).` etc. Note the fallback in `docs/viva_answers.md`.

### Phase 2 — Symbolic engines (after Phase 1, can parallelize, ~4 hours)

**T2.1 — FSM layer (Section 4)** ‖ parallel with T2.2
- File: `robocup.pl`, Section 4. **Showcase: FSM.**
- States per role:
  - Goalkeeper: `guard_goal`, `chase_ball`, `hold_ball`
  - Defender: `hold_line`, `intercept`, `pass_to_forward`
  - Forward: `advance`, `chase_ball`, `shoot`
- Predicates: `current_state/3` (already declared in T0.2), `transition(Role, FromState, Condition, ToState)` (static facts), `tick_fsm(Team,Role)` which reads world via Section 1 sensors and applies one transition.
- Conditions use ONLY sensor predicates defined in T1.1 (`has_possession/2`, `ball_in_own_half/1`, `ball_close/2`, etc.) — no direct reads of `player/4` / `ball/1` here.
- Acceptance: `?- tick_fsm(team1, forward).` progresses state given a scripted world; `listing(transition/4)` shows a readable table. Report-ready: one transition table per role.

**T2.2 — STRIPS action schema (Section 5)** ‖ parallel with T2.1
- File: `robocup.pl`, Section 5. **Showcase: STRIPS** (schema only — no planner, actions are selected per-tick by FSM).
- Representation: `action(Name, Actor, Preconds, Effects)` where Preconds/Effects are lists of world-literals (`at(Actor,Pos)`, `ball_at(Pos)`, `possesses(Actor)`, `stamina_ge(Actor,N)`).
- Four actions: `move_step(Actor, Dir)`, `kick(Actor, TargetPos)`, `catch(Actor)`, `pass(Actor, Teammate)`.
- Meta-predicates: `applicable(Action, World)`, `apply_effects(Action)` (asserts/retracts to mutate dynamic facts), `do_action(Action)` = applicable + apply + log.
- Preconditions for `kick` and `pass` check `has_possession(Actor)`; `catch` sets possession; `move_step` while in possession moves the ball with the carrier.
- Acceptance: `?- do_action(kick(player(team1,forward), position(60,25))).` succeeds only when preconditions hold and correctly updates ball + stamina. Scripted test: `kick` fails when actor lacks possession. Report-ready: a preconditions/effects table for each action.

### Phase 3 — Role behaviors (after Phase 2, ~2 hours)

Each of these glues FSM state → STRIPS action. Same file, **adjacent** sections — run **sequentially** to avoid merge conflicts, or use worktrees and merge at the end of the phase.

**T3.1 — Goalkeeper behavior** ⇢
- Predicate: `act_goalkeeper(Team)` — reads FSM state, picks an action via STRIPS, executes.
- Must include: catch when ball enters `catch_range`; reset ball (kick to midfield) after catch; stay near own goal otherwise.

**T3.2 — Defender behavior** ⇢
- Predicate: `act_defender(Team)` — intercept if ball in own half (compute intercept point on line from ball to own goal); pass forward once in possession; else hold formation line.

**T3.3 — Forward behavior** ⇢
- Predicate: `act_forward(Team)` — chase ball when not in possession; kick toward opponent goal when in range; account for stamina (skip action if exhausted).

Shared acceptance: each predicate is `nondet`-free, logs one `format/2` line per action, gracefully succeeds with `true` when no action applies.

### Phase 4 — Dynamics (after Phase 3, partially parallel, ~2 hours)

> **Note**: possession is **not** a Phase 4 feature. It is declared in T0.2 and integrated into STRIPS preconditions in T2.2. Phase 4 only adds stamina, goal detection, turn order, and pauses.

**T4.1 — Movement + stamina depletion** ⇢ (integrates into STRIPS `move_step`)
- Location: inside `apply_effects/1` for `move_step`. Deduct `stamina_cost_move`. Refuse action if `stamina < cost`.
- Acceptance: after 50 `move_step` applications on one player starting at 4000, stamina = 3500.

**T4.2 — Goal detection + scoring + reset** ‖ parallel with T4.3/T4.4
- File: Section 7. Predicate: `check_goal/0` — if ball inside a `goal_position` rectangle, increment the *opponent's* score (team whose goal the ball entered conceded; scoring team is the one attacking that goal), print celebration line, call `setup_world/0` to reset.
- Acceptance: scripted test where ball is asserted at (0,25) → team2's score increments.

**T4.3 — Alternating turn order** ‖ parallel
- File: Section 7. Predicate: `next_turn/0` — strict alternation. If `turn(team1)` → retract, assert `turn(team2)`. (Randomized version deferred — see D4.)
- Acceptance: `next_turn` toggles and prints.

**T4.4 — Pauses between rounds** ‖ parallel
- File: Section 8. Insert `sleep(0.3)` at end of `simulate_round/0` for readability.
- Acceptance: `run_simulation(3)` has visible pacing.

### Phase 5 — Simulator glue (after Phase 4, ~1 hour)

**T5.1 — `simulate_round/0`** ⇢
- Body: `next_turn`, for each role on both teams (in turn order): `tick_fsm` then `act_<role>`; then `check_goal`, then `print_state`, then `sleep`.
- Acceptance: one call prints exactly one round's events in order.

**T5.2 — `run_simulation(N)`** ⇢ after T5.1
- Recursive: `run_simulation(0) :- print_final_score.` and `run_simulation(N) :- N>0, simulate_round, N1 is N-1, run_simulation(N1).`
- Must include `setup_world` on first call (use `run_simulation(N) :- setup_world, loop(N).` pattern so nested calls don't reset).
- Acceptance: `?- run_simulation(10).` runs to completion, prints final score.

### Phase 6 — Tests & metrics (after Phase 5, ~2 hours)

**T6.1 — PLUnit test harness + scripted goal scenario** ‖ parallel with T6.2
- File: `tests/test_robocup.pl`. Use `:- begin_tests(robocup).`
- Scenarios:
  1. Scripted ball at (9,25) → `check_goal` registers a team2 goal.
  2. Stamina starts at 4000, after 50 `move_step` applications = 3500.
  3. CSP `place_teams` output satisfies inter-team spacing.
  4. STRIPS `kick` fails when actor lacks possession.
  5. **Scripted opening** (D6): after `setup_world`, assert a specific overrides (`retract(player(team1,forward,_,_)), assert(player(team1,forward,pos(80,25),4000)), retract(ball(_)), assert(ball(pos(80,25))), assert(possession(team1,forward))`), then `run_simulation(3)` → team1 score ≥ 1.
- Acceptance: `?- run_tests.` passes all 5 scenarios.

**T6.2 — Metrics logging** ‖ parallel with T6.1
- File: Section 7 of `robocup.pl`. Use `metric/3` already declared in T0.2. Increment in respective effect predicates.
- End-of-game `print_summary/0` prints a scoreboard + metrics (goals, kicks, catches).
- Acceptance: after `run_simulation(20)`, summary shows non-zero kicks and the goals that happened.

### Phase 7 — Documentation (after Phase 6, ~2.5 hours)

**T7.0 — Viva answer bank** ⇢ can run parallel with T7.1
- File: `docs/viva_answers.md`. One row per question, 2–4 short bullet answers in plain student language (NOT polished prose).
- Required questions (from `plan/claude_prompt.txt`):
  1. Why represent players/ball with `player/4` + `ball/1`?
  2. Why use dynamic predicates (assert/retract)?
  3. Why FSM for role behavior?
  4. Why STRIPS-style action schema (and why no planner)?
  5. Why CSP for initial placement (or: why the fallback to fixed positions)?
  6. Why text-based simulation, not a GUI?
  7. Why discrete positions instead of continuous movement?
  8. Why alternating turns instead of random?
  9. Why player-level possession?
  10. Strengths and limitations of the solution?
  11. What would we improve given more time?
- Acceptance: every row has a 1-line answer + 2-sentence elaboration. Tone = student understanding, not academic prose.

**T7.1 — Report outline** ⇢ sequential (one subagent writes bullets, humans fill prose)
- File: `docs/report-outline.md`. 5-page target → word-count budget:
  1. Introduction (~¾ page: RoboCup as benchmark, why symbolic)
  2. Symbolic representations (~¾ page: layered architecture, Section 1–2 citations)
  3. Strategies & rationale (~2½ pages total — ~¾ page each):
     - CSP for initial formation (constraints table, labeling heuristic)
     - FSM for role behavior (transition tables per role)
     - STRIPS for action execution (preconditions/effects table per action)
  4. Evaluation (~½ page: metrics from T6.2, sample run output, strengths, weaknesses)
  5. Limitations & future work (~½ page: noisy sensing, more players, learning)
- Each section: bullet points + direct code references (line numbers once code is final). Humans expand into prose.
- Acceptance: outline has ~80 substantive bullets across sections; every section has at least one code reference with file:line; word-count budgets noted per section.

**T7.2 — Code comment pass** ⇢ last
- File: `robocup.pl`. Every top-level predicate has a one-line header comment stating purpose + args. Each section banner has a 2-line rationale.
- Acceptance: grep over `robocup.pl` shows ≥1 comment per top-level predicate; `grep -c "^%" robocup.pl` ≥ 30.

**T7.3 — README with run instructions** ‖ parallel with T7.2
- File: `README.md`. Contents: prereqs (SWI-Prolog 9.x), how to run the sim, how to run tests, quick glossary of predicates.
- Acceptance: a teammate who clones the repo can run the sim from README alone.

**T7.4 — Post-implementation viva walkthrough** (NICE-TO-HAVE) ‖ parallel with T7.2/T7.3
- File: `docs/viva_explanations.md`. Walkthrough per Section of `robocup.pl` using the correct technical terms in simple student language: knowledge representation → dynamic world state → FSM → STRIPS → possession/scoring → stamina → simulation loop → design choices → limitations → improvements → Q&A.
- Acceptance: file exists, each Section of `robocup.pl` has a 2–3 paragraph walkthrough.
- Skip if total remaining time at start of Phase 7 is < 8h.

---

## Dependency graph (for dispatching subagents)

```
T0.0 ─► T0.2 ─┬─► T1.1 ─► T1.2 ─┬─► T2.1 ┐
T0.1 ─────────┘                 │        ├─► T3.1 ─► T3.2 ─► T3.3 ─┬─► T4.1 ─► T5.1 ─► T5.2 ─► T6.1 ─┬─► T7.0 ─► T7.1 ─► T7.2
                                └─► T2.2 ┘                        ├─► T4.2 ┘                 T6.2 ──┘         └─► T7.3
                                                                  ├─► T4.3                                    └─► T7.4 (nice-to-have)
                                                                  └─► T4.4
```

### Parallelizable checkpoints
- After **T0.0**: T0.1 runs alongside code tasks; T0.2 starts immediately.
- After **T1.2**: T2.1 and T2.2 run in parallel (separate sections, can use worktrees).
- After **T3.3**: T4.2, T4.3, T4.4 run in parallel.
- Phase 6: T6.1 and T6.2 run in parallel.
- Phase 7: T7.0 runs parallel with T7.1; T7.2 / T7.3 / T7.4 all run parallel after T7.1.

### Subagent dispatch recipe
Each task dispatched via the Agent tool with a self-contained prompt of the shape:

> **Read `docs/project-context.md` first.** Your task is `[T-id: title]`. **Edit only** Section N of `robocup.pl` (or the specific doc file named). **Acceptance**: [criteria from backlog]. **Do not** modify other sections or redefine predicates declared in T0.2. **Style**: each predicate gets a one-line header comment; plain Prolog, no meta-programming, no obscure tricks. **Consistency check before finishing**: Does this still match the global architecture? Does this change shared predicate signatures? Does this create a conflict with another section? Does this make the final report harder to explain? Is this still the simplest adequate solution?

For parallel groups, use `isolation: "worktree"` so each agent gets an isolated copy; merge their outputs between phases (P4 owns the merge window).

---

## Verification (how we know it works)

**Local smoke test** (run after every phase):
```
$ swipl -s robocup.pl
?- setup_world.
?- run_simulation(5).
?- listing(score/2).
```

**Full verification** (before submission):
1. `swipl -s robocup.pl -g "run_simulation(20)" -t halt` — runs without errors, prints rounds + final score.
2. `swipl -s robocup.pl -g "consult('tests/test_robocup.pl'), run_tests, halt"` — all 5 PLUnit scenarios pass, including the scripted-goal scenario (T6.1 scenario 5).
3. Grep check: `grep -c "^%" robocup.pl` ≥ 30 (proxy for documentation density).
4. Report outline: `wc -l docs/report-outline.md` ≥ 80 (substantive bullets); every section has at least one code reference; word-count budgets respected.
5. Viva bank: all 11 rows in `docs/viva_answers.md` have content.
6. Final sanity: open `robocup.pl` and confirm the 8 section banners are present and in order.

**Deliverable checklist**:
- [ ] `docs/project-context.md` — single source of truth
- [ ] `robocup.pl` — single file, loads cleanly, `run_simulation/1` works
- [ ] `tests/test_robocup.pl` — 5 scenarios, all pass
- [ ] `docs/report-outline.md` — 5-page outline with bullets per section, word-count budgets noted
- [ ] `docs/viva_answers.md` — 11 Q&As in student language
- [ ] `docs/floyd-2008-summary.md`, `docs/floyd-2012-summary.md` — reference summaries
- [ ] `README.md` — run instructions
- [ ] `docs/viva_explanations.md` (NICE-TO-HAVE) — post-implementation walkthrough
- [ ] Humans convert outline → prose → WORD + PDF before the Sunday deadline

---

## Risks & fallback plan

| Risk | Likelihood | Impact | Mitigation / fallback |
|---|---|---|---|
| `clpfd` constraints take > 1h to debug | Medium | Delays Phase 2 | **D3 fallback**: swap `place_teams/0` for hard-coded positions; keep the report section but reframe as "fixed initial formation; CSP was attempted and is documented below." |
| Merge conflicts in `robocup.pl` during Phase 4 | Medium | Delays Phase 5 | Worktrees per task; P4 merges at every phase boundary with smoke test before moving on. |
| `run_simulation(10)` finishes 0–0 in the demo | High (default) | Weakens viva | Scripted opening (T6.1 scenario 5) guarantees ≥1 goal; always demo via the scripted opening, not `setup_world` + `run_simulation(10)`. |
| Team member blocked on a section they own | Medium | Stalls a phase | Subagent dispatches the task; owner reviews instead of writes. Reassign via P4 if needed. |
| Report sounds AI-written | Medium | AI-detection risk → grade hit | Outline is bullets only (T7.1); humans write prose from scratch; two-pass review per section before submission. |
| Time overrun past Saturday evening | Medium | Submission risk | Drop NICE-TO-HAVE items (T7.4, extra evaluation scenario). Submission with MUST + most SHOULD is acceptable. |
| Live viva question about GPS / planning (absent from our code) | Medium | Answer gap | Pre-draft in `docs/viva_answers.md`: "We chose STRIPS schemas without a planner because per-tick FSM action selection is enough for this domain and is easier to explain. A real planner would be the natural next step — see Section 5 docstring." |
| SWI-Prolog version mismatch on a teammate's machine | Low | Local dev blocker | README pins 9.x; anyone on older version uses `swipl --version` check in README. |

**Hard stop rule**: at **Saturday 18:00** (Sunday midnight minus 30h), whatever state `robocup.pl` is in becomes the submission candidate. From then on: only bugfixes + report prose, no new features.
