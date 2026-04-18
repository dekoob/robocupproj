# RoboCup Symbolic-AI Prolog

Simplified RoboCup soccer simulation in SWI-Prolog. Two teams of three (goalkeeper, defender, forward) play on a discrete 100x50 field. Demonstrates three Symbolic-AI techniques explicitly:

- **CSP** — `library(clpfd)` constraints place players into legal formations at setup (`place_team/1`, `robocup.pl:66`).
- **FSM** — per-role state machines drive intent selection each tick (`tick_fsm/2`, `robocup.pl:291`).
- **STRIPS** — explicit precondition + effect schemas gate and execute every action (`applicable/2` + `apply_effects/1`, `robocup.pl:365`).

---

## Prerequisites

| Requirement | Version | Check |
|---|---|---|
| SWI-Prolog | 9.x (9.2 or later recommended) | `swipl --version` |

Install from <https://www.swi-prolog.org/Download.html>. The file uses `library(clpfd)` and `library(random)`, both bundled with SWI-Prolog 9.x.

---

## How to run the simulation

**Interactive (recommended for demos)**

```prolog
swipl -s robocup.pl
?- run_simulation(10).
```

**Single query from the toplevel**

```prolog
?- run_simulation(20).
```

**Batch (non-interactive, no prompt)**

```sh
swipl -s robocup.pl -g "run_simulation(20)" -t halt
```

Each call to `run_simulation(N)` runs `N` rounds. Output per round: FSM transitions, STRIPS actions taken, ball/player state snapshot, and goal events. Final score is printed after the last round.

---

## How to run the tests

```sh
swipl -s robocup.pl -g "consult('tests/test_robocup.pl'), run_tests, halt"
```

Expected result: **16 passed, 0 failed**.

The test file (`tests/test_robocup.pl`) uses the PLUnit harness and covers:

| Test | What it checks |
|---|---|
| `world_loads_cleanly` | `setup_world/0` asserts exactly 6 players |
| `scores_start_at_zero` | Both scores are 0 after setup |
| `ball_starts_at_midfield` | Ball at `position(50,25)` after setup |
| `possession_starts_none` | `possession(none,none)` after setup |
| `csp_spacing_team1` | team1 CSP positions are pairwise >= 15 apart (Manhattan) |
| `csp_spacing_team2` | team2 CSP positions are pairwise >= 15 apart (Manhattan) |
| `stamina_depletes_on_move` | One `move_step` deducts 10 stamina (4000 -> 3990) |
| `kick_fails_without_possession` | `kick` is a no-op when actor has no possession |
| `forward_cannot_catch` | `catch` precondition rejects non-goalkeeper roles |
| `goalkeeper_can_catch_when_ball_adjacent` | Goalkeeper catches ball within `catch_range(3)` |
| `goal_left_scores_for_team2` | Ball at `(0,25)` triggers team2 goal |
| `goal_right_scores_for_team1` | Ball at `(100,25)` triggers team1 goal |
| `check_goal_noop_at_midfield` | No goal at `(50,25)`; world unchanged |
| `run_simulation_completes_small_N` | `run_simulation(2)` terminates cleanly |
| `fsm_initial_states` | All 6 FSM slots start in the correct initial state |
| `stamina_depletes_over_50_moves` | 50 moves deduct 500 stamina (4000 -> 3500) |

---

## Predicate glossary

| Predicate | Arity | Section | Purpose |
|---|---|---|---|
| `setup_world` | 0 | 3 | Retract all dynamic state; CSP-place both teams; seed ball, scores, possession, turn, FSM. |
| `run_simulation` | 1 | 8 | Entry point. `setup_world` once, then loop N rounds, print final score. |
| `do_action` | 1 | 5 | Check STRIPS preconditions via `applicable/2`; if ok, call `apply_effects/1` and log one line. |
| `tick_fsm` | 2 | 4 | Read `current_state/3`; fire the first matching `transition/4`; update state. Args: `(Team, Role)`. |
| `check_goal` | 0 | 7 | If ball is inside any goal rectangle, increment attacker score, print celebration, call `setup_world`. |
| `print_summary` | 0 | 7 | Print final scoreboard and per-team kick/catch/goal metric counters. |

---

## File layout

| File | Description |
|---|---|
| `robocup.pl` | Single 778-line source file; 8 sections: static facts (1), dynamic world (2), CSP formation (3), FSM machines (4), STRIPS actions (5), role behaviors (6), game rules/metrics (7), simulator loop (8). |
| `tests/test_robocup.pl` | PLUnit harness; 16 tests covering setup, CSP, FSM, STRIPS, stamina, goal detection, and simulation completion. |
| `docs/` | Project context, report outline, viva answers, Floyd paper summaries. Read `docs/project-context.md` first. |
