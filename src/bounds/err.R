# This is not done best in R. I should switch to Matlab.
# Next Steps: Throw in some FPTaylor stuff
# Calculate Error based on FPTaylor and Ipsen
library(gmp)
library(Rmpfr)

eps <- .Machine$double.eps

# Theorem 4.3 from "Probabalistic Error Analysis for Inner Products" by Ipsen & Zhou
# x, y vectors
dotprod_abs_err_bound <- function(x, y, prec = "double") {
	if (prec == "double") {
		eps <- .Machine$double.eps
	} else if (prec == "single") {
		eps <- 2^-24
	} else {
		error("Precision", prec, "not supported")
	}
	n <- length(x)
	stopifnot(length(x) == length(y))

	# Error from + and * (guard digits, no fused-multiply-add)
	k_f_e <- function(k) {
		if (k > 1) {
			J <- 2:k
			abs(x[1]*y[1])*(1+eps)^(k-1) +
				sum(sapply(J, function(j) { abs(x[j] * y[j]) * (1 + eps)^(k-j+1) }))
		} else {
			abs(x[1]*y[1])*(1+eps)^(k-1)
		}
	}
	k_f_o <- function(k) {
		abs(x[k] * y[k])
	}
	c_k <- sapply(1:n, k_f_e)
	c_k <- c(c_k, sapply(1:n, k_f_o))
	return(sqrt(2 * n - 1) * sqrt(sum(c_k^2)) * eps)
}

# MPFR version of above
dotprod_abs_err_bound_m <- function(x, y, prec = "double") {
	if (prec == "double") {
		eps <- .Machine$double.eps
	} else if (prec == "single") {
		eps <- 2^-24
	} else {
		error("Precision", prec, "not supported")
	}
	n <- length(x)
	stopifnot(length(x) == length(y))

	# Error from + and * (guard digits, no fused-multiply-add)
	k_f_e <- function(k) {
		if (k > 1) {
			J <- 2:k
			tmp <- lapply(J, function(j) { abs(x[j] * y[j]) * (1 + eps)^(k-j+1) })
			abs(x[1]*y[1])*(1+eps)^(k-1) + sum(new("mpfr", unlist(tmp)))
		} else {
			abs(x[1]*y[1])*(1+eps)^(k-1)
		}
	}
	k_f_o <- function(k) {
		abs(x[k] * y[k])
	}
	tmp <- lapply(1:n, k_f_e)
	c_k <- new("mpfr", unlist(tmp))
	tmp <- lapply(1:n, k_f_o)
	c_k <- c(c_k, new("mpfr", unlist(tmp)))
	return(sqrt(2 * n - 1) * sqrt(sum(c_k^2)) * eps)
}

dotprod_rel_err_bound <- function(x, y, prec = "double") {
	dotprod_abs_err_bound(x, y, prec = prec) / (x %*% y)
}

# Try it
a_11 <- runif(100, -1, 1)
b_11 <- runif(100, -1, 1)

# How many bits precision do we want? Kulisch accumulator has >4000
a <- 2^-900 * a_11
b <- 2^-900 * b_11

a_m <- mpfr(a, precBits = 3324)
b_m <- mpfr(b, precBits = 3324)

cat(sprintf('a . b unscaled:\t%.16e\n', a_11 %*% b_11))
cat(sprintf('a . b double:\t%.16e\n', a %*% b))
cat(sprintf('a . b mpfr:\t'))
print((a_m %*% b_m)[1,1])
# Dto product absolute error bound
dpaeb <- dotprod_abs_err_bound(a, b)
dpaeb_m <- dotprod_abs_err_bound_m(a_m, b_m)
cat(sprintf('a . b Ipsen double abs bound:\t%.16e\n', dpaeb))
cat(sprintf('a . b Ipsen mpfr abs bound:\t%.16e\n', dpaeb_m))
cat(sprintf('a . b relative error:\t'))
print(abs((dpaeb_m - dpaeb)/dpaeb_m))
