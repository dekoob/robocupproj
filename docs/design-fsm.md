# T2.1 Design Note — FSM Role State Machines (Section 4)

## 1. Purpose

Each role in the RoboCup simulation has a small, nameable set of *intents*: the goalkeeper either guards, chases, or holds; the defender either holds the line, intercepts, or passes; the forward either advances, chases, or shoots. Intent selection is a finite, deterministic decision over sensed world conditions — a textbook Finite State Machine. **FSM is a course-taught technique**, and a transition table is the most readable representation for the report and the viva. One FSM per role, driven once per tick per player.

## 2. States per role (locked from partition.md T2.1)

| Role | State | Meaning (intent, not action) |
|---|---|---|
| goalkeeper | `guard_goal` | Stay near own goal; do not actively chase. |
| goalkeeper | `chase_ball` | Ball is loose in own half — move toward it. |
| goalkeeper | `hold_ball` | Ball has been caught; next action is to release (kick out). |
| defender | `hold_line` | Maintain defensive formation in own half. |
| defender | `intercept` | Ball is loose in own half — move to intercept. |
| defender | `pass_to_forward` | Has possession; next action is a pass forward. |
| forward | `advance` | Push toward opponent half / wait for the ball to arrive. |
| forward | `chase_ball` | Ball is loose in opponent half — pursue it. |
| forward | `shoot` | In possession and in range — next action is a shot on goal. |

**Initial states** (seeded at world setup): goalkeeper → `guard_goal`, defender → `hold_line`, forward → `advance`.

## 3. REQUIRED edit flagged for the T2.1 coder

`setup_world/0` (Section 3, lines 96–110) currently **does not** assert any `current_state/3` facts. The FSM will fire zero transitions until those seeds exist.

**Recommendation**: add a new predicate `init_fsm/0` in Section 4 that asserts the 6 initial-state facts (team1/team2 × goalkeeper/defender/forward) and have `setup_world/0` call `init_fsm` at the end. This keeps Section 3 CSP-only, which is what the report's CSP subsection needs to point at.

