# T2.2 — STRIPS Action Schema Design Notes (Section 5)

**Technique (course-taught):** STRIPS action representation. Each action is a name + **preconditions** (list of world-literals that must hold) + **effects** (add/del list over world-literals). No planner — the FSM picks one action per tick; STRIPS only decides *legality* and performs the *state update*.

---

## 1. Purpose

STRIPS is chosen because preconditions and effects as **explicit lists** are the course's canonical action-representation idiom. It cleanly separates *"can we do this?"* (`applicable/2`) from *"what changes?"* (`apply_effects/1`). This gives us the rubric-friendly preconditions/effects table, makes action legality trivially inspectable, and lets role behaviors (Section 6) stay thin — they just nominate an action; Section 5 enforces rules. This is the **second** named showcase technique for the report (CSP at setup, FSM for intents, STRIPS for actions).

---

## 2. Action signatures (locked)

| Action | Shape | Rationale |
|---|---|---|
| `move_step(Actor, Dir)` | `Dir ∈ {north, south, east, west}` | 4-way discrete movement keeps positions integer and preconditions trivial. |
| `kick(Actor, TargetPos)` | `TargetPos = position(X,Y)` | A kick is parameterised by *where you aim*, not by a direction — needed to shoot at the goal rect. |
| `catch(Actor)` | parameter-free | Goalkeeper catches the ball at its current position; nothing else to specify. |
| `pass(Actor, Teammate)` | `Teammate = player(Team, Role)` | Passes are role-to-role (forward is the usual recipient); the role name is the natural handle. |

`Actor = player(Team, Role)` everywhere. This is an **abstract handle**, not the full `player/4` fact — Section 5 looks the position/stamina up from the dynamic DB when needed.

---

## 3. World-literal vocabulary

The "state language" that appears in preconds/effects:

| Literal | Meaning | Backing fact |
|---|---|---|
| `at(Actor, Pos)` | Actor is at `Pos` | `player(Team, Role, Pos, _)` |
| `ball_at(Pos)` | Ball is at `Pos` | `ball(Pos)` |
| `has_ball(Actor)` | Actor currently possesses | `possession(Team, Role)` where `Actor = player(Team, Role)` |
| `stamina_ge(Actor, N)` | Actor's stamina ≥ N | `player(_,_,_,S), S >= N` |
| `in_field(Pos)` | `Pos` inside `field(size(100,50))` | computed from `field/1` |
| `in_range(Actor, Pos, R)` | Manhattan distance Actor→Pos ≤ R | computed from `player/4` + `manhattan/3` |

**Simplification vs textbook STRIPS:** we do **not** maintain a parallel world-literal database. These literals are **computed on demand** against the live dynamic facts (`player/4`, `ball/1`, `possession/2`). `applicable/2` just evaluates them as Prolog goals against the current DB. This is the single biggest divergence from the textbook and must be called out in the report: it simplifies state management at the cost of losing symbolic replay. For a 3v3 sim with one mutable world, this is the right trade-off.

---

## 4. Per-action specification

### 4.1 `move_step(Actor, Dir)`
- **Preconds:** `[at(Actor, Pos), stamina_ge(Actor, C), in_field(NewPos)]` where `NewPos = step(Pos, Dir, move_step)` and `C = stamina_cost_move`.
- **Effects:** `del(at(Actor, Pos)), add(at(Actor, NewPos))`; stamina `-= stamina_cost_move` (side effect on `player/4`). If `has_ball(Actor)` also holds: `del(ball_at(Pos)), add(ball_at(NewPos))` — **the ball moves with the carrier** (per partition.md T4.5).

### 4.2 `kick(Actor, TargetPos)`
- **Preconds:** `[has_ball(Actor), stamina_ge(Actor, C), in_field(TargetPos), in_range(Actor, TargetPos, kick_range)]` where `C = stamina_cost_kick`.
- **Effects:** `del(ball_at(_)), add(ball_at(TargetPos)), del(has_ball(Actor))`; stamina `-= stamina_cost_kick`; `possession → possession(none, none)`.

### 4.3 `catch(Actor)` — goalkeepers only
- **Preconds:** `[Actor = player(_, goalkeeper), at(Actor, Pos), ball_at(BPos), in_range(Actor, BPos, catch_range)]`. Role restriction is enforced by the pattern match on `Actor`.
- **Effects:** `del(ball_at(BPos)), add(ball_at(Pos))` (ball snaps to goalkeeper), `add(has_ball(Actor))`; `possession → possession(Team, goalkeeper)` where Actor = `player(Team, goalkeeper)`. No stamina cost (catching is passive).

### 4.4 `pass(Actor, Teammate)` — same team, within kick range
- **Preconds:** `[has_ball(Actor), at(Actor, Pa), at(Teammate, Pt), in_range(Actor, Pt, kick_range), same_team(Actor, Teammate), Actor \= Teammate, stamina_ge(Actor, C)]` where `C = stamina_cost_kick`.
- **Effects:** `del(ball_at(_)), add(ball_at(Pt)), del(has_ball(Actor)), add(has_ball(Teammate))`; `possession → possession(Team, TeammateRole)`; stamina `-= stamina_cost_kick`.

---

## 5. Predicate shapes (match T0.2 contract)

