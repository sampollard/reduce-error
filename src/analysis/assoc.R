# Associativity experiments for uniform distribution
library(ggplot2)
library(Rmpfr)
library(viridis)

#####################################################################
###                Helper Functions and Constants                 ###
#####################################################################
DBL_MIN <- 2.22507385850720138309e-308 # Machine Epsilon
FLT_MIN <- 1.17549435e-38
height <- 3
EPS <- 2^-53
ffmt = "%.3e"
base_dir <- 'experiments/assoc/'
# Color Mappings:
# A modified https://colorbrewer2.org/#type=qualitative&scheme=Dark2
# #               "orange"  "purple"  "cyan"    "magenta" "green"   "gold"    "brown"
# my_palette <- c("#f78631","#605c96","#178564","#e7298a","#66a61e","#e6ab02","#a6761d")
# my_palette <- viridis_pal()(4)
# my_palette <- c("#a1dab4","#41b6c4","#2c7fb8","#253494")    # YlGnBu without Yl
# my_palette <- c("#ffffcc", "#a1dab4", "#41b6c4", "#225ea8") # YlGnBu with Yl
my_palette <- c("#d7191c", "#abdda4", "#fdae61", "#2b83ba") # Spectral
ra_col <- list(
	rora = my_palette[1],
	fora = my_palette[3],
	rola = my_palette[2],
	allr = my_palette[4],
	unif1000 = "#440154",
	unif11 = "#31688E",
	subn  = "#35B779" ,
	unif01 = "#FDE725")

# Be careful with this: list(df1,df2) will give different results
# than list(rbind(df1,df2)) because it will find the minimum of _each_ result.
# The former gives you the "chunkier" bins, the latter gives you exactly
# one bin per unique floating point number.
count_bins <- function(l, by = 'error_mpfr') {
	binc <- sapply(l, function(x) {length(unique(sort(get(by, x))))})
	# Odd looks better for symmetry about 0
	return(min(ifelse(binc%%2 == 0, binc + 1, binc)))
}

# This is for taking a string with plotmath and turning it into an expression
# NOTE: It would probably be better to do this using quote
to_expr <- function(x) {
	bquote(.(parse(text=as.character(x))))
}

distr_expr <- function(x) {
	switch(x,
		"unif01"   = quote(A[k] %~% unif(0,1)),
		"unif11"   = quote(A[k] %~% unif(-1,1)),
		"unif1000" = quote(A[k] %~% unif(-1000,1000)),
		"subn"     = quote(A[k] %~% subn(0,1)),
		"unknown notation, check distr_expr")
}

# Reading in different distributions.
read_experiment <- function(fn, fields = c("order","fp_a")) {
	df <- read.table(file = fn, sep = "\t", header = TRUE)
	stopifnot(all(df$veclen == df$veclen[1]))
	veclen <- df$veclen[1]
	# Filter and get more R-friendly
	colnames(df)[colnames(df) == "FP..decimal."] <- "fp_decimal"
	colnames(df)[colnames(df) == "FP...a."] <- "fp_a"
	df = subset(df, select = fields)
	return(df)
}

# Read veclen and mpfr. Returns a list, doesn't do error checking.
read_mpfr <- function(fn) {
	df <- read.table(file = fn, sep = "\t", header = TRUE, nrows = 3,
		colClasses = c("character"))
	veclen <- as.integer(df$veclen[1])
	la_mpfr <- df[df$order == "MPFR(3324) left assoc",]$FP...a.
	la_mpfr <- mpfr(la_mpfr, 3324, base=16)
	return(list(veclen,la_mpfr))
}

# Relative Error
rel_err <- function(x, r) { abs((x$fp_a - r)/r) }

rel_err_mpfr <- function(x, r) {
	stopifnot(class(r) == "mpfr")
	xm <- mpfr(x$fp_a, 3324)
	abs((xm - r)/r)
}

# Geometric Mean
geom_mean <- function(x) { exp(mean(log(x))) }

