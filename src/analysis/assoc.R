# Associativity experiments for uniform distribution
library(ggplot2)
library(reshape2)
DBL_MIN = 2.22507385850720138309e-308 # Machine Epsilon
FLT_MIN = 1.17549435e-38

df <- read.table(file = 'experiments/assoc-runif01.tsv', sep = '\t', header = TRUE)
stopifnot(all(df$veclen == df$veclen[1]))
veclen <- df$veclen[1]
# Filter and get more R-friendly
colnames(df)[3] <- "fp_decimal"
df = subset(df, select = c("order","fp_decimal"))

canonical <- df$fp_decimal[df$order == "Left assoc"]
mpfr_1000 <- df$fp_decimal[df$order == "MPFR(3324) left assoc"]

allr <- df[df$order %in% c("Random assoc","Shuffle l assoc", "Shuffle rand assoc"),]
# Convert from the raw numbers to errors with respect to mpfr
allr$error_mpfr <- mpfr_1000 - allr$fp_decimal

# Just print some interesting values
cat(sprintf("min:\t%.20f\nmax:\t%.20f\ncanon:\t%.20f\nmpfr:\t%.20f\n",
	min(allr$fp_decimal), max(allr$fp_decimal), canonical, mpfr_1000))
min_diff <- min(allr$error_mpfr)
max_diff <- max(allr$error_mpfr)

ra  <- allr[allr$order == "Random assoc",]
sla <- allr[allr$order == "Shuffle l assoc",]
sra <- allr[allr$order == "Shuffle rand assoc",]

# Make some plots
for (x in c("ra", "sla", "sra", "allr")) {
	cdf <- get(x)
	cdf <- na.omit(cdf)
	p <- ggplot(cdf) +
		aes(x = seq_along(order), y = error_mpfr,
			ymin = 1.2*min_diff, ymax = 1.05*max_diff) +
		geom_point(aes(color = factor(order))) +
		geom_hline(yintercept = 0.0, color = "black") +
		geom_hline(yintercept = mpfr_1000 - canonical, color = "red", show.legend = TRUE)
	ggsave(paste0("figures/assoc-runif01-",x,".pdf"), plot = p, height = 4)
}
rm(cdf)

# Histograms
#            "orange"  "purple", "cyan"     "magenta"     # From https://colorbrewer2.org/#type=qualitative&scheme=Dark2&n=4
palette <- c("#d95f02","#7570b3","#1b9e77", "#e7298a")

binc <- sapply(list(ra,sla,sra), function(x) {length(unique(sort(x$error_mpfr)))})
binc <- min(ifelse(binc%%2 == 0, binc + 1, binc)) # Odd looks better for symmetry about 0

cat(sprintf("means\nra:\t%.20f\nsla:\t%.20f\nsra:\t%.20f\n",
	mean(ra$error_mpfr), mean(sla$error_mpfr), mean(sra$error_mpfr)))

# All 3
p <- ggplot(allr, aes(x = error_mpfr)) +
	geom_histogram(data = ra,  bins = binc, aes(fill = order), alpha = 0.5) +
	geom_histogram(data = sla, bins = binc, aes(fill = order), alpha = 0.5) +
	geom_histogram(data = sra, bins = binc, aes(fill = order), alpha = 0.5) +
	scale_fill_manual(name = "order", values = palette[1:3]) + # use labels = to make custom legend
	geom_vline(aes(xintercept = 0.0), # No error
			color = "black", linetype = "solid", alpha=1.0) +
	geom_vline(aes(xintercept = mpfr_1000 - canonical), # Canonical left-associative
			color = "red", linetype = "dotted", alpha=0.8) +
	geom_vline(aes(xintercept = mean(ra$error_mpfr)), # Random assoc
			color = palette[1], linetype = "solid", alpha=0.7) +
	geom_vline(aes(xintercept = mean(sla$error_mpfr)), # Shuffle l assoc
			color = palette[2], linetype = "solid", alpha=0.7) +
	geom_vline(aes(xintercept = mean(sra$error_mpfr)), # Shuffle random assoc
			color = palette[3], linetype = "solid", alpha=0.7)
ggsave(paste0("figures/assoc-runif01-hist-blended.pdf"), plot = p, height = 4)
# FIXME
	# geom_segment(aes(
	# 	x = max(abs(error_mpfr))/2,
	# 	y = 0.7*max(p_count),
	# 	xend = max(abs(error_mpfr)) + 1e9*DBL_MIN, #FIXME
	# 	yend = 0.7*max(p_count)))

# The two that basically look identical
binc <- sapply(list(ra,sla,sra), function(x) {length(unique(sort(abs(x$error_mpfr))))})
binc <- min(ifelse(binc%%2 == 0, binc + 1, binc)) # Odd looks better for symmetry about 0
p <- ggplot(subset(allr, allr$order %in% c("Random assoc", "Shuffle rand assoc")), aes(x = abs(error_mpfr))) +
	geom_histogram(bins = binc, aes(fill = order), alpha = 0.7) +
	geom_vline(aes(xintercept = 0.0), # No error
			color = "black", linetype = "solid", alpha=1.0) +
	geom_vline(aes(xintercept = mean(ra$error_mpfr)), # Random assoc
			color = palette[1], linetype = "solid", alpha=1) +
	geom_vline(aes(xintercept = mean(sra$error_mpfr)), # Shuffle random assoc
			color = palette[3], linetype = "solid", alpha=1)
ggsave(paste0("figures/assoc-runif01-hist-ra-sra-abs-stacked.pdf"), plot = p, height = 4)


# Histogram for allr (separate) - I don't think this is informative
binc <- sapply(list(allr), function(x) {length(unique(sort(x$error_mpfr)))})
binc <- ifelse(binc%%2 == 0, binc + 1, binc) # Odd looks better for symmetry about 0
p <- ggplot(allr, aes(x = error_mpfr)) +
	geom_histogram(bins = binc, alpha = 0.4, fill = palette[4]) +
	geom_vline( # Mean of everything --- not sure this is helpful
		aes(xintercept = mean(error_mpfr)),
			color = "blue", linetype = "dotted", alpha=0.8)
ggsave(paste0("figures/assoc-runif01-hist-allr.pdf"), plot = p, height = 4)
