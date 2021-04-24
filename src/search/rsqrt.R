# Experiments on Inverse Square Root
# Plotting different iterative methods for rsqrt
library(gmp)
library(ggplot2)
library(Rmpfr)
library(viridis)
library(reshape2)

DBL_EPS <- .Machine$double.eps
if (!dir.exists("figures")) {
	dir.create("figures")
}

DIM <- 50

# Don't want to generate uniformly, but logarithmically-uniformly
N_POINTS <- 1000
x_log <- seq(-1, 3, length.out=N_POINTS)
x <- 10^x_log

# The result, 3 different ways. rsqrt_md is rounded to double, easier to print.
# NOTE: Be careful with rsqrt_md and the floor effect! May show 0 error.
rsqrt <- 1.0 / sqrt(x)                           # Double approximation
rsqrt_m <- mpfr(1.0, 3324) / sqrt(mpfr(x, 3324)) # MPFR 1000 digit
rsqrt_md <- as.numeric(rsqrt_m)                  # MPFR 1000, rounded.
# Evidence that using rsqrt_md instead of rsqrt_m is not too bad
stopifnot(all(
	as.numeric(abs((rsqrt_m - rsqrt_md)/rsqrt_m)) <= DBL_EPS))
# If there was no error, these would all be zero!
rsqrt_dbl_abserr <- as.numeric(abs(rsqrt_m - rsqrt))

# Another interesting way to look at it - only get those which do not
# round to the closest floating-point approximation. May also want
# to look at
# sum(rsqrt_dbl_abserr > DBL_EPS) or sum(rsqrt_dbl_abserr > DBL_EPS/2)
abserr_dbl_approx <- abs(as.numeric(rsqrt_m) - rsqrt)

# Relative Error
rel_err <- function(xhat, x) {
	abs((xhat - x)/x)
}

# Compute one iteration of rsqrt, Quake Style
# Arm-style is y * 2 * (3 - x*y*y), but since multiplying or dividing by 2 has
# no error, this should be identical
rsqrt_newton_iter <- function(x, y) {
	y * (1.5 - 0.5*x*y*y)
}

plt_iters <- function(rsqrt, y, ..., title = "Newton's Method") {
	ys <- list(...)
	col <- viridis_pal()(1+length(ys))
	# Depending on if we use mpfr or double
	get_re <- function(y, yhat) {
		if (class(y) == "mpfr") {
			return(as.numeric(rel_err(y, mpfr(yhat, 3324))))
		} else {
			return(rel_err(y, yhat))
		}
	}

	# Data frame looks like this:
    #   rsqrt y0 y1 y2 ...
	# where rsqrt is the true result, y0 is the initial guess,
	# y1 is the first iteration, etc.
	df <- data.frame(rsqrt = as.numeric(rsqrt), y0 = get_re(rsqrt, y))
	i <- 1
	for (yi in ys) {
		i <- i + 1
		df <- cbind(df, get_re(rsqrt, yi))
		colnames(df)[i+1] <- sprintf("y%d", i-1)
	}
	message("Generating plot titled: ", title)
	dfp <- melt(df, id.vars = "rsqrt", value.name = "relerr", variable.name = "iterations")

	p <- ggplot(dfp, aes(x = rsqrt, y = relerr, color = iterations)) +
		#geom_point(shape = "square", size = 0.5)
		geom_point() +
		scale_color_viridis_d(end = 0.85) +
		geom_hline(yintercept = DBL_EPS/2, color = "red") +
		annotate("text", label = expression(epsilon),
			x = max(dfp$rsqrt), y = DBL_EPS/2, vjust = -1.0) +
		labs(title = title,
		     caption = sprintf("n = %d\n%.1f <= x <= %.1f",
	                           length(x), min(x), max(x))) +
		scale_y_log10()
	return(p)
}

