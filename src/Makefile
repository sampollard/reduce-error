# Makefile for MPI reduction tests
# usage:
# see README.md

USE_MPI ?= 1
# Make sure to recompile before switching between simgrid and other MPI
MPICXX = smpicxx
#MPICXX = mpicxx

EXTRA_SOURCES = rand.cxx mpi_op.cxx assoc.cxx
HEADERS = rand.hxx mpi_op.hxx assoc.hxx
ifeq ($(USE_MPI), 1)
TARGETS = mpi_pi_reduce dotprod_mpi
else
TARGETS = assoc_test gen_random
endif

# MPI and MPI Modular Component Architecture commands (OpenMPI)
NUM_PROCS_LOCAL = 16 # For running on the system MPI; simgrid runs use other process counts
VERBOSITY = coll_base_verbose 0
#VERBOSITY = coll_base_verbose 40

# Sizes
VECLEN = 14400
VECLEN_BIG = 72000000
RAND_TRIALS = 50000
VECLEN_RAND = 100000
VECLEN_RAND_BIG = 2000000
RAND_TRIALS_DEEP = 5000000
VECLEN_RAND_DEEP = 256

# SimGrid options
#LOG_LEVEL = --log=smpi_colls.threshold:debug
LOG_LEVEL = --log=root.thres:critical
# 3 Gflops. See notes.md for explanation.
FLOPS = 3000000000f
MPI_REDUCE_ALGOS = default ompi mpich mvapich2 impi automatic \
	arrival_pattern_aware binomial flat_tree NTSL scatter_gather ompi_chain \
	ompi_pipeline ompi_binary ompi_in_order_binary ompi_binomial \
	ompi_basic_linear mvapich2_knomial mvapich2_two_level rab
TOPOLOGY_16 = fattree-16 torus-2-2-4
TOPOLOGY_72 = fattree-72 torus-2-4-9
LDFLAGS += -L$${HOME}/.local/simgrid/lib -Wl,-rpath=$${HOME}/.local/simgrid/lib
LIBS += -lmpfr -lgmp

CXXFLAGS += -Wall -g

# Shouldn't need to change
OBJECTS = $(EXTRA_SOURCES:.cxx=.o)
TARGET_OBJS = $(TARGETS:=.o)
TOPO_DIR = ../topologies

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
	mkdir -p experiments
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
quick : $(TARGETS)
	smpirun -hostfile $(TOPO_DIR)/hostfile-fattree-16.txt -platform $(TOPO_DIR)/fattree-16.xml -np 16 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) fattree-16 auto
	smpirun -hostfile $(TOPO_DIR)/hostfile-fattree-72.txt -platform $(TOPO_DIR)/fattree-72.xml -np 72 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) fattree-72 auto
	smpirun -hostfile $(TOPO_DIR)/hostfile-fattree-72.txt -platform $(TOPO_DIR)/torus-2-4-9.xml -np 72 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) torus-2-4-9 auto
	smpirun -hostfile $(TOPO_DIR)/hostfile-fattree-16.txt -platform $(TOPO_DIR)/torus-2-2-4.xml -np 4 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) torus-2-2-4 auto

sim : $(TARGETS)
	$(foreach algo,$(MPI_REDUCE_ALGOS), \
		$(foreach topo,$(TOPOLOGY_16), \
			smpirun -hostfile $(TOPO_DIR)/hostfile-$(topo).txt -platform $(TOPO_DIR)/$(topo).xml \
				-np 16 \
				--cfg=smpi/host-speed:$(FLOPS) \
				--cfg=smpi/reduce:$(algo) \
				$(LOG_LEVEL) \
				./dotprod_mpi $(VECLEN_BIG) $(topo) $(algo); \
		) \
		$(foreach topo,$(TOPOLOGY_72), \
			smpirun -hostfile $(TOPO_DIR)/hostfile-$(topo).txt -platform $(TOPO_DIR)/$(topo).xml \
				-np 72 \
				--cfg=smpi/host-speed:$(FLOPS) \
				--cfg=smpi/reduce:$(algo) \
				$(LOG_LEVEL) \
				./dotprod_mpi $(VECLEN_BIG) $(topo) $(algo); \
		) \
	)

