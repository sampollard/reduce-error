% Examples
rng(1);
n = 300;
max_x = 1;
max_y = 1;
x = max_x .* rand(n,1);
y = max_y .* rand(n,1);
fprintf('dot(x,y) =\t%f\n', dot(x,y));
fprintf('rel_err_bound =\t%e\n', dotprod_rel_err_bound(x,y));
fprintf('abs_err_bound =\t%e\n', dot(x,y)*dotprod_rel_err_bound(x,y));
fprintf('abs_err_bound_est =\t%e\n', ...
    dotprod_abs_err_bound_estimate(max_x, max_y, n));

ns = 5;
As = sym('a', [ns,ns]);
bs = sym('b', [ns]);
xs = sym('x', [ns]);
% xs_ = As \ bs;
% Notes:
% - Symbolic math gets hilariously slow for n > 4
% - May also want to look into describing the set (positive, rational, etc)
% - Convert sym to Matlab with matlabFunction

% Doing an expression:
% alpha_i = dot(r_i,r_i)/dot(p_i, A*p_i)
%     r_i+1 = r_i - alpha * A * p_i
% <=> 
%

% Initialize the uppor bound on all errors all to 0
% Errors of r, p, alpha, beta may be > 0 if we start beyond iteration 0
% Errors of A or b will only be > 0 if there is a known error in the input
err_r = zeros(n,1);
err_p = zeros(n,1);
err_A = zeros(n,n);
err_b = zeros(n,1);
err_x = zeros(n,1);
err_stop = 0.0; % Stopping criteria
err_alpha = 0.0;
err_beta = 0.0;

% Make a random linear system
n = 30;
A = rand(n);
b = rand(n,1);
x = A \ b;

% Initialization (iteration 0)
err_r = sub_rel_err_bound(b, err_A * err_x) - err_A * err_x;
err_p = err_r;

% while ||r_i||_2 > tol

% Test bounds but for very small values to show Ipsen bound isn't sound
rng(1);
n = 100;
max_x = 2^-100;
max_y = 2^-100;
x = max_x .* (rand(n,1)-0.5);
y = max_y .* (rand(n,1)-0.5);
