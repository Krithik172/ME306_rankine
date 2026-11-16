function out = R3_fwh(st6, cfg, p) %#ok<INUSD>
% R3_FWH  *** STUB. R3 OWNER: IMPLEMENT. ***
% Baseline behaviour: no heaters, so boiler inlet (state 7) = pump exit (state 6).
% TODO (R3): extraction pressures, bleed fractions from energy balances, heater
% states e1..en / f1..fn / d1..dn, mass fractions through the turbine, irreversibility, capex.
if cfg.n_fwh > 0
    error('R3_fwh:notImplemented', 'Feedwater heating not implemented yet (R3 owner).');
end
out.st7 = st6;
out.D_fwh = 0;                           % exergy destruction, kJ/kg main steam
out.capex_added_crore = 0;
end
