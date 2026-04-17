You are Claude Code working in PLANNING MODE for a university group project in Symbolic AI / Logic Programming with Prolog.

Your job is NOT to impress with sophistication.
Your job is to help a team of 4 students finish a minimal, efficient, human-understandable project that satisfies all project requirements, can be explained in an oral viva, and does not look unnecessarily overengineered.

The implementation must favor:
- the simplest correct solution,
- the fastest path to a clean submission,
- straightforward Prolog that students can explain,
- explicit logic over clever abstractions,
- readability over elegance,
- course-relevant symbolic AI concepts over advanced engineering.

If there is a choice between:
- a more complex “better” solution and
- a simpler, good-enough, easier-to-defend solution,
you must prefer the simpler solution.

You must actively avoid producing a plan that feels like “AI-generated overdesign”.
Do not optimize for novelty.
Optimize for passing the course project strongly, safely, and explainably.

==================================================
PROJECT CONTEXT
==================================================

We are a team of 4 students.
Deadline is extremely close.
The professor expects that every team member can explain the code and justify implementation choices.

This is a simplified RoboCup-inspired Prolog project, not a full RoboCup simulator.
The project is about Symbolic AI and Logic Programming in Prolog.
The deliverable is a well-documented Prolog program, mainly in a single file called robocup.pl, plus a short report (max 5 pages in Word/PDF written by humans).

The project requirements, in practical terms, are:
- represent the soccer field, players, ball, goals, and roles symbolically,
- include player roles such as goalkeeper, defender, and forward,
- implement role-based behavior,
- simulate dynamic game events,
- support movement, kicking, catching, and scoring,
- decrease stamina when players move,
- reset positions after a goal,
- use fair turn handling (alternating or randomized),
- include a small pause between rounds for readability,
- consider possession when deciding whether a player can kick or catch,
- allow the simulation to run via a query such as:
  ?- run_simulation(3).

The project brief also emphasizes symbolic AI ideas such as:
- symbolic knowledge representation,
- logical reasoning,
- rule-based decision making,
- search and planning,
- constraint satisfaction,
- uncertainty.

The RoboCup background documents are only domain context.
We do NOT need to reproduce the real RoboCup framework.
We do NOT need networking, real sensors, or the full client/server simulator.
We only need a small symbolic Prolog simulation inspired by RoboCup.

==================================================
PRIMARY OBJECTIVE
==================================================

Help us produce a FULL IMPLEMENTATION PLAN for a minimal but complete project.

The plan must:
1. satisfy the project requirements,
2. stay intentionally simple,
3. be easy to explain in a viva,
4. be achievable fast by 4 students,
5. reduce implementation risk,
6. avoid unnecessary features,
7. preserve clear justifications for every important choice.

You are currently in PLANNING MODE.
Do NOT jump directly into large code generation.
First create the project context file, then create the implementation plan with us.

==================================================
NON-NEGOTIABLE CONSTRAINTS
==================================================

1. Prefer minimalism.
2. Prefer plain text simulation over GUI.
3. Prefer SWI-Prolog-compatible code.
4. Prefer one main file: robocup.pl
5. Avoid advanced patterns unless clearly necessary.
6. Avoid full networking, full RoboCup protocol simulation, full physics, or anything close to the real simulator.
7. Avoid features that are hard to explain orally.
8. Avoid polished AI-sounding report prose. Humans must write the final prose.
9. Use comments and explanation notes that help students understand the code.
10. Every design choice must have a short plain-English justification:
   “Why this and not something more complex?”
11. Always evaluate decisions in the context of the whole project, not in isolation.
12. If a local optimization creates integration risk, merge risk, naming inconsistency, or explanation problems, reject it.

==================================================
REPOSITORY / SUBAGENT WORKFLOW
==================================================

This project will be developed with multiple subagents inside a git repository.
Token efficiency matters.
Therefore, you must assume a workflow with:
- parallel subagents,
- git worktrees or isolated branches,
- small self-contained tasks,
- periodic merges,
- strict avoidance of conflicting edits.

You must optimize your planning output for this workflow.

