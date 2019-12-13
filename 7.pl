replace([_|Tail], 0, NewElem, [NewElem|Tail]).
replace([Head|Tail], Pos, Elem, [Head|NewTail]) :- NewPos is Pos - 1, replace(Tail, NewPos, Elem, NewTail), !.

mode(IntInstruction, 0, position_mode) :- 0 is mod(IntInstruction, 10).
mode(IntInstruction, 0, immediate_mode) :- 1 is mod(IntInstruction, 10).
mode(IntInstruction, ParamIndex, Mode) :-
  ParamIndex \= 0,
  NewParamIndex is ParamIndex - 1,
  mode(IntInstruction // 10, NewParamIndex, Mode).

math_op(1, add).
math_op(2, mul).

do_math_op(add, Val1, Val2, Result) :-
  Result is Val1 + Val2.
do_math_op(mul, Val1, Val2, Result) :-
  Result is Val1 * Val2.

jump_type(5, jump_if_true).
jump_type(6, jump_if_false).

jump(jump_if_true, Val1, Val2, _, Val2) :- Val1 \= 0.
jump(jump_if_true, Val1, _, InstPtr, NextInstPtr) :- Val1 = 0, NextInstPtr is InstPtr + 3.
jump(jump_if_false, Val1, Val2, _, Val2) :- Val1 = 0.
jump(jump_if_false, Val1, _, InstPtr, NextInstPtr) :- Val1 \= 0, NextInstPtr is InstPtr + 3.

comparison_type(7, less_than).
comparison_type(8, equals).
comparison(less_than, Val1, Val2, 1) :- Val1 < Val2.
comparison(less_than, Val1, Val2, 0) :- Val1 >= Val2.
comparison(equals, Val, Val, 1).
comparison(equals, Val1, Val2, 0) :- Val1 \= Val2.

resolve_val(Memory, position_mode, Param, Val) :-
  nth0(Param, Memory, Pos),
  nth0(Pos, Memory, Val).
resolve_val(Memory, immediate_mode, Param, Val) :-
  nth0(Param, Memory, Val).

inst_ptr(Comp, InstPtr) :-
  nth0(0, Comp, InstPtr). 

memory(Comp, Memory) :-
  nth0(1, Comp, Memory).

memory_val(Comp, Address, MemVal) :-
  nth0(1, Comp, Memory),
  nth0(Address, Memory, MemVal).

%assert_comp_len(OldComp, NewComp) :-
%  memory(OldComp, OldMemory),
%  length(OldMemory, MemoryLength),
%  memory(NewComp, NewMemory),
%  length(NewMemory, MemoryLength),
%  length(OldComp, 2),
%  length(NewComp, 2).

inputs(Comp, Inputs) :-
  nth0(2, Comp, Inputs).

outputs(Comp, Outputs) :-
  nth0(3, Comp, Outputs).
  
%Halt operation
current_operation(Comp, halt) :-
  inst_ptr(Comp, InstPtr),
  memory_val(Comp, InstPtr, MemVal),
  99 is mod(MemVal, 100).

%Math operation
current_operation(Comp, math_op(MathOp, Val1, Val2, Dest)) :-
  inst_ptr(Comp, InstPtr),
  memory_val(Comp, InstPtr, MemVal),
  OpInt is mod(MemVal, 100),
  math_op(OpInt, MathOp),

  Param1 is InstPtr + 1,
  Param2 is InstPtr + 2,
  Param3 is InstPtr + 3,

  mode(MemVal // 100, 0, Mode1),
  mode(MemVal // 100, 1, Mode2),

  memory(Comp, Memory),
  resolve_val(Memory, Mode1, Param1, Val1),
  resolve_val(Memory, Mode2, Param2, Val2),
  resolve_val(Memory, immediate_mode, Param3, Dest).

%Read operation
current_operation(Comp, input_op(Dest)) :-
  inst_ptr(Comp, InstPtr),
  memory_val(Comp, InstPtr, MemVal),
  3 is mod(MemVal, 100),

  memory(Comp, Memory),
  Param1 is InstPtr + 1,
  resolve_val(Memory, immediate_mode, Param1, Dest).

%Output operation
current_operation(Comp, output_op(Address)) :-
  inst_ptr(Comp, InstPtr),
  memory_val(Comp, InstPtr, MemVal),
  4 is mod(MemVal, 100),

  memory(Comp, Memory),
  Param1 is InstPtr + 1,
  resolve_val(Memory, immediate_mode, Param1, Address).

%Jump operation
current_operation(Comp, jump_op(NewInstPtr)) :-
  inst_ptr(Comp, InstPtr),
  memory_val(Comp, InstPtr, MemVal),
  OpInt is mod(MemVal, 100),
  jump_type(OpInt, JumpType),

  mode(MemVal // 100, 0, Mode1),
  mode(MemVal // 100, 1, Mode2),
  Param1 is InstPtr + 1,
  Param2 is InstPtr + 2,

  memory(Comp, Memory),
  resolve_val(Memory, Mode1, Param1, Val1),
  resolve_val(Memory, Mode2, Param2, Val2),
  jump(JumpType, Val1, Val2, InstPtr, NewInstPtr).

%Comparison operation
current_operation(Comp, comparison_op(Result, Dest)) :-
  inst_ptr(Comp, InstPtr),
  memory_val(Comp, InstPtr, MemVal),
  OpInt is mod(MemVal, 100),
  comparison_type(OpInt, ComparisonType),

  mode(MemVal // 100, 0, Mode1),
  mode(MemVal // 100, 1, Mode2),
  Param1 is InstPtr + 1,
  Param2 is InstPtr + 2,
  Param3 is InstPtr + 3,

  memory(Comp, Memory),
  resolve_val(Memory, Mode1, Param1, Val1),
  resolve_val(Memory, Mode2, Param2, Val2),
  resolve_val(Memory, immediate_mode, Param3, Dest),
  comparison(ComparisonType, Val1, Val2, Result).

%halt
single_step(Comp, Comp) :- current_operation(Comp, halt).

%add or multiply
single_step(Comp, NewComp) :- 
  current_operation(Comp, math_op(Op, Val1, Val2, Dest)),
  do_math_op(Op, Val1, Val2, Result),

  memory(Comp, Memory),
  replace(Memory, Dest, Result, NewMemory),
  memory(NewComp, NewMemory),

  inputs(Comp, Inputs),
  inputs(NewComp, Inputs),
  outputs(Comp, Outputs),
  outputs(NewComp, Outputs),

  inst_ptr(Comp, InstPtr),
  NewInstPtr is InstPtr + 4,
  inst_ptr(NewComp, NewInstPtr).

%input
single_step(Comp, NewComp) :- 
  current_operation(Comp, input_op(Dest)),
  inputs(Comp, [Input|RemainingInputs]),
  inputs(NewComp, RemainingInputs),

  memory(Comp, Memory),
  replace(Memory, Dest, Input, NewMemory),
  memory(NewComp, NewMemory),

  outputs(Comp, Outputs),
  outputs(NewComp, Outputs),

  inst_ptr(Comp, InstPtr),
  NewInstPtr is InstPtr + 2,
  inst_ptr(NewComp, NewInstPtr).

%output
single_step(Comp, NewComp) :- 
  current_operation(Comp, output_op(Address)),
  memory(Comp, Memory),
  memory(NewComp, Memory),
  inputs(Comp, Inputs),
  inputs(NewComp, Inputs),

  outputs(Comp, CurrentOutputs),
  memory_val(Comp, Address, Val),
  outputs(NewComp, [Val|CurrentOutputs]),

  inst_ptr(Comp, InstPtr),
  NewInstPtr is InstPtr + 2,
  inst_ptr(NewComp, NewInstPtr).

%jump
single_step(Comp, NewComp) :-
  current_operation(Comp, jump_op(JumpTo)),
  memory(Comp, Memory),
  memory(NewComp, Memory),
  inputs(Comp, Inputs),
  inputs(NewComp, Inputs),
  outputs(Comp, Outputs),
  outputs(NewComp, Outputs),
  inst_ptr(NewComp, JumpTo).

%comparison
single_step(Comp, NewComp) :-
  current_operation(Comp, comparison_op(Result, Dest)),

  memory(Comp, Memory),
  replace(Memory, Dest, Result, NewMemory),
  memory(NewComp, NewMemory),

  inputs(Comp, Inputs),
  inputs(NewComp, Inputs),
  outputs(Comp, Outputs),
  outputs(NewComp, Outputs),

  inst_ptr(Comp, InstPtr),
  NewInstPtr is InstPtr + 4,
  inst_ptr(NewComp, NewInstPtr).

run_until_halt(Comp, Comp) :- current_operation(Comp, halt).
run_until_halt(Comp, FinalComp) :-
  current_operation(Comp, Op),
  Op \= halt,
  single_step(Comp, NextComp),
  run_until_halt(NextComp, FinalComp).

%run_amps(State, [Phase], Input, Output) :-
%  single_step(State, 0, _, _, [Phase|Input], Output).
%
%run_amps(State, [Phase|Phases], Input, Output) :-
%  single_step(State, 0, _, _, [Phase|Input], IntermediateOutput),
%  run_amps(State, Phases, IntermediateOutput, Output). 
%
%outputs(State, Output) :-
%  permutation([0, 1, 2, 3, 4], Phase),
%  run_amps(State, Phase, [0], Output).
%
%solution1(State, MaxOutput) :-
%  setof(Output, outputs(State, Output), OutputSet),
%  max_list(OutputSet, MaxOutput).
