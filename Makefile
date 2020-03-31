# Makefile for MPI reduction tests
# Make sure to do spack load openmpi

SOURCES = rand.c
TARGETS = mpi_pi_reduce

OBJECTS = $(SOURCES:.c=.o)
HEADERS = rand.h
TARGET_OBJS = $(TARGETS:=.o)

CFLAGS += -Wall

# MPI Flags
RUNFLAGS += --mca coll_base_verbose 1
NUM_PROCS = 4
MPICC ?= mpicc

all : $(TARGETS)

rand.o : rand.c rand.h
	$(CC) $(CFLAGS) -c $<

mpi_pi_reduce : $(OBJECTS) mpi_pi_reduce.o 
	$(MPICC) $(CFLAGS) -o $@ $^

mpi_pi_reduce.o : mpi_pi_reduce.c
	$(CC) $(CFLAGS) -c $^


.PHONY : test
test : $(TARGETS)
	mpirun -np $(NUM_PROCS) $(RUNFLAGS) mpi_pi_reduce

.PHONY: clean
clean :
	$(RM) $(TARGETS) $(TARGET_OBJS) $(OBJECTS) $(HEADERS:=.gch)

# Dependency list
$(OBJECTS) $(TARGET_OBJS): rand.h

