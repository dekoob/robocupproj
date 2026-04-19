# Report Outline — RoboCup Symbolic-AI Prolog
<!-- T7.1 deliverable. Bullets only — humans write prose from this skeleton.
     Word-count budgets are targets, not hard limits.
     Code references cite robocup.pl:<line> or tests/test_robocup.pl:<line>.
     Source-of-truth for project decisions: docs/project-context.md.
     Design rationale for each technique: docs/design-csp.md, docs/design-fsm.md, docs/design-strips.md. -->

---

## Section 1 — Introduction
> Budget: ~3/4 page (~200 words of prose when expanded)

### 1.1 The RoboCup benchmark domain
- RoboCup Soccer Simulation League: autonomous software agents play soccer on a discrete virtual field
- Domain introduced by Kitano et al. (1997); used as testbed for AI decision-making under real-time constraints
- Floyd (2008, 2012) characterise the domain: server-client-monitor architecture, 100 ms decision cycles, actions dash/turn/kick/catch — see docs/floyd-2008-summary.md and docs/floyd-2012-summary.md
- Floyd's papers apply Case-Based Reasoning (CBR) — that is the benchmark domain they describe, NOT our technique
- Our work is a deliberate symbolic-AI rendition of that domain

### 1.2 Motivation for symbolic AI
- Course rubric targets explicit use of FSM, STRIPS, and CSP — the three named techniques this project showcases
- Sub-symbolic and learning-based approaches (CBR, neural networks) are out of scope — docs/project-context.md section 3
- Prolog is the natural host: declarative, rule-based, unification-driven — matches the knowledge-representation idiom
- Discrete-position field and integer stamina make constraint satisfaction and precondition checking trivially inspectable

### 1.3 Scope of implementation
- Two teams of three players: goalkeeper, defender, forward per team (team1, team2)
- 100 x 50 discrete field; ball at position(X, Y); entry point run_simulation(N) — robocup.pl:837
- Three symbolic-AI layers: CSP for initial formation, FSM for intent selection, STRIPS for action execution
- Single SWI-Prolog 9.x file (robocup.pl, ~845 lines, 8 banner-delimited sections) plus 16 PLUnit tests at tests/test_robocup.pl
- Report structure mirrors the three-technique layering so viva rationale is self-evident

---

## Section 2 — Symbolic Representations
> Budget: ~3/4 page (~200 words of prose when expanded)

### 2.1 Static knowledge base — Section 1 of robocup.pl
- field(size(100, 50)) — robocup.pl:23 — single fact encodes field dimensions; read by in_field/1 (robocup.pl:339) and CSP domain bounds
- goal_position(team1, rect(0,20,0,30)), goal_position(team2, rect(100,20,100,30)) — robocup.pl:26-27 — goal rectangles used by check_goal/0 for scoring detection
- kick_range(50), catch_range(3), move_step(5) — robocup.pl:30-35 — action radii; referenced by FSM sensor helpers and STRIPS applicable/2; kick_range(50) allows cross-field kicks and goalkeeper clearances
- stamina_init(100), stamina_cost_move(5), stamina_cost_kick(10) — robocup.pl:38-45 — constants; read by apply_effects/1; never mutated during a run

### 2.2 Dynamic world model — Section 2 of robocup.pl
- All mutable predicates declared centrally at robocup.pl:52-58 to avoid dependency cycles across sections
- ball(position(X, Y)) — current ball position; retracted and reasserted by apply_effects and check_goal
- player(Team, Role, position(X, Y), Stamina) — robocup.pl:54 — four-argument fact; one per player; mutated by movement and kick effects
- possession(Team, Role) / possession(none, none) — robocup.pl:55 — player-level possession; gates kick and pass preconditions; none/none sentinel for loose ball
- score(Team, N) — robocup.pl:53; turn(Team) — robocup.pl:56; current_state(Team, Role, State) — robocup.pl:57; metric(Key, Team, N) — robocup.pl:58
- Rationale for assert/retract model: one-line-per-change for a continuously evolving world; trivially inspectable in viva — docs/project-context.md section 11

### 2.3 Layered architecture

| Layer | Technique | Entry predicate | robocup.pl section |
|---|---|---|---|
| Setup | CSP | place_team/1 | Section 3 |
| Intent | FSM | tick_fsm/2 | Section 4 |
| Action | STRIPS | do_action/1 | Section 5 |
| Glue | Role behaviors | act_goalkeeper/1, act_defender/1, act_forward/1 | Section 6 |
| Book-keeping | Dynamics + simulator | check_goal/0, simulate_round/0 | Sections 7-8 |

