# Project Context — RoboCup Symbolic-AI Prolog

Single source of truth for all subagents. **Read this first** before any task. Kept intentionally short; the full backlog lives in [../plan/project-partition.md](../plan/project-partition.md).

---

## 1. Project goal

Simplified RoboCup soccer simulator in SWI-Prolog 9.x, single file `robocup.pl`, showcasing Symbolic AI (FSM + STRIPS-schema + CSP). Two teams, 3 players each (goalkeeper, defender, forward), round-based, discrete 100×50 field. Entry point: `?- run_simulation(N).` prints rounds, detects goals, resets, prints final score. Deliverable = `robocup.pl` + 5-page human-written report (WORD + PDF). Deadline: **Sun 19 Apr 2026 midnight**. Team: 4 students; every student must defend any predicate in a viva.

## 2. Locked decisions (team-ratified)

All decisions are defaults from [../plan/project-partition.md](../plan/project-partition.md) §"Decision checkpoints". Update status column as team confirms.

| # | Decision | Locked choice | Status |
|---|---|---|---|
| D1 | Starting point | Full rewrite of `robocup.pl` | ☐ PENDING |
| D2 | Symbolic techniques | FSM + STRIPS + CSP (3 techniques) | ☐ PENDING |
| D3 | CSP implementation | `clpfd` with **30-min fallback trigger** → hard-coded positions | ☐ PENDING |
| D4 | Turn order | Alternating (`team1 → team2`) | ☐ PENDING |
| D5 | Possession | `possession(Team, Role)` with sentinel `possession(none, none)` | ☐ PENDING |
| D6 | Demo scenario | Deterministic scripted opening → guaranteed goal | ☐ PENDING |
| D7 | Test harness | PLUnit (`tests/test_robocup.pl`) | ☐ PENDING |
| D8 | Report prose | Human-written from bullets (no AI prose) | ☐ PENDING |

## 3. Non-goals (DO NOT BUILD)

No GUI. No networking / client-server. No real RoboCup protocol or sensor parsing (`see`, `sense_body`). No machine learning, probabilistic reasoning, case-based reasoning. No forward-search planner / GPS. No pathfinding (A*, Dijkstra). No continuous physics. No multi-file modules. No libraries beyond `clpfd`, `random`, `lists`, `plunit`.

## 4. Architecture overview

Single file `robocup.pl` in 8 sections, each bracketed by `% === Section N. <title> ===` banners. One Symbolic-AI technique per layer so the report rationale writes itself.

```
1. Static knowledge (facts)       — field/1, goal_position/2, constants
2. Dynamic world model            — :- dynamic ball/1, player/4, score/2, possession/2, turn/1, current_state/3, metric/3
3. CSP layer                      — place_teams/0 via library(clpfd)
4. FSM layer                      — current_state/3, transition/4, tick_fsm/2
5. STRIPS layer                   — action/4, applicable/1, apply_effects/1, do_action/1
6. Role behaviors                 — act_goalkeeper/1, act_defender/1, act_forward/1
7. Dynamics & rules               — stamina, check_goal/0, next_turn/0, setup_world/0
8. Simulator entry points         — simulate_round/0, run_simulation/1, print_state/0
```

Full rationale: [../plan/project-partition.md](../plan/project-partition.md) §Architecture.

## 5. Canonical data representation

```prolog
field(size(100, 50)).
goal_position(team1, rect(0, 20, 0, 30)).
goal_position(team2, rect(100, 20, 100, 30)).

:- dynamic ball/1.            % ball(pos(X, Y))
:- dynamic player/4.          % player(Team, Role, pos(X, Y), Stamina)  — Stamina is a bare int
:- dynamic score/2.           % score(Team, N)
:- dynamic possession/2.      % possession(Team, Role) or possession(none, none)
:- dynamic turn/1.            % turn(Team)
:- dynamic current_state/3.   % current_state(Team, Role, StateAtom)
:- dynamic metric/3.          % metric(Name, Team, Count)
```

`Team` ∈ `{team1, team2}`. `Role` ∈ `{goalkeeper, defender, forward}`. `StateAtom` depends on Role (see §Phase 2 in partition.md).

## 6. Shared predicate contracts

These predicates are called across sections. Their signatures are frozen after T0.2; don't change without updating this file.

| Predicate | Purpose | Owner Section |
|---|---|---|
| `setup_world/0` | Reset dynamic facts; place teams; ball at center; score 0–0 | §3 (uses §7 glue) |
| `place_teams/0` | CSP-based formation, joint across both teams | §3 |
| `tick_fsm(+Team, +Role)` | Advance one FSM state using §1 sensors | §4 |
| `applicable(+Action)` | True iff preconditions hold in current world | §5 |
| `apply_effects(+Action)` | Mutate dynamic facts per action effects | §5 |
| `do_action(+Action)` | `applicable` + `apply_effects` + log | §5 |
| `act_<role>(+Team)` | Role behavior glue (FSM → STRIPS action) | §6 |
| `check_goal/0` | Detect goal, increment opponent score, reset | §7 |
| `next_turn/0` | Alternate `turn/1` | §7 |
| `simulate_round/0` | One full round | §8 |
| `run_simulation(+N)` | Setup + N rounds + final score | §8 |
| `print_state/0` | Readable round-end snapshot | §8 |
| `print_summary/0` | End-of-game metrics | §8 |

