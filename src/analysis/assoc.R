# Associativity experiments for uniform distribution
library(ggplot2)
library(reshape2)

df <- read.table(file = 'experiments/assoc-runif.tsv', sep = '\t', header = TRUE)
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
		geom_hline(yintercept = 0.0, color = "black") +
		geom_hline(yintercept = mpfr_1000 - canonical, color = "red", show.legend = TRUE) +
		geom_point(aes(color = factor(order)))
	ggsave(paste0("figures/assoc-runif-",x,".pdf"), plot = p, height = 4)
}

