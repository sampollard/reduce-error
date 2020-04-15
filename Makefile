# Makefile for MPI reduction tests
# Make sure to do spack load openmpi

EXTRA_SOURCES = rand.c
TARGETS = mpi_pi_reduce omp_dotprod_mpi
HEADERS = rand.h

# MPI Modular Component Architecture commands
VERBOSITY = coll_base_verbose 0
#VERBOSITY = coll_base_verbose 40

# MPI Flags
NUM_PROCS = 10
MPICC ?= mpicc

CFLAGS += -Wall

# Shouldn't need to change
OBJECTS = $(EXTRA_SOURCES:.c=.o)
TARGET_OBJS = $(TARGETS:=.o)

all : $(TARGETS)

%.o : %.c
	$(CC) $(CFLAGS) -c $^

mpi_pi_reduce : $(OBJECTS) mpi_pi_reduce.o 
	$(MPICC) $(CFLAGS) -o $@ $^

omp_dotprod_mpi : $(OBJECTS) omp_dotprod_mpi.o 
	$(MPICC) $(CFLAGS) -o $@ $^

ALGOS = 0 1 2 3 4 5 6
# 1:"linear"
# 2:"chain"
# 3:"pipeline"
# 4:"binary"
# 5:"binomial"
# 6:"in-order_binary"

.PHONY : test
basic : $(TARGETS)
	mpirun -np $(NUM_PROCS) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm 1 mpi_pi_reduce
	mpirun -np $(NUM_PROCS) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm 1 omp_dotprod_mpi

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