- CSP runs once at setup; FSM picks intents per tick; STRIPS executes intents — clean technique separation
- Full predicate contracts and cross-section surface: docs/project-context.md sections 4-6

---

## Section 3 — Strategies and Rationale
> Budget: ~2.5 pages total (~650 words of prose when expanded); approximately 3/4 page per subsection

---

### 3.1 CSP — Initial Formation
> Subsection budget: ~3/4 page (~220 words)

#### Rationale
- Initial player placement is a canonical unary + binary constraint problem: each role has a legal zone (unary) and teammates must not clump (binary spacing)
- CSP runs exactly once at setup — not per round — keeps the layer self-contained and the report story clean — docs/design-csp.md section 1
- clpfd from SWI-Prolog standard library; loaded at robocup.pl:10

#### Variables and domains

| Variable(s) | Domain team1 | Domain team2 | Constraint kind |
|---|---|---|---|
| Xgk, Ygk | X in [0,15], Y in [20,30] | X in [85,100], Y in [20,30] | Unary — goalkeeper penalty zone near own goal |
| Xdf, Ydf | X in [0,50], Y in [0,50] | X in [50,100], Y in [0,50] | Unary — defender own-half zone |
| Xfw, Yfw | X in [50,100], Y in [0,50] | X in [0,50], Y in [0,50] | Unary — forward past midline into opponent half |
| (gk,df), (gk,fw), (df,fw) pairs | — | — | Binary — pairwise Manhattan spacing #>= 15 |
| Cross-team pairs | — | — | Not enforced — mirrored domains already separate teams |

> Source: docs/design-csp.md sections 3-4 and robocup.pl:69-86

#### Constraints and labeling
- Three pairwise Manhattan spacing constraints posted at robocup.pl:84-86
- abs(Xgk - Xdf) + abs(Ygk - Ydf) #>= 15 — robocup.pl:84
- abs(Xgk - Xfw) + abs(Ygk - Yfw) #>= 15 — robocup.pl:85
- abs(Xdf - Xfw) + abs(Ydf - Yfw) #>= 15 — robocup.pl:86
- Labeling: once(labeling([], [Xgk, Ygk, Xdf, Ydf, Xfw, Yfw])) — robocup.pl:88 — default heuristic; first valid solution; once/1 enforces determinism of setup_world/0
- setup_world/0 calls place_team(team1) then place_team(team2) — robocup.pl:108-109
- PLUnit tests 5 and 6 verify pairwise spacing >= 15 for both teams — tests/test_robocup.pl:94-108

---

### 3.2 FSM — Role Behavior
> Subsection budget: ~3/4 page (~220 words)

#### Rationale
- Each role has exactly three named intents; intent selection over sensed conditions is a textbook Finite State Machine — docs/design-fsm.md section 1
- Transition table maps directly into the report figure and is recitable from memory in a viva
- FSM produces intents; STRIPS executes them — clear separation; no overlap between layers

#### States and initial conditions
- Initial states seeded by init_fsm/0 — robocup.pl:245-252; called from setup_world/0 — robocup.pl:113
- FSM state stored in current_state(Team, Role, State) — robocup.pl:57

| Role | States | Initial state |
|---|---|---|
| goalkeeper | guard_goal, chase_ball, hold_ball | guard_goal |
| defender | hold_line, intercept, pass_to_forward | hold_line |
| forward | advance, chase_ball, shoot | advance |

#### Transition table — nine static transition/4 facts at robocup.pl:191-206

| Role | From | Condition(s) | To |
|---|---|---|---|
| goalkeeper | guard_goal | ball_in_own_half AND NOT has_possession | chase_ball |
| goalkeeper | chase_ball | in_catch_range | hold_ball |
| goalkeeper | hold_ball | NOT has_possession | guard_goal |
| defender | hold_line | ball_in_own_half AND ball_is_loose | intercept |
| defender | intercept | has_possession | pass_to_forward |
| defender | pass_to_forward | NOT has_possession | hold_line |
| forward | advance | ball_is_loose AND NOT has_possession | chase_ball |
| forward | chase_ball | can_shoot | shoot |
| forward | shoot | NOT has_possession | advance |

> Source: docs/design-fsm.md section 5 and robocup.pl:191-206

