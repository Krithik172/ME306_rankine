function check_val(name, val, ref)
% CHECK_VAL  Compare a model value against a reference (tolerance 0.1 %).
if abs(val/ref - 1) < 1e-3, tag = 'PASS'; else, tag = 'CHECK'; end
fprintf('  %-10s model %9.4f | ref %9.4f | %s\n', name, val, ref, tag);
end
