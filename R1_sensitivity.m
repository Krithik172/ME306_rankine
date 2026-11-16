function out = R1_sensitivity(sw, base, p)
% R1_SENSITIVITY  How robust is the cost-optimal main-steam condition to the cost assumptions?
%   sw   : reheat sweep from R1_sweep (e.g. swB)
%   base : baseline cycle from R5_cycle
%   p    : params() (needs p.tier_T, p.tier_prem, p.pprem_per_bar)
% The thermodynamics is NOT recomputed; only the cost assumptions change.
% Annualised incremental cost  dCost = (CRF + OM)*added capex - fuel saving   [Rs crore/yr]

% ---- OAT cases: {label, field, [low base high]}
oat = {
    'Premium 566-600 C',          'tier2',          [0.03 0.06 0.10];
    'Premium 600-620 C',          'tier3',          [0.08 0.15 0.25];
    'Boiler share of capex',      'boiler_share',   [0.25 0.35 0.45];
    'Baseline capex [Rs cr/MW]',  'capex',          [6 8 10];
    'Coal price [Rs/t]',          'coal_cost_Rs_t', [2500 3500 4500];
    'Discount rate',              'i',              [0.07 0.09 0.12];
    'PLF',                        'PLF',            [0.60 0.75 0.85];
    'Pressure premium [per bar]', 'pprem_per_bar', [2.5e-4 5e-4 1e-3]
    };

% ---- base case
q0 = p;
d0 = dcost_map(sw, base, q0);
[T0, P0, d0min] = optimum(sw, d0);
fprintf('Base case optimum: T1 = %.0f C, P1 = %.0f bar, dCost = %.1f Rs crore/yr\n', T0, P0, d0min);

% ---- one-at-a-time sensitivity
fprintf('\nOne-at-a-time sensitivity:\n');
rows = {};
for r = 1:size(oat,1)
    vals = oat{r,3};
    for k = 1:3
        q = set_assumption(q0, oat{r,2}, vals(k));
        [To, Po, dm] = optimum(sw, dcost_map(sw, base, q));
        fprintf('  %-28s %-8g -> T1 = %3.0f C, P1 = %3.0f bar, dCost = %7.1f\n', ...
                oat{r,1}, vals(k), To, Po, dm);
        rows(end+1,:) = {oat{r,1}, vals(k), To, Po, dm}; %#ok<AGROW>
    end
end
out.oat = cell2table(rows, 'VariableNames', {'Parameter','Value','T1_opt','P1_opt','dCost'});

% ---- Monte Carlo: all assumptions varied together, uniform between low and high
rng(1);  nMC = 1000;
Tmc = zeros(nMC,1);  Pmc = zeros(nMC,1);
for n = 1:nMC
    q = q0;
    for r = 1:size(oat,1)
        v = oat{r,3};
        q = set_assumption(q, oat{r,2}, v(1) + rand*(v(3) - v(1)));
    end
    [Tmc(n), Pmc(n)] = optimum(sw, dcost_map(sw, base, q));
end
fprintf('\nMonte Carlo (%d scenarios), optimum temperature:\n', nMC);
Tu = unique(Tmc)';
for t = Tu
    fprintf('  T1 = %3.0f C : %5.1f %% of scenarios\n', t, 100*mean(Tmc == t));
end
fprintf('Optimum pressure:\n');
Pu = unique(Pmc)';
for pp = Pu
    fprintf('  P1 = %3.0f bar: %5.1f %% of scenarios\n', pp, 100*mean(Pmc == pp));
end

% ---- break-even premium for the 600-620 C tier
be = NaN;
for v = 0:0.005:0.40
    To = optimum(sw, dcost_map(sw, base, set_assumption(q0, 'tier3', v)));
    if To < 620, be = v; break, end
end
fprintf('\n620 C beats 600 C only if its premium is below about %.1f %% of boiler-island cost (assumed %.0f %%).\n', ...
        100*be, 100*p.tier_prem(3));

% ---- plots
figure('Name','R1 sensitivity','Position',[100 100 1100 450]);
tiledlayout(1,2,'TileSpacing','compact');
nexttile
freq = arrayfun(@(t) 100*mean(Tmc == t), Tu);
bar(Tu, freq);
xlabel('Optimum $T_1$ [$^\circ$C]', 'Interpreter','latex');
ylabel('Share of scenarios [\%]', 'Interpreter','latex');
title('Monte Carlo: cost-optimal temperature', 'Interpreter','latex');
nexttile
iP0 = find(sw.P == P0, 1);  hold on
for v = [0.08 0.15 0.25]
    d = dcost_map(sw, base, set_assumption(q0, 'tier3', v));
    plot(sw.T, d(:,iP0), '-o', 'DisplayName', sprintf('premium 600-620 C = %.0f\\%%', 100*v));
end
xlabel('$T_1$ [$^\circ$C]', 'Interpreter','latex');
ylabel('Annualised incremental cost [Rs crore/yr]', 'Interpreter','latex');
title(sprintf('Cost vs temperature at $P_1$ = %.0f bar', P0), 'Interpreter','latex');
legend('Location','best', 'Interpreter','latex'); grid on

out.base_opt = [T0 P0 d0min];  out.T_mc = Tmc;  out.P_mc = Pmc;  out.breakeven_tier3 = be;
end

function d = dcost_map(sw, base, q)
crf = q.i*(1+q.i)^q.N / ((1+q.i)^q.N - 1);
yr  = 3600*8760*q.PLF/1000;                              % kg/s -> tonnes per year
fuel      = sw.coal_kg_s   * yr * q.coal_cost_Rs_t / 1e7;   % Rs crore/yr
fuel_base = base.coal_kg_s * yr * q.coal_cost_Rs_t / 1e7;
capex = zeros(size(fuel));
for iT = 1:numel(sw.T)
    for iP = 1:numel(sw.P)
        capex(iT,iP) = material_premium(sw.P(iP), sw.T(iT), q);
    end
end
d = (crf + q.OM)*capex - (fuel_base - fuel);
d(sw.feasible ~= 1) = inf;
end

function [Topt, Popt, dmin] = optimum(sw, d)
[dmin, k] = min(d(:));
[iT, iP] = ind2sub(size(d), k);
Topt = sw.T(iT);  Popt = sw.P(iP);
end

function q = set_assumption(q, field, v)
switch field
    case 'tier2',  q.tier_prem(2) = v;
    case 'tier3',  q.tier_prem(3) = v;
    case 'capex',  q.capex_base_crore = v * q.W_gross_MW;
    otherwise,     q.(field) = v;
end
end
