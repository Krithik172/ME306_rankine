function out = R5_cycle(cfg, p)
% R5_CYCLE  Integrated cycle (R5 owns). Calls R1..R4 with the agreed state numbering.
%   cfg fields: P1, T1, Pcond, reheat (0/1), P_rh, T_rh, n_fwh
if ~isfield(cfg, 'reheat'), cfg.reheat = 0; end
if ~isfield(cfg, 'n_fwh'),  cfg.n_fwh  = 0; end

% ---- condenser exit, pump, feedwater train (states 5, 6, 7)
c4        = R4_condenser(cfg.Pcond, [], p);   st5 = c4.st5;
[st6,w_p] = pump_compress(st5, cfg.P1, p);
fw        = R3_fwh(st6, cfg, p);              st7 = fw.st7;

% ---- main steam (state 1)
r1a = R1_boiler(cfg.P1, cfg.T1, st7, p);      st1 = r1a.st1;

% ---- expansion (states 2, 3, 4) and reheat
if cfg.reheat == 0
    [st4, w_t] = turbine_expand(st1, cfg.Pcond, p.eta_t);
    st2 = [];  st3 = [];
    reh = struct('q', 0, 'dpsi', 0);
    capex_rh = 0;
    D_turb = exergy_flow(st1,p) - exergy_flow(st4,p) - w_t;
else
    rh = R2_reheat(st1, cfg.P_rh, cfg.T_rh, p);
    st2 = rh.st2;  st3 = rh.st3;
    [st4, w_lp] = turbine_expand(st3, cfg.Pcond, p.eta_t);
    w_t = rh.w_hp + w_lp;
    reh = struct('q', rh.q_rh, 'dpsi', rh.dpsi);
    capex_rh = rh.capex_added_crore;
    D_turb = (exergy_flow(st1,p) - exergy_flow(st2,p)) ...
           + (exergy_flow(st3,p) - exergy_flow(st4,p)) - w_t;
end

% ---- boiler including reheater heat, then condenser duty
r1 = R1_boiler(cfg.P1, cfg.T1, st7, p, reh);
c4 = R4_condenser(cfg.Pcond, st4, p);

% ---- energy / performance (per kg of main steam)
q_in      = r1.q_steam;
w_net     = w_t - w_p;
eta_cycle = w_net / q_in;
eta_plant = eta_cycle * p.eta_boiler * p.eta_gen;
HR        = p.kWh2kcal / eta_plant;                       % kcal/kWh
mdot      = p.W_gross_MW*1000 / (p.eta_gen * w_net);      % kg/s main steam

% ---- fuel and emissions
coal_kg_s = mdot * r1.q_fuel / p.GCV_kJ;
CO2_kWh   = p.EF_CO2 * (3600/eta_plant) / 1e6;            % kg CO2 / kWh
coal_t_yr = coal_kg_s * 3600 * 8760 * p.PLF / 1000;
fuel_cost_crore_yr = coal_t_yr * p.coal_cost_Rs_t / 1e7;

% ---- exergy balance (per kg main steam)
psi5 = exergy_flow(st5,p);  psi6 = exergy_flow(st6,p);
ex.fuel    = r1.Ex_fuel;
ex.net     = w_net;
ex.boiler  = r1.Ex_destr;
ex.turbine = D_turb;
ex.pump    = w_p - (psi6 - psi5);
ex.fwh     = fw.D_fwh;
ex.cond    = c4.L_cond;                                   % external loss (cooling water)
ex.resid   = ex.fuel - (ex.net + ex.boiler + ex.turbine + ex.pump + ex.fwh + ex.cond);
ex.eta_II  = w_net / ex.fuel;                             % second-law efficiency (cycle level)
ex.destr_total_MW = (ex.boiler + ex.turbine + ex.pump + ex.fwh) * mdot / 1000;

% ---- energy closure (valid while R3 is the no-heater stub; R3 owner generalises)
E_resid = q_in - w_net - c4.q_rej;

% ---- cost (added capex vs baseline, Rs crore)
capex_added = r1.capex_prem_crore + capex_rh + c4.capex_added_crore + fw.capex_added_crore;

% ---- pack
out.st1 = st1; out.st2 = st2; out.st3 = st3; out.st4 = st4;
out.st5 = st5; out.st6 = st6; out.st7 = st7;
out.w_t = w_t;  out.w_p = w_p;  out.w_net = w_net;  out.q_in = q_in;
out.eta_cycle = eta_cycle;  out.eta_plant = eta_plant;  out.HR = HR;
out.mdot = mdot;  out.x4 = st4.x;
out.feasible = (st4.x >= p.x_min);
out.coal_kg_s = coal_kg_s;  out.CO2_kWh = CO2_kWh;
out.fuel_cost_crore_yr = fuel_cost_crore_yr;
out.capex_added_crore  = capex_added;
out.ann_cap_om_crore   = (p.CRF + p.OM) * capex_added;
out.cw_m3_s = mdot * c4.cw_per_kg / 1000;
out.ex = ex;  out.E_resid = E_resid;  out.r1 = r1;
end
