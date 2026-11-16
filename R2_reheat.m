function out = R2_reheat(st1, P_rh, T_rh, p)
% R2_REHEAT  *** PLACEHOLDER (R1 reference reheat). R2 OWNER: REPLACE / EXTEND. ***
% Single reheat: HP turbine st1 -> st2 (P_rh), reheater st2 -> st3 (T_rh), no pressure drop.
% TODO (R2): pressure drop, double reheat, optimum P_rh, reheater exergy loss, capex.
[st2, w_hp] = turbine_expand(st1, P_rh, p.eta_t);
st3 = steam_props('PT', P_rh, T_rh);
out.st2  = st2;
out.st3  = st3;
out.w_hp = w_hp;
out.q_rh = st3.h - st2.h;
out.dpsi = exergy_flow(st3, p) - exergy_flow(st2, p);
out.capex_added_crore = 0;               % TODO (R2)
end
