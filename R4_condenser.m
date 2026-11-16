function out = R4_condenser(Pcond, st4, p)
% R4_CONDENSER  Condenser module (state 5, heat rejection, cooling water).
%   out = R4_condenser(Pcond, [], p)    -> state 5 only
%   out = R4_condenser(Pcond, st4, p)   -> also rejection duty and exergy loss
% TODO (R4): condenser-pressure capex / cooling-tower penalty, feasible pressure range.
out.st5 = steam_props('Px', Pcond, 0);                 % saturated liquid
out.capex_added_crore = 0;                             % TODO (R4)
if nargin >= 2 && ~isempty(st4)
    out.q_rej   = st4.h - out.st5.h;                   % kJ/kg main steam
    out.cw_per_kg = out.q_rej / (p.cp_w * p.dT_cw);    % kg cooling water / kg steam
    out.L_cond  = exergy_flow(st4, p) - exergy_flow(out.st5, p);   % external loss, kJ/kg
end
end
