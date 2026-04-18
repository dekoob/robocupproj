# Project Context — RoboCup Symbolic-AI Prolog

> Single source of truth for every subagent. Read this first. Then read the task body in `plan/project-partition.md`. Do not re-explain the project in task prompts — link here.

## 1. Project goal

A simplified RoboCup soccer simulation in **SWI-Prolog** that demonstrates Symbolic AI. Two teams of three (goalkeeper, defender, forward) on a discrete 100×50 field. The team runs `?- run_simulation(N).` and watches N rounds of role-based play with stamina, possession, goal detection, scoring, reset, and pauses. The evaluation rewards **explicit use of FSM + STRIPS + CSP**, not code cleverness. Output: single `robocup.pl` + 5-page human-written report. Deadline: 2026-04-19 midnight.

## 2. Locked decisions

- **Scope**: Option B — minimum viable + strong symbolic emphasis. No GUI.
- **Techniques**: FSM + STRIPS + CSP (one subsection in the report per technique).
- **Dialect**: SWI-Prolog 9.x. `library(clpfd)`, `library(random)` allowed.
- **Starting point**: Full rewrite. The file at repo root called `project` is reference only.
- **Delivery**: one `robocup.pl`, one `tests/test_robocup.pl`, report in WORD + PDF.
- **Report**: subagents produce bullets only; humans write prose (AI-detection safety).
- **Agent dispatch**: autonomous subagents in git worktrees, section-based ownership.
- **D1 Turn order**: **random** via `random_member/2` among both teams. Requires `:- use_module(library(random)).` Seed left unseeded for variety; tests that need determinism call `set_random(seed(42))` in their setup.
- **D2 CSP scope**: **formation-only at setup**. CSP appears exactly once, in `place_team/1`. No per-round replanning.
- **D3 Possession granularity**: **player-level** — `possession(Team, Role)`. Sentinel for loose ball: `possession(none, none)`. Matches partition §T4.5.
- **D4 Tests**: **PLUnit** harness at `tests/test_robocup.pl`.

## 3. Non-goals (do not build)

- GUI / graphics of any kind.
- Real RoboCup networking (server/client, UDP, monitor protocol).
- Real-time cycle simulation — rounds are discrete turns.
- Machine learning, probabilistic reasoning, case-based reasoning.
- Continuous physics, pathfinding beyond Manhattan, advanced planners.
- Multiple Prolog modules. One main file + one test file is enough.
- Opponent strategy modeling beyond the FSM rules.

## 4. Architecture overview

`robocup.pl` is a **single file** split into 8 numbered sections (`% === Section N. <title> ===` banners). One subagent owns one section at a time.

Layering: **CSP** runs once at setup. **FSM** picks intents per role each tick. **STRIPS** turns intents into legal actions whose preconditions hold. Dynamics/simulator are book-keeping.

Full diagram and rationale: see [plan/project-partition.md](../plan/project-partition.md) §Architecture. Do not recopy the diagram into task prompts — link it.

## 5. Canonical data representation

| Kind | Form | Where | Mutability |
|---|---|---|---|
| Field size | `field(size(100,50))` | Sec 1 | static |
| Goals | `goal_position(team1, rect(0,20,0,30))`, `goal_position(team2, rect(100,20,100,30))` | Sec 1 | static |
| Ranges | `kick_range(50)`, `catch_range(3)`, `move_step(5)` | Sec 1 | static |
| Stamina constants | `stamina_init(100)`, `stamina_cost_move(5)`, `stamina_cost_kick(10)` | Sec 1 | static |
| Ball | `ball(position(X,Y))` | Sec 2 | `:- dynamic` |
| Players | `player(Team, Role, position(X,Y), Stamina)` | Sec 2 | `:- dynamic` |
| Score | `score(Team, N)` | Sec 2 | `:- dynamic` |
| Possession | `possession(Team, Role)` — `possession(none, none)` when loose. | Sec 2 | `:- dynamic` |
| Turn | `turn(Team)` | Sec 2 | `:- dynamic` |
| FSM state | `current_state(Team, Role, State)` | Sec 4 | `:- dynamic` |
| FSM transitions | `transition(Role, FromState, Condition, ToState)` | Sec 4 | static |
| Metrics | `metric(kicks|catches|goals, Team, N)` | Sec 7 | `:- dynamic` |

`Team` is `team1` or `team2`. `Role` is `goalkeeper`, `defender`, or `forward`. Positions are integer pairs.

## 6. Shared predicate contracts

Cross-section surface. Do not change signatures without updating this file and notifying the team.

| Predicate | Semantics |
|---|---|
| `setup_world/0` | Retract all dynamic state, assert initial ball, call `place_team/1` for both teams, init score/possession/turn. Sec 3. |
| `place_team/1` | CSP placement for one team using clpfd. Sec 3. |
| `tick_fsm/2` — `tick_fsm(Team, Role)` | Read world, apply one transition, update `current_state/3`. Sec 4. |
| `applicable/2` — `applicable(Action, World)` | Check STRIPS preconditions. Sec 5. |
| `apply_effects/1` — `apply_effects(Action)` | Assert/retract to mutate world. Sec 5. |
| `do_action/1` — `do_action(Action)` | `applicable` + `apply_effects` + one `format/2` log line. Sec 5. |
| `act_goalkeeper/1`, `act_defender/1`, `act_forward/1` | Thin glue: FSM state → STRIPS action. Sec 6. |
| `check_goal/0` | If ball inside a goal rect, increment attacker's score, reset via `setup_world`. Sec 7. |
| `next_turn/0` | Pick next `turn/1` via `random_member([team1,team2], T)`; retract old fact, assert new one, log the pick. Sec 7. |
| `simulate_round/0` | One round: next_turn → for each role on each team (in turn order) tick_fsm + act_role → check_goal → print_state → sleep. Sec 8. |
| `run_simulation/1` — `run_simulation(N)` | Entry point. `setup_world` once, then loop N rounds, print final score. Sec 8. |
| `print_state/0`, `print_summary/0` | Console logging. Sec 8 / Sec 7. |

