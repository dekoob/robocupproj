# Floyd 2008 — Summary for Team Reference

**Title**: Using Case-Based Reasoning for Improving Robotic Soccer  
**Authors**: Michael W. Floyd, Babak Esfandiari, Kevin Lam  
**Venue**: FLAIRS-21 (Florida AI Research Society), 2008  
**Thesis (author framing)**: CBR can improve agent behavior in the RoboCup Soccer Server simulation by retrieving and adapting past game situations to guide current decisions.

> Note for our team: Floyd's approach is the **benchmark domain** we work in. We do NOT use CBR. Our technique stack is FSM + STRIPS + CSP.

---

## RoboCup Architecture (as described in paper)

- **Server/client/monitor triad**: Soccer Server manages physics; each player is a separate client process; monitor visualises play.
- **100 ms decision cycle**: every 100 ms the server broadcasts perceptual messages; clients must respond within that window.
- **Perceptual messages**: `see` (visual flags, players, ball), `sense_body` (stamina, speed, angle) — noisy and range-limited.
- **Action primitives available to clients**: `dash` (accelerate), `turn` (change body angle), `kick` (apply force to ball if in range), `catch` (goalkeeper only, within catch area).
- **Sensor noise**: distance and angle readings are subject to quantisation error; far objects disappear from `see` entirely.
- **Stamina model**: stamina initialised at 4000; decreases per dash; recovery each cycle; sprint speed tied to remaining stamina.
- **11-vs-11 standard team**: full teams with heterogeneous roles; paper uses simplified subsets for experiments.

---

## Floyd's CBR Approach

- **Case representation**: a case = (world-state snapshot, action taken, outcome quality score).
- **Retrieval**: nearest-neighbour match on world-state features (ball position, player positions, score, stamina).
- **Adaptation**: retrieved action reused or lightly modified for the current situation.
- **Learning loop**: outcomes feed back to update case utility weights — sub-symbolic, data-driven.
- **Baseline agent — Krislet**: a minimal Java RoboCup client; forward chases ball and kicks toward opponent goal; goalkeeper positions near own goal; used as the starting behavior that CBR is intended to improve.
- **Sprinter agent**: CBR-equipped variant; evaluates retrieved cases to decide dash/kick parameters.
- **Evaluation metric**: goal differential against fixed opponents over many simulated matches.

---

## What Our Project Keeps (from this domain framing)

- **Role-based behavior** — goalkeeper, defender, forward distinction directly from Krislet's design.
- **Discrete world state** — our 100×50 grid abstracts the continuous field; ball + player positions as integer pairs.
- **Action primitives mapped**: `dash` → `move_step`; `kick` → `kick`; `catch` → `catch`; `turn` folded into movement direction.
- **Stamina initialised at 4000** — same constant, used as a resource constraint in our STRIPS preconditions.
- **Goal detection + reset** — the paper's match loop (score, reset to kickoff) is replicated in our `check_goal/0`.

## What Our Project Drops

- **CBR entirely** — no case storage, no retrieval, no adaptation, no learning loop.
- **Real networking** — no UDP sockets, no Soccer Server process, no client-server protocol.
- **Sensor noise** — our agents have perfect, noise-free world state via Prolog dynamic facts.
- **Continuous physics** — no velocity, acceleration, spin, or wind; movement is one-step Manhattan.
- **Full 11-player teams** — we use 3 players per team (goalkeeper, defender, forward).
- **100 ms real-time cycle** — our simulation is round-based, discrete, driven by `run_simulation(N)`.

---

## Useful Ideas Borrowed for Our Symbolic Design

- **Krislet goalkeeper heuristic** → our `guard_goal` FSM state: goalkeeper moves toward own goal center when ball is distant.
- **Krislet forward heuristic** → our `chase_ball` and `shoot` FSM states: forward chases ball, kicks when in range.
- **Goalkeeper reset kick** → after a catch, goalkeeper kicks ball toward midfield (our `hold_ball` → kick action in STRIPS).
- **Role as the primary behavioral axis** — each role has a distinct decision loop; directly maps to one FSM per role.
- **Stamina as a STRIPS precondition** — Krislet-style stamina checks gate whether a `move_step` or `kick` action is applicable.