Sensor helpers (§1, read-only, no mutation): `ball_close/2`, `in_kick_range/2`, `in_catch_range/2`, `ball_in_own_half/1`, `has_possession/2`, `can_shoot/1`, `can_pass/2`.

## 7. File / section ownership

| Person | Owns code sections | Owns docs |
|---|---|---|
| P1 — ___ | §1, §2, §8 | `docs/project-context.md`, `README.md` |
| P2 — ___ | §3 (CSP), §4 (FSM) | `docs/viva_answers.md` FSM/CSP rows |
| P3 — ___ | §5 (STRIPS), §6, §7 | `docs/viva_answers.md` STRIPS rows |
| P4 — ___ | Cross-section glue, `tests/test_robocup.pl`, merges | `docs/report-outline.md`, floyd summaries |

**Before dispatch: write real names in the blanks.**

Task → subagent mapping:
- Prolog sections (T0.2, T1.x, T2.x, T3.x, T4.x, T5.x, T7.2) → `prolog-coder`
- Design notes for CSP/FSM/STRIPS (T1.2, T2.1, T2.2) → `symbolic-ai-architect` first, then `prolog-coder`
- Tests (T6.1) → `prolog-test-engineer`
- Docs (T0.1, T7.0, T7.1, T7.3) → `report-writer`
- Verdicts after every task → `prolog-reviewer`

## 8. Current phase / backlog status

**Status**: Phase 0 (decisions) in progress. Nothing built yet. Blocker = team ratification of D1–D8 above.

**Next dispatches** (once D1–D8 locked):
1. T0.1 `report-writer` ‖ — floyd PDF summaries to `docs/floyd-200{8,12}-summary.md`
2. T0.2 `prolog-coder` ⇢ — `robocup.pl` skeleton with §1–§8 banners + all `:- dynamic` declarations

Full backlog: [../plan/project-partition.md](../plan/project-partition.md) §Feature backlog.

## 9. Open decisions

D1–D8 above, pending team tick. No other open decisions.

## 10. Verification commands

Run after every phase (P4 owns):

```bash
# Load check — must exit 0 with no warnings
swipl -s robocup.pl -g halt

# Smoke test — 3 rounds, no crashes
swipl -s robocup.pl -g "setup_world, run_simulation(3)" -t halt

# Full test suite (once tests/ exists)
swipl -s robocup.pl -g "consult('tests/test_robocup.pl'), run_tests, halt"

# Documentation density proxy
grep -c "^%" robocup.pl   # target ≥ 30
```

## 11. Viva-critical justification points

Short answers to the 11 viva questions; full bank in `docs/viva_answers.md` (or appendix of `docs/report-outline.md`).

- **Representation `player/4` + `ball/1`**: facts are the natural Prolog knowledge unit; dynamic predicates model the changing world.
- **FSM for role behavior**: one transition table per role makes behavior auditable and easy to defend.
- **STRIPS schema (no planner)**: preconditions/effects are rubric-named; the FSM chooses actions per tick so we don't need a planner.
- **CSP for formation**: demonstrates `clpfd` on a tiny, defensible problem; fallback = hard-coded positions if solving is slow.
- **Text sim, not GUI**: rubric doesn't ask for a GUI; prose-friendly; saves time.
- **Discrete positions**: continuous physics adds engineering, no symbolic-AI value.
- **Alternating turns**: deterministic → easier viva, easier tests.
- **Player-level possession**: lets `kick`/`pass`/`catch` preconditions name the actor cleanly.
- **Strengths/limitations**: simple, explainable, testable / no learning, no opponent modeling, no noisy sensing.
- **What we'd improve**: richer FSM, planner on top of STRIPS, bigger teams, sensor noise model.

---

## Audit fixes applied 2026-04-17

- `possession/1` vs `possession/2` inconsistency in partition.md → **resolved to `/2`**.
- Absolute `/Users/book/...` paths in partition.md and `.claude/agents/*.md` → **rewritten relative**.
- STRIPS `applicable(Action, World)` redundant `World` arg → **dropped to `applicable(Action)`**.
- Duplicate `agents/` dir at repo root → **removed**; `.claude/agents/` is the single source.
- Obsolete `plan/use-the-prompt-in-peppy-harp.md` → **removed** (superseded by this file).
- `plan/claude_prompt.txt` → renamed to `plan/brief.md` for consistency.
- `project` (root partial Prolog) → moved to `docs/prior-attempt.pl` (reference only).
- `memory/context.md` (partial report draft) → moved to `docs/report-notes-raw.md`.
- CSP pairwise Manhattan distance loosened 15 → 10 (feasibility); CSP fallback trigger tightened 1h → 30 min.
