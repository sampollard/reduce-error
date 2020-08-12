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

# Filter by where the residuals differ (across different trials)
# We filter out the ones that didn't converge and smp_rsag_lr,
# which seems to do the wrong algorithm
nbu <- nb %>%
	group_by(elements, NP, topology, algo, cg_residual) %>%
	tally(name = "count") %>%
	filter(elements == canon$elements) %>%
	filter(cg_residual < canon$max_residual) %>%
	filter(algo != "smp_rsag_lr")

# Ignore the topologies (for simplicity)
p <- ggplot(nbu) + aes(y = cg_residual, fill = topology, x = algo) +
	geom_bar(stat = "identity", color = "black", position = position_dodge()) +
	theme(axis.text.x = element_text(angle = 30, hjust = 1)) +
	scale_fill_viridis_d(option = "plasma") +
	labs(title = "Nekbone with Simgrid Allreduce Algorithms")

ggsave(paste0("figures/nekbone.pdf"), plot = p, height = unit(3.5, "in"))
