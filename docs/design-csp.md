# T1.2 Design — CSP Initial Formation (`place_team/1`)

## 1. Purpose

CSP (Constraint Satisfaction Problem, course technique) is the natural fit for initial player placement: each player has a legal zone (unary domain constraint) and teammates must not clump (binary spacing constraint). We run CSP **once, at setup** — not per round — because formation constraints are static knowledge about the kickoff state. Per-round replanning would be redundant with the FSM/STRIPS layer and dilute the "CSP at setup" story we tell in the report.

## 2. Variables

`place_team/1` is called **once per team**. Recommendation: treat each call as **fully independent** (the simpler option). Cross-team spacing is already enforced implicitly by the mirrored zone domains (team1 bounded to `X in [0,50]` for keeper/defender; team2 symmetric on `[50,100]`), so no cross-team variables need to be introduced. Seeding from already-placed players would force `place_team/1` to read `player/4` facts and add extra constraints — unnecessary complexity for no symbolic gain.

Six clpfd variables per call (one X + one Y per role):

| Role | X var | Y var |
|---|---|---|
| goalkeeper | `X_gk` | `Y_gk` |
| defender   | `X_df` | `Y_df` |
| forward    | `X_fw` | `Y_fw` |

(When documenting team2 separately in the report, suffix with `_t2`: `X_gk_t2`, etc. Within the predicate body they are locally scoped, so no suffix is needed in code.)

## 3. Domains (field locked at `size(100, 50)`)

| Player | X domain | Y domain | Rationale |
|---|---|---|---|
| team1 goalkeeper | `[0, 15]` | `[20, 30]` | own penalty zone, near own goal at x=0 |
| team1 defender   | `[0, 50]` | `[0, 50]` | own half |
| team1 forward    | `[50, 100]` | `[0, 50]` | past midline, pressing opponent |
| team2 goalkeeper | `[85, 100]` | `[20, 30]` | mirror: own penalty zone at x=100 |
| team2 defender   | `[50, 100]` | `[0, 50]` | mirror: own half |
| team2 forward    | `[0, 50]` | `[0, 50]` | mirror: past own midline into team1 half |

## 4. Constraints

- **Domain constraints** — posted with `ins`/`in` using the table above. Rationale: pins each role to its zone without any search pruning heuristics.
- **Pairwise same-team Manhattan spacing ≥ 15** — for each of the 3 unordered pairs within the team: `abs(Xa - Xb) + abs(Ya - Yb) #>= 15`. Rationale: prevents clumping so FSM transitions during play have meaningful geometric state.
- **Cross-team spacing**: **not enforced**. Rationale: the mirrored zone domains already give keepers & defenders of opposite teams ≥ 35 apart on X; forwards from both teams share the central band but that's realistic for a kickoff (no need to over-constrain). Keeping CSP small (6 vars, ~4 inequalities per call) is worth more to the report than enforcing a constraint the domain already implies.

## 5. Solution strategy

- `labeling([], [X_gk, Y_gk, X_df, Y_df, X_fw, Y_fw])` with default options.
- Wrap the whole search in `once/1` at the call site inside `place_team/1`: we want **one valid formation**, not an enumeration of all of them. `once/1` enforces determinism so `setup_world/0` is deterministic.

## 6. Predicate shape — `place_team(+Team)`

Signature: `place_team(+Team)` where `Team` is ground, one of `team1` or `team2`. Mode: `+`. Deterministic (cuts via `once/1`).

Pseudocode outline (no Prolog — implementer fills in):
1. Dispatch on `Team` to select the three (X,Y) domain bound pairs for goalkeeper / defender / forward.
2. Declare 6 fresh clpfd vars: `X_gk, Y_gk, X_df, Y_df, X_fw, Y_fw`.
3. Post domain constraints using `in` / `#>=` / `#=<` per the table in §3.
4. Post the 3 pairwise Manhattan spacing constraints (gk↔df, gk↔fw, df↔fw) each `#>= 15`.
5. `once(labeling([], [X_gk, Y_gk, X_df, Y_df, X_fw, Y_fw]))`.
6. `retractall(player(Team, _, _, _))` then `assertz(player(Team, goalkeeper, position(X_gk, Y_gk), S))` etc. for all 3 roles, where `S` is bound via `stamina_init(S)`.

Signatures touched: `player/4` (already declared dynamic in Section 2, shape `player(Team, Role, position(X,Y), Stamina)`). No new predicates introduced beyond `place_team/1`.

## 7. Interaction with `setup_world/0`

`setup_world/0` is the orchestrator (Section 3, same file) and does the following in order:
1. `retractall(ball(_))`, `retractall(player(_,_,_,_))`, `retractall(score(_,_))`, `retractall(possession(_,_))`, `retractall(turn(_))`, `retractall(current_state(_,_,_))`, `retractall(metric(_,_,_))`.
2. `assertz(ball(position(50, 25)))`.
3. `place_team(team1)`, `place_team(team2)`.
4. `assertz(score(team1, 0))`, `assertz(score(team2, 0))`.
5. `assertz(possession(none, none))`.
6. `assertz(first_mover(team1))` — initial seed only. `next_first_mover/0` randomizes via `random_member/2` each round, so this seed value is not load-bearing.

Note: FSM initial states (`current_state/3`) are asserted by Section 4 bootstrap logic, not by `place_team/1`. `setup_world/0` may call a Section-4 helper after step 6 if T2.1 exposes one.

## 8. Acceptance test hook

```
?- setup_world,
   findall(P, player(team1, _, P, _), Ps),
   length(Ps, 3),
   write(Ps).
```

Expected: prints 3 `position(X,Y)` terms, each within team1's zone table row (§3), with all three pairs ≥ 15 Manhattan apart. Same shape test for `team2`.

## 9. Viva justification (3 bullets)

- **Right tool**: CSP is purpose-built for zone + spacing constraints — this is a canonical unary+binary constraint problem from the course.
- **Small by design**: 6 variables, 2 constraint kinds (domain, spacing), first solution via `once/1` — the CSP layer is self-contained and fits in one report paragraph.
- **Used once**: CSP runs only at setup. The FSM and STRIPS layers stay symbolically distinct — no overlap, no planner-vs-solver ambiguity to defend in viva.

## 10. Report-ready table

| Variable(s) | Domain | Constraint kind |
|---|---|---|
| `X_gk`, `Y_gk` (team1) | `X in [0,15]`, `Y in [20,30]` | Unary — goalkeeper zone (penalty box, near own goal) |
| `X_df`, `Y_df` (team1) | `X in [0,50]`, `Y in [0,50]` | Unary — defender zone (own half) |
| `X_fw`, `Y_fw` (team1) | `X in [50,100]`, `Y in [0,50]` | Unary — forward zone (past midline) |
| team2 equivalents | mirrored on `X` | Unary — mirror of team1 domains |
| (gk, df), (gk, fw), (df, fw) | — | Binary — `|Xa-Xb| + |Ya-Yb| #>= 15` same-team spacing |
| cross-team pairs | — | **Not enforced** — mirrored domains already separate teams |
