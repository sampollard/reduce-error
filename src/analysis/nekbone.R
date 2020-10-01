# Analyze Nekbone output.
# First, using openmpi (easier), then using simgrid (more files)
library(dplyr)
options(dplyr.summarise.inform=F) # Remove "summarise() regrouping output" warning
library(ggplot2)
library(scales)
library(viridis)
library(Cairo)

# Some magic numb--err... constants
canon <- list(
	elements = 9216,
	max_residual = 1.0,
	fill_color = viridis(5)[4])

topo_pp <- function(x) {
	switch(x,
		"fattree-72"   = "72-node Fat Tree Cluster",
		"unknown topology, check topo_pp")
}

# Return the smallest double-precision number greater than x (nextafter in C/C++)
# Works for all positive, non-subnormal x
next_dbl <- function(x) {
	x / (1 - .Machine$double.neg.eps)
}

# Some terminology: nb = neckbone
# f = filtered, t = topology, s = summarized and subsetted, u = unique trials
fn <- paste0('experiments/nekbone.tsv')
nb <- na.omit(read.table(fn, header = TRUE, fill=TRUE))

# Let's investigate this further - smp_rsag_lr is the only allreduce
# algorithm that doesn't for fattree-72
nbnon <- nb %>% filter(elements == canon$elements)
# See https://gitlab.inria.fr/simgrid/simgrid/-/blob/f734ec7475682eb90323e804cbcfddd7e4523992/src/smpi/colls/allreduce/allreduce-smp-rsag-rab.cpp
cat(sprintf("smp_rsag_lr appears (not documented) to only work with power-two number of ranks\n"))
cat(sprintf("smp_rsag_rab only works (documented) with power-two number of ranks\n"))

# Filter out the ones that didn't converge and smp_rsag_lr
nbconverged <- nbnon %>% filter(cg_residual < canon$max_residual)
nbf <- nbconverged %>% filter(algo != "smp_rsag_lr")

# Filter by where the residuals differ (across different trials)
filter_nbf <- function (df, topo, filter_algos = c(), min_trials = NULL) {
	nbt <- df %>%
		filter(!(algo %in% filter_algos)) %>%
		filter(topology %in% topo)
	def_res_nbt <- min(filter(nbt, algo == 'default')$cg_residual)
	nbt$difference <- nbt$cg_residual - def_res_nbt
	# Get the number of trials. To be conservative, count the minimum for each
	# experiment, where an experiment is each triple of (NP, topology, algo)
	if (is.null(min_trials)) {
		mt <- nbt %>%
			group_by(NP, topology, algo) %>%
			summarize(num_trials = n_distinct(trial)) %>%
			pull(num_trials) %>% min()
	} else {
		mt <- min_trials
	}

	nbt <- nbt %>% filter(trial <= mt, .preserve = TRUE)

	# For each unique cg_residual, count the total number of trials that
	# had that exact cg_residual
	nbt$count <- nbt %>%
		group_by(elements, NP, topology, algo, cg_residual) %>%
		add_tally(name = "count") %>%
		pull(count)
	return(nbt)
}

nbt_topo <- "fattree-72"
# Uh.... KISS. By the paper deadline I've done about 75 so choose that.
min_trials <- 69

# Single out one topology. Filter out smp_rsag by default because it makes
# other points all look the same, even with a log scale.
outlier_algo <- 'smp_rsag'
#filter_algos <- c(outlier_algo) # Different choice to visualize: make a tag only
filter_algos <- c() # Alternatively, just chop off so smp_rsag is "off the charts"
nbt <- filter_nbf(nbf, c(nbt_topo), filter_algos = filter_algos, min_trials = min_trials)
min_res_nbt  <- min(filter(nbt, algo != outlier_algo)$cg_residual)
min_diff_nbt <- min(filter(nbt, algo != outlier_algo)$difference)
max_diff_nbt <- max(filter(nbt, algo != outlier_algo)$difference)
min_res_all  <- min(nbt$cg_residual)
def_res_nbt  <- min(filter(nbt, algo == 'default')$cg_residual)

