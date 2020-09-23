#####################################################################
###            Looking at Reduction Tree Height                   ###
#####################################################################
library(ggplot2)
library(gmp)
library(Rmpfr)
# Utility functions. Also in assoc.R
# Read veclen and mpfr. Returns a list, doesn't do error checking.
read_mpfr <- function(fn) {
	df <- read.table(file = fn, sep = "\t", header = TRUE, nrows = 3,
		colClasses = c("character"))
	veclen <- as.integer(df$veclen[1])
	la_mpfr <- df[df$order == "MPFR(3324) left assoc",]$FP...a.
	la_mpfr <- mpfr(la_mpfr, 3324, base=16)
	return(list(veclen,la_mpfr))
}
# Reading in different distributions.
read_experiment <- function(fn, fields = c("order","fp_a")) {
	df <- read.table(file = fn, sep = "\t", header = TRUE)
	stopifnot(all(df$veclen == df$veclen[1]))
	# Filter and get more R-friendly
	colnames(df)[colnames(df) == "FP..decimal."] <- "fp_decimal"
	colnames(df)[colnames(df) == "FP...a."] <- "fp_a"
	df = subset(df, select = fields)
	return(df)
}
# Relative Error
rel_err <- function(x, r) { abs((x$fp_a - r)/r) }
# Pretty-print distribution for titles
distr_pp <- function(x) {
	switch(x,
		"unif01"   = "U(0,1)",
		"unif11"   = "U(-1,1)",
		"unif1000" = "U(-1000,1000)",
		"subn"     = "subn",
		"unknown notation, check distr_pp")
}

# Is not very strongly correlated
base_dir <- 'experiments/with-height/'
for (x in c("unif01", "unif11", "unif1000", "subn")) {
	fn <- paste0(base_dir,"assoc-r",x,".tsv")
	df <- read_experiment(fn, fields = c("order","distribution","fp_a","height"))
	l <- read_mpfr(fn)
	veclen <- l[[1]]
	mpfr_1000_m <- l[[2]]
	canonical <- df$fp_a[df$order == "Left assoc"]
	mpfr_1000 <- df$fp_a[df$order == "MPFR(3324) left assoc"]
	df$abs_err <- abs(df$fp_a - mpfr_1000)
	df$relative_error <- rel_err(df, mpfr_1000)

	fora <- df[df$order == "Random assoc",]
	rho_fora <- cor(fora$relative_error, fora$height)
	cat(sprintf("%s fora\tρ(rel err,height) = %0.3f\n", x, rho_fora))

	rora <- df[df$order == "Shuffle rand assoc",]
	rho <- cor(rora$relative_error, rora$height)
	cat(sprintf("%s rora\tρ(rel err,height) = %0.3f\n", x, rho))
	cat(sprintf("%s rora\tmean(height) = %.1f\n", x, mean(rora$height)))

	# Then plot for rora only
	p <- ggplot(rora, aes(y = relative_error, x = height)) +
		geom_point(shape = "square", size = 0.5) +
		#geom_bin2d(bins = 20) +
		geom_smooth(method = "lm", formula = y ~ x, color = "blue") +
		labs(title = paste("Reduction Tree Height with RORA and", distr_pp(x)),
		     caption = sprintf("cor = %0.3f\nn = %s, |A| = %s", rho,
		                       format(nrow(rora), big.mark=","),
			                   format(veclen, big.mark=","))) +
		scale_y_continuous(
			breaks = seq(0, max(rora$relative_error), length.out = 4),
			labels = function(x) sprintf("%0.1e", x)) +
		# Add in a legend just for the correlation coefficient
		xlab("Maximum Reduction Tree Height") +
		ylab("Relative Error")
	ggsave(paste0("figures/rora-height-r",x,".pdf"),
		plot = p, scale = 0.9, height = 3.5, width = 7)
}
