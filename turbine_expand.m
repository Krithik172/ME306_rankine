function [st_out, w] = turbine_expand(st_in, P_out, eta)
% TURBINE_EXPAND  Adiabatic expansion with isentropic efficiency (R5 owns this).
%   w = specific work, kJ/kg
st_s   = steam_props('Ps', P_out, st_in.s);
h_out  = st_in.h - eta*(st_in.h - st_s.h);
st_out = steam_props('Ph', P_out, h_out);
w      = st_in.h - h_out;
end
