#!/bin/bash
set -u
# Generate different Satire values
USAGE='./gen-satire.sh'

if [ "$#" -ne 0 ]; then
	echo $USAGE
	exit 2
fi
mkdir -p input
mkdir -p output
LOG=log.txt
rm -f "$LOG"

SATIRE_PY="$HOME/Documents/uo/reduce-error/Satire/src/satire.py"
SKELETON="satire_skeleton.txt"

RND_T_LIST='rnd32 rnd64'
# RND_TYPE implies a certain FL_TYPE, at least for now
UB_LIST='10000.0 1000.0 100.0 10.0 1.0'
LB_LIST='0.0001 0.001 0.01'

for RND_TYPE in $RND_T_LIST; do
	if [ "$RND_TYPE" = "rnd32" ]; then
		FL_TYPE='fl32'
	fi
	if [ "$RND_TYPE" = "rnd64" ]; then
		FL_TYPE='fl64'
	fi
	for UPPER_BOUND in $UB_LIST; do
		for LOWER_BOUND in $LB_LIST; do
				SLUG="satire-$FL_TYPE-$RND_TYPE-$LOWER_BOUND-$UPPER_BOUND.txt"
				INFILE="input/$SLUG"
				OUTFILE="output/$SLUG"

				echo "Writing Satire input to $INFILE..."

				sed "s/FL_TYPE/$FL_TYPE/; \
					 s/RND_TYPE/$RND_TYPE/; \
					 s/LOWER_BOUND/$LOWER_BOUND/; \
					 s/UPPER_BOUND/$UPPER_BOUND/;" \
					 satire_skeleton.txt > "$INFILE"

				echo "Writing Satire output to $OUTFILE..."
				time python3 "$SATIRE_PY" --file "$INFILE" --outfile "$OUTFILE" >> "$FILE"
		done
	done
done

# Just try one for debugging purposes
FL_TYPE='fl64'
RND_TYPE='rnd64'
LOWER_BOUND=0.0000001
UPPER_BOUND=1000000.0

SLUG="satire-$FL_TYPE-$RND_TYPE-$LOWER_BOUND-$UPPER_BOUND"
INFILE="input/$SLUG.txt"
OUTFILE="output/$SLUG.out"

echo "Writing Satire input to $INFILE..." | tee -a "$LOG"

sed "s/FL_TYPE/$FL_TYPE/; \
	 s/RND_TYPE/$RND_TYPE/; \
	 s/LOWER_BOUND/$LOWER_BOUND/; \
	 s/UPPER_BOUND/$UPPER_BOUND/;" \
	 satire_skeleton.txt > "$INFILE"

echo "Writing Satire output to $OUTFILE..." | tee -a "$LOG"
time python3 "$SATIRE_PY" --file "$INFILE" --outfile "$OUTFILE" >> "$LOG"

# Generate a larger example
N=100
LEN_INFILE='test.txt'
LEN_OUTFILE='test.out'

FILE="$LEN_INFILE"
printf "INPUTS {\n" > "$FILE"
for n in `seq $N`; do
	printf "\tx_$n $FL_TYPE : ($LOWER_BOUND, $UPPER_BOUND);\n" >> "$FILE"
done
printf "}\nOUTPUTS {\n\ts_$N;\n\tsquare_root;\n\tinvsqrt;\n" >> "$FILE"
printf "\tx_${N}_unit;\n}\n" >> "$FILE"

printf "EXPRS {\n\ts_1 $RND_TYPE = x_1 * x_1;\n" >> "$FILE"
for n in `seq 2 $N`; do
	n_1=$(($n - 1))
	printf "\ts_$n $RND_TYPE = s_$n_1 + x_$n * x_$n;\n" >> "$FILE"
done
printf "\tsquare_root $RND_TYPE = sqrt(s_$N);\n" >> "$FILE"
printf "\tinvsqrt $RND_TYPE = 1.0 / square_root;\n" >> "$FILE"
printf "\tx_${N}_unit $RND_TYPE = x_$N * invsqrt;\n}\n" >> "$FILE"

echo "Running for N = $N..." | tee -a "$LOG"
time python3 "$SATIRE_PY" --file "$LEN_INFILE" --outfile "$LEN_OUTFILE" >> $LOG
