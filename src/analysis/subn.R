# Generate histogram for subn distribution and compare with exponential
library(ggplot2)

fn <- 'experiments/subn.tsv'
df <- read.table(file = fn, sep = "\t", header = TRUE, nrows = 10000)

p <- ggplot(df, aes(x = rsubn)) +
	#geom_density() +
	geom_histogram(bins = 101, color = "black", fill = viridis(3)[2]) +
	#scale_y_continuous(trans="log10") +
	scale_x_continuous(trans="log2", limits=c(1e-308,2))




