function sw = R1_sweep(Pv, Tv, reheat, p, rh_frac)
% R1_SWEEP  Sweep main-steam P (bar) and T (degC). Matrices are indexed (iT, iP).
% reheat = 0 (none) or 1 (placeholder single reheat at P_rh = rh_frac*P1, T_rh = T1).
if nargin < 5, rh_frac = 0.20; end
nP = numel(Pv);  nT = numel(Tv);
names = {'eta_cycle','eta_plant','HR','x4','feasible','coal_kg_s','boiler_ex_frac', ...
         'capex_prem','fuel_cost','CO2_kWh'};
for k = 1:numel(names), sw.(names{k}) = nan(nT, nP); end
for iP = 1:nP
    for iT = 1:nT
        cfg = struct('P1',Pv(iP), 'T1',Tv(iT), 'Pcond',p.Pcond_base, 'reheat',reheat, ...
                     'P_rh',rh_frac*Pv(iP), 'T_rh',Tv(iT), 'n_fwh',0);
        o = R5_cycle(cfg, p);
        sw.eta_cycle(iT,iP)      = o.eta_cycle;
        sw.eta_plant(iT,iP)      = o.eta_plant;
        sw.HR(iT,iP)             = o.HR;
        sw.x4(iT,iP)             = o.x4;
        sw.feasible(iT,iP)       = o.feasible;
        sw.coal_kg_s(iT,iP)      = o.coal_kg_s;
        sw.boiler_ex_frac(iT,iP) = o.ex.boiler / o.ex.fuel;
        sw.capex_prem(iT,iP)     = o.capex_added_crore;
        sw.fuel_cost(iT,iP)      = o.fuel_cost_crore_yr;
        sw.CO2_kWh(iT,iP)        = o.CO2_kWh;
    end
end
sw.P = Pv;  sw.T = Tv;  sw.reheat = reheat;
end
