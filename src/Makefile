# Makefile for MPI reduction tests
# usage:
# see README.md

USE_MPI ?= 1
# Make sure to recompile before switching between simgrid and other MPI
MPICXX = smpicxx
#MPICXX = mpicxx

EXTRA_SOURCES = assoc.cxx mpi_op.cxx rand.cxx
HEADERS = assoc.hxx mpi_op.hxx rand.hxx util.hxx
ifeq ($(USE_MPI), 1)
TARGETS = mpi_pi_reduce dotprod_mpi
else
TARGETS = assoc_test gen_random
endif

# Experiment Parameters
EXP_DIR = experiments/post-acceptance
VECLEN_BIG = 72000000
RAND_TRIALS = 1000000
VECLEN_RAND_QUICK = 100000
VECLEN_RAND_BIG = 2000000
RAND_TRIALS_DEEP = 5000000
VECLEN_RAND_DEEP = 256

# SimGrid options
#LOG_LEVEL = --log=smpi_colls.threshold:debug
LOG_LEVEL = --log=root.thres:critical
TOPOLOGY_16 = fattree-16 torus-2-2-4
LDFLAGS += -L$${HOME}/.local/simgrid/lib -Wl,-rpath=$${HOME}/.local/simgrid/lib
LIBS += -lmpfr -lgmp

CXXFLAGS += -Wall -g

# MPI and MPI Modular Component Architecture commands (OpenMPI). Currently Unused
NUM_PROCS_LOCAL = 16 # For running on the system MPI; simgrid runs use other process counts
VERBOSITY = coll_base_verbose 0
#VERBOSITY = coll_base_verbose 40

# Shouldn't need to change
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
dotprod_mpi : $(OBJECTS) rand.o mpi_op.o dotprod_mpi.o
	$(MPICXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^ $(LIBS)
else 
# Non-MPI targets
assoc_test : assoc_test.o rand.o assoc.o
	mkdir -p $(EXP_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
gen_random : gen_random.o rand.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)
endif

# OpenMPI MPI_Reduce Algorithms
OMPI_ALGOS = 0 1 2 3 4 5 6 7
# 0:"ignore"
# 1:"linear"
# 2:"chain"
# 3:"pipeline"
# 4:"binary"
# 5:"binomial"
# 6:"in-order_binary"
# 7:"rabenseifner"

.PHONY : quick sim ompi clean differ assoc assoc_quick assoc_big assoc_deep

# OpenMPI command line arguments
ompi: $(TARGETS)
	$(foreach algo,$(OMPI_ALGOS),\
		echo Reduction algorithm $(algo) ; \
		mpirun -np $(NUM_PROCS_LOCAL) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) ./mpi_pi_reduce;)
	$(foreach algo,$(OMPI_ALGOS),\
		mpirun -np $(NUM_PROCS_LOCAL) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) ./dotprod_mpi $(VECLEN_BIG) native $(algo);)

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

clean :
	$(RM) $(TARGETS) $(TARGET_OBJS) $(OBJECTS) $(HEADERS:=.gch) $(TARGETS)_*.so

# Simgrid targets
sim : dotprod_mpi
	$(MAKE) -f simgrid.mk sim

export USE_MPI MPICXX
quick : dotprod_mpi
	$(MAKE) -f simgrid.mk quick


# Dependency lists
assoc.o : assoc.hxx
assoc_test.o : assoc.hxx rand.hxx util.hxx
dotprod_mpi.o : rand.hxx assoc.hxx mpi_op.hxx
gen_random.o : rand.hxx
mpi_op.o : mpi_op.hxx
mpi_pi_reduce.o : rand.hxx
rand.o : rand.hxx
