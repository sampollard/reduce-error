#!/bin/bash
set -u

# First, get nekbone and modify it to work with SimGrid
if [ ! -d "test" ]; then
	git clone https://github.com/Nek5000/Nekbone
	mv -f Nekbone/src && mv -f Nekbone/test && rm -rf Nekbone
fi
cp custom/cg.f src/
cp custom/makenek custom/nekpmpi test/example1/
mkdir -p experiments
cd "test/example1/"

# See SIZE for explanation of these three
LP=288
LELT=9216 # 72 * 128
POLY=10

NUM_TRIALS=50
NP_COUNT="16 72"
ALLREDUCE_ALGOS="default ompi mpich mvapich2 impi rab1 rab2 rab_rsag rdb smp_binomial smp_binomial_pipeline smp_rdb smp_rsag smp_rsag_lr smp_rsag_rab redbcast ompi_ring_segmented mvapich2_rs mvapich2_two_level rab"
# Algorithms that don't work in this case (and thus change to default):
# lr automatic

# Some necessary janitorial code. SIZE contains compile-time constants
TRIAL_FMT=$(seq --format='%03.0f' 1 $NUM_TRIALS)
LELG=$(echo "$LP * $LELT" | bc)
cp ../../custom/SIZE .

# Experiment loop
# Doing trial as the outermost loop is slower, but more flexible since we can stop, say,
# if we only get to 10 trials or something.
for TRIAL in $TRIAL_FMT; do
	for NP in $NP_COUNT; do
		# Build for a given processor count
		IEL0=$(echo "$LELT / $NP" | bc)
		IELN=$(echo "$IEL0 * 2 + 1" | bc)
		sed "s/400 400 1 = iel0,ielN/$IEL0 $IELN $IEL0 = iel0,ielN/g ;
		     s/10  10  1 = nx0,nxN,stride/$POLY  $POLY  1 = nx0,nxN,stride/g" \
		    ../../custom/data.rea > data.rea

		# Loop over the topologies that make sense for a given processor count.
		if [ "$NP" -eq 72 ]; then
			make -j -f ../../custom/exp-Makefile TRIAL="$LELT-$TRIAL" TOPO="fattree-72" NP=$NP all
			# Note: these experiments take a while so you might just want to do one at a time
			make -j -f ../../custom/exp-Makefile TRIAL="$LELT-$TRIAL" TOPO="torus-2-4-9" NP=$NP all
		elif [ "$NP" -eq 16 ]; then
			make -j -f ../../custom/exp-Makefile TRIAL="$LELT-$TRIAL" TOPO="fattree-$NP" NP=$NP all
			make -j -f ../../custom/exp-Makefile TRIAL="$LELT-$TRIAL" TOPO="torus-2-2-4" NP=$NP all
		else
			echo "Bad topology for np = $NP"
			exit 1
		fi
	done
done
cd -

