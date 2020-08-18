# Generate histogram for subn distribution and compare with exponential
library(ggplot2)
library(MASS)
library(reshape2)

NR <- 10000
fn <- 'experiments/subn.tsv'
df <- read.table(file = fn, sep = "\t", header = TRUE, nrows = NR)

efit <- fitdistr(df$rsubn, "exponential")
cat(sprintf("mean(subn) = %e, expfit = %s\n", mean(df$rsubn), efit$estimate))

df$exp <- dexp(seq(0,2,length.out=NR),rate=efit$estimate)
dfm <- melt(df)

p <- ggplot(dfm, aes(x = value, fill = variable)) +
	geom_histogram(bins = 51, color = "black", position = "dodge") +
	#stat_function(fun = dexp, args = (rate=efit$estimate)) + # This looks bad
	scale_x_continuous(trans="log2", limits=c(2^(-1022),2)) +
	scale_fill_viridis_d(begin = 0.1, end = 0.9, direction = -1, option = "plasma")
ggsave('figures/rsubn.pdf', plot = p, height=2.5)
