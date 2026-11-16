function [eta_plant, x4, HR, feasible] = cycle_for_simulink(P1, T1, Pcond, reheat, P_rh, T_rh)
% CYCLE_FOR_SIMULINK  Scalar-in / scalar-out wrapper so a Simulink MATLAB Function block
% can call the whole cycle model (see the notebook, section 9).
persistent p
if isempty(p), p = params(); end
cfg = struct('P1',P1, 'T1',T1, 'Pcond',Pcond, 'reheat',reheat, 'P_rh',P_rh, 'T_rh',T_rh, 'n_fwh',0);
o = R5_cycle(cfg, p);
eta_plant = o.eta_plant;
x4        = o.x4;
HR        = o.HR;
feasible  = double(o.feasible);
end
