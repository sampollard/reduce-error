# Associativity experiments for uniform distribution
library(ggplot2)
library(reshape2)
library(Rmpfr)

#####################################################################
###                Helper Functions and Constants                 ###
#####################################################################
DBL_MIN <- 2.22507385850720138309e-308 # Machine Epsilon
FLT_MIN <- 1.17549435e-38
height <- 3
# A modified https://colorbrewer2.org/#type=qualitative&scheme=Dark2
# #               "orange"  "purple"  "cyan"    "magenta" "green"   "gold"    "brown"
# my_palette <- c("#f78631","#605c96","#178564","#e7298a","#66a61e","#e6ab02","#a6761d")
# my_palette <- scale_color_viridis(4, discrete = T, begin=0, end=0.8)$palette(4)
# my_palette <- c("#a1dab4","#41b6c4","#2c7fb8","#253494") # YlGnBu without Yl
# my_palette <- c("#ffffcc", "#a1dab4", "#41b6c4", "#225ea8") # YlGnBu with Yl
my_palette <- c("#d7191c", "#abdda4", "#fdae61", "#2b83ba") # Spectral

# Be careful with this: list(df1,df2) will give different results
# than list(rbind(df1,df2)) because it will find the minimum of _each_ result.
# The former gives you the "chunkier" bins, the latter gives you exactly
# one bin per unique floating point number.
count_bins <- function(l) {
	binc <- sapply(l, function(x) {length(unique(sort(x$error_mpfr)))})
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
		"runif01"   = quote(A[k] %~% unif(0,1)),
		"runif11"   = quote(A[k] %~% unif(-1,1)),
		"runif1000" = quote(A[k] %~% unif(-1000,1000)),
		"rsubn"     = quote(A[k] %~% subn(0,1)),
		"unknown notation, check distr_expr")
}

# Reading in different distributions
read_experiment <- function(fn) {
	df <- read.table(file = fn, sep = "\t", header = TRUE)
	stopifnot(all(df$veclen == df$veclen[1]))
	veclen <- df$veclen[1]
	# Filter and get more R-friendly
	colnames(df)[4] <- "fp_decimal"
	df = subset(df, select = c("order","fp_decimal"))
	return(df)
}

# Absolute Error
rel_err <- function(x, r) { abs(x$error_mpfr - r)/r }

rel_err_mpfr <- function(x, r) {
	rm <- mpfr(r, 3324)
	xm <- mpfr(x$error_mpfr, 3324)
	abs(xm - rm)/rm
}

# Geometric Mean
geom_mean <- function(x) { exp(mean(log(x))) }

geom_mean <- function(x) { exp(mean(log(x))) }

#####################################################################
###         Reading In Data and Interesting Values                ###
#####################################################################

for (x in c("runif11", "runif1000", "rsubn")) {
	df <- read_experiment(paste0("experiments/assoc-",x,".tsv"))
	canonical <- df$fp_decimal[df$order == "Left assoc"]
	mpfr_1000 <- df$fp_decimal[df$order == "MPFR(3324) left assoc"]

	allr <- df[df$order %in% c("Random assoc","Shuffle l assoc", "Shuffle rand assoc"),]
	# Convert from the raw numbers to errors with respect to mpfr
	allr$error_mpfr <- mpfr_1000 - allr$fp_decimal
	ra  <- allr[allr$order == "Random assoc",]
	sla <- allr[allr$order == "Shuffle l assoc",]
	sra <- allr[allr$order == "Shuffle rand assoc",]
	cat(sprintf("*** %s ***\nrel error:\nra:\t%.20f\nsla:\t%.20f\nsra:\t%.20f\n",
		x, mean(ra$error_mpfr), mean(sla$error_mpfr), mean(sra$error_mpfr)))
	cat(sprintf("rel error:\nra:\t%.20f\nsla:\t%.20f\nsra:\t%.20f\n",
		mean(rel_err(ra,mpfr_1000)),
		mean(rel_err(sla,mpfr_1000)),
		mean(rel_err(sra,mpfr_1000))))
	cat(sprintf("Unique:\nra:\t%d\nsla:\t%d\nsra:\t%d\n",
		length(unique(ra$error_mpfr)),
		length(unique(sla$error_mpfr)),
		length(unique(sra$error_mpfr))))
	cat(sprintf("Nonidentical (ra - sra): %d\n",
		length(intersect(ra$error_mpfr, sra$error_mpfr))))
	cat(sprintf("min:\t%.20f\nmax:\t%.20f\ncanon:\t%.20f\nmpfr:\t%.20f\n",
		min(allr$fp_decimal), max(allr$fp_decimal), canonical, mpfr_1000))
}

