# RoboCup Symbolic-AI Prolog — Project Partition & Feature Backlog

## Context

**What**: Group course project: implement a simplified RoboCup soccer simulation in SWI-Prolog, showcasing Symbolic AI (not the sub-symbolic CBR approach described in the Floyd papers). Single file `robocup.pl` + 5-page report (WORD+PDF).

**Why**: Evaluated on proficiency in Symbolic AI + Logic Programming. The rubric rewards explicit use of course-taught techniques (GPS, STRIPS, FSM, CSP, Tic-Tac-Toe, 8-Puzzle, Sudoku…). The Floyd papers outline the *benchmark domain*; we implement a *symbolic-AI rendition* of it.

**When**: Deadline is 12:00 midnight Sunday 19 April 2026. Today is 17 April — **~56 hours remaining**.

**Outcome expected**: A working `swipl` program where `?- run_simulation(N).` runs `N` rounds between two 3-player teams with role-based behavior, stamina, possession, goal detection, scoring, position reset, and pauses — with the code organized around three named Symbolic-AI techniques so the report rationale writes itself.

**Decisions already made** (from brainstorm):
- Scope = Option B (minimum viable + strong symbolic emphasis, no GUI bonus)
- Techniques to showcase = **FSM + STRIPS + CSP**
- Dialect = **SWI-Prolog**
- Starting point = **Full rewrite** for coherence (existing `project` file becomes reference material only)
- Report = subagent produces **outline + bullet sections**; humans write prose (AI-detection safety)
- Delegation target = **Claude subagents (autonomous)** — each backlog task must be self-contained

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
│   place_team/1 with zone + spacing constraints          │
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
- STRIPS **executes intents** by finding an applicable action whose preconditions hold, then applying effects.
- Role behaviors are thin glue: FSM state → STRIPS action selection.
- Dynamics + simulator are orthogonal book-keeping.

**Acceptance criterion for the whole program**: `?- run_simulation(10).` runs 10 rounds, prints per-round world state, detects at least one goal in a deterministic scripted scenario, and terminates cleanly with a final score.

---

## Critical files

- `/Users/book/Documents/proj/robocup/robocup.pl` — **the submission** (to be created)
- `/Users/book/Documents/proj/robocup/docs/report-outline.md` — report skeleton for humans to flesh out
- `/Users/book/Documents/proj/robocup/docs/floyd-2008-summary.md` — 1-page MD summary of Floyd 2008 for team reference
- `/Users/book/Documents/proj/robocup/docs/floyd-2012-summary.md` — 1-page MD summary of Floyd 2012
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

### Phase 0 — Background & skeleton (blocking, ~1 hour)

**T0.1 — Convert Floyd PDFs to 1-page MD summaries** ‖ parallel
- Output: `docs/floyd-2008-summary.md`, `docs/floyd-2012-summary.md`
- Scope: For each PDF, produce ≤1 page of markdown covering (a) RoboCup architecture (server/clients/monitor, 100ms cycle, actions: dash/turn/kick/catch), (b) which aspects we deliberately simplify in our symbolic version, (c) which example teams (Sprinter/Tracker/Krislet/NoSwarm/CMUnited) inspire our role behaviors.
- Acceptance: both files exist, each ≤1 page, no copy-paste of PDF prose.

**T0.2 — Create `robocup.pl` skeleton + section markers** ⇢ first (blocks everything else)
- Output: `robocup.pl` with `% === Section N. <title> ===` banners matching the 8 sections above, plus `:- dynamic` declarations and module-level comments. No predicate bodies yet beyond `:- dynamic ball/1.` etc.
- Acceptance: `swipl -s robocup.pl` loads without warnings; `listing.` shows the dynamic predicates.

### Phase 1 — Static core + CSP (after T0.2, ~2 hours)

**T1.1 — Static facts (Section 1)** ⇢ sequential (blocks CSP)
- File: `robocup.pl`, Section 1.
- Content: `field(size(100,50))`, `goal_position(team1, rect(0, 20, 0, 30))`, `goal_position(team2, rect(100,20, 100,30))`, `kick_range(10)`, `catch_range(2)`, `move_step(1)`, `stamina_init(4000)`, `stamina_cost_move(10)`, `stamina_cost_kick(20)`.
- Acceptance: `?- field(F), kick_range(K).` returns bindings.

**T1.2 — CSP initial formation (Section 3)** ⇢ after T1.1
- File: `robocup.pl`, Section 3. **Showcase: CSP** — use `library(clpfd)`.
- Predicate: `place_team(Team)` with constraints: goalkeeper within own penalty zone, defender in own half, forward past midline, pairwise Manhattan distance ≥ 15, all within field bounds.
- Export: `setup_world/0` that retracts then asserts ball at (50,25), calls `place_team(team1)`, `place_team(team2)`, sets `score(team1,0), score(team2,0), possession(none), turn(team1)`.
- Acceptance: `?- setup_world.` is deterministic (pick first solution) and `?- findall(P, player(team1,_,P,_), Ps).` returns 3 positions satisfying the constraints above. Report-ready: the CSP can be described as "domain = field cells; constraints = role-zones + min spacing".

