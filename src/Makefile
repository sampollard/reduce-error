# Makefile for MPI reduction tests
# usage:
# see README.md

USE_MPI ?= 1
# Make sure to recompile before switching between simgrid and other MPI
MPICXX ?= smpicxx
#MPICXX = mpicxx

# If using a different install location for simgrid, specify that here
LDFLAGS += -L$${HOME}/.local/simgrid/lib -Wl,-rpath=$${HOME}/.local/simgrid/lib

# Experiment Parameters
EXP_DIR = experiments/2021
RAND_TRIALS = 1000000
VECLEN_RAND_QUICK = 100000
VECLEN_RAND_BIG = 2000000
RAND_TRIALS_DEEP = 5000000
VECLEN_RAND_DEEP = 256

EXTRA_SOURCES = assoc.cxx error_semantics.cxx mpi_op.cxx rand.cxx
HEADERS = assoc.hxx error_semantics.hxx mpi_op.hxx rand.hxx util.hxx
# All targets for cleaning
ifeq ($(USE_MPI), 1)
TARGETS = mpi_pi_reduce dotprod_mpi
else
TARGETS = assoc_test gen_random
endif
ALL_TARGETS = mpi_pi_reduce dotprod_mpi assoc_test gen_random

LIBS += -lmpfr -lgmp
CXXFLAGS += -Wall -g -std=c++14
OBJECTS = $(EXTRA_SOURCES:.cxx=.o)
TARGET_OBJS = $(TARGETS:=.o)

all : $(TARGETS)

%.o : %.cxx
ifeq ($(USE_MPI), 1)
	$(MPICXX) $(CXXFLAGS) $(LDFLAGS) -c $^
else
	$(CXX) $(CXXFLAGS) -c $^
endif

# MPI targets
ifeq ($(USE_MPI),1)
mpi_pi_reduce: mpi_pi_reduce.o rand.o
	$(MPICXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^ $(LIBS)
dotprod_mpi : dotprod_mpi.o assoc.o error_semantics.o mpi_op.o rand.o
	$(MPICXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^ $(LIBS)
else 
# Non-MPI targets
assoc_test : assoc_test.o rand.o assoc.o
	mkdir -p $(EXP_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
gen_random : gen_random.o rand.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
endif

.PHONY : quick sim ompi clean differ assoc assoc_quick assoc_big assoc_deep

# Associativity experiments
# Random associations (serial)
assoc_quick : assoc_test
	./assoc_test $(VECLEN_RAND_QUICK) 10 runif[0,1]
	./assoc_test $(VECLEN_RAND_QUICK) 10 runif[-1,1]
	./assoc_test $(VECLEN_RAND_QUICK) 10 runif[-1000,1000]
	./assoc_test $(VECLEN_RAND_QUICK) 10 rsubn

assoc : assoc_test assoc01 assoc11 assoc1000 assocrsubn
assoc01: assoc_test
	./assoc_test $(VECLEN_RAND_BIG) $(RAND_TRIALS) runif[0,1]        > $(EXP_DIR)/assoc-runif01.tsv
assoc11: assoc_test
	./assoc_test $(VECLEN_RAND_BIG) $(RAND_TRIALS) runif[-1,1]       > $(EXP_DIR)/assoc-runif11.tsv
assoc1000: assoc_test
	./assoc_test $(VECLEN_RAND_BIG) $(RAND_TRIALS) runif[-1000,1000] > $(EXP_DIR)/assoc-runif1000.tsv
assocrsubn: assoc_test
	./assoc_test $(VECLEN_RAND_BIG) $(RAND_TRIALS) rsubn             > $(EXP_DIR)/assoc-rsubn.tsv

assoc_big : assoc_test assoc01_big assoc11_big assoc1000_big assocrsubn_big
assoc01_big: assoc_test
	./assoc_test $(VECLEN_RAND_BIG) $(RAND_TRIALS) runif[0,1]        > $(EXP_DIR)/assoc-runif01-big.tsv
assoc11_big: assoc_test
	./assoc_test $(VECLEN_RAND_BIG) $(RAND_TRIALS) runif[-1,1]       > $(EXP_DIR)/assoc-runif11-big.tsv
assoc1000_big: assoc_test
	./assoc_test $(VECLEN_RAND_BIG) $(RAND_TRIALS) runif[-1000,1000] > $(EXP_DIR)/assoc-runif1000-big.tsv
assocrsubn_big: assoc_test
	./assoc_test $(VECLEN_RAND_BIG) $(RAND_TRIALS) rsubn             > $(EXP_DIR)/assoc-rsubn-big.tsv

assoc_deep : assoc_test assoc01_deep assoc11_deep assoc1000_deep assocrsubn_deep
assoc01_deep: assoc_test
	./assoc_test $(VECLEN_RAND_DEEP) $(RAND_TRIALS_DEEP) runif[0,1]        > $(EXP_DIR)/assoc-runif01-deep.tsv
assoc11_deep: assoc_test
	./assoc_test $(VECLEN_RAND_DEEP) $(RAND_TRIALS_DEEP) runif[-1,1]       > $(EXP_DIR)/assoc-runif11-deep.tsv
assoc1000_deep: assoc_test
	./assoc_test $(VECLEN_RAND_DEEP) $(RAND_TRIALS_DEEP) runif[-1000,1000] > $(EXP_DIR)/assoc-runif1000-deep.tsv
assocrsubn_deep: assoc_test
	./assoc_test $(VECLEN_RAND_DEEP) $(RAND_TRIALS_DEEP) rsubn             > $(EXP_DIR)/assoc-rsubn-deep.tsv

# Simgrid experiments
export USE_MPI MPICXX
sim : dotprod_mpi
	$(MAKE) -f simgrid.mk sim

quick : dotprod_mpi
	$(MAKE) -f simgrid.mk quick

# OpenMPI experiments
ompi : mpi_pi_reduce dotprod_mpi
	$(MAKE) -f openmpi.mk ompi

clean :
	$(RM) $(TARGETS) $(ALL_TARGETS) $(ALL_TARGETS:=.o) $(TARGET_OBJS) $(OBJECTS) $(HEADERS:=.gch) $(TARGETS)_*.so smpitmp-app*

# Dependency lists
assoc.o : assoc.hxx
assoc_test.o : assoc.hxx rand.hxx util.hxx
error_semantics.o : error_semantics.hxx
dotprod_mpi.o : error_semantics.hxx rand.hxx assoc.hxx mpi_op.hxx util.hxx
gen_random.o : rand.hxx
mpi_op.o : mpi_op.hxx
mpi_pi_reduce.o : rand.hxx
rand.o : rand.hxx

