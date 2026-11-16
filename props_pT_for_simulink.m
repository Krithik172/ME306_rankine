function [h, s] = props_pT_for_simulink(P, T)
h = XSteam('h_pT', P, T);
s = XSteam('s_pT', P, T);
end