#!/bin/bash
set -u
# Join all the experiments for nekbone 
# You better not have spaces in your filenames or path

TSV=experiments/nekbone.tsv
echo -e "elements\tNP\ttopology\talgo\ttrial\tcg_residual" > "$TSV"

# OpenMPI
DIR="experiments/openmpi"
PREFIX="log-np16-"
for f in $DIR/$PREFIX*.txt; do
	TRIAL=${f%%.txt}
	TRIAL=${TRIAL##*-}
	# the cg lines have the format cg: iter rnorm alpha beta pap
	awk -v t=$TRIAL -v a="native" -v np=16 -v topo=native \
		'/cg:/ && ++n == 2 {r=$3}
		 /nelt/{e=$NF}
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
		 /nelt/{e=$NF}
		 END {printf "%s\t%s\t%s\t%s\t%s\t%s\n", e, np, topo, a, t, r}' "$f" >> "$TSV"
done
