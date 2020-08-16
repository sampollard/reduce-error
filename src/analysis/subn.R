# Generate histogram for subn distribution and compare with exponential
library(ggplot2)

fn <- 'experiments/subn.tsv'
df <- read.table(file = fn, sep = "\t", header = TRUE, nrows = 10000)

efit <- fitdistr(df$rsubn, "exponential")

p <- ggplot(df, aes(x = rsubn)) +
	geom_histogram(bins = 101, color = "black", fill = viridis(3)[2]) +
	#stat_function(fun = dexp, args = (rate=efit$estimate)) +
	scale_x_continuous(trans="log2", limits=c(2^(-1022),2)) +
	scale_color_viridis_d()
ggsave('figures/rsubn.pdf', plot = p, height=2.5)
