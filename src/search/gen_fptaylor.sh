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
FPTAYLOR="$HOME/fn-methods/FPTaylor/fptaylor"

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
for n in `seq $(($N - 1))`; do
	printf "\treal x_$n in [$LOWER_BOUND, $UPPER_BOUND],\n" >> "$FILE"
done
printf "\treal x_$N in [$LOWER_BOUND, $UPPER_BOUND]\n;\n" >> "$FILE"

printf "\nDefinitions\n\ts_1 $RND_TYPE = x_1 * x_1,\n" >> "$FILE"
for n in `seq 2 $N`; do
	n_1=$(($n - 1))
	printf "\ts_$n $RND_TYPE = s_$n_1 + x_$n * x_$n,\n" >> "$FILE"
done
printf "\tnorm $RND_TYPE = sqrt(s_$N),\n" >> "$FILE"
printf "\trsqrt $RND_TYPE = 1.0 / norm,\n" >> "$FILE"
printf "\tq_$N $RND_TYPE = x_$N * rsqrt\n;\n" >> "$FILE"

printf "\nExpressions\n" >> "$FILE"
printf "\tdot_$N = s_$N,\n" >> "$FILE"
printf "\tsquare_root_$N = norm,\n" >> "$FILE"
printf "\tinvsqrt_$N = rsqrt,\n" >> "$FILE"
printf "\tx_${N}_unit = q_$N\n;\n" >> "$FILE"

echo "Running for N = $N..." | tee -a "$LOG"

# May also want --intermediate-opt=true
#FP_OPTIONS="--maxima-simplification=true"
FP_OPTIONS=""

"$FPTAYLOR" $FP_OPTIONS "$LEN_INFILE" > "$LEN_OUTFILE"

