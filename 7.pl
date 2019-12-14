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
current_operation(Comp, output_op(Value)) :-
  inst_ptr(Comp, InstPtr),
  memory_val(Comp, InstPtr, MemVal),
  4 is mod(MemVal, 100),

  mode(MemVal // 100, 0, Mode),

  memory(Comp, Memory),
  Param1 is InstPtr + 1,
  resolve_val(Memory, Mode, Param1, Value).

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
  current_operation(Comp, output_op(Value)),
  memory(Comp, Memory),
  memory(NewComp, Memory),
  inputs(Comp, Inputs),
  inputs(NewComp, Inputs),

  outputs(Comp, CurrentOutputs),
  outputs(NewComp, [Value|CurrentOutputs]),

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

run_until_output(Comp, Comp) :- current_operation(Comp, halt).
run_until_output(Comp, Comp) :- outputs(Comp, [X]), number(X).
run_until_output(Comp, FinalComp) :-
  current_operation(Comp, Op),
  Op \= halt,
  outputs(Comp, []),
  single_step(Comp, NextComp),
  run_until_output(NextComp, FinalComp).

run_amps(Memory, [Phase1, Phase2, Phase3, Phase4, Phase5], Output5) :-
  run_until_halt([0, Memory, [Phase1, 0], []], Comp1),
  outputs(Comp1, [Output1]),
  run_until_halt([0, Memory, [Phase2, Output1], []], Comp2),
  outputs(Comp2, [Output2]),
  run_until_halt([0, Memory, [Phase3, Output2], []], Comp3),
  outputs(Comp3, [Output3]),
  run_until_halt([0, Memory, [Phase4, Output3], []], Comp4),
  outputs(Comp4, [Output4]),
  run_until_halt([0, Memory, [Phase5, Output4], []], Comp5),
  outputs(Comp5, [Output5]).

amp_output(Memory, Output) :-
  permutation([0, 1, 2, 3, 4], Phases),
  run_amps(Memory, Phases, Output).

solution1(Memory, MaxOutput, OutputSet) :-
  setof(Output, amp_output(Memory, Output), OutputSet),
  max_list(OutputSet, MaxOutput).

run_amps2(_, [Comp1, Comp2, Comp3, Comp4, Comp5], _, Outputs, FinalOutput) :-
  (current_operation(Comp1, halt);
   current_operation(Comp2, halt);
   current_operation(Comp3, halt);
   current_operation(Comp4, halt);
   current_operation(Comp5, halt)),
  last(Outputs, FinalOutput), !.
run_amps2(InitialInput, [Comp1, Comp2, Comp3, Comp4, Comp5], [Phase1, Phase2, Phase3, Phase4, Phase5], Outputs, FinalOutput) :-
  append(Phase1, InitialInput, Comp1Input),
  append_inputs(Comp1, Comp1Input, Comp1WithInputs),
  run_until_output(Comp1WithInputs, NewComp1),
  outputs(NewComp1, Outputs1),

  append(Phase2, Outputs1, Comp2Input),
  append_inputs(Comp2, Comp2Input, Comp2WithInputs),
  run_until_output(Comp2WithInputs, NewComp2),
  outputs(NewComp2, Outputs2),

  append(Phase3, Outputs2, Comp3Input),
  append_inputs(Comp3, Comp3Input, Comp3WithInputs),
  run_until_output(Comp3WithInputs, NewComp3),
  outputs(NewComp3, Outputs3),

  append(Phase4, Outputs3, Comp4Input),
  append_inputs(Comp4, Comp4Input, Comp4WithInputs),
  run_until_output(Comp4WithInputs, NewComp4),
  outputs(NewComp4, Outputs4),

  append(Phase5, Outputs4, Comp5Input),
  append_inputs(Comp5, Comp5Input, Comp5WithInputs),
  run_until_output(Comp5WithInputs, NewComp5),
  outputs(NewComp5, Outputs5),
  append(Outputs, Outputs5, NewOutputs),

  run_amps2(Outputs5, [NewComp1, NewComp2, NewComp3, NewComp4, NewComp5], [[], [], [], [], []], NewOutputs, FinalOutput).

append_inputs(Comp, Inputs, NewComp) :-
  memory(Comp, Mem),
  memory(NewComp, Mem),
  inst_ptr(Comp, Ptr),
  inst_ptr(NewComp, Ptr),
  inputs(NewComp, Inputs).

test_basic :-
  %output 1 if input equal to 8 otherwise 0
  run_until_output([0, [3,9,8,9,10,9,4,9,99,-1,8], [8], []], [_, _, _, [1]]),
  run_until_output([0, [3,9,8,9,10,9,4,9,99,-1,8], [2], []], [_, _, _, [0]]),
  run_until_output([0, [3,9,8,9,10,9,4,9,99,-1,8], [10], []], [_, _, _, [0]]),

  %output 1 if input less than 8 otherwise 0
  run_until_output([0, [3,9,7,9,10,9,4,9,99,-1,8], [8], []], [_, _, _, [0]]),
  run_until_output([0, [3,9,7,9,10,9,4,9,99,-1,8], [9], []], [_, _, _, [0]]),
  run_until_output([0, [3,9,7,9,10,9,4,9,99,-1,8], [7], []], [_, _, _, [1]]),

  %output 1 if equal to 8 otherwise 0
  run_until_output([0, [3,3,1108,-1,8,3,4,3,99], [8], []], [_, _, _, [1]]),
  run_until_output([0, [3,3,1108,-1,8,3,4,3,99], [10], []], [_, _, _, [0]]),
  run_until_output([0, [3,3,1108,-1,8,3,4,3,99], [7], []], [_, _, _, [0]]),

  %output 1 if less than 8 otherwise 0
  run_until_output([0, [3,3,1107,-1,8,3,4,3,99], [10], []], [_, _, _, [0]]),
  run_until_output([0, [3,3,1107,-1,8,3,4,3,99], [8], []], [_, _, _, [0]]),
  run_until_output([0, [3,3,1107,-1,8,3,4,3,99], [7], []], [_, _, _, [1]]),

  %output 0 if input 0, otherwise 1 
  run_until_output([0, [3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9], [0], []], [_, _, _, [0]]),
  run_until_output([0, [3,12,6,12,15,1,13,14,13,4,13,99,-1,0,1,9], [1], []], [_, _, _, [1]]),
  run_until_output([0, [3,3,1105,-1,9,1101,0,0,12,4,12,99,1], [0], []], [_, _, _, [0]]),
  run_until_output([0, [3,3,1105,-1,9,1101,0,0,12,4,12,99,1], [1], []], [_, _, _, [1]]),

  %The program will then output 999 if the input value is below 8, output 1000 if the input value is equal to 8, or output 1001 if the input value is greater than 8.
  run_until_output([0, [3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31, 1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104, 999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99], [7], []], [_, _, _, [999]]),
  run_until_output([0, [3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31, 1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104, 999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99], [8], []], [_, _, _, [1000]]),
  run_until_output([0, [3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31, 1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104, 999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99], [9], []], [_, _, _, [1001]]).


test1(Output) :-
  Comp = [0, [3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5], [], []],
  run_amps2([0], [Comp, Comp, Comp, Comp, Comp], [[9],[8],[7],[6],[5]],[], Output).

test2(Output) :-
  Comp = [0, [3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54, -5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4, 53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10], [], []],
  run_amps2([0], [Comp, Comp, Comp, Comp, Comp], [[9],[7],[8],[5],[6]],[], Output).

amp_output2(Memory, Output) :-
  permutation([[9],[8],[7],[6],[5]], Phases),
  Comp = [0, Memory, [], []],
  run_amps2([0], [Comp, Comp, Comp, Comp, Comp], Phases,[], Output).

solution2(Memory, MaxOutput, OutputSet) :-
  setof(Output, amp_output2(Memory, Output), OutputSet),
  max_list(OutputSet, MaxOutput).
