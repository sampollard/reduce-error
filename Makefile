# Makefile for MPI reduction tests
# Make sure to do spack load openmpi

SOURCES = rand.c
TARGETS = mpi_pi_reduce

OBJECTS = $(SOURCES:.c=.o)
HEADERS = rand.h
TARGET_OBJS = $(TARGETS:=.o)
# MPI Modular Component Architecture commands
VERBOSITY = coll_base_verbose 40
REDUCE_ALGO = coll_tuned_reduce_algorithm 1

CFLAGS += -Wall

# MPI Flags
NUM_PROCS = 10
MPICC ?= mpicc

all : $(TARGETS)

rand.o : rand.c rand.h
	$(CC) $(CFLAGS) -c $<

mpi_pi_reduce : $(OBJECTS) mpi_pi_reduce.o 
	$(MPICC) $(CFLAGS) -o $@ $^

mpi_pi_reduce.o : mpi_pi_reduce.c
	$(CC) $(CFLAGS) -c $^

ALGOS = 0 1 2 3 4 5 6
# 1:"linear"
# 2:"chain"
# 3:"pipeline"
# 4:"binary"
# 5:"binomial"
# 6:"in-order_binary"

.PHONY : test
test : $(TARGETS)
	mpirun -np $(NUM_PROCS) mpi_pi_reduce
	mpirun -np $(NUM_PROCS) --mca coll_base_verbose 0 --mca coll_tuned_reduce_algorithm 0 mpi_pi_reduce
	mpirun -np $(NUM_PROCS) --mca coll_base_verbose 0 --mca coll_tuned_reduce_algorithm 1 mpi_pi_reduce
	mpirun -np $(NUM_PROCS) --mca coll_base_verbose 0 --mca coll_tuned_reduce_algorithm 2 mpi_pi_reduce
	# $(foreach algo,$(ALGOS),\
	# 	echo Reduction algorithm $(algo) ; \
	# 	mpirun -np $(NUM_PROCS) --mca coll_base_verbose 0 --mca coll_tuned_reduce_algorithm $(algo) mpi_pi_reduce;)


.PHONY: clean
clean :
	$(RM) $(TARGETS) $(TARGET_OBJS) $(OBJECTS) $(HEADERS:=.gch)

# Dependency list
$(OBJECTS) $(TARGET_OBJS): rand.h