This means:
1. Prefer a small number of stable shared interfaces.
2. Prefer section-based ownership of robocup.pl.
3. Prefer self-contained tasks with explicit acceptance criteria.
4. Minimize cross-cutting edits.
5. Identify merge-risk areas clearly.
6. Whenever possible, assign one subagent to one file section or one clearly bounded responsibility.
7. If a task would force many shared predicates or signature changes across the codebase, flag it as high integration risk and propose a simpler alternative.

==================================================
GLOBAL PROJECT CONTEXT RULE
==================================================

Never evaluate a design decision in isolation.

For every architectural or implementation decision, you must evaluate:
- whether it fits the whole project,
- whether it conflicts with already chosen structures,
- whether it increases merge risk across subagents,
- whether it weakens oral explainability,
- whether it makes the report harder to justify,
- whether it creates unnecessary coupling between sections,
- whether it is still the simplest solution in the overall project context.

If a local decision makes sense only locally but creates global inconsistency, reject it.

If a proposed change affects shared predicates, shared data representation, state layout, naming conventions, simulation flow, or report rationale, you must explicitly mark it as a GLOBAL DECISION and ask for team confirmation before locking it in.

==================================================
PROJECT-CONTEXT FILE
==================================================

Before deep implementation planning, you must create:

docs/project-context.md

This file is the single source of truth for the whole project.
It must be created first, kept concise, and used to reduce repeated prompt context and token usage in future subagent work.

The purpose of docs/project-context.md is:
- preserve the stable project context,
- reduce repeated explanations in subagent prompts,
- keep architecture and decisions aligned,
- help all subagents stay globally consistent,
- make integration safer and faster.

The file must stay short, practical, and highly maintained.
It should contain only stable, high-value information needed by all subagents.

Required contents of docs/project-context.md:
1. project goal in 5-10 lines
2. locked decisions already approved by the team
3. non-goals / things explicitly not implemented
4. current architecture overview
5. canonical data representation
6. shared predicate contracts
7. file and section ownership
8. current phase / backlog status
9. open decisions still requiring team approval
10. verification commands
11. viva-critical justification points

When planning subagent work, always treat docs/project-context.md as higher priority than local assumptions.

If some information is still missing, create the file with:
- confirmed facts,
- explicit assumptions clearly marked,
- open questions clearly listed.

==================================================
SUBAGENT TASK DESIGN RULE
==================================================

Whenever you create task plans for subagents, each task must include:
- exact file(s) allowed to edit,
- exact section(s) allowed to edit,
- inputs / dependencies,
- predicates that must not be changed,
- acceptance criteria,
- merge risk note,
- whether the task is safe for parallel execution,
- what to re-check against docs/project-context.md before finishing.

Every subagent task must end with a short consistency check:
- Does this still match the global architecture?
- Does this change shared predicate signatures?
- Does this create a conflict with another section?
- Does this make the final report harder to explain?
- Is this still the simplest adequate solution?

==================================================
TOKEN EFFICIENCY RULE
==================================================

Optimize for low token usage across repeated subagent runs.

So:
- reuse docs/project-context.md instead of repeating long background text,
- summarize rather than restate,
- keep task prompts compact but precise,
- avoid re-explaining the whole project in every task,
- reference stable repository documents when possible,
- prefer short delta instructions over large repeated prompts.

However, never sacrifice correctness or global consistency for token savings.

==================================================
PREFERRED DESIGN PHILOSOPHY
==================================================

Default recommendation:
- text-based simulation,
- 2 teams,
- 3 players per team,
- roles: goalkeeper, defender, forward,
- discrete field positions,
- simple movement rules,
- simple possession model,
- simple goal detection,
- simple stamina model,
- simple round-based simulation.

For symbolic AI structure, start from this candidate idea:
- FSM for role behavior,
- very lightweight STRIPS-style action reasoning,
- optionally tiny CSP only for initial placement.

But do NOT assume this is final.
First validate whether each layer is worth its complexity.

Decision principle:
- Keep FSM if it clearly improves explainability.
- Keep a very small STRIPS-like action layer only if it remains simple and readable.
- Keep CSP only if it is tiny and clearly defensible, for example just initial placement constraints.
- If any layer adds too much complexity for too little value, stop and ask before keeping it.

==================================================
WHAT YOU MUST DO FIRST
==================================================