# Potential bug in SimGrid
differ : dotprod_mpi
	smpirun -hostfile $(TOPO_DIR)/hostfile-torus-2-4-9.txt -platform $(TOPO_DIR)/torus-2-4-9.xml -np 72 --cfg=smpi/host-speed:3000000000f --cfg=smpi/reduce:mvapich2_knomial --log=root.thres:critical ./dotprod_mpi 720 torus-2-4-9 mvapich2_knomial

# OpenMPI command line arguments
ompi: $(TARGETS)
	$(foreach algo,$(OMPI_ALGOS),\
		echo Reduction algorithm $(algo) ; \
		mpirun -np $(NUM_PROCS_LOCAL) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) ./mpi_pi_reduce;)
	$(foreach algo,$(OMPI_ALGOS),\
		mpirun -np $(NUM_PROCS_LOCAL) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) ./dotprod_mpi $(VECLEN_BIG) native $(algo);)

# Random associations (serial)
assoc_quick : assoc_test
	./assoc_test $(VECLEN_RAND) 10 runif[0,1]
	./assoc_test $(VECLEN_RAND) 10 runif[-1,1]
	./assoc_test $(VECLEN_RAND) 10 runif[-1000,1000]
	./assoc_test $(VECLEN_RAND) 10 rsubn

assoc : assoc_test assoc01 assoc11 assoc1000 assocrsubn
assoc01: assoc_test
	./assoc_test $(VECLEN_RAND) $(RAND_TRIALS) runif[0,1]        > experiments/assoc-runif01.tsv
assoc11: assoc_test
	./assoc_test $(VECLEN_RAND) $(RAND_TRIALS) runif[-1,1]       > experiments/assoc-runif11.tsv
assoc1000: assoc_test
	./assoc_test $(VECLEN_RAND) $(RAND_TRIALS) runif[-1000,1000] > experiments/assoc-runif1000.tsv
assocrsubn: assoc_test
	./assoc_test $(VECLEN_RAND) $(RAND_TRIALS) rsubn             > experiments/assoc-rsubn.tsv

assoc_big : assoc_test assoc01_big assoc11_big assoc1000_big assocrsubn_big
assoc01_big: assoc_test
	./assoc_test $(VECLEN_RAND_BIG) $(RAND_TRIALS) runif[0,1]        > experiments/assoc-runif01-big.tsv
assoc11_big: assoc_test
	./assoc_test $(VECLEN_RAND_BIG) $(RAND_TRIALS) runif[-1,1]       > experiments/assoc-runif11-big.tsv
assoc1000_big: assoc_test
	./assoc_test $(VECLEN_RAND_BIG) $(RAND_TRIALS) runif[-1000,1000] > experiments/assoc-runif1000-big.tsv
assocrsubn_big: assoc_test
	./assoc_test $(VECLEN_RAND_BIG) $(RAND_TRIALS) rsubn             > experiments/assoc-rsubn-big.tsv

assoc_deep : assoc_test assoc01_deep assoc11_deep assoc1000_deep assocrsubn_deep
assoc01_deep: assoc_test
	./assoc_test $(VECLEN_RAND_DEEP) $(RAND_TRIALS_DEEP) runif[0,1]        > experiments/assoc-runif01-deep.tsv
assoc11_deep: assoc_test
	./assoc_test $(VECLEN_RAND_DEEP) $(RAND_TRIALS_DEEP) runif[-1,1]       > experiments/assoc-runif11-deep.tsv
assoc1000_deep: assoc_test
	./assoc_test $(VECLEN_RAND_DEEP) $(RAND_TRIALS_DEEP) runif[-1000,1000] > experiments/assoc-runif1000-deep.tsv
assocrsubn_deep: assoc_test
	./assoc_test $(VECLEN_RAND_DEEP) $(RAND_TRIALS_DEEP) rsubn             > experiments/assoc-rsubn-deep.tsv

clean :
	$(RM) $(TARGETS) $(TARGET_OBJS) $(OBJECTS) $(HEADERS:=.gch) $(TARGETS)_*.so

# Dependency lists
assoc.o : assoc.hxx
assoc_test.o : assoc.hxx rand.hxx
dotprod_mpi.o : rand.hxx assoc.hxx mpi_op.hxx
gen_random.o : rand.hxx
mpi_op.o : mpi_op.hxx
mpi_pi_reduce.o : rand.hxx
rand.o : rand.hxx