# Analytical Absolute Error Bounds
analytical_abs_bound <- function(n, d) {
	s <- switch(d,
		"unif01"   = 1*n,
		"unif11"   = 1*n,
		"unif1000" = 1000*n,
		"subn"     = 2*n)
	return(EPS*(n-1)*s + EPS^2)
}

# Only applies for positive numbers
robertazzi_bound <- function(mu, n) {
	return((1/3) * (mu/2)^2 * n^3 * EPS^2 * (1/12))
}

#####################################################################
###         Reading In Data and Interesting Values                ###
#####################################################################

for (x in c("unif11", "unif1000", "subn")) {
	fn <- paste0(base_dir,"assoc-r",x,"-big.tsv")
	df <- read_experiment(fn)
	l <- read_mpfr(fn)
	veclen <- l[[1]]
	mpfr_1000_m <- l[[2]]
	canonical <- df$fp_a[df$order == "Left assoc"]
	mpfr_1000 <- df$fp_a[df$order == "MPFR(3324) left assoc"]

	allr <- df[df$order %in% c("Random assoc","Shuffle l assoc", "Shuffle rand assoc"),]
	# Convert from the raw numbers to errors with respect to mpfr
	allr$error_mpfr <- mpfr_1000 - allr$fp_a
	fora <- allr[allr$order == "Random assoc",]
	rola <- allr[allr$order == "Shuffle l assoc",]
	rora <- allr[allr$order == "Shuffle rand assoc",]
	cat(sprintf("*** %s ***\n",x))
	cat(sprintf(paste0("min:\t",ffmt,"\nmax:\t",ffmt,"\ncanon:\t",ffmt,"\nmpfr:\t",ffmt,"\n"),
		min(allr$fp_a), max(allr$fp_a), canonical, mpfr_1000))
	cat(sprintf(paste0("abs error:\nfora:\t",ffmt,"\nrola:\t",ffmt,"\nrora:\t",ffmt,"\n"),
		mean(abs(fora$error_mpfr)),
		mean(abs(rola$error_mpfr)),
		mean(abs(rora$error_mpfr))))
	cat(sprintf(paste0("analy:\t",ffmt,"\n"), analytical_abs_bound(veclen, x)))
	cat(sprintf(paste0("rel error:\nfora:\t",ffmt,"\nrola:\t",ffmt,"\nrora:\t",ffmt,"\n"),
		mean(rel_err(fora,mpfr_1000)),
		mean(rel_err(rola,mpfr_1000)),
		mean(rel_err(rora,mpfr_1000))))
	cat(sprintf(paste0("sla:\t",ffmt,"\n"), abs((canonical-mpfr_1000)/mpfr_1000)))
	cat(sprintf(paste0("analy:\t",ffmt,"\n"), abs(analytical_abs_bound(veclen, x)/mpfr_1000)))
	# This is pretty slow
	# cat(sprintf("rel error mpfr:\nfora:\t",ffmt,"\nrola:\t",ffmt,"\nrora:\t",ffmt,"\n",
	# 	mean(rel_err_mpfr(fora,mpfr_1000_m)),
	# 	mean(rel_err_mpfr(rola,mpfr_1000_m)),
	# 	mean(rel_err_mpfr(rora,mpfr_1000_m))))
	cat(sprintf("Unique:\nfora:\t%d\nrola:\t%d\nrora:\t%d\n",
		length(unique(fora$error_mpfr)),
		length(unique(rola$error_mpfr)),
		length(unique(rora$error_mpfr))))
	cat(sprintf("Nonidentical (fora - rora): %d\n",
		length(intersect(fora$error_mpfr, rora$error_mpfr))))
}

