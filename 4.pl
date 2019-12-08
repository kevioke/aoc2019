never_decreases([_]).
never_decreases([X, Y|T]) :-
  X =< Y,
  never_decreases([Y|T]).

has_two_adj([X,X|_]) :- !.
has_two_adj([_|T]) :-
  has_two_adj(T),
  !.

codes_to_numbers([], []).
codes_to_numbers([H|T], [Number|Numbers]) :-
  char_code('0', Zero),
  Number is H - Zero,
  codes_to_numbers(T, Numbers).

passwords(Number) :-
  between(124075, 580769, Number),
  number_codes(Number, Codes),
  codes_to_numbers(Codes, SplitNumbers),
  has_two_adj(SplitNumbers),
  never_decreases(SplitNumbers).

solution1(NumPasswords) :-
  setof(Number, passwords(Number), Solutions),
  length(Solutions, NumPasswords).

%solution2
has_exactly_two([X, X], Prev) :-
  Prev \= X.
has_exactly_two([X, X, Y|_], Prev) :-
  X \= Y,
  Prev \= X,
  !.
has_exactly_two([H|T], _) :-
  has_exactly_two(T, H),
  !.

passwords2(Number) :-
  between(124075, 580769, Number),
  number_codes(Number, Codes),
  codes_to_numbers(Codes, SplitNumbers),
  has_exactly_two(SplitNumbers, nil),
  never_decreases(SplitNumbers).

solution2(NumPasswords) :-
  setof(Number, passwords2(Number), Solutions),
  length(Solutions, NumPasswords).
