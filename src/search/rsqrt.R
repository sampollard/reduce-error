# Experiments on Inverse Square Root
# Plotting different iterative methods for rsqrt
library(gmp)
library(ggplot2)
library(Rmpfr)
library(viridis)

# Don't want to generate uniformly, but logarithmically-uniformly n_points <- 100
x_log <- seq(-3, 3, length.out=n_points)
x <- 10^x_log

# The result, 3 different ways. rsqrt_md is rounded to double, easier to print.
rsqrt <- 1.0 / sqrt(x)                           # Double approximation
rsqrt_m <- mpfr(1.0, 3324) / sqrt(mpfr(x, 3324)) # MPFR 1000 digit
rsqrt_md <- as.numeric(rsqrt_m)                  # MPFR 1000, rounded.
# Evidence that using rsqrt_md instead of rsqrt_m is not too bad
stopifnot(all(
	as.numeric(abs((rsqrt_m - rsqrt_md)/rsqrt_m)) <= .Machine$double.eps))
# If there was no error, these would all be zero!
rsqrt_dbl_abserr <- as.numeric(abs(rsqrt_m - rsqrt))

# Another interesting way to look at it - only get those which do not
# round to the closest floating-point approximation.
abserr_dbl_approx <- abs(as.numeric(rsqrt_m) - rsqrt)

# Relative Error
relerr <- function(xhat, x) {
	abs((xhat - x)/x)
}

# Compute one iteration of rsqrt, Quake Style
# Arm-style is y * 2 * (3 - x*y*y), but since multiplying or dividing by 2 has
# no error, this should be identical
rsqrt_newton_iter <- function(x, y) {
	y * (1.5 - 0.5*x*y*y)
}

# Satire initial guess (iteration 0)
y0_S <- 0.5 / x
y1_S <- rsqrt_newton_iter(x, y0_S)
y2_S <- rsqrt_newton_iter(x, y1_S)
y3_S <- rsqrt_newton_iter(x, y2_S)

# Taylor series first-order approximation
# if g(x) = 1/sqrt(1+mx), then g(x) = 1 - mx/2 + O(x^2)
# So, m = 1 and z = (x-1) give g(z) = 1/sqrt(x)
y0_T <- 1 - (x-1)/2
y1_T <- rsqrt_newton_iter(x, y0_T)
y2_T <- rsqrt_newton_iter(x, y1_T)
y3_T <- rsqrt_newton_iter(x, y2_T)

# Bound the relative error
# Intel has two rounding modes, one with
# 2^-14 relative error ~= 4.21 digits
# and one with 2^-28 relative error ~= 8.43 digits.
y0_C <- signif(1/sqrt(x), digits=4)
y1_C <- rsqrt_newton_iter(x, y0_C)
y2_C <- rsqrt_newton_iter(x, y1_C)
y3_C <- rsqrt_newton_iter(x, y2_C)
y4_C <- rsqrt_newton_iter(x, y3_C)

# Use MPFR to get actually lower precision.
y0_R14 <- as.numeric(mpfr(1.0, 14)/sqrt(mpfr(x, 14)))
y1_R14 <- rsqrt_newton_iter(x, y0_R14)
y2_R14 <- rsqrt_newton_iter(x, y1_R14)
y3_R14 <- rsqrt_newton_iter(x, y2_R14)
y4_R14 <- rsqrt_newton_iter(x, y3_R14)

# MPFR to get 28 bits relative error like Intel intrinsics
y0_R28 <- as.numeric(mpfr(1.0, 28)/sqrt(mpfr(x, 28)))
y1_R28 <- rsqrt_newton_iter(x, y0_R28)
y2_R28 <- rsqrt_newton_iter(x, y1_R28)
y3_R28 <- rsqrt_newton_iter(x, y2_R28)
y4_R28 <- rsqrt_newton_iter(x, y3_R28)

plt_iters <- function(rsqrt, y, ...) {
	ys <- list(...)
	i <- 1
	col <- viridis_pal()(1+length(ys))
	# Depending on if we use mpfr or double
	get_re <- function(y, yhat) {
		if (class(y) == "mpfr") {
			return(as.numeric(relerr(y, mpfr(yhat, 3324))))
		} else {
			return(relerr(y, yhat))
		}
	}

	df <- data.frame(rsqrt = rsqrt, y = y)
	p <- ggplot(df, aes(x = y, y = get_re(rsqrt, y))) +
		#geom_point(shape = "square", size = 0.5)
		geom_point(color = col[i]) +
		scale_y_log10()
	for (yi in ys) {
		i <- i + 1
		re <- get_re(rsqrt, yi)
		p <- p +
			geom_point(data = data.frame(rsqrt = rsqrt, y = yi),
			           color = col[i])
	}
	# p <- p + guides(color = col)
	return(p)
}

p0T <- plt_iters(rsqrt_md, y0_T)
p1T <- plt_iters(rsqrt_md, y1_T)
# ...
pnT <- plt_iters(rsqrt_md, y0_T, y1_T)
pmR14 <- plt_iters(rsqrt_md, y0_R14, y1_R14, y2_R14, y3_R14)
#pdR14 <- plt_iters(rsqrt_md, y0_R14, y1_R14, y2_R14, y3_R14)
#p0R28 <- plt_iters(rsqrt_md, y0_R28)
p4C <- plt_iters(rsqrt_md, y3_C)

