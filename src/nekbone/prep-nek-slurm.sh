#!/bin/bash
# Run some experiments with slurm. Will need to be adjusted for your system
# I found `sacctmgr list account` useful
set -u -e
OMPI_ALLREDUCE=0                # Set to 1 to cycle through OpenMPI allreduce algos
LOG_DIR=logs                    # where to store output
ACCOUNT=hpcl                    # change this to your actual account for charging
PARTITION=short                 # queue to submit to
JOB_NAME=nek-trials-0001        # job name
NODES=16                        # number of nodes to use
OUTPUT="$LOG_DIR/$JOB_NAME.out" # file in which to store job stdout
ERROR="$LOG_DIR/$JOB_NAME.err"  # file in which to store job stderr
#
#                             # Shouldn't need to change below this
#
TIME=10                       # wall-clock time limit, in minutes
MEM=32000                     # memory limit per node, in MB
NTASKS_PER_NODE=1             # number of tasks to launch per node
CPUS_PER_TASK=1               # number of cores for each task
LP=288
LELT=9216 # 72 * 128
NP=$NODES
NUM_TRIALS=100

./makenek

ALGO=1
if [ "$OMPI_ALLREDUCE" -eq 1 ]; then
	OMPI_OPT_START="for ALGO in 0 1 2 3 4 5 6; do"
	OMPI_OPT_ARG="--mca coll_tuned_allreduce_algorithm \$ALGO"
	OMPI_OPT_FN="-a\$ALGO"
	OMPI_OPT_END="done"
else
	OMPI_OPT_START=""
	OMPI_OPT_ARG=""
	OMPI_OPT_FN=""
	OMPI_OPT_END=""
fi

# LOOP
IEL0=$(echo "$LELT / $NP" | bc)
IELN=$(echo "$IEL0 * 2 + 1" | bc)
sed "s/400 400 1 = iel0,ielN/$IEL0 $IELN $IEL0 = iel0,ielN/g" data.rea.orig > data.rea

# Might also want sbatch version:
cat <<EndOfTransmission > nekbone-batch.sh
#!/bin/bash
#SBATCH --account="$ACCOUNT"
#SBATCH --partition="$PARTITION"
#SBATCH --job-name="$JOB_NAME"
#SBATCH --output="$OUTPUT"
#SBATCH --error="$ERROR"
#SBATCH --time="$TIME"
#SBATCH --nodes="$NODES"
#SBATCH --mem="$MEM"
#SBATCH --ntasks-per-node="$NTASKS_PER_NODE"
#SBATCH --cpus-per-task="$CPUS_PER_TASK"

TRIAL_FMT=\$(seq -f '%04.0f' 1 $NUM_TRIALS)
$OMPI_OPT_START
for TRIAL in \$TRIAL_FMT; do
	mpirun -np $NODES $OMPI_OPT_ARG ./nekbone ex1 $NODES > $LOG_DIR/log-np$NP$OMPI_OPT_FN-\$TRIAL.txt
done
$OMPI_OPT_END
EndOfTransmission

echo "nekbone-batch.sh created. Now run"
echo "sbatch nekbone-batch.sh"