# Also get the value of the outlier and how much it's different from 'default'
nbt_all_algos <- filter_nbf(nbconverged, c(nbt_topo), filter_algos = c(), min_trials = min_trials)
min_filter_algo_res <- min(filter(nbt_all_algos, algo == outlier_algo)$cg_residual) - def_res_nbt

# Here's a weird result. The later experiments are more consistent. If we do
# nbt <- nbt %>% filter(trial <= min_trials, trial > 25, .preserve = TRUE)
# and then plot, they are all the same result.
# UPDATE (9/15/2020): This goes away when the earlier experiments were deleted. It
# was an artifact of sloppy cleaning between experiment modification

#####################################################################
###            Plot used in Correctness 2020 Paper                ###
#####################################################################
# We subtract from the default allreduce to get the y-axis to have a reasonable scale
# scale_y_continuous(limits = range(nbt$cg_residual))  seems not to work
p <- ggplot(nbt, aes(x = algo, y = difference, group = difference,
	                 fill = difference >= 0.0)) +
	geom_bar(stat = "identity", color = "black", position = "dodge") + # canon$fill_color) +
	# The numbers above the bars just confuse people since they are all the same
	# (the non-reproducibility I originally observed went away when I was more careful with
	# how and where I ran experiments)
	# geom_text(aes(label = count),
	# 	position = position_dodge(0.9), vjust = -0.7, size = 3,
	# 	check_overlap = TRUE) +
	theme(axis.text.x = element_text(angle = 30, hjust = 1, size = 10)) +
	guides(fill = FALSE) +
	labs(title = paste("Unique Results for Nekbone on a", topo_pp(nbt_topo)),
		tag = sprintf("\u2B33 smp_rsag = %0.2e", min_filter_algo_res)) +
	theme(plot.tag = element_text(angle = 90, size = 11),
		plot.tag.position = "right") +
	scale_fill_viridis_d(option = "plasma", begin = 0.4, end = 1, direction = -1) +
	scale_y_continuous(
		limits = c(-max_diff_nbt*0.25, max_diff_nbt*1.1), # Make room for the counts
		labels = function(x) sprintf("%0.2e", x),
		breaks = seq(min_diff_nbt, max_diff_nbt, length.out = 6),
		# Like oob_keep, but allows "zoom" to account for the lack of floating point precision
		# at such small scales
		oob = function(x, range = c(0,1)) {
			oob_keep(ifelse(x < 0, -max_diff_nbt , x), range = range)
		}) +
	xlab("Allreduce Algorithm") +
	ylab("Difference from Default Residual")
# Add in a scale for machine epsilon. This feels a little hacky.
left_edge <- ggplot_build(p)$layout$panel_params[[1]]$x.range[1]
right_edge <- ggplot_build(p)$layout$panel_params[[1]]$x.range[2]
bottom_edge <- ggplot_build(p)$layout$panel_params[[1]]$y.range[1]
top_edge <- ggplot_build(p)$layout$panel_params[[1]]$y.range[2]
p <- p +
	geom_segment(
		aes(x    = left_edge*1.4,
			xend = left_edge*1.4,
			y    = top_edge*0.9,
			yend = top_edge*0.9 + min_res_nbt - next_dbl(min_res_nbt)),
		size = 1) +
	annotate("text",
		x = left_edge*1.4 + 0.15, # Can't use nudge_x for annotate
		y = top_edge*0.89 + 0.8 * (min_res_nbt - next_dbl(min_res_nbt)),
		label = "= gap between doubles",
		size = 3, vjust = 0, hjust = "left") +
	# Add in an arrow to show the outlier extends beyond
	annotate("text",
		x = right_edge*0.975,
		y = 0.0,
		label = "\u2B33       ",
		size = 4, vjust = 0, angle = 90, hjust = "right")
ggsave(paste0("figures/nekbone-trials.pdf"), device=cairo_pdf, plot = p,
	scale = 0.85, height = 5, width = 7)

# These are nice to have, but too verbose for the figure.
cat(paste("minimum trials =", min_trials, "\n"))
cat(paste("elements =", format(canon$elements,big.mark=","),
		                "\ntoplogy =", nbt_topo, "\n"))

