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

solution1(Filename, NumTotalOrbits) :-
  parse_file(Filename, _, Orbitals),
  assert_orbits(Orbitals),
  setof(orbital(A, B), orbits(A, B), AllOrbits),
  length(AllOrbits, NumTotalOrbits).

assert_orbits([]).
assert_orbits([Orbit|RemainingOrbits]) :-
  assert(Orbit),
  assert_orbits(RemainingOrbits).
