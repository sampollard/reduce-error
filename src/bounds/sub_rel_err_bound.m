function err = sub_rel_err_bound(x,y)
    cmp = ~((.5*x < y) & (y < 2*x)); % 0 if within bound, 1 if not
    err = cmp * eps;
end