### Phase 2 — Symbolic engines (after Phase 1, can parallelize, ~4 hours)

**T2.1 — FSM layer (Section 4)** ‖ parallel with T2.2
- File: `robocup.pl`, Section 4. **Showcase: FSM.**
- States per role:
  - Goalkeeper: `guard_goal`, `chase_ball`, `hold_ball`
  - Defender: `hold_line`, `intercept`, `pass_to_forward`
  - Forward: `advance`, `chase_ball`, `shoot`
- Predicates: `current_state(Team,Role,State)` (dynamic), `transition(Role, FromState, Condition, ToState)` (static facts), `tick_fsm(Team,Role)` which reads world and applies one transition.
- Conditions are sensed facts: `ball_in_own_half/1`, `ball_close/2`, `has_possession/2`, etc.
- Acceptance: `?- tick_fsm(team1, forward).` progresses state given a scripted world; `listing(transition/4)` shows a readable table. Report-ready: one transition table per role.

**T2.2 — STRIPS action schema (Section 5)** ‖ parallel with T2.1
- File: `robocup.pl`, Section 5. **Showcase: STRIPS.**
- Representation: `action(Name, Actor, Preconds, Effects)` where Preconds/Effects are lists of world-literals (`at(Actor,Pos)`, `ball_at(Pos)`, `possesses(Actor)`, `stamina_ge(Actor,N)`).
- Four actions: `move_step(Actor, Dir)`, `kick(Actor, TargetPos)`, `catch(Actor)`, `pass(Actor, Teammate)`.
- Meta-predicates: `applicable(Action, World)`, `apply_effects(Action)` (asserts/retracts to mutate dynamic facts), `do_action(Action)` = applicable + apply + log.
- Acceptance: `?- do_action(kick(player(team1,forward), position(60,25))).` succeeds only when preconditions hold and correctly updates ball + stamina. Report-ready: a preconditions/effects table for each action.

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

### Phase 4 — Dynamics (after Phase 3, partially parallel, ~3 hours)

**T4.1 — Movement + stamina depletion** ⇢ (integrates into STRIPS `move_step`)
- Location: inside `apply_effects/1` for `move_step`. Deduct `stamina_cost_move`. Refuse action if `stamina < cost`.

**T4.2 — Goal detection + scoring + reset** ‖ parallel with T4.3/T4.4
- File: Section 7. Predicate: `check_goal/0` — if ball inside a `goal_position` rectangle, increment the *opponent's* score (team whose goal the ball entered scored AGAINST them — scoring team is the one attacking that goal), print celebration line, call `setup_world/0` to reset.
- Acceptance: scripted test where ball is asserted at (0,25) → team2's score increments.

**T4.3 — Turn order (randomized/alternating)** ‖ parallel
- File: Section 7. Predicate: `next_turn/0` uses `random_member/2` among both teams to pick who moves first in the round. Alternative: strict alternation if `turn(team1)` → `turn(team2)`.
- Acceptance: `:- use_module(library(random)).` added; `next_turn` toggles and prints.

**T4.4 — Pauses between rounds** ‖ parallel
- File: Section 8. Insert `sleep(0.3)` at end of `simulate_round/0` for readability.
- Acceptance: `run_simulation(3)` has visible pacing.

**T4.5 — Ball possession** ⇢ (cross-cutting — integrates into STRIPS preconditions)
- Add `possession(Team,Role)` fact. `kick` and `pass` preconditions require `possession(Actor)`. `catch` sets possession. Moving while in possession moves the ball with the carrier.

### Phase 5 — Simulator glue (after Phase 4, ~1 hour)

**T5.1 — `simulate_round/0`** ⇢
- Body: `next_turn`, for each role on both teams (in turn order): `tick_fsm` then `act_<role>`; then `check_goal`, then `print_state`, then `sleep`.
- Acceptance: one call prints exactly one round's events in order.