# Satire initial guess (iteration 0)
y0_S <- 0.5 / x
y1_S <- rsqrt_newton_iter(x, y0_S)
y2_S <- rsqrt_newton_iter(x, y1_S)
y3_S <- rsqrt_newton_iter(x, y2_S)
y4_S <- rsqrt_newton_iter(x, y3_S)
y5_S <- rsqrt_newton_iter(x, y4_S)
y6_S <- rsqrt_newton_iter(x, y5_S)
y7_S <- rsqrt_newton_iter(x, y6_S)
pmS <- plt_iters(rsqrt_m, y0_S, y1_S, y2_S, y3_S, y4_S, y5_S, y6_S, y7_S,
	title = "Newton's Method, Initial Guess 0.5/x")
ggsave("figures/pmS.pdf",
    plot = pmS, scale = 0.9, height = 4, width = 6)

# Taylor series first-order approximation
# if g(x) = 1/sqrt(1+mx), then g(x) = 1 - mx/2 + O(x^2)
# So, m = 1 and z = (x-1) give g(z) = 1/sqrt(x)
y0_T1 <- 1 - (x-1)/2
y1_T1 <- rsqrt_newton_iter(x, y0_T1)
y2_T1 <- rsqrt_newton_iter(x, y1_T1)
y3_T1 <- rsqrt_newton_iter(x, y2_T1)
y4_T1 <- rsqrt_newton_iter(x, y3_T1)
y5_T1 <- rsqrt_newton_iter(x, y4_T1)
y6_T1 <- rsqrt_newton_iter(x, y5_T1)
y7_T1 <- rsqrt_newton_iter(x, y6_T1)
y8_T1 <- rsqrt_newton_iter(x, y7_T1)
pmT1 <- plt_iters(rsqrt_m, y0_T1, y1_T1, y2_T1, y3_T1, y4_T1, y5_T1, y6_T1, y6_T1,
	title = "Newton's Method, Initial Guess 1st Order Taylor")
ggsave("figures/pmT1.pdf",
    plot = pmT1, scale = 0.9, height = 4, width = 6)


# Bound the relative error
# Intel has two rounding modes, one with
# 2^-14 relative error ~= 4.21 digits
# and one with 2^-28 relative error ~= 8.43 digits.
y0_R4D <- signif(1/sqrt(x), digits=4)
y1_R4D <- rsqrt_newton_iter(x, y0_R4D)
y2_R4D <- rsqrt_newton_iter(x, y1_R4D)
y3_R4D <- rsqrt_newton_iter(x, y2_R4D)
y4_R4D <- rsqrt_newton_iter(x, y3_R4D)

# Use MPFR to get actually lower precision.
y0_R14 <- as.numeric(mpfr(1.0, 14)/sqrt(mpfr(x, 14)))
y1_R14 <- rsqrt_newton_iter(x, y0_R14)
y2_R14 <- rsqrt_newton_iter(x, y1_R14)
y3_R14 <- rsqrt_newton_iter(x, y2_R14)
y4_R14 <- rsqrt_newton_iter(x, y3_R14)
pmR14 <- plt_iters(rsqrt_m, y0_R14, y1_R14, y2_R14, y3_R14,
	title = "Newton's Method, Initial Guess 2^-14")
ggsave("figures/pmR14.pdf",
    plot = pmR14, scale = 0.9, height = 4, width = 6)

# MPFR to get 28 bits relative error like Intel intrinsics
y0_R28 <- as.numeric(mpfr(1.0, 28)/sqrt(mpfr(x, 28)))
y1_R28 <- rsqrt_newton_iter(x, y0_R28)
y2_R28 <- rsqrt_newton_iter(x, y1_R28)
y3_R28 <- rsqrt_newton_iter(x, y2_R28)
y4_R28 <- rsqrt_newton_iter(x, y3_R28)
pmR28 <- plt_iters(rsqrt_m, y0_R28, y1_R28, y2_R28, y3_R28,
	title = "Newton's Method, Initial Guess 2^-28")
ggsave("figures/pmR28.pdf",
    plot = pmR28, scale = 0.9, height = 4, width = 6)