#### Sensor helpers and tick mechanism
- Side-effect-free sensor predicates — robocup.pl:125-196: in_catch_range/2, ball_in_own_half/1, has_possession/2, ball_is_loose/1, can_shoot/2
- Arity dispatch table at robocup.pl:243-244: ball_in_own_half and ball_is_loose are arity-1; all others arity-2
- tick_fsm(Team, Role) — robocup.pl:262-269 — reads current_state/3, applies first matching transition via once/1, logs the change; silent no-op if no transition fires
- PLUnit test 15 confirms all 6 initial FSM states after setup_world — tests/test_robocup.pl:220-227

---

### 3.3 STRIPS — Action Schema
> Subsection budget: ~3/4 page (~220 words)

#### Rationale
- STRIPS separates "can we do this?" (applicable/2) from "what changes?" (apply_effects/1) — course-canonical action representation — docs/design-strips.md section 1
- No planner: the FSM selects one action per tick; STRIPS only enforces legality and mutates state — deliberate simplification documented in docs/project-context.md section 3
- Preconditions and effects table is the rubric-facing deliverable; four actions suffice to showcase the technique — docs/design-strips.md section 9

#### Key simplification vs textbook STRIPS
- No parallel world-literal database; preconditions computed on demand against live dynamic facts (player/4, ball/1, possession/2) — docs/design-strips.md section 3
- applicable(Action, world) — world argument kept for textbook fidelity but unused — robocup.pl:365
- This is a design choice, not an oversight: one mutable world is simpler and easier to defend in a viva

#### Preconditions and effects table

| Action | Preconditions | Key effects |
|---|---|---|
| move_step(Actor, Dir) | at(Actor,Pos) (robocup.pl:336), stamina_ge(Actor,cost_move) (robocup.pl:338), in_field(NewPos) (robocup.pl:341-342) | del at(Actor,Pos), add at(Actor,NewPos); stamina -= 5; if carrier: ball moves with player |
| kick(Actor, TargetPos) | has_ball(Actor) (robocup.pl:346), stamina_ge(Actor,cost_kick) (robocup.pl:348-350), in_field(TargetPos) (robocup.pl:351), in_range(Actor,TargetPos,kick_range) (robocup.pl:352) | del ball_at(_), add ball_at(TargetPos); possession -> (none,none); stamina -= 10; inc metric(shots,T) |
| catch(Actor) | Actor=player(_,goalkeeper) (robocup.pl:356), possession(none,none) (robocup.pl:357), in_range(Actor,BPos,catch_range) (robocup.pl:359) | ball snaps to goalkeeper pos; possession -> (Team,goalkeeper); inc metric(saves,T) |
| collect(Actor) | Actor=player(_,R) R\=goalkeeper (robocup.pl:363), possession(none,none) (robocup.pl:365), manhattan(ActorPos,BallPos,D) D =< move_step(5) (robocup.pl:368-370) | ball snaps to player pos; possession -> (Team,R); inc metric(collects,T) — field player secures loose ball |
| tackle(Tackler, Opponent) | Opponent has possession (robocup.pl:377), different teams (robocup.pl:376), manhattan(Tackler,Opponent) ≤ move_step(5) (robocup.pl:380-382) | 50% random roll (tackle_success_rate=50, robocup.pl:48): success → tackler gains possession + ball (robocup.pl:471-475), inc metric(tackles_won,T); failure → inc metric(tackles_lost,T) only (robocup.pl:476) |
| pass(Actor, Teammate) | has_ball(Actor) (robocup.pl:387), same team, different role (robocup.pl:389), in_range(Actor,TeammatePos,kick_range) (robocup.pl:394), stamina_ge(Actor,cost_kick) (robocup.pl:392) | ball moves to teammate pos (robocup.pl:481-491); possession -> (Team,TeammateRole); stamina -= 10; inc metric(passes,T) |

> Source: docs/design-strips.md section 4 and robocup.pl:300-471

#### do_action wrapper and PLUnit verification
- do_action(Action) — robocup.pl:500-505 — safe wrapper: applicable check then apply_effects plus one format/2 log line; always succeeds so role behaviors never crash on inapplicable actions
- PLUnit test 8: kick is a no-op without possession — tests/test_robocup.pl:136-140
- PLUnit test 9: forward cannot catch (role mismatch blocks applicable/2) — tests/test_robocup.pl:147-150
- PLUnit test 10: goalkeeper can catch when adjacent — tests/test_robocup.pl:158-166

---

## Section 4 — Evaluation
> Budget: ~1/2 page (~130 words of prose when expanded)