**T5.2 — `run_simulation(N)`** ⇢ after T5.1
- Recursive: `run_simulation(0) :- print_final_score.` and `run_simulation(N) :- N>0, simulate_round, N1 is N-1, run_simulation(N1).`
- Must include `setup_world` on first call (use `run_simulation(N) :- setup_world, loop(N).` pattern so nested calls don't reset).
- Acceptance: `?- run_simulation(10).` runs to completion, prints final score.

### Phase 6 — Tests & metrics (after Phase 5, ~2 hours)

**T6.1 — PLUnit test harness** ‖ parallel with T6.2
- File: `tests/test_robocup.pl`. Use `:- begin_tests(robocup).`
- Scenarios: (1) scripted ball at (9,25) → team2 goal should register; (2) stamina starts at 4000, after 50 moves should be 3500; (3) CSP `place_team` satisfies spacing; (4) STRIPS `kick` fails when no possession.
- Acceptance: `?- run_tests.` passes all.

**T6.2 — Metrics logging** ‖ parallel with T6.1
- File: Section 7 of `robocup.pl`. Add dynamic counters: `metric(goals,T,N), metric(kicks,T,N), metric(catches,T,N)`. Increment in respective effect predicates.
- End-of-game `print_summary/0` prints a scoreboard + metrics.
- Acceptance: after `run_simulation(20)`, summary shows non-zero kicks and at least the goals that happened.

### Phase 7 — Documentation (after Phase 6, ~2 hours)

**T7.1 — Report outline** ⇢ sequential (one subagent writes, humans fill prose)
- File: `docs/report-outline.md`. Structure:
  1. Introduction (RoboCup as benchmark, why symbolic)
  2. Symbolic representations (the layered architecture, citing Sections 1–2)
  3. Strategies & rationale — one subsection per technique:
     - CSP for initial formation (constraints table)
     - FSM for role behavior (transition tables per role)
     - STRIPS for action execution (preconditions/effects table per action)
  4. Evaluation (metrics from T6.2, sample run output, strengths, weaknesses)
  5. Limitations & future work (noisy sensing, more players, learning)
- Each section: bullet points + direct code references (line numbers once code is final). Humans expand into prose.
- Acceptance: outline fits a 5-page target when expanded; each code-reference has a concrete file/line citation.

**T7.2 — Code comment pass** ⇢ last
- File: `robocup.pl`. Every top-level predicate has a one-line header comment stating purpose + args. Each section banner has a 2-line rationale.
- Acceptance: `pldoc` or a grep over `robocup.pl` shows ≥1 comment per predicate.

**T7.3 — README with run instructions** ‖ parallel with T7.2
- File: `README.md`. Contents: prereqs (SWI-Prolog 9.x), how to run the sim, how to run tests, quick glossary of predicates.
- Acceptance: a teammate who clones the repo can run the sim from README alone.

---

## Dependency graph (for dispatching subagents)

```
T0.1 ─────────────────────┐                              (background, never blocks code)
T0.2 ─┬─► T1.1 ─► T1.2 ─┬─► T2.1 ┐
      │                 │        ├─► T3.1 ─► T3.2 ─► T3.3 ─► T4.1 ─► T4.5 ─► T5.1 ─► T5.2 ─► T6.1 ─┬─► T7.1 ─► T7.2
      │                 │        │                       ├─► T4.2 ┘                        T6.2 ──┘         └─► T7.3
      │                 │        │                       ├─► T4.3
      │                 └─► T2.2 ┘                       └─► T4.4
```

### Parallelizable checkpoints
- After **T0.2**: T0.1 runs alongside code tasks.
- After **T1.2**: T2.1 and T2.2 run in parallel (separate sections, can use worktrees).
- After **T3.3**: T4.2, T4.3, T4.4 run in parallel.
- Phase 6: T6.1 and T6.2 run in parallel.
- Phase 7: T7.2 and T7.3 run in parallel; T7.1 must precede them.

### Subagent dispatch recipe
Each task dispatched via the Agent tool with a self-contained prompt of the shape:

> Context: we're building `/Users/book/Documents/proj/robocup/robocup.pl` — a SWI-Prolog RoboCup simulation layered as [CSP, FSM, STRIPS, dynamics, simulator]. **Your task** is `[T-id: title]`. **Edit only** Section N of `robocup.pl`. **Acceptance**: [criteria from backlog]. **Do not** modify other sections. **Style**: each predicate gets a one-line header comment. Consult existing sections for data layout; do not redefine existing predicates.

For parallel groups, use `isolation: "worktree"` so each agent gets an isolated copy; merge their outputs between phases.

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
2. `swipl -s robocup.pl -g "consult('tests/test_robocup.pl'), run_tests, halt"` — all PLUnit tests pass.
3. Grep check: `grep -c "^%" robocup.pl` ≥ 30 (proxy for documentation density).
4. Report outline: `wc -l docs/report-outline.md` ≥ 80 (substantive bullets), every section has at least one code reference.
5. Final sanity: open `robocup.pl` and confirm the 8 section banners are present and in order.

**Deliverable checklist**:
- [ ] `robocup.pl` — single file, loads cleanly, `run_simulation/1` works
- [ ] `tests/test_robocup.pl` — passes
- [ ] `docs/report-outline.md` — 5-page outline with bullets per section
- [ ] `docs/floyd-2008-summary.md`, `docs/floyd-2012-summary.md` — reference summaries
- [ ] `README.md` — run instructions
- [ ] Humans convert outline → prose → WORD + PDF before the Sunday deadline
