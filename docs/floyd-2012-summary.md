# Floyd 2012 — Summary for Team Reference

**Title**: Incorporating CBR into a Multi-Agent RoboCup Simulation  
**Authors**: Michael W. Floyd, Babak Esfandiari  
**Venue**: ICCBR 2012 (International Conference on Case-Based Reasoning), 2012  
**Thesis (author framing)**: A CBR system embedded in a multi-agent RoboCup team can coordinate role-specific behaviors across agents by sharing and retrieving cases that encode team-level game situations.

> Note for our team: This paper is the **benchmark domain** extended to multi-agent coordination. We do NOT use CBR. Our technique stack is FSM + STRIPS + CSP.

---

## RoboCup Architecture (as described / extended in paper)

- **Same server/client/monitor triad** as 2008 paper; this paper targets the full multi-agent setting.
- **Multi-agent coordination problem**: 11 clients run independently; sharing state across clients requires explicit mechanisms.
- **Coach channel**: the RoboCup server provides an optional coach agent that can broadcast team-level messages; Floyd uses this as the CBR coordination bus.
- **100 ms cycle retained**: each player client still must act within the server's 100 ms window regardless of coordination overhead.
- **Action primitives unchanged**: `dash`, `turn`, `kick`, `catch` — same as 2008 domain.
- **Team-level case**: a case now encodes multi-player formation snapshot + coordinated action sequence + outcome.
- **NoSwarm baseline**: a simple reactive team with no coordination; used as a weaker opponent benchmark.
- **CMUnited reference**: the historically strong RoboCup champion team; cited as an upper-bound performance target that CBR-equipped teams are measured against.

---

## Floyd's Extended CBR Approach (2012)

- **Shared case library**: all agents on a team read from a common case base rather than each maintaining their own.
- **Role-indexed retrieval**: a case is retrieved per role (goalkeeper case, defender case, forward case) but cases are jointly encoded with teammate positions.
- **Tracker agent**: a CBR-equipped agent that tracks ball trajectory across cycles and feeds trajectory features into case retrieval; contrasted with Sprinter's single-snapshot approach from 2008.
- **Coordination signal**: after retrieval, a team-level action recommendation is broadcast via the coach channel so roles act coherently.
- **Outcome evaluation**: outcome is measured at team level (goal differential) not per-agent, rewarding emergent coordination.
- **Comparison baselines**: NoSwarm (no coordination), fixed-strategy teams, and the 2008 single-agent CBR variant.

---

## What Our Project Keeps (from this domain framing)

- **Role-specific behavior modules** — goalkeeper / defender / forward as named, distinct behavioral units; directly motivates our three FSMs.
- **Formation as a setup constraint** — paper's team-level case includes initial formation; we implement formation via CSP (`place_team/1` with `clpfd` zone + spacing constraints).
- **Possession as a coordination primitive** — the paper tracks which agent has ball control to gate kick/catch; we model this as `possession(Team, Role)` dynamic fact.
- **Pass action as a role transition trigger** — defender-to-forward pass is a named coordination action; we have `pass` in our STRIPS action schema with explicit preconditions/effects.
- **Defender intercept behavior** — the paper describes a defender role that moves to cut off ball-to-goal paths; we model this as the `intercept` FSM state for the defender.

## What Our Project Drops

- **CBR coordination bus** — no shared case library, no coach channel, no retrieval over historical games.
- **Multi-agent message passing** — no inter-agent communication beyond shared Prolog dynamic facts.
- **Trajectory tracking (Tracker agent)** — no ball velocity or trajectory state; ball is a static position fact each round.
- **Learning / outcome feedback** — no case utility update after each game.
- **Large team scale** — paper experiments with 11-player teams; we use 3 per team.
- **Real-time constraints** — no 100 ms deadline; our round-based `simulate_round/0` runs at Prolog speed.

---

## Useful Ideas Borrowed for Our Symbolic Design

- **Tracker-style ball proximity sensing** → our `in_catch_range/2` sensor helper abstracts this into a Boolean condition for FSM transitions.
- **Formation zones per role** → CSP constraints in `place_team/1`: goalkeeper zone near own goal, defender in own half, forward near opposing half.
- **Defender intercept role** → `intercept` FSM state: defender moves toward a computed intercept point on the ball-to-goal line.
- **Pass-to-forward as a named action** → STRIPS `pass(Actor, Teammate)` with precondition `possession(Team, defender)` and effect `possession(Team, forward)`.
- **NoSwarm as implicit foil** → our two-team setup mirrors the paper's single vs. coordinated team experiments; CSP formation and FSM coordination give us a "symbolic coordination" advantage over a NoSwarm-style random team.