### 4.1 Metrics infrastructure
- metric(Key, Team, N) — robocup.pl:58 — dynamic counter; seven keys: shots, passes, saves, collects, tackles_won, tackles_lost, goals
- inc_metric(Key, Team) — robocup.pl:739-744 — atomic increment with retract/assertz; no race conditions (single-threaded)
- print_summary/0 — robocup.pl:755 — final scoreboard plus per-team metric counts after run_simulation/1 completes; metrics reset once at match start via retractall in run_simulation/1 (not in setup_world/0, so they accumulate across goal resets)

### 4.2 Sample run output structure
- Per-round output from simulate_round/0 — robocup.pl:807-824:
  - "-- first_mover: team --" from next_first_mover/0 — robocup.pl:726
  - "Team Role: FromState -> ToState" from tick_fsm/2 — robocup.pl:267
  - "  do_action: action" from do_action/1 — robocup.pl:503
  - "[state] ball=... first_mover=... possession=... score=..." plus 6 player lines from print_state/0 — robocup.pl:790
  - "*** GOAL! Team scored! Score is now N-M ***" from check_goal/0 — robocup.pl:702
- Sample match summary (10-round run): `team1: shots=1 passes=2 saves=1 collects=0 tackles=0/0 goals=0`

### 4.3 PLUnit test coverage summary — all 16 tests pass

| Test name | What it verifies | File:line |
|---|---|---|
| world_loads_cleanly | setup_world asserts exactly 6 players | tests/test_robocup.pl:58-61 |
| scores_start_at_zero | both scores = 0 after setup | tests/test_robocup.pl:67-70 |
| ball_starts_at_midfield | ball at position(50,25) after setup | tests/test_robocup.pl:75-78 |
| possession_starts_none | possession(none,none) after setup | tests/test_robocup.pl:83-86 |
| csp_spacing_team1 | CSP pairwise spacing >= 15 for team1 | tests/test_robocup.pl:94-98 |
| csp_spacing_team2 | CSP pairwise spacing >= 15 for team2 | tests/test_robocup.pl:104-108 |
| stamina_depletes_on_move | single move deducts 5 stamina (stamina_cost_move=5) | tests/test_robocup.pl:117-128 |
| kick_fails_without_possession | STRIPS precondition blocks illegal kick | tests/test_robocup.pl:136-140 |
| forward_cannot_catch | role mismatch blocks catch applicable/2 | tests/test_robocup.pl:147-150 |
| goalkeeper_can_catch_when_ball_adjacent | catch succeeds within catch_range | tests/test_robocup.pl:158-166 |
| goal_left_scores_for_team2 | ball at (0,25) credits team2 | tests/test_robocup.pl:175-180 |
| goal_right_scores_for_team1 | ball at (100,25) credits team1 | tests/test_robocup.pl:186-191 |
| check_goal_noop_at_midfield | ball at (50,25) changes nothing | tests/test_robocup.pl:199-204 |
| run_simulation_completes_small_N | run_simulation(2) terminates cleanly | tests/test_robocup.pl:211-213 |
| fsm_initial_states | all 6 initial current_state/3 facts correct | tests/test_robocup.pl:220-227 |
| stamina_depletes_over_10_moves | 10 moves deduct 50 stamina (100 → 50) | tests/test_robocup.pl:226-235 |

### 4.4 Strengths
- Symbolic legibility: every game event traces to a named FSM state or STRIPS precondition — no hidden side effects
- Deterministic test harness: scripted world states make edge cases reproducible regardless of run order
- Three rubric-named techniques present and independently inspectable in separate code sections

### 4.5 Weaknesses
- Turn order is randomised (random_member/2 — robocup.pl:727): full-match outcome is non-deterministic between runs without seed pinning
- Sensor helpers use Manhattan distance throughout: overestimates effective range on diagonals vs Euclidean — may cause occasional missed interceptions near corners

---

## Section 5 — Limitations and Future Work
> Budget: ~1/2 page (~130 words of prose when expanded)

### 5.1 Noisy sensing
- All sensor helpers (in_catch_range/2, ball_in_own_half/1, can_shoot/2, etc.) read ball/1 and player/4 perfectly — no noise model
- Real RoboCup server delivers noisy partial observations via see messages with distance/angle estimates
- Future: add sensor-noise predicate that perturbs readings by configurable epsilon; FSM transitions would then require probabilistic guards or a belief-state layer

### 5.2 Fixed team size — three players per team
- Role set [goalkeeper, defender, forward] is hardcoded as atoms in transition/4 facts — robocup.pl:191-206
- Scaling to 11-a-side requires a richer role taxonomy, multi-player coordination in STRIPS, and a CSP with 11 * 6 = 66 variables per team
- Future: parameterise team size; switch to labeling([ff], Vars) (first-fail heuristic) for larger variable sets; docs/design-csp.md section 5 already notes this option

