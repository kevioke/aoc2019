parse_file(Filename, Chars, OrbitalSet):-
  read_file_to_string(Filename, String, []),
  string_chars(String, Chars),
  orbitals(Orbitals, Chars, []),
  list_to_ord_set(Orbitals, OrbitalSet).

orbitals([directly_orbits(X, Y)]) --> planet(X), [')'], planet(Y), ['\n'].
orbitals([directly_orbits(X, Y)|Orbitals]) --> planet(X), [')'], planet(Y), ['\n'], orbitals(Orbitals).
planet(X) -->
  [A, B, C],
  { A \= ')', B \= ')', C \= ')' },
  { A \= '\n', B \= '\n', C \= '\n' },
  {atomic_list_concat([A, B, C], X)}.

orbits(A, B) :- directly_orbits(A, B).
orbits(A, B) :- directly_orbits(A, C), orbits(C, B).

assert_orbits([]).
assert_orbits([Orbit|RemainingOrbits]) :-
  assert(Orbit),
  assert_orbits(RemainingOrbits).

solution1(Filename, NumTotalOrbits) :-
  retractall(directly_orbits(_, _)),
  parse_file(Filename, _, Orbitals),
  assert_orbits(Orbitals),
  setof(orbital(A, B), orbits(A, B), AllOrbits),
  length(AllOrbits, NumTotalOrbits).


neighbor(X, Y) :- directly_orbits(X, Y); directly_orbits(Y, X).

bfs([PlanetPath|_], Goal, _, PlanetPath) :-
  last(PlanetPath, CurrentPlanet),
  neighbor(CurrentPlanet, Goal),
  !.

bfs([PlanetPath|RemainingPlanetPaths], Goal, Visited, ShortestPath) :-
  last(PlanetPath, CurrentPlanet),
  ord_add_element(Visited, CurrentPlanet, UpdatedVisited),

  %Warning: maybe we should check for not neighbor goal
  setof(Neighbor, neighbor(CurrentPlanet,Neighbor), Neighbors),
  ord_subtract(Neighbors, Visited, NotVisitedNeighbors),

  gen_paths(PlanetPath, NotVisitedNeighbors, NeighborPaths),
  append(RemainingPlanetPaths, NeighborPaths, NewPaths),

  bfs(NewPaths, Goal, UpdatedVisited, ShortestPath).

bfs(Start, Goal, ShortestPath) :-
  setof(Neighbor, neighbor(Start,Neighbor), Neighbors),
  gen_paths([], Neighbors, NeighborPaths),
  bfs(NeighborPaths, Goal, [], ShortestPath).

gen_paths(_, [], []).
gen_paths(PlanetPath, [TargetPlanet|NextTargetPlanets], [TargetPlanetPath|NextTargetPlanetsPath]) :-
  append(PlanetPath, [TargetPlanet], TargetPlanetPath),
  gen_paths(PlanetPath, NextTargetPlanets, NextTargetPlanetsPath).

solution2(Filename, ShortestPath, ResultLength) :-
  retractall(directly_orbits(_, _)),
  parse_file(Filename, _, Orbitals),
  assert_orbits(Orbitals),
  bfs('YOU', 'SAN', ShortestPath),
  length(ShortestPath, Length),
  ResultLength is Length -1. % Don't consider the last traversal
