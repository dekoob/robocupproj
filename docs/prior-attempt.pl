%defining the game environment
% Fields and goals
field(size(100,50)). %The sizes were chosen this way for simplification
goal_position(team1,position(0,25)).
goal_position(team2,position(100,25)).

%initialization of the position of the ball
:- dynamic ball/1.
ball(position(50, 25)).

%initialization of the state of players
:- dynamic player/4.
% Team 1 setup
player(team1, goalkeeper, position(5, 25), stamina(4000)).
player(team1, defender, position(25, 15), stamina(4000)).
player(team1, forward, position(45, 25), stamina(4000)).
%we initialized stamina 4000 following the provided slides of samples
% stamina is an indicator about the energy every player has

% Team 2 setup
player(team2, goalkeeper, position(95, 25), stamina(4000)).
player(team2, defender, position(75, 35), stamina(4000)).
player(team2, forward, position(55, 25), stamina(4000)).

% implementing each agents' behaviour

%facts and rules for different player roles
% goal keeper takes the ball if it is close enough

% Defender Logic: Intercepts if ball is in defensive half
action_defender(Team) :-
    player(Team, defender, Pos, _),
    ball(BallPos),
    % Logic to stay between the ball and home goal
    goal_position(Team, GoalPos),
    calculate_intercept_point(BallPos, GoalPos, InterceptPos),
    move_to_position(Team, defender, InterceptPos).

% Goalkeeper Logic: Catch the ball if it is close enough, ie if it
% enters the small radius

action_goalkeeper(Team) :-
    player(Team, goalkeeper, Pos, _),
    ball(BallPos),
    distance(Pos, BallPos, D),
    ( D =< 2.0 -> 
        format('~w Goalkeeper CATCHES the ball!~n', [Team]) ; 
        move_to_block_shot(Team)
    ).


% Moves player toward the ball and reduces their stamina

move_towards_ball(Team, Role) :-
    player(Team, Role, position(X1, Y1), stamina(S)),
    ball(position(X2, Y2)),
    S >= 10, % The player shoul have enough energy to move
    NewX is X1 + sign(X2 - X1),
    NewY is Y1 + sign(Y2 - Y1),
    NewS is S - 10, % Stamina depletion
    retract(player(Team, Role, _, _)),
    assertz(player(Team, Role, position(NewX, NewY), stamina(NewS))),
    format('~w ~w moves. Remaining Stamina: ~w~n', [Team, Role, NewS]).


