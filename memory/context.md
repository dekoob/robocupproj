Symbolic AI project report 

Comment to be removed later: what i wrote isn’t definitive, but it describes the steps written in the code. Feel free to change some formulations or to add things if you find it pertinent. 
 Symbolic Knowledge Representation
Our design began with the translation of the continuous soccer environment into a discrete Symbolic AI framework. We utilized Prolog facts to define the static geometry of the field, specifically choosing a 100x50 coordinate system. This simplification allows for clear logical reasoning while maintaining the proportional integrity of a standard RoboCup field.
We implemented the following symbolic structures:
Static Entities: The field dimensions and goal locations are represented as constant facts, providing a fixed reference for all spatial calculations.
Dynamic Entities: To simulate the agent's "World Model," we used the :- dynamic directive for the ball and players. This allows our program to simulate sensory updates—effectively mimicking the see and sense_body messages described in the RoboCup server protocols.

 Role-Based Agent Strategy
A key design decision was the delegation of tasks through specific player roles: the Forward and the Goalkeeper.
Rationale for Initial Positions: We strategically initialized the Team 1 Forward at (45,25). This placement ensures the agent is positioned near the midline, reducing the distance to the ball at kickoff and optimizing the path to the opponent’s goal.
Stamina Constraints: Stamina indicates the level of energy every player has. Following the specifications found in the research slides, we initialized player stamina at 4000. This introduces a realistic physical constraint. We considered that every action in our simulation is designed to consume energy, requiring the agent to manage its effort during a round.

 Logic Programming and Inference
We chose a Rule-Based Decision-Making approach. Instead of using sub-symbolic or probabilistic methods, our agents function on pure logical inference. For example, the decision to "kick" versus "move" is determined by evaluating symbolic proximity constants. This ensures that the agent's behavior is predictable, explainable, and adheres to the strict logical structure required by Prolog.