Sensed helpers used by FSM conditions: `ball_close/2`, `in_kick_range/2`, `in_catch_range/2`, `ball_in_own_half/1`, `has_possession/2`, `can_shoot/1`, `can_pass/2`. Defined in Sec 4 alongside the FSM.

## 7. File and section ownership

One task → one region. Parallel subagents must touch different rows.

| Task | File | Section | Agent |
|---|---|---|---|
| T0.1 | `docs/floyd-2008-summary.md`, `docs/floyd-2012-summary.md` | — | report-writer |
| T0.2 | `robocup.pl` | all banners only | prolog-coder |
| T1.1 | `robocup.pl` | Sec 1 | prolog-coder |
| T1.2 design | (notes) | — | symbolic-ai-architect |
| T1.2 code | `robocup.pl` | Sec 3 | prolog-coder |
| T2.1 design | (notes) | — | symbolic-ai-architect |
| T2.1 code | `robocup.pl` | Sec 4 | prolog-coder |
| T2.2 design | (notes) | — | symbolic-ai-architect |
| T2.2 code | `robocup.pl` | Sec 5 | prolog-coder |
| T3.1/T3.2/T3.3 | `robocup.pl` | Sec 6 | prolog-coder (sequential) |
| T4.1 | `robocup.pl` | Sec 5 edit to `apply_effects` | prolog-coder |
| T4.2/T4.3/T4.4 | `robocup.pl` | Sec 7 / Sec 8 | prolog-coder (parallel, distinct predicates) |
| T4.5 | `robocup.pl` | Sec 5 preconds + Sec 2 fact | prolog-coder |
| T5.1/T5.2 | `robocup.pl` | Sec 8 | prolog-coder |
| T6.1 | `tests/test_robocup.pl` | — | prolog-test-engineer |
| T6.2 | `robocup.pl` | Sec 7 | prolog-coder |
| T7.1 | `docs/report-outline.md` | — | report-writer |
| T7.2 | `robocup.pl` | comments only | prolog-coder |
| T7.3 | `README.md` | — | report-writer |
| Any phase boundary | — | — | prolog-reviewer (read-only) |

## 8. Current phase and backlog status

- Nothing built. `robocup.pl` does not exist. `tests/` does not exist. `docs/` contains only this file.
- **Next dispatch**: T0.1 (report-writer) ∥ T0.2 (prolog-coder). T0.2 blocks every Phase 1+ code task.
- **Phase 0 exit**: `swipl -s robocup.pl` loads without warnings; two Floyd summaries exist.

## 9. Open decisions requiring team approval

All resolved 2026-04-17 — see §2 for locked values. D1 = B (random), D2 = A (formation-only), D3 = B (player-level), D4 = A (PLUnit). No open decisions remain.

## 10. Verification commands

```
swipl -s robocup.pl                            % smoke load
?- setup_world, run_simulation(5).             % interactive run
swipl -s robocup.pl -g "run_simulation(20)" -t halt        % batch run
swipl -s robocup.pl -g "consult('tests/test_robocup.pl'), run_tests, halt"
```

Doc density proxy: `grep -c "^%" robocup.pl` ≥ 30. Report outline: `wc -l docs/report-outline.md` ≥ 80.

## 11. Viva-critical justification points

Short student-tone answers for the oral. One line each.

- **Why Prolog?** Natural fit for symbolic knowledge and rule-based reasoning; the assignment targets logic programming.
- **Why dynamic predicates for world state?** Mutable world is the simplest correct model of a changing game; `assert/retract` makes it one-line-per-change.
- **Why FSM for roles?** Each role has a small, nameable set of intents — a transition table is the most readable representation.
- **Why STRIPS for actions?** Gives preconditions and effects as explicit lists; the action table is the rubric-friendly deliverable.
- **Why CSP only at setup?** Initial placement has real constraints (zones, spacing); per-round CSP would be overkill and hard to justify.
- **Why discrete positions?** Continuous physics adds no symbolic value; discrete ones make constraints and preconditions trivial.
- **Why random turn order?** Simulates the unpredictability of a real match kickoff; `random_member/2` is one line; tests pin the seed when they need determinism.
- **Why player-level possession?** Role-specific action gating is cleaner: goalkeeper catches, forward shoots, defender passes — the precondition is a match on `possession(Team, Role)`, not a separate lookup.
- **Why a single file?** Reduces cognitive load for four students under deadline; the course does not reward module architecture.
- **Limitations / future work?** Noisy sensing, more than three players per team, learned role policies.

---

### Known paper-cuts (do not fix now, just be aware)

- `plan/project-partition.md` uses Mac paths (`/Users/book/...`). The real workspace is `c:\Users\dimik\Workspace\robocupproj\`. Translate when dispatching.
- `plan/project-partition.md` §Architecture Section 2 row still shows `possession/1`; the locked shape is `possession(Team, Role)` (matches §T4.5). This file is the source of truth — update partition.md next time someone edits it.