# unif(0,1) is separate because we focus on this one a lot.
# It would be nice if this worked in a loop, but I think the .(dist_expr part
# of bquote is messing things up.  I tried "force" but that didn't seem to
# work. Maybe look into substitute instead?
distr <- 'unif01'
message("Running batch of plots with ", distr)
df <- read_experiment(paste0(base_dir,"assoc-r",distr,".tsv"))
canonical <- df$fp_a[df$order == "Left assoc"]
mpfr_1000 <- df$fp_a[df$order == "MPFR(3324) left assoc"]
allr <- df[df$order %in% c("Random assoc","Shuffle l assoc", "Shuffle rand assoc"),]
# Convert from the raw numbers to errors with respect to mpfr
allr$error_mpfr <- mpfr_1000 - allr$fp_a
fora  <- allr[allr$order == "Random assoc",]
rola <- allr[allr$order == "Shuffle l assoc",]
rora <- allr[allr$order == "Shuffle rand assoc",]

cat(sprintf("*** %s ***\n", distr))
cat(sprintf(paste0("min:\t",ffmt,"\nmax:\t",ffmt,"\ncanon:\t",ffmt,"\nmpfr:\t",ffmt,"\n"),
	min(allr$fp_a), max(allr$fp_a), canonical, mpfr_1000))
cat(sprintf(paste0("abs error:\nfora:\t",ffmt,"\nrola:\t",ffmt,"\nrora:\t",ffmt,"\n"),
	mean(abs(fora$error_mpfr)),
	mean(abs(rola$error_mpfr)),
	mean(abs(rora$error_mpfr))))
cat(sprintf(paste0("analy:\t",ffmt,"\n"), analytical_abs_bound(veclen, distr)))
cat(sprintf(paste0("rel error:\nfora:\t",ffmt,"\nrola:\t",ffmt,"\nrora:\t",ffmt,"\n"),
	mean(rel_err(fora,mpfr_1000)),
	mean(rel_err(rola,mpfr_1000)),
	mean(rel_err(rora,mpfr_1000))))
	cat(sprintf(paste0("sla:\t",ffmt,"\n"), abs((canonical-mpfr_1000)/mpfr_1000)))
	cat(sprintf(paste0("analy:\t",ffmt,"\n"), abs(analytical_abs_bound(veclen, x)/mpfr_1000)))
cat(sprintf("Unique:\nfora:\t%d\nrola:\t%d\nrora:\t%d\n",
	length(unique(fora$error_mpfr)), length(unique(rola$error_mpfr)), length(unique(rora$error_mpfr))))
cat(sprintf("Nonidentical (fora - rora): %d\n", length(intersect(fora$error_mpfr, rora$error_mpfr))))
min_diff <- min(allr$error_mpfr)
max_diff <- max(allr$error_mpfr)

#####################################################################
###                  Uninteresting Scatterplots                   ###
#####################################################################

# Make some scatterplots. Not particularly useful (also huge pdf files!) so
# they're commented out
# c("fora", "rola", "rora", "allr"))
for (x in c()) {
	cdf <- get(x)
	cdf <- na.omit(cdf)
	p <- ggplot(cdf) +
		aes(x = seq_along(order), y = error_mpfr,
			ymin = 1.2*min_diff, ymax = 1.05*max_diff) +
		geom_point(aes(color = factor(order))) +
		geom_hline(yintercept = 0.0, color = "black") +
		geom_hline(yintercept = mpfr_1000 - canonical, color = "red", show.legend = TRUE)
	ggsave(paste0("figures/assoc-r",distr,"-",x,".pdf"), plot = p, height = height)
}
#rm(cdf)

#####################################################################
###                    Some Histograms                            ###
#####################################################################

# Just Shuffling random-associative
binc <- count_bins(list(rora))
p <- ggplot(rora, aes(x = error_mpfr)) +
	geom_histogram(data = rora, bins = binc, fill = ra_col$rora, alpha = 0.7) +
	geom_vline(aes(xintercept = 0.0, color = "Zero"), # No error
			linetype = "solid", alpha = 1.0, show.legend = TRUE) +
	geom_vline( # Shuffle random assoc
		aes(xintercept = mean(error_mpfr), color = "Mean"),
		linetype = "solid", alpha = 1.0, show.legend = TRUE) +
	scale_color_manual(name = NULL, values = c(Mean = ra_col$rora, Zero = "black")) +
	theme(legend.position = c(0.8, 0.9), legend.direction="horizontal") +
	labs(title = "Shuffling and Random Associativity",
		caption = paste0("n = ", format(nrow(rora),big.mark=","),
						 "\n|A| = ", format(veclen, big.mark=","))) +
	ylab("Count") +
	xlab(expression(sum[mpfr] - sum[double]))
