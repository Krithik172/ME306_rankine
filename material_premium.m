function c = material_premium(P1, T1, p)
% Tiered material premium (fraction of boiler-island capex). All values are ASSUMPTIONS.
k = find(T1 <= p.tier_T, 1);
if isempty(k), k = numel(p.tier_prem); end
tprem = p.tier_prem(k);
pprem = p.pprem_per_bar * max(P1 - 247, 0);
c = p.boiler_share * p.capex_base_crore * (tprem + pprem);
end