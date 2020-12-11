% Theorem 4.3 from "Probabalistic Error Analysis for Inner Products" by
% Ipsen & Zhou
% input: x, y vectors of the same length
% output: upper bound on the relative error of floating-point dot product
% eps is already predefined in Matlab
function relerr = dotprod_rel_err_bound(x, y)
	if any(size(x) ~= size(y))
		error('size of x and y must be the same');
	end
	n = length(x);
	function c = c_k(k)
		c = abs(x(1)*y(1))*(1+eps)^(k-1);
		if k > 1
			c = c + sum(arrayfun(@(j) (abs(x(j)*y(j))*(1+eps)^(k-j+1)), 2:k));
		end
	end
	c = [ arrayfun(@c_k, 1:n)' ; abs(x .* y) ];
	relerr = sqrt(2*n - 1) * sqrt(sum(c.^2)) * eps / dot(x,y);
end