ggsave(paste0("figures/assoc-r",distr,"-hist-rora.pdf"), plot = p, height = height)

# Shuffle Random Associations vs. Shuffle, left-associative
# Second data frame for vertical lines
vlines <- data.frame(
	"Statistic" = c("Zero", "Canon", "bar('ROLA')", "bar('RORA')"),
	"Value"     = c(0.0, mpfr_1000 - canonical, mean(rola$error_mpfr), mean(rora$error_mpfr)),
	"Color"     = c("black", "#0042ff", ra_col$rola, ra_col$rora),
	"Linetype"  = c("solid", "dotdash", "dashed", "dotted"),
	stringsAsFactors = FALSE)
hist_style <- data.frame(
	"Statistic" = c("ROLA", "RORA"),
	"Fill"      = c(ra_col$rola, ra_col$rora))
Labels <- to_expr(vlines$Statistic)
# So the orderings are just as as I wrote them above
vlines$Statistic <- factor(
	vlines$Statistic, levels = vlines$Statistic, ordered = TRUE)
hist_style$Statistic <- factor(
	hist_style$Statistic, levels = hist_style$Statistic, ordered = TRUE)
binc <- count_bins(list(rola,rora))
# binc <- count_bins(list(rbind(rola,rora))) # This gives some interesting peaks for rora
p <- ggplot(rbind(rola,rora), aes(x = error_mpfr, fill = order)) +
	geom_histogram(bins = 101, position = "identity", alpha = 0.6, color = "black") +
	geom_vline(data = vlines, show.legend = TRUE,
		aes(xintercept = Value, color = Statistic, linetype = Statistic)) +
	scale_linetype_manual(name = "Lines", values = vlines$Linetype,
		labels = Labels) +
	scale_color_manual(name = "Lines", values = vlines$Color,
		labels = Labels) +
	# The legends for the histograms
	scale_fill_manual(name = "Histograms", guide = "legend",
		values = hist_style$Fill,
		labels = hist_style$Statistic) +
	guides(fill = guide_legend(override.aes = list(linetype = 0))) +
	labs(title = "Random Associativity With and Without Random Ordering",
		caption = bquote(n == .(format(nrow(rola),big.mark=","))*"," ~~~
						 "|A|" == .(format(veclen, big.mark=","))*"," ~~~
						 .(distr_expr(distr)))) +
	theme(legend.title = element_blank(),
		legend.position = "top",
		legend.direction = "horizontal",
		legend.box = "horizontal") +
	ylab("Count") +
	xlab(expression(sum[mpfr] - sum[double]))
ggsave(paste0("figures/assoc-r",distr,"-hist-rola-rora.pdf"), plot = p, height = 4, width = 6)

# The two that look very similar
vlines <- data.frame(
	"Statistic" = c("Zero", "bar('FORA')", "bar('RORA')", "'max(Error)'"),
	"Value"     = c(0.0, mean(fora$error_mpfr), mean(rora$error_mpfr), max(max(fora$error_mpfr),max(rora$error_mpfr))),
	"Color"     = c("black", ra_col$fora, ra_col$rora, "#0042ff"),
	"Linetype"  = c("solid", "dotdash", "dashed", "dotted"),
	stringsAsFactors = FALSE)
vlines$Statistic <- factor(
	vlines$Statistic, levels = vlines$Statistic, ordered = TRUE)