| Predicate | Mode | Semantics |
|---|---|---|
| `applicable(+Action, +World)` | det/semidet | True iff every precondition holds. `World` arg is kept for textbook fidelity but is unused — pass the atom `world`. Reads live dynamic state. |
| `apply_effects(+Action)` | det | `retract/1` + `assertz/1` on `player/4`, `ball/1`, `possession/2`. No logging. |
| `do_action(+Action)` | det | `( applicable(Action, world) -> apply_effects(Action), format(...) ; true )`. Emits one `format/2` log line per successful action. Always succeeds so callers never crash on inapplicable actions. |

---

## 6. Helpers to define alongside (Section 5)

| Helper | Signature | Notes |
|---|---|---|
| `step/4` | `step(+Pos, +Dir, +StepSize, -NewPos)` | Compute next position. Out-of-field clipping is **not** done here — `in_field/1` precondition filters illegal moves. |
| `manhattan/3` | `manhattan(+PosA, +PosB, -Dist)` | Integer Manhattan distance. Used by `in_range/3`. |
| `in_field/1` | `in_field(+Pos)` | Reads `field(size(W,H))` and checks bounds. |
| `in_range/3` | `in_range(+Actor, +Pos, +RangePred)` | `RangePred` is an atom like `kick_range` or `catch_range`; helper calls it to get the numeric radius. |
| `same_team/2` | `same_team(+ActorA, +ActorB)` | Both have the same team name. |

---

## 7. Stamina enforcement boundary (T4.1 touch-point)

Stamina logic lives **only** in two places:
1. **`applicable/2`** — checks `stamina_ge(Actor, C)` in `move_step`, `kick`, and `pass` preconds.
2. **`apply_effects/1`** — decrements stamina on the corresponding `player/4` fact after the action succeeds.

Role behaviors (Section 6) must **not** duplicate stamina checks. T4.1 is implemented as edits to `apply_effects(move_step(...))`, `apply_effects(kick(...))`, and `apply_effects(pass(...))` only.

---

## 8. Possession boundary (T4.5 touch-point)

Possession is read/written **only** in Section 5:
- **Read** as `has_ball(Actor)` precondition in `kick`, `pass`.
- **Written** as a possession effect in `catch` (set), `kick` (clear to `none/none`), `pass` (transfer). Also implicitly touched by `move_step` because the ball moves with the carrier.

T4.5 does not add new predicates — it fills in these precondition/effect clauses inside Section 5 and the `possession/2` dynamic fact declared in Section 2.

---

## 9. Viva justifications (three bullets)

- STRIPS is the course-taught action representation; the preconds/effects list form maps **one-to-one** onto the rubric's "symbolic action schema" line item.
- World-literals computed on demand (no parallel state DB) keep the implementation small and easy for a student to defend — the only state is the live dynamic facts.
- Four actions (`move_step`, `kick`, `catch`, `pass`) is enough to demonstrate the technique without combinatorial blow-up; adding more would hurt the report more than help it.

---

## 10. Acceptance test hooks

| Query | Expected behaviour |
|---|---|
| `?- setup_world, do_action(move_step(player(team1, forward), east)).` | Logs a move; forward's X coordinate increases by 1; stamina drops by 10. |
| `?- setup_world, do_action(kick(player(team1, forward), position(60, 25))).` | `applicable` fails (no possession at setup); no log, no mutation, query still succeeds (`true`). |
| `?- setup_world, do_action(catch(player(team1, forward))).` | `applicable` fails (Actor pattern `player(_, goalkeeper)` mismatch); no log, no mutation. |

---

## 11. Report-ready preconditions/effects table

| Action | Preconditions | Effects |
|---|---|---|
| `move_step(Actor, Dir)` | `at(Actor, Pos)`, `stamina_ge(Actor, stamina_cost_move)`, `in_field(NewPos)` (with `NewPos = step(Pos, Dir, move_step)`) | `del(at(Actor,Pos))`, `add(at(Actor,NewPos))`; stamina `-= stamina_cost_move`; if carrier: `del(ball_at(Pos))`, `add(ball_at(NewPos))` |
| `kick(Actor, TargetPos)` | `has_ball(Actor)`, `stamina_ge(Actor, stamina_cost_kick)`, `in_field(TargetPos)`, `in_range(Actor, TargetPos, kick_range)` | `del(ball_at(_))`, `add(ball_at(TargetPos))`, `del(has_ball(Actor))`; stamina `-= stamina_cost_kick`; `possession → (none,none)` |
| `catch(Actor)` | `Actor = player(_, goalkeeper)`, `at(Actor, Pos)`, `ball_at(BPos)`, `in_range(Actor, BPos, catch_range)` | `del(ball_at(BPos))`, `add(ball_at(Pos))`, `add(has_ball(Actor))`; `possession → (Team, goalkeeper)` |
| `pass(Actor, Teammate)` | `has_ball(Actor)`, `at(Actor, Pa)`, `at(Teammate, Pt)`, `in_range(Actor, Pt, kick_range)`, `same_team(Actor, Teammate)`, `Actor \= Teammate`, `stamina_ge(Actor, stamina_cost_kick)` | `del(ball_at(_))`, `add(ball_at(Pt))`, `del(has_ball(Actor))`, `add(has_ball(Teammate))`; `possession → (Team, TeammateRole)`; stamina `-= stamina_cost_kick` |