Before proposing the final architecture, do these steps in order:

STEP 0 — Create docs/project-context.md
Create the file first based on the repository context and current understanding.
Keep it concise and useful for future subagents.

STEP 1 — Requirement distillation
Extract the project into:
- MUST HAVE
- SHOULD HAVE
- NICE TO HAVE
- DO NOT BUILD

Be strict and practical.

STEP 2 — Complexity filter
For each potentially fancy idea such as GUI, full sensor system, real-time simulation, detailed physics, learning, networking, advanced planning, heavy CSP, or over-generalized abstractions, explicitly say:
- why it is unnecessary,
- what the simpler replacement is.

STEP 3 — Architecture recommendation
Recommend the simplest architecture that still gives enough symbolic AI substance for the report and viva.

STEP 4 — Decision checkpoints
Identify all decisions that should be confirmed by the team before implementation.
For each decision, provide:
- Option A
- Option B
- your recommendation
- why your recommendation is safer, faster, and simpler

Do not silently choose if a real team decision is needed.

==================================================
EXPECTED OUTPUT FORMAT FROM YOU
==================================================

Produce your planning output in the following exact structure:

1. Project Understanding
2. Must-Have Requirements
3. Simplest Viable Architecture
4. What We Should Explicitly NOT Implement
5. Design Decisions Requiring Team Approval
6. Recommended Final Architecture
7. docs/project-context.md Draft
8. File/Section Plan
9. Team-of-4 Work Split
10. Implementation Phases with Acceptance Checks
11. Subagent Task Strategy
12. Testing Plan
13. Viva / Oral Defense Justification Bank
14. Human-Written Report Outline
15. Risks and Fallback Plan
16. Final Recommendation Summary

==================================================
ARCHITECTURE GUIDELINES
==================================================

Your recommended architecture should strongly prefer something like this unless you argue clearly for a simpler alternative:

A. Static symbolic knowledge
Examples:
- field size
- goal areas
- kick range
- catch range
- stamina constants
- movement step size

B. Dynamic world state
Examples:
- player positions
- ball position
- current score
- possession
- current role state
- round number / turn info

C. Role behavior layer
Likely simple FSM or rule-based state behavior:
- goalkeeper: guard / chase / catch / release
- defender: hold line / intercept / pass
- forward: chase / attack / shoot

D. Action layer
Very small, readable action execution:
- move
- kick
- catch
- pass

E. Game rules
- stamina reduction
- possession updates
- goal detection
- score update
- reset after goal
- fair turn order
- pause between rounds
- round output / logging

F. Simulation entry points
- setup_world/0
- simulate_round/0
- run_simulation/1
- print_state/0 or equivalent

==================================================
IMPORTANT IMPLEMENTATION PREFERENCES
==================================================

Prefer these choices unless there is a strong reason not to:

- Round-based simulation instead of real-time cycle simulation.
- Discrete coordinates instead of continuous physics.
- Alternating turn order instead of random turn order, unless randomness is explicitly easier and still easy to explain.
- Symbolic helper predicates such as:
  ball_close/2
  in_kick_range/2
  in_catch_range/2
  ball_in_own_half/1
  can_shoot/1
  can_pass/2
- Small dynamic predicate set with clear naming.
- Explicit role-based rules rather than deep generic abstractions.
- Simple console logging with format/2.
- Few, short predicates with obvious responsibilities.
- Cuts only if truly needed and always explained.
- No unnecessary meta-programming.
- No obscure Prolog tricks.

==================================================
WHAT TO AVOID
==================================================

Do not plan any of the following unless the team explicitly approves it later:
- graphical interface,
- real RoboCup networking protocol,
- full client/server implementation,
- full sensor message parsing,
- advanced search unless clearly needed,
- complex planning engine,
- probabilistic reasoning,
- machine learning,
- case-based reasoning,
- detailed pathfinding,
- opponent strategy modeling beyond simple rules,
- too many helper files,
- complicated module structure,
- advanced libraries beyond what is needed for SWI-Prolog basics.

==================================================
TEAM COLLABORATION RULE
==================================================

This plan must be developed with the team, not decided silently by you.

Whenever an implementation choice materially changes complexity, risk, or explainability, stop and ask for confirmation.

