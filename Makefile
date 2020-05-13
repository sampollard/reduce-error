# Makefile for MPI reduction tests
# Make sure to do spack load openmpi

EXTRA_SOURCES = rand.cxx mpi_op.cxx assoc.cxx
HEADERS = rand.hxx mpi_op.hxx assoc.hxx
TARGETS = mpi_pi_reduce dotprod_mpi

# MPI Modular Component Architecture commands
VERBOSITY = coll_base_verbose 0
#VERBOSITY = coll_base_verbose 40

# MPI Flags
NUM_PROCS = 16
#MPICXX ?= mpicxx
MPICXX = smpicxx

VECLEN = 1440

CXXFLAGS += -Wall -g
LDFLAGS += -L/home/users/spollard/.local/lib -Wl,-rpath=/home/users/spollard/.local/lib

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

.PHONY : quick sim test clean
quick : $(TARGETS)
	smpirun -hostfile topologies/hostfile-16.txt -platform topologies/torus-2-2-4.xml -np 16 --cfg=smpi/host-speed:20000000 --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN)
	smpirun -hostfile topologies/hostfile-16.txt -platform topologies/fattree-16.xml -np 16 --cfg=smpi/host-speed:20000000 --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN)
	smpirun -hostfile topologies/hostfile-72.txt -platform topologies/fattree-72.xml -np 72 --cfg=smpi/host-speed:20000000 --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN)
	smpirun -hostfile topologies/hostfile-72.txt -platform topologies/torus-2-4-9.xml -np 72 --cfg=smpi/host-speed:20000000 --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN)

sim : $(TARGETS)
	$(foreach algo,$(MPI_REDUCE_ALGOS), \
		smpirun -hostfile topologies/hostfile-$(NUM_PROCS).txt -platform topologies/fattree-$(NUM_PROCS).xml -np $(NUM_PROCS) \
			--cfg=smpi/host-speed:20000000 \
			--cfg=smpi/reduce:$(algo) \
			--log=smpi_colls.threshold:debug \
			./dotprod_mpi $(VECLEN);)

test : $(TARGETS)
	$(foreach algo,$(ALGOS),\
		echo Reduction algorithm $(algo) ; \
		mpirun -np $(NUM_PROCS) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) mpi_pi_reduce;)
	$(foreach algo,$(ALGOS),\
		echo Reduction algorithm $(algo) ; \
		mpirun -np $(NUM_PROCS) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) dotprod_mpi $(VECLEN);)


clean :
	$(RM) $(TARGETS) $(TARGET_OBJS) $(OBJECTS) $(HEADERS:=.gch)

# Dependency lists
mpi_pi_reduce.o : rand.hxx
dotprod_mpi.o : rand.hxx assoc.hxx mpi_op.hxx
rand.o : rand.hxx
mpi_op.o : mpi_op.hxx
rand.o : rand.hxx
assoc.hxx: assoc.cxx
