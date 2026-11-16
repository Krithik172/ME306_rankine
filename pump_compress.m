function [st6, w_p] = pump_compress(st5, P_out, p)
% PUMP_COMPRESS  Feed pump, incompressible liquid. w_p in kJ/kg.
w_s = st5.v*(P_out - st5.P)*100;      % m3/kg * bar * (100 kPa/bar) = kJ/kg
w_p = w_s/p.eta_p;
st6 = steam_props('Ph', P_out, st5.h + w_p);
end
