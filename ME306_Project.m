%% ME306 Project: Supercritical Coal Rankine Plant Uprate
% Integrated team notebook. Sections are owned by roles R1-R5.
% Run section by section (Ctrl+Enter). To convert to a Live Script:
% Editor tab > Save > Save As > "MATLAB Live Code Files (*.mlx)".
% Conventions: see the Team Alignment Sheet (units: bar, degC, kJ/kg, MW; state numbers 1-7, e/f/d).

%% 0. Setup (everyone)
clear; clc; close all
addpath(genpath(pwd));
assert(exist('XSteam','file') == 2, ...
    'XSteam.m not found. Download it from MATLAB File Exchange and put it in this folder.');
p = params();
set(groot, 'defaultTextInterpreter', 'latex', 'defaultAxesTickLabelInterpreter', 'latex', ...
           'defaultLegendInterpreter', 'latex');
fprintf('Setup OK. CRF = %.4f\n', p.CRF);

%% 1. Baseline validation point (everyone; owner R5)
% Baseline: 247 bar, 565 degC, 0.10 bar, no reheat, no feedwater heaters.
cfg0 = struct('P1',p.P1_base, 'T1',p.T1_base, 'Pcond',p.Pcond_base, ...
              'reheat',0, 'n_fwh',0);
base = R5_cycle(cfg0, p);
print_state_table(base)

fprintf('\nw_turbine = %.1f kJ/kg | w_pump = %.2f | w_net = %.1f | q_in = %.1f\n', ...
        base.w_t, base.w_p, base.w_net, base.q_in);
fprintf('eta_cycle = %.4f | eta_plant = %.4f | heat rate = %.0f kcal/kWh\n', ...
        base.eta_cycle, base.eta_plant, base.HR);
fprintf('x4 = %.4f -> feasible: %d\n', base.x4, base.feasible);
fprintf('steam flow = %.1f kg/s | coal = %.1f kg/s | CO2 = %.3f kg/kWh\n', ...
        base.mdot, base.coal_kg_s, base.CO2_kWh);
fprintf('Energy closure residual = %.2e kJ/kg | exergy closure residual = %.2e kJ/kg\n', ...
        base.E_resid, base.ex.resid);

% Independent reference values (IAPWS-IF97), tolerance 0.1 %
ref = struct('h1',3390.3, 'h4',2147.0, 'x4',0.8174, 'eta_cycle',0.3830, 'HR',2621);
fprintf('\nValidation against reference:\n');
check_val('h1',        base.st1.h,     ref.h1);
check_val('h4',        base.st4.h,     ref.h4);
check_val('x4',        base.x4,        ref.x4);
check_val('eta_cycle', base.eta_cycle, ref.eta_cycle);
check_val('HR',        base.HR,        ref.HR);

%% 2. R1: Boiler and steam generation
% Heat input per kg of steam and fuel heat:
%   q_in = h_1 - h_7 (+ q_reheat),     q_fuel = q_in / eta_boiler
% Boiler exergy destruction:
%   X_dest = phi * q_fuel - [ (psi_1 - psi_7) + (psi_3 - psi_2) ],   psi = (h - h_0) - T_0 (s - s_0)
fprintf('Baseline boiler:\n');
fprintf('  q_main = %.1f kJ/kg | q_fuel = %.1f kJ/kg\n', base.r1.q_main, base.r1.q_fuel);
fprintf('  boiler exergy destruction = %.1f kJ/kg (%.1f %% of fuel exergy)\n', ...
        base.r1.Ex_destr, 100*base.r1.Ex_destr/base.r1.Ex_fuel);
fprintf('  boiler exergy efficiency = %.3f\n', base.r1.Ex_boiler_eff);

%% 2a. R1: P-T sweep (no reheat vs placeholder reference reheat)
Pv = 220:10:300;          % bar
Tv = 540:10:620;          % degC
swA = R1_sweep(Pv, Tv, 0, p);          % no reheat
swB = R1_sweep(Pv, Tv, 1, p, 0.20);    % single reheat, P_rh = 0.20 P1, T_rh = T1 (R2 placeholder)
[PP, TT] = meshgrid(Pv, Tv);

figure('Name','R1 feasible P-T maps','Position',[100 100 1100 450]);
tl = tiledlayout(1,2,'TileSpacing','compact');
sws = {swA, swB};  ttl = {'No reheat', 'Single reheat ($P_{rh}=0.2P_1$, $T_{rh}=T_1$)'};
for k = 1:2
    nexttile; sw = sws{k};
    contourf(Pv, Tv, 100*sw.eta_plant, 12, 'LineColor','none'); hold on
    cb = colorbar; cb.Label.String = '$\eta_{plant}$ [\%]'; cb.Label.Interpreter = 'latex';
    plot(PP(sw.feasible==0), TT(sw.feasible==0), 'kx', 'MarkerSize', 7);   % x < 0.88
    plot(p.P1_base, p.T1_base, 'rp', 'MarkerFaceColor','r', 'MarkerSize', 12);
    xlabel('$P_1$ [bar]'); ylabel('$T_1$ [$^\circ$C]'); title(ttl{k});
end
title(tl, 'Plant efficiency (x = infeasible: $x_4<0.88$; star = baseline)', 'Interpreter', 'latex');