Labels <- to_expr(vlines$Statistic)
binc <- count_bins(list(fora,rora))
p <- ggplot(rbind(fora,rora), aes(x = abs(error_mpfr))) +
	# Histogram info and legnd
	geom_histogram(bins = binc, aes(fill = order),
		position = "identity", color = "black", alpha = 0.6) +
	scale_fill_manual(name = "order",
		values = c(ra_col$fora, ra_col$rora),
		labels = c("FORA", "RORA")) +
	guides(fill = guide_legend(override.aes = list(linetype = 0))) +
	# Vlines info and legend
	geom_vline(data = vlines, show.legend = TRUE,
		aes(xintercept = Value, color = Statistic, linetype = Statistic)) +
	scale_color_manual(name = "Lines", values = vlines$Color,
		labels = Labels) +
	scale_linetype_manual(name = "Lines", values = vlines$Linetype,
		labels = Labels) +
	guides(color = guide_legend("Lines"), linetype = guide_legend("Lines")) +
	theme(legend.title = element_blank(),
		legend.position = "top",
		legend.direction = "horizontal",
		legend.box = "horizontal") +
	labs(title = "Random Associativity With and Without Random Ordering",
		caption = bquote(n == .(format(nrow(rola),big.mark=","))*"," ~~~
						 "|A|" == .(format(veclen, big.mark=","))*"," ~~~
						 .(distr_expr(distr)))) +
	ylab("Count") +
	xlab(expression(paste("Error as |",sum[mpfr] - sum[double],"|")))
ggsave(paste0("figures/assoc-r",distr,"-hist-fora-rora-abs.pdf"), plot = p, height = 3.5, width = 6)

# FIXME: I want to put the max error bounds...
	# geom_segment(aes(
	# 	x = max(abs(error_mpfr))/2,
	# 	y = 0.7*max(p_count),
	# 	xend = max(abs(error_mpfr)) + 1e9*DBL_MIN, #FIXME
	# 	yend = 0.7*max(p_count)))

# Histogram for allr (separate) - I don't think this is informative
binc <- sapply(list(allr), function(x) {length(unique(sort(x$error_mpfr)))})
binc <- ifelse(binc%%2 == 0, binc + 1, binc) # Odd looks better for symmetry about 0
p <- ggplot(allr, aes(x = error_mpfr)) +
	geom_histogram(bins = binc, alpha = 0.8, fill = ra_col$allr) +
	geom_vline( # Mean of everything --- not sure this is helpful
		aes(xintercept = mean(error_mpfr)),
			color = "blue", linetype = "dotted", alpha = 1.0)
ggsave(paste0("figures/assoc-r",distr,"-hist-allr.pdf"), plot = p, height = height)

#####################################################################
###             Comparing Uniform [0,1] and [-1,1]                ###
#####################################################################
get_distribution_data <- function(fn) {
	df <- read_experiment(fn, fields = c("order","distribution","fp_a"))
	l <- read_mpfr(fn)
	veclen <- l[[1]]
	mpfr_1000_m <- l[[2]]
	canonical <- df$fp_a[df$order == "Left assoc"]
	mpfr_1000 <- df$fp_a[df$order == "MPFR(3324) left assoc"]
	allr <- df[df$order %in% c("Random assoc","Shuffle l assoc", "Shuffle rand assoc"),]
	allr$error_mpfr <- mpfr_1000 - allr$fp_a
	allr$relative_error <- rel_err(allr, mpfr_1000)

	fora <- allr[allr$order == "Random assoc",]
	rola <- allr[allr$order == "Shuffle l assoc",]
	rora <- allr[allr$order == "Shuffle rand assoc",]
	return(list(
		veclen = veclen,
		mpfr_1000_m = mpfr_1000_m,
		canonical = canonical,
		fora = fora,
		rola = rola,
		rora = rora
	))
}
distr1 <- "unif01"
fn <- paste0(base_dir,"assoc-r",distr1,"-big.tsv")
l1 <- get_distribution_data(fn)
distr2 <- "unif11"
fn <- paste0(base_dir,"assoc-r",distr2,"-big.tsv")
l2 <- get_distribution_data(fn)
distr3 <- "unif1000"
fn <- paste0(base_dir,"assoc-r",distr3,"-big.tsv")
l3 <- get_distribution_data(fn)
distr4 <- "subn"
fn <- paste0(base_dir,"assoc-r",distr4,"-big.tsv")
l4 <- get_distribution_data(fn)
stopifnot(l1$veclen == l2$veclen, l2$veclen == l3$veclen)

