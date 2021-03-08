# Makefile for OpenMPI experiments

VECLEN_BIG = 72000000

ifeq ($(USE_MPI), 0)
$(error "make clean, then rerun with USE_MPI=1 MPICXX=mpicxx make")
endif
ifndef ($(MPICXX))
$(error "make clean, then rerun with USE_MPI=1 MPICXX=mpicxx make")
endif

# For running on the host MPI (i.e. not Simgrid)
NUM_PROCS_LOCAL = 16

# MPI and MPI Modular Component Architecture commands (OpenMPI). Currently Unused
VERBOSITY = coll_base_verbose 0
#VERBOSITY = coll_base_verbose 40

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

# OpenMPI command line arguments
ompi :
	$(foreach algo,$(OMPI_ALGOS),\
		echo Reduction algorithm $(algo) ; \
		mpirun -np $(NUM_PROCS_LOCAL) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) ./mpi_pi_reduce;)
	$(foreach algo,$(OMPI_ALGOS),\
		mpirun -np $(NUM_PROCS_LOCAL) --mca $(VERBOSITY) --mca coll_tuned_reduce_algorithm $(algo) ./dotprod_mpi $(VECLEN_BIG) runif[-1,1] native $(algo);)

