# Associativity experiments for uniform distribution
library(ggplot2)
library(reshape2)
DBL_MIN <- 2.22507385850720138309e-308 # Machine Epsilon
FLT_MIN <- 1.17549435e-38
height <- 3

df <- read.table(file = 'experiments/assoc-runif01.tsv', sep = '\t', header = TRUE)
stopifnot(all(df$veclen == df$veclen[1]))
veclen <- df$veclen[1]
# Filter and get more R-friendly
colnames(df)[4] <- "fp_decimal"
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

# Make some scatterplots. Not particularly useful.
for (x in c("ra", "sla", "sra", "allr")) {
	cdf <- get(x)
	cdf <- na.omit(cdf)
	p <- ggplot(cdf) +
		aes(x = seq_along(order), y = error_mpfr,
			ymin = 1.2*min_diff, ymax = 1.05*max_diff) +
		geom_point(aes(color = factor(order))) +
		geom_hline(yintercept = 0.0, color = "black") +
		geom_hline(yintercept = mpfr_1000 - canonical, color = "red", show.legend = TRUE)
	ggsave(paste0("figures/assoc-runif01-",x,".pdf"), plot = p, height = height)
}
rm(cdf)

# Histograms
# From https://colorbrewer2.org/#type=qualitative&scheme=Dark2
#            "orange"  "purple"  "cyan"     "magenta"  "green"    "gold"     "brown"
dark2_pal <- c("#d95f02","#7570b3","#1b9e77", "#e7298a", "#66a61e", "#e6ab02", "#a6761d")

binc <- sapply(list(ra,sla,sra), function(x) {length(unique(sort(x$error_mpfr)))})
binc <- min(ifelse(binc%%2 == 0, binc + 1, binc)) # Odd looks better for symmetry about 0

# Print some more interesting values
cat(sprintf("means\nra:\t%.20f\nsla:\t%.20f\nsra:\t%.20f\n",
	mean(ra$error_mpfr), mean(sla$error_mpfr), mean(sra$error_mpfr)))
cat(sprintf("Unique:\nra:\t%d\nsla:\t%d\nsra:\t%d\n",
	length(unique(ra$error_mpfr)), length(unique(sla$error_mpfr)), length(unique(sra$error_mpfr))))
cat(sprintf("Nonidential (ra - sra): %d\n", length(intersect(ra$error_mpfr, sra$error_mpfr))))

# Just Shuffling random-associative
p <- ggplot(allr, aes(x = error_mpfr)) +
	geom_histogram(data = sra, bins = binc, fill = dark2_pal[2], alpha = 0.7) +
	geom_vline(aes(xintercept = 0.0, color = "Zero"), # No error
			linetype = "solid", alpha = 1.0, show.legend = TRUE) +
	geom_vline( # Shuffle random assoc
		aes(xintercept = mean(sra$error_mpfr), color = "Mean"),
		linetype = "solid", alpha = 1.0, show.legend = TRUE) +
	scale_color_manual(name = NULL, values = c(Mean = dark2_pal[2], Zero = "black")) +
	theme(legend.position = c(0.8, 0.9), legend.direction="horizontal") +
	labs(title = "Shuffling and Random Associativity",
		caption = paste0("n = ", format(nrow(sra),big.mark=","), "\n|A| = ", format(veclen, big.mark=","))) +
	ylab("Count") +
	xlab(expression(sum[mpfr] - sum[double]))
ggsave(paste0("figures/assoc-runif01-hist-sra.pdf"), plot = p, height = height)

# Shuffle Random Associations vs. Shuffle, left-associative
# Second data frame for vertical lines
vlines <- data.frame(
	"Statistic" = c("Zero", "Canon", "Mean L Assoc", "Mean Rand Assoc"),
	"Value"     = c(0.0, mpfr_1000 - canonical, mean(sla$error_mpfr), mean(sra$error_mpfr)),
	"Color"     = c("black", "#0042ff", dark2_pal[1], dark2_pal[2]),
	"Linetype"  = c("solid", "dotdash", "dashed", "dotted"),
	stringsAsFactors = FALSE)