d1 <- l1$rora
d2 <- l2$rora
d3 <- l3$rora
d4 <- l4$rora

stopifnot(nrow(d1) == nrow(d2), nrow(d1) == nrow(d3), nrow(d1) == nrow(d4))
vlines <- data.frame(
	"Statistic" = sapply(list(distr1,distr2,distr3,distr4), function(s){paste0("bar('",s,"')")}),
	"Value"     = sapply(list(d1,d2,d3,d4), function(x){mean(x$relative_error)}),
	"Color"     = sapply(list(distr1,distr2,distr3,distr4), function(x){get(x, ra_col)}),
	"Linetype"  = c("solid", "dashed", "dotdash", "dotted"),
	stringsAsFactors = FALSE)
hist_style <- data.frame(
	"Statistic" = c(distr1,distr2,distr3,distr4),
	"Fill"      = sapply(list(distr1,distr2,distr3,distr4), function(x){get(x, ra_col)}),
	stringsAsFactors = FALSE)
# So the orderings are just as as I wrote them above
vlines$Statistic <- factor(
	vlines$Statistic, levels = vlines$Statistic, ordered = TRUE)
hist_style$Statistic <- factor(
	hist_style$Statistic, levels = hist_style$Statistic, ordered = TRUE)
Labels <- to_expr(vlines$Statistic)
binc <- count_bins(list(d1,d2,d3,d4), by = 'relative_error')
binc <- 51
p <- ggplot(rbind(d1,d2,d3,d4), aes(x = relative_error)) +
    # Histograms
    geom_histogram(bins = binc, aes(fill = distribution),
        position = "identity", color = "black", alpha = 0.5) +
	scale_fill_manual(name = "Histograms", guide = "legend",
		values = hist_style$Fill,
		labels = hist_style$Statistic) +
	# Vlines
	geom_vline(data = vlines, show.legend = TRUE,
		aes(xintercept = Value, color = Statistic, linetype = Statistic)) +
	scale_linetype_manual(name = "Lines", values = vlines$Linetype,
		labels = Labels) +
	scale_color_manual(name = "Lines", values = vlines$Color,
		labels = Labels) +
	guides(fill = guide_legend(override.aes = list(linetype = 0))) +
	labs(title = "RORA with Different Distributions",
		caption = bquote(n == .(format(nrow(d1),big.mark=","))*"," ~~~
						 "|A|" == .(format(l1$veclen, big.mark=",")))) +
	theme(legend.title = element_blank(),
		legend.position = "top",
		legend.direction = "horizontal",
		legend.box = "horizontal") +
	ylab("Count") +
	xlab("Relative Error")
ggsave(paste0("figures/assoc-all-distr-hist-rora.pdf"),
	plot = p, height = 4, width = 7)

#####################################################################
###            Looking at Reduction Tree Height                   ###
#####################################################################
# Is not very strongly correlated, so probably not good to plot
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

	fora <- df[df$order == "Random assoc",]
	rho_fora <- cor(fora$abs_err, fora$height)
	cat(sprintf("%s fora\tρ(abs_err,height) = %0.3f\n", x, rho_fora))

	rora <- df[df$order == "Shuffle rand assoc",]
	rho <- cor(rora$abs_err, rora$height)
	cat(sprintf("%s rora\tρ(abs_err,height) = %0.3f\n", x, rho))

	# Then plot for rora only
	p <- ggplot(rora, aes(y = abs_err, x = height)) +
		#geom_point(alpha = 0.3) +
		geom_bin2d(bins = 20) +
		geom_smooth(method = "lm") +
		labs(caption = sprintf("cor = %.3f", rho)) +
		scale_fill_viridis()
	ggsave(paste0("figures/cor-rora-r",x,".pdf"),
		plot = p, height = 4)
}