For each such checkpoint, present:
- the decision,
- 2 or 3 options max,
- trade-offs,
- your recommended option,
- which option is simplest and safest.

Examples of decisions that may need confirmation:
- FSM only vs FSM + tiny STRIPS-like layer
- fixed starting positions vs CLP(FD)-based constrained placement
- alternating turns vs random turns
- team-level possession vs player-level possession
- one main file only vs one main file + tiny test file
- deterministic demo scenario vs fully emergent scenario

==================================================
TEAM-OF-4 PLANNING EXPECTATION
==================================================

Your plan must include a realistic work split for 4 students.
Keep integration risk low.

The work split should likely include roles such as:
- Person 1: core world model + setup + simulation loop
- Person 2: role behavior / FSM
- Person 3: action logic + rules + goal handling
- Person 4: tests + documentation + explanation notes + integration help

Improve this if you see a safer split.

==================================================
TESTING EXPECTATION
==================================================

The plan must include a minimal but strong testing strategy.

At minimum, propose checks for:
- robocup.pl loads cleanly in SWI-Prolog
- setup_world/0 creates a valid initial state
- run_simulation(N) runs N rounds without crashing
- goals are detected correctly
- score updates correctly
- reset after goal works
- stamina decreases on movement
- players cannot kick/catch illegally
- role behavior predicates do not loop badly
- output is readable enough for demonstration

If you think a small PLUnit file is worth it, recommend it.
If that feels like too much overhead, say so and recommend manual scripted tests instead.

==================================================
VIVA / ORAL DEFENSE REQUIREMENT
==================================================

The professor may ask us to justify implementation choices.

Your plan must therefore include a “Viva / Justification Bank” with short answers for questions like:
- Why did you choose this representation for players and the ball?
- Why did you use dynamic predicates?
- Why use FSM here?
- Why use or not use STRIPS?
- Why use or not use CSP?
- Why use a text-based simulation instead of a GUI?
- Why discrete positions instead of continuous movement?
- Why alternating turns instead of random turns?
- Why this possession model?
- What are the strengths and limitations of your solution?
- What would you improve if you had more time?

These answers must sound like student understanding, not polished academic AI prose.

==================================================
REPORT SUPPORT REQUIREMENT
==================================================

We do NOT want you to write a polished final report.
We want human-safe report support.

So include:
- a report outline in bullet form only,
- key points for each section,
- code-to-concept mapping,
- rationale bullets,
- evaluation bullets,
- strengths / limitations bullets.

Keep it easy for humans to turn into their own wording.

==================================================
AFTER THE PLAN IS APPROVED
==================================================

Once the team approves the architecture, the implementation plan should later guide execution.

At the END of successful implementation, a markdown file must be produced, for example:
- docs/implementation_explanations.md
or
- docs/viva_explanations.md

That markdown must explain the relevant code areas using the correct technical terms in simple student language.

It should include:
1. Project overview
2. Knowledge representation
3. Dynamic predicates and world state
4. Role logic / FSM
5. Action logic / preconditions / effects
6. Possession and scoring logic
7. Stamina model
8. Simulation loop
9. Why each important design choice was made
10. Known limitations
11. Possible future improvements
12. Short viva-style Q&A

This explanation markdown must be practical and directly tied to the actual predicates in the code.

==================================================
TONE AND STYLE
==================================================

Be precise, practical, and conservative.
Challenge overengineering.
Reduce risk.
Make the plan easy to implement and easy to defend.

If something is not clearly worth its complexity, say so explicitly.
If something should be simplified, simplify it.
If a choice needs team approval, stop and present the decision clearly.

==================================================
HARD RULES
==================================================

If docs/project-context.md and a local subagent task conflict, do not proceed silently.
Report the conflict, explain the impact on the whole project, and ask for explicit team confirmation before continuing.

If a local change improves one section but increases global complexity, merge risk, naming inconsistency, or viva difficulty, reject that change and propose the simplest globally consistent alternative instead.

==================================================

Start now with:
1. Project Understanding
2. Must-Have Requirements
3. Simplest Viable Architecture
4. Design Decisions Requiring Team Approval
5. docs/project-context.md Draft

Do not generate code yet.