# unif(0,1) is separate because we focus on this one a lot
distr <- "runif01"
df <- read_experiment(paste0("experiments/assoc-",distr,".tsv"))
canonical <- df$fp_decimal[df$order == "Left assoc"]
mpfr_1000 <- df$fp_decimal[df$order == "MPFR(3324) left assoc"]
allr <- df[df$order %in% c("Random assoc","Shuffle l assoc", "Shuffle rand assoc"),]
# Convert from the raw numbers to errors with respect to mpfr
allr$error_mpfr <- mpfr_1000 - allr$fp_decimal
ra  <- allr[allr$order == "Random assoc",]
sla <- allr[allr$order == "Shuffle l assoc",]
sra <- allr[allr$order == "Shuffle rand assoc",]

cat(sprintf("*** %s ***\nrel error:\nra:\t%.20f\nsla:\t%.20f\nsra:\t%.20f\n",
	distr, mean(ra$error_mpfr), mean(sla$error_mpfr), mean(sra$error_mpfr)))
cat(sprintf("rel error:\nra:\t%.20f\nsla:\t%.20f\nsra:\t%.20f\n",
	mean(rel_err(ra,mpfr_1000)),
	mean(rel_err(sla,mpfr_1000)),
	mean(rel_err(sra,mpfr_1000))))
cat(sprintf("Unique:\nra:\t%d\nsla:\t%d\nsra:\t%d\n",
	length(unique(ra$error_mpfr)), length(unique(sla$error_mpfr)), length(unique(sra$error_mpfr))))
cat(sprintf("Nonidentical (ra - sra): %d\n", length(intersect(ra$error_mpfr, sra$error_mpfr))))
cat(sprintf("min:\t%.20f\nmax:\t%.20f\ncanon:\t%.20f\nmpfr:\t%.20f\n",
	min(allr$fp_decimal), max(allr$fp_decimal), canonical, mpfr_1000))
min_diff <- min(allr$error_mpfr)
max_diff <- max(allr$error_mpfr)

#####################################################################
###                  Uninteresting Scatterplots                   ###
#####################################################################

# Make some scatterplots. Not particularly useful (also huge pdf files!) so
# they're commented out
for (x in c()) { # c("ra", "sla", "sra", "allr")) {
	cdf <- get(x)
	cdf <- na.omit(cdf)
	p <- ggplot(cdf) +
		aes(x = seq_along(order), y = error_mpfr,
			ymin = 1.2*min_diff, ymax = 1.05*max_diff) +
		geom_point(aes(color = factor(order))) +
		geom_hline(yintercept = 0.0, color = "black") +
		geom_hline(yintercept = mpfr_1000 - canonical, color = "red", show.legend = TRUE)
	ggsave(paste0("figures/assoc-",distr,"-",x,".pdf"), plot = p, height = height)
}
#rm(cdf)

#####################################################################
###                    Some Histograms                            ###
#####################################################################

# Just Shuffling random-associative
binc <- count_bins(list(sra))
p <- ggplot(sra, aes(x = error_mpfr)) +
	geom_histogram(data = sra, bins = binc, fill = my_palette[2], alpha = 0.7) +
	geom_vline(aes(xintercept = 0.0, color = "Zero"), # No error
			linetype = "solid", alpha = 1.0, show.legend = TRUE) +
	geom_vline( # Shuffle random assoc
		aes(xintercept = mean(error_mpfr), color = "Mean"),
		linetype = "solid", alpha = 1.0, show.legend = TRUE) +
	scale_color_manual(name = NULL, values = c(Mean = my_palette[2], Zero = "black")) +
	theme(legend.position = c(0.8, 0.9), legend.direction="horizontal") +
	labs(title = "Shuffling and Random Associativity",
		caption = paste0("n = ", format(nrow(sra),big.mark=","),
		                 "\n|A| = ", format(veclen, big.mark=","))) +
	ylab("Count") +
	xlab(expression(sum[mpfr] - sum[double]))
ggsave(paste0("figures/assoc-",distr,"-hist-sra.pdf"), plot = p, height = height)

