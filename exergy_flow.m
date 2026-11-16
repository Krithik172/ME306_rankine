function psi = exergy_flow(st, p)
% EXERGY_FLOW  Specific flow exergy (kJ/kg) relative to the dead state in params().
%   psi = (h - h0) - T0 (s - s0)
d   = steam_props('PT', p.P0, p.T0_C);
psi = (st.h - d.h) - p.T0*(st.s - d.s);
end
