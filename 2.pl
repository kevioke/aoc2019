get([Elem|_], 0,  Elem).
get([_|Tail], Pos, Elem) :- NewPos is Pos - 1, get(Tail, NewPos, Elem).

replace([_|Tail], 0, NewElem, [NewElem|Tail]).
replace([Head|Tail], Pos, Elem, [Head|NewTail]) :- NewPos is Pos - 1, replace(Tail, NewPos, Elem, NewTail).

add_op(Loc1, Loc2, DestPos, Input, Output) :-
  get(Input, Loc1, A),
  get(Input, A, Op1),

  get(Input, Loc2, B),
  get(Input, B, Op2),

  Result is Op1 + Op2,

  get(Input, DestPos, Dest),

  replace(Input, Dest, Result, Output).

mul_op(Loc1, Loc2, DestPos, Input, Output) :-
  get(Input, Loc1, A),
  get(Input, A, Op1),

  get(Input, Loc2, B),
  get(Input, B, Op2),

  Result is Op1 * Op2,

  get(Input, DestPos, Dest),

  replace(Input, Dest, Result, Output).

process_ops(Input, CurrentPos, Input) :- get(Input, CurrentPos, 99).

process_ops(Input, CurrentPos, RunningResult) :-
  get(Input, CurrentPos, 1),
  Pos1 is 1 + CurrentPos,
  Pos2 is 2 + CurrentPos,
  DestPos is 3 + CurrentPos,
  add_op(Pos1, Pos2, DestPos, Input, Output),
  NewPos is CurrentPos + 4,
  process_ops(Output, NewPos, RunningResult).

process_ops(Input, CurrentPos, RunningResult) :-
  get(Input, CurrentPos, 2),
  Pos1 is 1 + CurrentPos,
  Pos2 is 2 + CurrentPos,
  DestPos is 3 + CurrentPos,
  mul_op(Pos1, Pos2, DestPos, Input, Output),
  NewPos is CurrentPos + 4,
  process_ops(Output, NewPos, RunningResult).

run_computer(Noun, Verb, ValAt0) :-
  Input = [1,0,0,3,1,1,2,3,1,3,4,3,1,5,0,3,2,6,1,19,2,19,9,23,1,23,5,27,2,6,27,31,1,31,5,35,1,35,5,39,2,39,6,43,2,43,10,47,1,47,6,51,1,51,6,55,2,55,6,59,1,10,59,63,1,5,63,67,2,10,67,71,1,6,71,75,1,5,75,79,1,10,79,83,2,83,10,87,1,87,9,91,1,91,10,95,2,6,95,99,1,5,99,103,1,103,13,107,1,107,10,111,2,9,111,115,1,115,6,119,2,13,119,123,1,123,6,127,1,5,127,131,2,6,131,135,2,6,135,139,1,139,5,143,1,143,10,147,1,147,2,151,1,151,13,0,99,2,0,14,0],
  replace(Input, 1, Noun, Input1),
  replace(Input1, 2, Verb, Input2),
  process_ops(Input2, 0, Result),
  get(Result, 0, ValAt0).

solution_1(ValAt0) :- run_computer(12, 2, ValAt0).

solution_2(Noun100PlusVerb) :-
  between(0, 99, Noun),
  between(0, 99, Verb),
  run_computer(Noun, Verb, 19690720),
  Noun100PlusVerb is 100 * Noun + Verb.
