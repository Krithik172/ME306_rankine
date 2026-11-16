function p = params()
% PARAMS  Single source of truth for every constant (ME306 Alignment Sheet v1).
% Units: bar, degC, kJ/kg, kJ/kgK, MW, kg/s, Rs crore.  (TBC) = awaiting instructor.

% ---- conversions
p.kcal2kJ  = 4.1868;
p.kWh2kcal = 860.42;

% ---- baseline plant
p.W_gross_MW = 660;        % gross generator output, fixed for all designs
p.P1_base    = 247;        % bar
p.T1_base    = 565;        % degC
p.Pcond_base = 0.10;       % bar
p.PLF        = 0.75;

% ---- component efficiencies (TBC)
p.eta_t      = 0.88;       % isentropic, HP / IP / LP
p.eta_p      = 0.85;       % pump isentropic
p.eta_gen    = 0.985;      % generator + mechanical
p.eta_boiler = 0.87;       % fixed for all designs

% ---- fuel and emissions
p.GCV_kcal      = 4000;                    % kcal/kg
p.GCV_kJ        = 4000*4.1868;             % kJ/kg
p.coal_cost_Rs_t = 3500;                   % Rs per tonne
p.EF_CO2        = 96;                      % kg CO2 per GJ coal heat (TBC)

% ---- constraint
p.x_min = 0.88;                            % LP exhaust dryness fraction

% ---- design-space bounds, "conventional" values (TBC)
p.P1_range       = [220 300];              % bar
p.T1_range       = [540 620];              % degC
p.Trh_range      = [565 620];              % degC
p.Prh_frac_range = [0.15 0.25];            % reheat pressure / main-steam pressure
p.Pcond_range    = [0.05 0.15];            % bar
p.n_fwh_max      = 8;

% ---- exergy
p.T0_C = 25;                               % degC (dead state)
p.T0   = 298.15;                           % K
p.P0   = 1.013;                            % bar
p.phi  = 1.0;                              % fuel exergy / GCV (TBC)

% ---- economics
p.i   = 0.09;
p.N   = 25;
p.CRF = p.i*(1+p.i)^p.N / ((1+p.i)^p.N - 1);   % ~0.1018
p.OM  = 0.02;                              % fraction of capex per year
p.capex_base_crore_per_MW = 8;             % Rs crore/MW (TBC)
p.capex_base_crore = p.capex_base_crore_per_MW * p.W_gross_MW;
p.boiler_share     = 0.35;                 % R1 assumption: boiler island share of capex
p.tier_T        = [566 600 620];          % degC upper limits of tiers 1-3
p.tier_prem     = [0 0.06 0.15 0.30];     % fraction of boiler-island capex per tier
p.pprem_per_bar = 5e-4;                   % pressure premium per bar above 247

% ---- cooling water (R4)
p.cp_w  = 4.18;                            % kJ/kgK
p.dT_cw = 10;                              % K temperature rise
end
