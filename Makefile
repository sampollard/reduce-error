# Makefile for MPI reduction tests
# Make sure to do spack load openmpi

EXTRA_SOURCES = rand.c
TARGETS = mpi_pi_reduce omp_dotprod_mpi
HEADERS = rand.h

# MPI Modular Component Architecture commands
VERBOSITY = coll_base_verbose 0
#VERBOSITY = coll_base_verbose 40

# MPI Flags
NUM_PROCS = 16
#MPICC ?= mpicc
MPICC ?= smpicc

CFLAGS += -Wall

# Shouldn't need to change
OBJECTS = $(EXTRA_SOURCES:.c=.o)
TARGET_OBJS = $(TARGETS:=.o)

all : $(TARGETS)

%.o : %.c
	$(MPICC) $(CFLAGS) -c $^

mpi_pi_reduce : $(OBJECTS) mpi_pi_reduce.o 
	$(MPICC) $(CFLAGS) -o $@ $^

omp_dotprod_mpi : $(OBJECTS) omp_dotprod_mpi.o 
	$(MPICC) $(CFLAGS) -o $@ $^

# OpenMPI MPI_Reduce Algorithms
OMPI_ALGOS = 0 1 2 3 4 5 6
# 1:"linear"
# 2:"chain"
# 3:"pipeline"
# 4:"binary"
# 5:"binomial"
# 6:"in-order_binary"

# MPI_Reduce options for SimGrid:
MPI_REDUCE_ALGOS = default ompi mpich mvapich2 impi automatic \
	arrival_pattern_aware binomial flat_tree NTSL scatter_gather ompi_chain \
	ompi_pipeline ompi_binary ompi_in_order_binary ompi_binomial \
	ompi_basic_linear mvapich2_knomial mvapich2_two_level rab

.PHONY : sim
NUM_PROCS = 16
sim : $(TARGETS)
	smpirun -hostfile topologies/hostfile-16.txt -platform topologies/fattree-16.xml -np 16 --cfg=smpi/host-speed:20000000 --cfg=smpi/reduce:ompi --log=smpi_colls.threshold:debug ./omp_dotprod_mpi
	$(foreach algo,$(MPI_REDUCE_ALGOS),\
		smpirun -hostfile topologies/hostfile-$(NUM_PROCS).txt -platform topologies/fattree-$(NUM_PROCS).xml -np $(NUM_PROCS) \
			--cfg=smpi/host-speed:20000000 \
			--cfg=smpi/reduce:$(algo) \
			--log=smpi_colls.threshold:debug \
			./omp_dotprod_mpi;)

.PHONY : test
test : $(TARGETS)
	$(foreach algo,$(ALGOS),\
		echo Reduction algorithm $(algo) ; \
		mpirun -np $(NUM_PROCS) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) mpi_pi_reduce;)
	$(foreach algo,$(ALGOS),\
		echo Reduction algorithm $(algo) ; \
		mpirun -np $(NUM_PROCS) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) omp_dotprod_mpi;)


.PHONY: clean
clean :
	$(RM) $(TARGETS) $(TARGET_OBJS) $(OBJECTS) $(HEADERS:=.gch)

# Dependency list
$(OBJECTS) $(TARGET_OBJS): rand.h