### 5.3 No look-ahead planner
- FSM picks the next single action per tick; no search beyond the current world state
- STRIPS schema supports a planner in principle — applicable/2 and apply_effects/1 are the state-transition oracle — but GPS/BFS excluded from scope — docs/project-context.md section 3
- Future: replace FSM with a STRIPS-based forward-search planner reusing the existing Section 5 predicates; this would also make the project a full GPS showcase

### 5.4 Static formation mid-match
- CSP runs once in setup_world/0 — robocup.pl:96; after a goal check_goal/0 calls setup_world/0 — robocup.pl:646 which re-runs CSP, but mid-match the formation never adapts to drift
- Future: trigger partial CSP re-solve when player positions violate zone bounds by more than a threshold — would require detecting zone violations via sensor predicates already in Section 4

### 5.5 No learning or adaptation
- Role policies are fixed static transition/4 facts; they do not update from match experience
- Deliberately excluded: machine learning and CBR are out of scope — docs/project-context.md section 3
- Future: encode role strategies as weighted preference lists adjusted by reinforcement signal (goals scored or conceded); hybrid symbolic-subsymbolic architecture with FSM/STRIPS as symbolic baseline

### 5.6 Stamina exhaustion freezes play
- When all players reach stamina=0, no action passes the applicable/2 stamina check; the simulation advances rounds but no moves execute — the world freezes until N rounds complete
- Root cause: stamina restores only on setup_world/0 (goal reset); within a match it only decreases
- Observed in 30-round simulations: around round 20 exhausted players hold possession indefinitely since opponents also lack stamina to tackle
- Future: add a stamina-regen rule (e.g. +2 per idle round) so matches remain active regardless of length

### 5.7 Loose-ball recovery near goal area
- After a shot lands close to the goal (e.g. position(98,22)), the ball stays loose for many rounds: the goalkeeper overshoots by following the goal-center target rather than the ball, and field players in `intercept` state only pick up via collect/1 which requires manhattan distance <= move_step(5)
- In the 30-round test run the ball sat at (98,22) uncollected for 8 consecutive rounds while all three team2 players circled it
- Future: add a second chase target in act_goalkeeper when in chase_ball state — try catch first, then step directly onto the ball position if within gk_zone_depth

### 5.8 Loose-ball collects are rare in practice
- The `collect` action (field player picks up a loose ball) fires only when a shot falls short of the goal area and a field player steps within manhattan distance = move_step(5) of the ball
- In most simulations shots reach the goal area where the goalkeeper's catch_range(3) fires first, leaving no loose ball for field players to collect; so collects=0 or collects=1 in match summaries is normal
- This is expected behaviour: the collect path exists for correctness and appears when a shot misses the goal area entirely and bounces into field territory

### 5.9 Goals require enough simulation rounds to develop
- In a 10-round run the simulation frequently ends 0-0: players spend early rounds advancing and passing before a forward can line up a shot within kick_range of the goal
- Stamina constants (init=100, cost_move=5, cost_kick=10) allow ~20 moves or ~10 kicks per player; goals reliably appear at 15+ rounds once enough ball movement has accumulated
- This is a calibration tradeoff, not a logic error — the 16 PLUnit tests confirm goal detection is correct (ball at goal position → score increment)

### 5.10 team1 always takes the opening kickoff
- do_kickoff/3 is hardcoded to team1 at match start (run_simulation/1 — robocup.pl:841); after a goal the conceding team kicks off (check_goal/0 — robocup.pl:715)
- No coin-toss or alternating opening kickoff is implemented; team1 consistently gains the first possession at match start
- Future: randomly select the opening kickoff team using random_member/2 (already used by next_first_mover/0) for symmetry

---

<!-- Acceptance checklist (T7.1):
  [x] Approximately 80 substantive bullets distributed across 5 sections
  [x] Word-count budgets noted per section
  [x] Every section has at least one code reference with robocup.pl:<line> or tests/test_robocup.pl:<line>
  [x] Section 3 subsections each have a constraints / transition / preconds-effects table
  [x] Tables cite concrete rows from the code
  [x] Design docs cited, not copied: docs/design-csp.md, docs/design-fsm.md, docs/design-strips.md
  [x] Floyd papers framed as benchmark domain, not our technique
  [x] Bullets only — no multi-sentence prose paragraphs written by this agent
-->