hist_style <- data.frame(
	"Statistic" = c("L Assoc", "Rand Assoc"),
	"Fill"      = c(dark2_pal[1], dark2_pal[2]))
# So the ordering is as I wrote it above
vlines$Statistic <- factor(vlines$Statistic, levels = vlines$Statistic, ordered = TRUE)
hist_style$Statistic <- factor(hist_style$Statistic, levels = hist_style$Statistic, ordered = TRUE)

p <- ggplot(rbind(sla,sra), bins = binc, aes(x = error_mpfr, fill = order)) +
	geom_histogram(bins = binc, position = "identity", alpha = 0.7) +
	geom_vline(data = vlines, show.legend = TRUE,
		aes(xintercept = Value, color = Statistic, linetype = Statistic)) +
	scale_linetype_manual(name = "Lines", values = vlines$Linetype) +
	scale_color_manual(name = "Lines", values = vlines$Color) +
	# The legends for the histograms
	scale_fill_manual(name = "Histograms", guide = "legend",
		values = hist_style$Fill,
		labels = hist_style$Statistic) +
	guides(fill = guide_legend(override.aes = list(linetype = 0))) +
	labs(title = "Shuffling With and Without Random Associativity",
		caption = paste0("n = ", format(nrow(sla),big.mark=","), "\n|A| = ", format(veclen, big.mark=","))) +
	theme(legend.title = element_blank(),
		legend.position = "top",
		legend.direction = "horizontal",
		legend.box = "horizontal") +
	ylab("Count") +
	xlab(expression(sum[mpfr] - sum[double]))
ggsave(paste0("figures/assoc-runif01-hist-sra-sla.pdf"), plot = p, height = 5)

# FIXME
	# geom_segment(aes(
	# 	x = max(abs(error_mpfr))/2,
	# 	y = 0.7*max(p_count),
	# 	xend = max(abs(error_mpfr)) + 1e9*DBL_MIN, #FIXME
	# 	yend = 0.7*max(p_count)))

# The two that basically look identical
binc <- sapply(list(ra,sla,sra), function(x) {length(unique(sort(abs(x$error_mpfr))))})
binc <- min(ifelse(binc%%2 == 0, binc + 1, binc)) # Odd looks better for symmetry about 0
p <- ggplot(rbind(ra,sra), aes(x = abs(error_mpfr))) +
	geom_histogram(bins = binc, aes(fill = order), position = "identity", color = "white", alpha = 0.5) +
	geom_vline(aes(xintercept = 0.0), # No error
			color = "black", linetype = "solid", alpha=1.0) +
	geom_vline(aes(xintercept = mean(ra$error_mpfr)), # Random assoc
			color = dark2_pal[1], linetype = "solid", alpha=1) +
	geom_vline(aes(xintercept = mean(sra$error_mpfr)), # Shuffle random assoc
			color = dark2_pal[3], linetype = "solid", alpha=1) +
	scale_fill_manual(name = "order", values = dark2_pal[c(1,3)]) +
	theme(legend.position = c(0.8,0.9))
ggsave(paste0("figures/assoc-runif01-hist-ra-sra-abs.pdf"), plot = p, height = height)

# Histogram for allr (separate) - I don't think this is informative
binc <- sapply(list(allr), function(x) {length(unique(sort(x$error_mpfr)))})
binc <- ifelse(binc%%2 == 0, binc + 1, binc) # Odd looks better for symmetry about 0
p <- ggplot(allr, aes(x = error_mpfr)) +
	geom_histogram(bins = binc, alpha = 0.4, fill = dark2_pal[4]) +
	geom_vline( # Mean of everything --- not sure this is helpful
		aes(xintercept = mean(error_mpfr)),
			color = "blue", linetype = "dotted", alpha=0.8)
ggsave(paste0("figures/assoc-runif01-hist-allr.pdf"), plot = p, height = height)