%% 2b. R1: boiler exergy and cost premium maps
figure('Name','R1 exergy and cost','Position',[100 100 1100 450]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile
contourf(Pv, Tv, 100*swB.boiler_ex_frac, 12, 'LineColor','none'); colorbar
xlabel('$P_1$ [bar]'); ylabel('$T_1$ [$^\circ$C]');
title('Boiler exergy destruction [\% of fuel exergy] (with reheat)')
nexttile
contourf(Pv, Tv, swA.capex_prem, 12, 'LineColor','none'); colorbar
xlabel('$P_1$ [bar]'); ylabel('$T_1$ [$^\circ$C]');
title('Material premium, added capex [Rs crore]')

%% 2c. R1: candidate main-steam conditions (feasible only, with reheat)
% Annualised incremental cost vs baseline = (CRF + OM) * added capex - fuel saving  [Rs crore/yr]
annCapOM = (p.CRF + p.OM) * swB.capex_prem;
fuelSave = base.fuel_cost_crore_yr - swB.fuel_cost;
dCost    = annCapOM - fuelSave;                    % negative = net saving
feasMask = swB.feasible == 1;
score = dCost;  score(~feasMask) = inf;
[~, idx] = sort(score(:));
fprintf('\nTop 5 feasible (reheat) main-steam conditions by annualised cost:\n');
fprintf('%8s %8s %10s %12s %14s\n','P1[bar]','T1[C]','eta_plant','HR[kcal/kWh]','dCost[Rs cr/yr]');
for k = 1:5
    [iT, iP] = ind2sub(size(score), idx(k));
    fprintf('%8.0f %8.0f %10.4f %12.0f %14.1f\n', Pv(iP), Tv(iT), swB.eta_plant(iT,iP), ...
            swB.HR(iT,iP), dCost(iT,iP));
end
% TODO (R1): choose the recommended (P1, T1) and justify against the
% thermodynamic optimum (highest P, T corner) and the material-cost premium.


%% 2d. R1: sensitivity of the recommended condition to the cost assumptions
% Re-scores the reheat sweep under different cost assumptions (premiums, capex,
% coal price, discount rate, PLF) and checks whether the optimum (P1, T1) moves.
sens = R1_sensitivity(swB, base, p);

%% 2e. R1: recommended condition vs baseline
cfgR = struct('P1',280, 'T1',600, 'Pcond',p.Pcond_base, 'reheat',1, ...
              'P_rh',0.2*280, 'T_rh',600, 'n_fwh',0);
rec = R5_cycle(cfgR, p);
print_state_table(rec)
names = {'eta_plant [%]','Heat rate [kcal/kWh]','x4 [-]','Coal [kg/s]', ...
         'CO2 [kg/kWh]','Boiler exergy destr. [% fuel]','Added capex [Rs cr]'};
b = [100*base.eta_plant, base.HR, base.x4, base.coal_kg_s, base.CO2_kWh, ...
     100*base.ex.boiler/base.ex.fuel, base.capex_added_crore];
r = [100*rec.eta_plant, rec.HR, rec.x4, rec.coal_kg_s, rec.CO2_kWh, ...
     100*rec.ex.boiler/rec.ex.fuel, rec.capex_added_crore];
disp(table(names', b', r', 'VariableNames', {'Metric','Baseline','Recommended'}))
%% 3. R2: Reheat system (FILLER)
% TODO (R2): replace R2_reheat.m. Compare none / single / double reheat,
% sweep P_rh, report exhaust quality, reheater exergy loss, incremental capex.

%% 4. R3: Regenerative feedwater heating (FILLER)
% TODO (R3): implement R3_fwh.m. Extraction pressures, bleed fractions, n = 0..8 heaters,
% diminishing returns, heater irreversibility, added capex.

%% 5. R4: Condenser and heat rejection (FILLER)
% TODO (R4): extend R4_condenser.m. Sweep P_cond over 0.05-0.15 bar, report
% w_net, eta, x4, cooling-water flow (base.cw_m3_s), and the capex penalty for low pressure.

%% 6. R5: Turbine expansion and integration (FILLER)
% TODO (R5): refine turbine_expand.m / R5_cycle.m (HP/IP/LP, extractions, mass-fraction bookkeeping).
% Full design-space search -> results table -> Pareto filter.

%% 7. Overall results table (R5 collects; format shared by all)
% One row per design; infeasible designs are flagged, not deleted.
mk = @(sw) table(PP(:), TT(:), repmat(sw.reheat, numel(PP), 1), sw.eta_plant(:), sw.HR(:), ...
        sw.x4(:), sw.boiler_ex_frac(:), sw.capex_prem(:), sw.coal_kg_s(:), sw.CO2_kWh(:), ...
        sw.feasible(:), 'VariableNames', {'P1','T1','reheat','eta_plant','HR','x4', ...
        'boilerExFrac','addedCapex_crore','coal_kg_s','CO2_kg_per_kWh','feasible'});
results = [mk(swA); mk(swB)];
disp(head(results, 5))
% writetable(results, 'results/R1_designs.csv');   % uncomment to share with R5

%% 8. Pareto / trade-off plots (R5 FILLER)
% TODO (R5): efficiency vs annualised cost vs exergy destruction vs CO2, feasible set only.

%% 9. Simulink hook (optional)
% 1) In MATLAB: simulink            % open Simulink
% 2) Add a MATLAB Function block and paste:
%
%   function [eta, x4, HR, feas] = fcn(P1, T1, Pcond, rh, Prh, Trh)
%   coder.extrinsic('cycle_for_simulink');
%   eta = 0; x4 = 0; HR = 0; feas = 0;
%   [eta, x4, HR, feas] = cycle_for_simulink(P1, T1, Pcond, rh, Prh, Trh);
%
% 3) Drive the inputs with Constant blocks, route outputs to Display blocks.
%    Test: 247, 565, 0.10, 0, 49.4, 565 should reproduce the baseline from section 1.