# Some other data I used when qualifying the paper
all_topos <- c("fattree-72","fattree-16","torus-2-2-4","torus-2-4-9", "native-16", "native-36")
nbf_all <- filter_nbf(nbf, all_topos, min_trials = min_trials)
best_res <- nbf_all %>%
	group_by(NP, topology, algo) %>%
	summarize(best = min(cg_residual)) %>%
	arrange(best) %>% as.data.frame()
unique_res <- nbf_all %>%
	group_by(NP, topology) %>%
	summarize(unique(cg_residual))
res_72 <- unique_res %>% filter(topology == 'fattree-72')
cat("Unique results for fattree-72:", as.character(res_72$"unique(cg_residual)"), "\n")
cat("Num unique experiments",
	nbf_all %>% group_by(NP, topology, algo) %>% summarize(n_distinct(NP, topology, algo)) %>% nrow(),
	"\n")
# Print results for Table III
nbt_diffs <- nbt %>% group_by(algo) %>% summarize(res = min(cg_residual))
cat(sprintf("%s &\t%s \\\\\n", gsub("_", "\\\\_", nbt_diffs$algo), nbt_diffs$res))


# Now, include the extra low-residual results (smp_rsag)
special <- "smp_rsag"
nbt_all <- filter_nbf(nbf, c(nbt_topo), min_trials = min_trials)
cat(paste('unique results =', length(unique(nbt_all$cg_residual)), "\n"))

nba <- nbt_all %>%
	group_by(topology, algo) %>%
	distinct(cg_residual)
nb_bi <- rbind(
	nba %>% group_by(topology) %>%
		filter(cg_residual == max(cg_residual)) %>% slice_head(),
	nba %>% group_by(topology) %>%
		filter(algo != special) %>%
		filter(cg_residual == min(cg_residual)) %>% slice_head(),
	nba %>% group_by(topology) %>%
		filter(cg_residual == min(cg_residual)) %>% slice_head())
format(as.data.frame(nb_bi), digits = 17)
# On second thought, this isn't so useful as a plot :(
# min_res_all <- min(nbt_all$cg_residual)
# p <- ggplot(nb_bi, aes(x = algo, y = cg_residual)) +
# 	geom_bar(stat = "identity", color = "black", position = "dodge", fill = canon$fill_color)

#####################################################################
###              Those Weird Subset Plots I Made                  ###
#####################################################################
# Group by the different subsets of all the algorithms
# Count trials which got the exact same result (which is most trials)
nbu <- nbf %>%
	group_by(elements, NP, topology, algo, cg_residual) %>%
	tally(name = "count")

# This plot is not as useful because so many of the bars are exactly the same -
# Maybe if simgrid + nekbone resulted in different runs more often this would
# be the better plot, but alas. Look to the second one.
p <- ggplot(nbu, aes(y = cg_residual, fill = topology, x = algo)) +
	geom_bar(stat = "identity", color = "black", position = position_dodge()) +
	theme(axis.text.x = element_text(angle = 30, hjust = 1)) +
	scale_fill_viridis_d(option = "plasma") +
	labs(title = "Nekbone with Simgrid Allreduce Algorithms")
ggsave(paste0("figures/nekbone-weird-timing.pdf"), plot = p, height = 3.5)

nbs <- nbu %>%
	group_by(elements, NP, topology, cg_residual) %>%
	summarize(identical_algos = toString(algo))
nbs$algos_index <- sprintf("%02d", as.integer(factor(nbs$identical_algos)))

# Print the factor conversions (intgers |-> list of reduce algorithms) in LaTeX-friendly table
fc <- nbs[c("algos_index", "identical_algos")] %>% distinct() %>% arrange(algos_index)
cat(sprintf("%s &\t%s \\\\\n", fc$algos_index, gsub("_", "\\\\_", fc$identical_algos)))

# Plot the summarized subsetted version. This is not so useful.
p <- ggplot(nbs, aes(y = cg_residual, fill = topology, x = algos_index)) +
	geom_bar(stat = "identity", color = "black", position = position_dodge()) +
	scale_fill_viridis_d() +
	labs(title = "Nekbone with Simgrid Allreduce Algorithms",
		caption = paste("elements =", format(canon$elements,big.mark=","))) +
	xlab("Subset of Allreduce Algorithms")
ggsave(paste0("figures/nekbone-subset.pdf"), plot = p, height = 3.5)

