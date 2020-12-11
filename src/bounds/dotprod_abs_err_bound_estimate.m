% Theorem 4.3 from "Probabalistic Error Analysis for Inner Products" by
% Ipsen & Zhou, adjusted for scalar bounds for x and y.
% input: maximum magnitude that values x or y may take
% output: upper bound on the relative error of floating-point dot product
% eps is already predefined in Matlab
function abserr = dotprod_abs_err_bound_estimate(max_x, max_y, n)
	if any(size(max_x) ~= [1,1]) || any(size(max_y) ~= [1,1])
		error('max_x and max_y must be scalar');
	end
    
	function c = c_k(k)
		c = abs(max_x * max_y)*(1+eps)^(k-1);
		if k > 1
			c = c + sum(arrayfun(@(j) abs(max_x*max_y)*(1+eps)^(k-j+1), 2:k));
		end
	end
	c = [ arrayfun(@c_k, 1:n)' ; repelem(abs(max_x*max_y), n)'];
	abserr = sqrt(2*n - 1) * sqrt(sum(c.^2)) * eps;
end