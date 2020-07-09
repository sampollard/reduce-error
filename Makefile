# Makefile for MPI reduction tests
# usage:
# Do "make clean" before changing between USE_MPI and not using it
# `make quick` runs some short MPI programs
# `make sim` runs tests for different simgrid reduction algorithms
# `make ompi` runs tests for different OpenMPI reduction algorithms
# `USE_MPI=0 make assoc` runs many random associations (must have USE_MPI = 0)

USE_MPI ?= 1
# Make sure to recompile before switching between simgrid and other MPI
MPICXX = smpicxx
#MPICXX = mpicxx

EXTRA_SOURCES = rand.cxx mpi_op.cxx assoc.cxx
HEADERS = rand.hxx mpi_op.hxx assoc.hxx
ifeq ($(USE_MPI), 1)
TARGETS = mpi_pi_reduce dotprod_mpi
else
TARGETS = assoc_test
LIBS += -lmpfr -lgmp
endif

# MPI and MPI Modular Component Architecture commands (OpenMPI)
NUM_PROCS_LOCAL = 16 # For running on the system MPI; simgrid runs use other process counts
VERBOSITY = coll_base_verbose 0
#VERBOSITY = coll_base_verbose 40

# Sizes
VECLEN = 14400
VECLEN_BIG = 72000000

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

CXXFLAGS += -Wall -g

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
	$(MPICXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^
dotprod_mpi : $(OBJECTS) rand.o mpi_op.o dotprod_mpi.o
	$(MPICXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^
else 
# Non-MPI targets
assoc_test : assoc_test.o rand.o assoc.o
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

.PHONY : quick sim ompi clean differ assoc
quick : $(TARGETS)
	smpirun -hostfile topologies/hostfile-fattree-16.txt -platform topologies/fattree-16.xml -np 16 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) fattree-16 auto
	smpirun -hostfile topologies/hostfile-fattree-72.txt -platform topologies/fattree-72.xml -np 72 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) fattree-72 auto
	smpirun -hostfile topologies/hostfile-fattree-72.txt -platform topologies/torus-2-4-9.xml -np 72 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) torus-2-4-9 auto
	smpirun -hostfile topologies/hostfile-fattree-16.txt -platform topologies/torus-2-2-4.xml -np 4 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) torus-2-2-4 auto

sim : $(TARGETS)
	$(foreach algo,$(MPI_REDUCE_ALGOS), \
		$(foreach topo,$(TOPOLOGY_16), \
			smpirun -hostfile topologies/hostfile-$(topo).txt -platform topologies/$(topo).xml \
				-np 16 \
				--cfg=smpi/host-speed:$(FLOPS) \
				--cfg=smpi/reduce:$(algo) \
				$(LOG_LEVEL) \
				./dotprod_mpi $(VECLEN_BIG) $(topo) $(algo); \
		) \
		$(foreach topo,$(TOPOLOGY_72), \
			smpirun -hostfile topologies/hostfile-$(topo).txt -platform topologies/$(topo).xml \
				-np 72 \
				--cfg=smpi/host-speed:$(FLOPS) \
				--cfg=smpi/reduce:$(algo) \
				$(LOG_LEVEL) \
				./dotprod_mpi $(VECLEN_BIG) $(topo) $(algo); \
		) \
	)

# Potential bug in SimGrid
differ : dotprod_mpi
	smpirun -hostfile topologies/hostfile-torus-2-4-9.txt -platform topologies/torus-2-4-9.xml -np 72 --cfg=smpi/host-speed:3000000000f --cfg=smpi/reduce:mvapich2_knomial --log=root.thres:critical ./dotprod_mpi 720 torus-2-4-9 mvapich2_knomial

# OpenMPI command line arguments
ompi: $(TARGETS)
	$(foreach algo,$(OMPI_ALGOS),\
		echo Reduction algorithm $(algo) ; \
		mpirun -np $(NUM_PROCS_LOCAL) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) ./mpi_pi_reduce;)
	$(foreach algo,$(OMPI_ALGOS),\
		mpirun -np $(NUM_PROCS_LOCAL) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) ./dotprod_mpi $(VECLEN_BIG) native $(algo);)

# Random associations (serial)
assoc : assoc_test
	./assoc_test 100000 500

clean :
	$(RM) $(TARGETS) $(TARGET_OBJS) $(OBJECTS) $(HEADERS:=.gch) $(TARGETS)_*.so

# Dependency lists
rand.o :
mpi_op.o : mpi_op.hxx
mpi_pi_reduce.o : rand.hxx
dotprod_mpi.o : rand.hxx assoc.hxx mpi_op.hxx
assoc_test.o: assoc.hxx rand.hxx