Minimal contract for `init_fsm/0`: retract any stale `current_state/3` (already done by `setup_world`'s `retractall`), then assert `current_state(team1, goalkeeper, guard_goal)`, `current_state(team1, defender, hold_line)`, `current_state(team1, forward, advance)`, and the same three for team2.

`setup_world/0` needs one additional line — a call to `init_fsm` — immediately before its final `assertz(turn(team1))`.

## 4. Sensed helper predicates (Section 4, defined above `transition/4`)

All helpers are side-effect-free queries on `player/4`, `ball/1`, `possession/2`. Manhattan distance throughout.

| Predicate | Arity | Semantics |
|---|---|---|
| `in_catch_range(+Team, +Role)` | 2 | Manhattan distance from player to ball ≤ `catch_range(C)`. |
| `ball_in_own_half(+Team)` | 1 | Uses ball X only. team1 owns `X in [0,50]`, team2 owns `X in [50,100]`. |
| `has_possession(+Team, +Role)` | 2 | Matches the current `possession(Team, Role)` fact. Fails when loose (`possession(none,none)`). |
| `ball_is_loose(+Team)` | 1 | Succeeds when `possession(none, none)`. Team arg ignored. |
| `can_shoot(+Team, +Role)` | 2 | `has_possession(Team, Role)` **and** Manhattan distance from player to opponent goal centre ≤ `kick_range(K)`. Opponent goal centres: team1 attacks (100,25); team2 attacks (0,25). |

## 5. Transition table (report figure)

Conditions are evaluated for `(Team, Role)` — see §6 for the predicate shape.

| Role | From | Condition | To |
|---|---|---|---|
| goalkeeper | `guard_goal` | `ball_in_own_half(Team)` AND `\+ has_possession(Team, goalkeeper)` | `chase_ball` |
| goalkeeper | `chase_ball` | `in_catch_range(Team, goalkeeper)` | `hold_ball` |
| goalkeeper | `hold_ball` | `\+ has_possession(Team, goalkeeper)` | `guard_goal` |
| defender | `hold_line` | `ball_in_own_half(Team)` AND `\+ has_possession(_, _)` (ball is loose) | `intercept` |
| defender | `intercept` | `has_possession(Team, defender)` | `pass_to_forward` |
| defender | `pass_to_forward` | `\+ has_possession(Team, defender)` | `hold_line` |
| forward | `advance` | `ball_is_loose(Team)` AND `\+ has_possession(Team, forward)` | `chase_ball` |
| forward | `chase_ball` | `can_shoot(Team, forward)` | `shoot` |
| forward | `shoot` | `\+ has_possession(Team, forward)` | `advance` |

Structural invariants the coder must preserve:
- Every state has **at most 2 outgoing transitions** (in this design, exactly 1 each — but the table format supports 2 if needed).
- Every `To` state is on that role's own 3-state list — **no dead ends, no cross-role states**.
- "Post-action reset" transitions (`hold_ball → guard_goal`, `pass_to_forward → hold_line`, `shoot → advance`) fire on loss of possession, which happens naturally the tick after STRIPS applies a kick/pass effect.

## 6. Predicate shape

**Transition facts (static, Section 4)**:
`transition(+Role, +FromState, +CondList, +ToState)` — `CondList` is a list of callable atoms. Each entry is either a bare predicate name (called as `Pred(Team, Role)` for binary sensors or `Pred(Team)` for `ball_in_own_half`) or a `\+ Pred` term for negation.

**Locked form** — uniform list-of-goals. This is simpler than placeholder-substitution because `tick_fsm/2` only has to `call/2` or `call/3` each goal with the current `(Team, Role)` and AND them together. Arity of the sensor (1 vs 2) is known from the list entry itself.

Pseudocode (for the implementer, not executable):

```
eval_cond(Team, Role, Pred)        :- sensor_arity(Pred, 2), call(Pred, Team, Role).
eval_cond(Team, _,   Pred)         :- sensor_arity(Pred, 1), call(Pred, Team).
eval_cond(Team, Role, \+ Pred)     :- \+ eval_cond(Team, Role, Pred).
eval_all(_, _, []).
eval_all(Team, Role, [C|Cs])       :- eval_cond(Team, Role, C), eval_all(Team, Role, Cs).
```

Example fact: `transition(goalkeeper, guard_goal, [ball_in_own_half, \+ has_possession], chase_ball).`
(Here `ball_in_own_half` is arity-1 and `has_possession` is arity-2 — the eval helper dispatches on the known sensor arity.)

Defender's "ball loose" case needs `\+ has_possession(_, _)` (anyone holding the ball blocks interception). The list form uses a wildcard-aware variant or a dedicated sensor `ball_is_loose/1` (arity 1, checks `possession(none, none)`) — **recommend adding `ball_is_loose(+Team)`** as an extra helper so the transition list stays uniform. Flag this extra helper in the coder's T2.1 PR.

**Tick predicate** — `tick_fsm(+Team, +Role)`:
1. `current_state(Team, Role, S)`.
2. `once( ( transition(Role, S, Cond, NewS), eval_all(Team, Role, Cond) ) )` — first matching transition wins.
3. If a transition matched: `retract(current_state(Team, Role, S))`, `assertz(current_state(Team, Role, NewS))`, log `format("~w ~w: ~w -> ~w~n", [Team, Role, S, NewS])`.
4. If no transition matched: do nothing — succeed silently with `true`.

## 7. Determinism

`tick_fsm/2` must be deterministic. Wrap the transition lookup in `once/1`. Do not leave choice points behind — the simulator calls `tick_fsm` in a loop and a stray choice point corrupts the turn order. The transitions per-state are already mutually exclusive in the current design, but `once/1` is a belt-and-braces guarantee for the report's "deterministic simulator" claim.

## 8. Viva justifications (three bullets)

- **Course-taught technique.** FSM is a named course topic; each role's intent selection is precisely the decision an FSM is designed to make (what state should I be in next given the sensed world?).
- **Report-ready transition tables.** The table in §5 prints verbatim into the report's FSM subsection — one figure, nine rows, no prose gymnastics.
- **Tiny state space students can recite.** 3 states × 3 roles = 9 named states. Any teammate can list them on the whiteboard in the viva without notes.

## 9. Worked example (unit-test fact for the implementer)

After `setup_world` on a fresh world (ball at (50,25), possession(none,none)):
- `current_state(team1, forward, advance)` is asserted by `init_fsm`.
- `ball_is_loose(team1)` succeeds (possession is none-none).
- `\+ has_possession(team1, forward)` succeeds.
- `tick_fsm(team1, forward)` fires `advance → chase_ball` immediately. Forward starts chasing ball in round 1.

Second call with ball at forward's position and possession(team1, forward):
- `can_shoot` fires if forward is within kick_range(50) of opponent goal — at midfield this is satisfied.
- `tick_fsm` fires `chase_ball → shoot`; `act_forward` calls `do_action(kick(…, position(100,25)))`. Goal possible.

## 10. Acceptance test hook

```
?- setup_world.
?- tick_fsm(team1, forward).    % first tick — stays at advance OR moves to chase_ball
?- tick_fsm(team1, forward).    % second tick — re-evaluates; idempotent for same world
?- current_state(team1, forward, S).    % S is bound to one of {advance, chase_ball, shoot}
```

T2.1 is complete when: (a) `init_fsm` exists and `setup_world` calls it, (b) all 9 `transition/4` facts listed in §5 are present, (c) all 7 sensors from §4 (plus optional `ball_is_loose/1`) are defined, (d) `tick_fsm/2` is deterministic per §7, (e) the worked example in §9 behaves as described.
