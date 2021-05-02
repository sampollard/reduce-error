#!/bin/bash
set -u

# Generate different FPTaylor test cases to test scalability
USAGE='./gen-satire.sh'

if [ "$#" -ne 0 ]; then
	echo $USAGE
	exit 2
fi
mkdir -p input
mkdir -p output

LOG=log-fp.txt

rm -f "$LOG"
FPTAYLOR="$HOME/Documents/uo/reduce-error/FPTaylor/fptaylor"

# Generate large case
N=100
LEN_INFILE="rsqrt_$N.txt"
LEN_OUTFILE="rsqrt_$N.out"
LOWER_BOUND=0.001
UPPER_BOUND=1000.0
RND_TYPE='rnd64'

LEN_INFILE="rsqrt_fp_$N.txt"
LEN_OUTFILE="rsqrt_fp_$N.out"

FILE="$LEN_INFILE"

printf "Variables\n" > "$FILE"
for n in `seq $N`; do
	printf "\treal x_$n in [$LOWER_BOUND, $UPPER_BOUND];\n" >> "$FILE"
done
printf "\nExpressions\n\ts_1 $RND_TYPE = x_1 * x_1;\n" >> "$FILE"
for n in `seq 2 $N`; do
	n_1=$(($n - 1))
	printf "\ts_$n $RND_TYPE = s_$n_1 + x_$n * x_$n;\n" >> "$FILE"
done
printf "\tsquare_root $RND_TYPE = sqrt(s_$N);\n" >> "$FILE"
printf "\tinvsqrt $RND_TYPE = 1.0 / square_root;\n" >> "$FILE"
printf "\tx_${N}_unit $RND_TYPE = x_$N * invsqrt;\n" >> "$FILE"

echo "Running for N = $N..." | tee -a "$LOG"

"$FPTAYLOR" "$LEN_INFILE" > "$LEN_OUTFILE"
