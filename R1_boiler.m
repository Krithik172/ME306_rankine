function out = R1_boiler(P1, T1, st7, p, reh)
% R1_BOILER  Steam generator module (state 1, heat input, exergy, cost).
%   P1, T1  main-steam pressure (bar) and temperature (degC)
%   st7     feedwater state entering the boiler (from R3, or the pump if no heaters)
%   reh     optional struct with fields q (kJ/kg) and dpsi (kJ/kg): reheater duty and
%           exergy gain, supplied by R2 so the boiler exergy balance includes reheat.
% All outputs are per kg of main steam.
if nargin < 5 || isempty(reh), reh = struct('q', 0, 'dpsi', 0); end

st1     = steam_props('PT', P1, T1);
q_main  = st1.h - st7.h;                 % kJ/kg, boiler (economiser + evaporator + SH)
q_steam = q_main + reh.q;                % kJ/kg, total heat to steam
q_fuel  = q_steam / p.eta_boiler;        % kJ/kg, fuel heat (GCV basis)

psi1    = exergy_flow(st1, p);
psi7    = exergy_flow(st7, p);
Ex_fuel = p.phi * q_fuel;
Ex_gain = (psi1 - psi7) + reh.dpsi;

out.st1      = st1;
out.q_main   = q_main;
out.q_steam  = q_steam;
out.q_fuel   = q_fuel;
out.Ex_fuel  = Ex_fuel;
out.Ex_gain  = Ex_gain;
out.Ex_destr = Ex_fuel - Ex_gain;        % includes stack (flue-gas) loss
out.Ex_boiler_eff = Ex_gain / Ex_fuel;
out.capex_prem_crore = material_premium(P1, T1, p);
end
