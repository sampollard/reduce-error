# Analyze Nekbone output.
# First, using openmpi (easier), then using simgrid (more files)
library(dplyr)
library(ggplot2)

# Some magic numb--err... constants
canon <- list(
	elements = 9216,
	max_residual = 1.0)

fn <- paste0('experiments/nekbone.tsv')
nb <- na.omit(read.table(fn, header = TRUE, fill=TRUE))

# Filter by where the residuals differ (across different trials) We filter out
# the ones that didn't converge and smp_rsag_lr, which seems to do the wrong
# algorithm
nbf <- nb %>%
	filter(elements == canon$elements) %>%
	filter(cg_residual < canon$max_residual) %>%
	filter(algo != "smp_rsag_lr")

# Remove duplicates across trials (which in this case is every trial)
nbu <- nbf %>%
	group_by(elements, NP, topology, algo, cg_residual) %>%
	tally(name = "count")

# https://gitlab.inria.fr/simgrid/simgrid/-/blob/f734ec7475682eb90323e804cbcfddd7e4523992/src/smpi/colls/allreduce/allreduce-smp-rsag-rab.cpp
cat(sprintf("smp_rsag_lr not working for simgrid\n"))
cat(sprintf("smp_rsag_rab only works with power-two number of processors\n"))

# This plot is not as useful because so many of the bars are exactly the same -
# Maybe if simgrid + nekbone resulted in different runs more often this would
# be the better plot, but alas. Look to the second one.
p <- ggplot(nbu) + aes(y = cg_residual, fill = topology, x = algo) +
	geom_bar(stat = "identity", color = "black", position = position_dodge()) +
	theme(axis.text.x = element_text(angle = 30, hjust = 1)) +
	scale_fill_viridis_d(option = "plasma") +
	labs(title = "Nekbone with Simgrid Allreduce Algorithms")

# Group by the different subsets of all the algorithms
nbr <- nbu %>%
	group_by(elements, NP, topology, cg_residual) %>%
	summarize(identical_algos = toString(algo))
nbr$algos_index <- sprintf("%02d", as.integer(factor(nbr$identical_algos)))

# Print the factor conversions
fc <- nbr[c("algos_index", "identical_algos")] %>% distinct() %>% arrange(algos_index)
cat(sprintf("%s &\t%s \\\\\n", fc$algos_index, gsub("_", "\\\\_", fc$identical_algos)))

# Plot
p <- ggplot(nbr) + aes(y = cg_residual, fill = topology, x = algos_index) +
	geom_bar(stat = "identity", color = "black", position = position_dodge()) +
	scale_fill_viridis_d() +
	labs(title = "Nekbone with Simgrid Allreduce Algorithms",
		caption = paste("elements =", format(canon$elements,big.mark=","))) +
	xlab("Subset of Allreduce Algorithms") +
	ylab("CG Residual")
	
ggsave(paste0("figures/nekbone.pdf"), plot = p, height = 3.5)

