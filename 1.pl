%Part 1
sum([], 0).
sum([Head|Tail], Result) :- sum(Tail, TailSum), Result is TailSum + Head.

module_fuel(Mass, FuelNeeded) :- FuelNeeded is div(Mass,3)-2.
module_fuels([], []).
module_fuels([HMass|TMass], [HFuel|TFuel]) :- module_fuel(HMass, HFuel), module_fuels(TMass, TFuel).

total_fuel(Masses, TotalFuel) :-
  module_fuels(Masses,ModuleFuels),
  sum(ModuleFuels,TotalFuel).

total_fuel(TotalFuel) :- Masses = [147383 ,111288 ,130868 ,140148 ,79840 ,63305 ,98475 ,66403 ,68753 ,136306 ,94135 ,51317 ,136151 ,71724 ,68795 ,68526 ,130515 ,73606 ,56828 ,57778 ,86134 ,105030 ,123367 ,97633 ,85043 ,110888 ,110785 ,90662 ,128865 ,70997 ,90658 ,79944 ,141089 ,67543 ,78358 ,143579 ,146971 ,78795 ,94097 ,82473 ,73216 ,50919 ,100248 ,112751 ,86227 ,117399 ,123833 ,148570 ,141464 ,123266 ,94346 ,53871 ,51180 ,112900 ,119863 ,106694 ,129841 ,75990 ,63509 ,50135 ,140081 ,138387 ,112697 ,57023 ,114256 ,81429 ,95573 ,57056 ,52277 ,75137 ,53364 ,125823 ,113227 ,93993 ,129808 ,114025 ,101677 ,127114 ,65823 ,65834 ,57955 ,102314 ,60656 ,89982 ,61068 ,72089 ,71745 ,72460 ,142318 ,91951 ,111759 ,61177 ,143739 ,92202 ,70168 ,80164 ,77867 ,64235 ,141137 ,102636], total_fuel(Masses, TotalFuel).

%Part 2
new_module_fuel(Mass, FuelNeeded) :-
  module_fuel(Mass, SingleFuel),
  SingleFuel =< 0, FuelNeeded = 0.

new_module_fuel(Mass, FuelNeeded) :-
  module_fuel(Mass, SingleFuel),
  new_module_fuel(SingleFuel, LeftOverFuel),
  FuelNeeded is SingleFuel + LeftOverFuel.

new_module_fuels([], []).
new_module_fuels([HMass|TMass], [HFuel|TFuel]) :- new_module_fuel(HMass, HFuel), new_module_fuels(TMass, TFuel).

new_total_fuel(Masses, TotalFuel) :-
  new_module_fuels(Masses, ModuleFuels),
  sum(ModuleFuels, TotalFuel).

new_total_fuel(TotalFuel) :- Masses = [147383 ,111288 ,130868 ,140148 ,79840 ,63305 ,98475 ,66403 ,68753 ,136306 ,94135 ,51317 ,136151 ,71724 ,68795 ,68526 ,130515 ,73606 ,56828 ,57778 ,86134 ,105030 ,123367 ,97633 ,85043 ,110888 ,110785 ,90662 ,128865 ,70997 ,90658 ,79944 ,141089 ,67543 ,78358 ,143579 ,146971 ,78795 ,94097 ,82473 ,73216 ,50919 ,100248 ,112751 ,86227 ,117399 ,123833 ,148570 ,141464 ,123266 ,94346 ,53871 ,51180 ,112900 ,119863 ,106694 ,129841 ,75990 ,63509 ,50135 ,140081 ,138387 ,112697 ,57023 ,114256 ,81429 ,95573 ,57056 ,52277 ,75137 ,53364 ,125823 ,113227 ,93993 ,129808 ,114025 ,101677 ,127114 ,65823 ,65834 ,57955 ,102314 ,60656 ,89982 ,61068 ,72089 ,71745 ,72460 ,142318 ,91951 ,111759 ,61177 ,143739 ,92202 ,70168 ,80164 ,77867 ,64235 ,141137 ,102636], new_total_fuel(Masses, TotalFuel).
