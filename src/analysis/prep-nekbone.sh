#!/bin/bash
set -u
# Join all the experiments for nekbone 
# You better not have spaces in your filenames or path

TSV=experiments/nekbone.tsv
echo -e "elements\tNP\ttopology\talgo\ttrial\tcg_residual" > "$TSV"
echo -n "Writing to $TSV... "

# OpenMPI Native (single-node)
DIR="experiments/openmpi"
for NP in 16 36; do
	PREFIX="log-np$NP-"
	for f in $DIR/$PREFIX*.txt; do
		TRIAL=${f%%.txt}
		TRIAL=${TRIAL##*-}
		# the cg lines have the format cg: iter rnorm alpha beta pap
		awk -v t=$TRIAL -v a="native" -v np=$NP -v topo="native-$NP" \
			'/cg:/ && ++n == 2 {r=$3}
			 /nelt/ && e==0 {e=$NF}
			 END {printf "%s\t%s\t%s\t%s\t%s\t%s\n", e, np, topo, a, t, r}' "$f" >> "$TSV"
	done
done

# Running on a cluster
DIR="experiments/cluster"
PREFIX="log-"
for f in $DIR/$PREFIX*.txt; do
	fb=$(basename $f)
	NP=$(echo $fb    | sed -E 's/log-np([0-9]+)-a([0-9]+)-([0-9]+)\.txt/\1/g')
	ALGO=$(echo $fb  | sed -E 's/log-np([0-9]+)-a([0-9]+)-([0-9]+)\.txt/\2/g')
	TRIAL=$(echo $fb | sed -E 's/log-np([0-9]+)-a([0-9]+)-([0-9]+)\.txt/\3/g')
	TOPO=talapas-$NP
	# the cg lines have the format cg: iter rnorm alpha beta pap
	awk -v t=$TRIAL -v a="allreduce$ALGO" -v np=$NP -v topo="$TOPO" \
		'/cg:/ && ++n == 2 {r=$3}
		 /nelt/ && e==0 {e=$NF}
		 END {printf "%s\t%s\t%s\t%s\t%s\t%s\n", e, np, topo, a, t, r}' "$f" >> "$TSV"
done

# Simgrid
DIR="experiments/simgrid"
PREFIX="log-"
for f in $DIR/$PREFIX*.txt; do
	fb=$(basename $f)
	TOPO=$(echo $fb  | sed -E 's/log-(.*)-np([0-9]+)-(.+)-([0-9]+)-([0-9]+)\.txt/\1/g')
	NP=$(echo $fb    | sed -E 's/log-(.*)-np([0-9]+)-(.+)-([0-9]+)-([0-9]+)\.txt/\2/g')
	ALGO=$(echo $fb  | sed -E 's/log-(.*)-np([0-9]+)-(.+)-([0-9]+)-([0-9]+)\.txt/\3/g')
	TRIAL=$(echo $fb | sed -E 's/log-(.*)-np([0-9]+)-(.+)-([0-9]+)-([0-9]+)\.txt/\5/g')
	awk -v t=$TRIAL -v a=$ALGO -v np=$NP -v topo=$TOPO \
		'/cg:/ && ++n == 2 {r=$3}
		 /nelt/ && e==0 {e=$NF}
		 END {printf "%s\t%s\t%s\t%s\t%s\t%s\n", e, np, topo, a, t, r}' "$f" >> "$TSV"
done
echo "done"
