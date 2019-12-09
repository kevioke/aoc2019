replace([_|Tail], 0, NewElem, [NewElem|Tail]).
replace([Head|Tail], Pos, Elem, [Head|NewTail]) :- NewPos is Pos - 1, replace(Tail, NewPos, Elem, NewTail), !.

mode(Int, Mode1, Mode2, Mode3):-
  Int1 is mod(Int // 100, 10),
  Int2 is mod(Int // 1000, 10),
  Int3 is mod(Int // 10000, 10),
  mode(Int1, Mode1),
  mode(Int2, Mode2),
  mode(Int3, Mode3).

mode(0, position_mode).
mode(1, immediate_mode).

math_op(1, add).
math_op(2, mul).

do_math_op(add, Val1, Val2, Result) :-
  Result is Val1 + Val2.
do_math_op(mul, Val1, Val2, Result) :-
  Result is Val1 * Val2.

resolve_val(State, position_mode, Param, Val) :-
  nth0(Param, State, Pos),
  nth0(Pos, State, Val).
resolve_val(State, immediate_mode, Param, Val) :-
  nth0(Param, State, Val).

%halt instruction
run_computer(State, InstPtr, State, [State]) :- nth0(InstPtr, State, 99).

%add or multiply instructions
run_computer(State, InstPtr, FinalState, [State|NextStates]) :-
  nth0(InstPtr, State, CurrentInt),
  OpInt is mod(CurrentInt, 100),
  math_op(OpInt, Op),

  mode(CurrentInt, Mode1, Mode2, _),
  ParamPtr1 is InstPtr + 1,
  ParamPtr2 is InstPtr + 2,
  resolve_val(State, Mode1, ParamPtr1, Val1),
  resolve_val(State, Mode2, ParamPtr2, Val2),

  do_math_op(Op, Val1, Val2, MathResult),

  DestPtr is InstPtr + 3,
  resolve_val(State, immediate_mode, DestPtr, Dest),
  replace(State, Dest, MathResult, NextState),

  NextInstPtr is InstPtr + 4,
  run_computer(NextState, NextInstPtr, FinalState, NextStates).

run_computer(State, InstPtr, FinalState, [printed(State, InstPtr)|NextStates]) :-
  nth0(InstPtr, State, CurrentInt),
  OpInt is mod(CurrentInt, 100),
  OpInt = 4,
  mode(CurrentInt, Mode, _, _),

  ValPtr is InstPtr + 1,
  resolve_val(State, Mode, ValPtr, Val),
  print(Val),
  nl,

  NextInstPtr is InstPtr + 2,
  run_computer(State, NextInstPtr, FinalState, NextStates).

run_computer(State, InstPtr, FinalState, [State|NextStates]) :-
  nth0(InstPtr, State, CurrentInt),
  OpInt is mod(CurrentInt, 100),
  OpInt = 3,

  DestPtr is InstPtr + 1,
  resolve_val(State, immediate_mode, DestPtr, Dest),
  replace(State, Dest, 1, NextState),

  NextInstPtr is InstPtr + 2,
  run_computer(NextState, NextInstPtr, FinalState, NextStates).
