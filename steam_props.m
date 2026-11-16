function st = steam_props(mode, a, b)
% STEAM_PROPS  The ONLY place XSteam is called. Swap the library here if needed.
%   st = steam_props('PT', P, T)   % bar, degC
%   st = steam_props('Ph', P, h)   % bar, kJ/kg
%   st = steam_props('Ps', P, s)   % bar, kJ/kgK
%   st = steam_props('Px', P, x)   % bar, dryness fraction 0..1
% Returns struct with fields P, T, h, s, v, x. (x = NaN above critical pressure.)
% XSteam default units: bar, degC, kJ/kg, kJ/kgK, m3/kg.

Pcrit = 220.64;
switch mode
    case 'PT'
        P = a;  T = b;
        h = XSteam('h_pT', P, T);
        s = XSteam('s_pT', P, T);
        v = XSteam('v_pT', P, T);
        if P >= Pcrit
            x = NaN;
        elseif T > XSteam('Tsat_p', P)
            x = 1;
        else
            x = 0;
        end
    case 'Ph'
        P = a;  h = b;
        T = XSteam('T_ph', P, h);
        s = XSteam('s_ph', P, h);
        v = XSteam('v_ph', P, h);
        x = quality(P, XSteam('x_ph', P, h), Pcrit);
    case 'Ps'
        P = a;  s = b;
        T = XSteam('T_ps', P, s);
        h = XSteam('h_ps', P, s);
        v = XSteam('v_ps', P, s);
        x = quality(P, XSteam('x_ps', P, s), Pcrit);
    case 'Px'
        P = a;  x = b;
        T  = XSteam('Tsat_p', P);
        hL = XSteam('hL_p', P);   hV = XSteam('hV_p', P);
        sL = XSteam('sL_p', P);   sV = XSteam('sV_p', P);
        vL = XSteam('vL_p', P);   vV = XSteam('vV_p', P);
        h = hL + x*(hV - hL);
        s = sL + x*(sV - sL);
        v = vL + x*(vV - vL);
    otherwise
        error('steam_props:mode', 'Unknown mode "%s"', mode);
end
st = struct('P', P, 'T', T, 'h', h, 's', s, 'v', v, 'x', x);
end

function x = quality(P, xraw, Pcrit)
if P >= Pcrit
    x = NaN;
else
    x = xraw;
end
end
