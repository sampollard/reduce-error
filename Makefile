# Makefile for MPI reduction tests
# Make sure to do spack load spack load openmpi@4.0.3

EXTRA_SOURCES = rand.cxx mpi_op.cxx assoc.cxx
HEADERS = rand.hxx mpi_op.hxx assoc.hxx
TARGETS = mpi_pi_reduce dotprod_mpi

MPICXX = smpicxx
#MPICXX = mpicxx
# MPI Modular Component Architecture commands (OpenMPI)
VERBOSITY = coll_base_verbose 0
#VERBOSITY = coll_base_verbose 40


# MPI Flags
NUM_PROCS = 16
VECLEN = 14400
VECLEN_BIG = 72000000

# SimGrid options
#LOG_LEVEL = --log=smpi_colls.threshold:debug
LOG_LEVEL = --log=root.thres:critical
# 3 Gflops. See notes.md for explanation.
FLOPS = 3000000000
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
	$(MPICXX) $(CXXFLAGS) $(LDFLAGS) -c $^

mpi_pi_reduce: mpi_pi_reduce.o rand.o
	$(MPICXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^

dotprod_mpi : $(OBJECTS) rand.o mpi_op.o dotprod_mpi.o assoc.hxx
	$(MPICXX) $(CXXFLAGS) $(LDFLAGS) -o $@ $^

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

.PHONY : quick sim ompi clean differ
quick : $(TARGETS)
	smpirun -hostfile topologies/hostfile-fattree-16.txt -platform topologies/torus-2-2-4.xml -np 16 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) torus-2-2-4 auto
	smpirun -hostfile topologies/hostfile-fattree-16.txt -platform topologies/fattree-16.xml -np 16 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) fattree-16 auto
	smpirun -hostfile topologies/hostfile-fattree-72.txt -platform topologies/fattree-72.xml -np 72 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) fattree-72 auto
	smpirun -hostfile topologies/hostfile-fattree-72.txt -platform topologies/torus-2-4-9.xml -np 72 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) torus-2-4-9 auto

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
	smpirun -hostfile topologies/hostfile-torus-2-4-9.txt -platform topologies/torus-2-4-9.xml -np 72 --cfg=smpi/host-speed:3000000000 --cfg=smpi/reduce:mvapich2_knomial --log=root.thres:critical ./dotprod_mpi 720 torus-2-4-9 mvapich2_knomial

# OpenMPI command line arguments
ompi: $(TARGETS)
	$(foreach algo,$(OMPI_ALGOS),\
		echo Reduction algorithm $(algo) ; \
		mpirun -np $(NUM_PROCS) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) ./mpi_pi_reduce;)
	$(foreach algo,$(OMPI_ALGOS),\
		mpirun -np $(NUM_PROCS) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) ./dotprod_mpi $(VECLEN_BIG) $(algo);)

clean :
	$(RM) $(TARGETS) $(TARGET_OBJS) $(OBJECTS) $(HEADERS:=.gch)

# Dependency lists
mpi_pi_reduce.o : rand.hxx
dotprod_mpi.o : rand.hxx assoc.hxx mpi_op.hxx
rand.o : rand.hxx
mpi_op.o : mpi_op.hxx
rand.o : rand.hxx
assoc.hxx: assoc.cxx