# Shuffle Random Associations vs. Shuffle, left-associative
# Second data frame for vertical lines
vlines <- data.frame(
	"Statistic" = c("Zero", "Canon", "bar('ROLA')", "bar('RORA')"),
	"Value"     = c(0.0, mpfr_1000 - canonical, mean(sla$error_mpfr), mean(sra$error_mpfr)),
	"Color"     = c("black", "#0042ff", my_palette[1], my_palette[2]),
	"Linetype"  = c("solid", "dotdash", "dashed", "dotted"),
	stringsAsFactors = FALSE)
hist_style <- data.frame(
	"Statistic" = c("ROLA", "RORA"),
	"Fill"      = c(my_palette[1], my_palette[2]))
Labels <- to_expr(vlines$Statistic)
# So the orderings are just as as I wrote them above
vlines$Statistic <- factor(
	vlines$Statistic, levels = vlines$Statistic, ordered = TRUE)
hist_style$Statistic <- factor(
	hist_style$Statistic, levels = hist_style$Statistic, ordered = TRUE)
binc <- count_bins(list(sla,sra))
# binc <- count_bins(list(rbind(sra,sla))) # This gives some interesting peaks for sra
p <- ggplot(rbind(sla,sra), aes(x = error_mpfr, fill = order)) +
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
		caption = bquote(n == .(format(nrow(sla),big.mark=","))*"," ~~~
						 "|A|" == .(format(veclen, big.mark=","))*"," ~~~
		                 .(distr_expr(distr)))) +
	theme(legend.title = element_blank(),
		legend.position = "top",
		legend.direction = "horizontal",
		legend.box = "horizontal") +
	ylab("Count") +
	xlab(expression(sum[mpfr] - sum[double]))
ggsave(paste0("figures/assoc-",distr,"-hist-sra-sla.pdf"), plot = p, height = 5)

# FIXME
	# geom_segment(aes(
	# 	x = max(abs(error_mpfr))/2,
	# 	y = 0.7*max(p_count),
	# 	xend = max(abs(error_mpfr)) + 1e9*DBL_MIN, #FIXME
	# 	yend = 0.7*max(p_count)))

# The two that look very similar
vlines <- data.frame(
	"Statistic" = c("Zero", "bar('FORA')", "bar('RORA')", "'max(Error)'"),
	"Value"     = c(0.0, mean(ra$error_mpfr), mean(sra$error_mpfr), max(max(ra$error_mpfr),max(sra$error_mpfr))),
	"Color"     = c("black", my_palette[1], my_palette[3], "#0042ff"),
	"Linetype"  = c("solid", "dotdash", "dashed", "dotted"),
	stringsAsFactors = FALSE)
vlines$Statistic <- factor(
	vlines$Statistic, levels = vlines$Statistic, ordered = TRUE)
Labels <- to_expr(vlines$Statistic)
binc <- count_bins(list(rbind(ra,sra)))
p <- ggplot(rbind(ra,sra), aes(x = abs(error_mpfr))) +
	# Histogram info and legnd
	geom_histogram(bins = binc, aes(fill = order),
		position = "identity", color = "black", alpha = 0.6) +
	scale_fill_manual(name = "order", values = my_palette[c(1,3)],
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
		caption = bquote(n == .(format(nrow(sla),big.mark=","))*"," ~~~
						 "|A|" == .(format(veclen, big.mark=","))*"," ~~~
		                 .(distr_expr(distr)))) +
	ylab("Count") +
	xlab(expression(paste("Error as |",sum[mpfr] - sum[double],"|")))
ggsave(paste0("figures/assoc-",distr,"-hist-ra-sra-abs.pdf"), plot = p, height = 4)

# Histogram for allr (separate) - I don't think this is informative
binc <- sapply(list(allr), function(x) {length(unique(sort(x$error_mpfr)))})
binc <- ifelse(binc%%2 == 0, binc + 1, binc) # Odd looks better for symmetry about 0
p <- ggplot(allr, aes(x = error_mpfr)) +
	geom_histogram(bins = binc, alpha = 0.8, fill = my_palette[4]) +
	geom_vline( # Mean of everything --- not sure this is helpful
		aes(xintercept = mean(error_mpfr)),
			color = "blue", linetype = "dotted", alpha = 1.0)
ggsave(paste0("figures/assoc-",distr,"-hist-allr.pdf"), plot = p, height = height)
