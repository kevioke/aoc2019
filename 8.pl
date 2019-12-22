% 1. No last element to remove, fail - cut stops alternatives
remove_last([], []) :- !, fail.

% 2. Only one element in list - return empty list - cut stops alternatives
remove_last([_], []) :- !.

% 3. If the rules above did not match, preserve the head of the
% list in the result list and recurse...
remove_last([X | T], [X | T2]) :-
    remove_last(T, T2).

sublist(_, Start, End, []) :- 0 is End, 0 is Start, !.
sublist([H|T], Start, End, [H|Sublist]) :-
  0 is Start,
  \+ 0 is End,
  sublist(T, 0, End - 1, Sublist).

sublist([_|T], Start, End, Sublist) :-
  \+ 0 is Start,
  \+ 0 is End,
  sublist(T, Start - 1, End - 1, Sublist).

layers([], _, []).
layers(Input, LayerSize, [Layer|RemainingLayers]) :-
  sublist(Input, 0, LayerSize, Layer),
  length(Input, InputSize),
  sublist(Input, LayerSize, InputSize, RemainingInput),
  layers(RemainingInput, LayerSize, RemainingLayers).

get_layers(LayerSize, Layers) :-
  read_file_to_string("input8.txt", StringInput, []),
  string_chars(StringInput, Input),
  remove_last(Input, CleanInput),
  print(CleanInput),
  nl,
  layers(CleanInput, LayerSize, Layers).


