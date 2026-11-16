function print_state_table(out)
% PRINT_STATE_TABLE  Print the T-s/state table using the agreed numbering.
names = {'st1','st2','st3','st4','st5','st6','st7'};
fprintf('%-6s %9s %9s %10s %10s %8s\n','State','P [bar]','T [C]','h [kJ/kg]','s [kJ/kgK]','x');
for k = 1:numel(names)
    if isfield(out, names{k}) && ~isempty(out.(names{k}))
        s = out.(names{k});
        fprintf('%-6s %9.3f %9.2f %10.2f %10.4f %8.4f\n', names{k}(3:end), s.P, s.T, s.h, s.s, s.x);
    end
end
end
