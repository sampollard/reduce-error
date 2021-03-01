# Makefile for running SMPI (simgrid) versions of experiments
ifeq ($(USE_MPI), 0)
$(error "make clean, then rerun with USE_MPI=1 MPICXX=smpicxx make")
endif

ifneq ($(MPICXX), smpicxx)
$(error "make clean, then rerun with USE_MPI=1 MPICXX=smpicxx make")
endif

# 3 Gflops. See notes.md for explanation.
FLOPS = 3000000000f

#LOG_LEVEL = --log=smpi_colls.threshold:debug
LOG_LEVEL = --log=root.thres:critical

VECLEN = 14400
TOPO_DIR = ../topologies
MPI_REDUCE_ALGOS = default ompi mpich mvapich2 impi automatic \
	arrival_pattern_aware binomial flat_tree NTSL scatter_gather ompi_chain \
	ompi_pipeline ompi_binary ompi_in_order_binary ompi_binomial \
	ompi_basic_linear mvapich2_knomial mvapich2_two_level rab
TOPOLOGY_72 = fattree-72 torus-2-4-9

quick :
	smpirun -hostfile $(TOPO_DIR)/hostfile-fattree-16.txt -platform $(TOPO_DIR)/fattree-16.xml -np 16 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) runif[-1,1] fattree-16 auto
	smpirun -hostfile $(TOPO_DIR)/hostfile-fattree-72.txt -platform $(TOPO_DIR)/fattree-72.xml -np 72 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) runif[-1,1] fattree-72 auto
	smpirun -hostfile $(TOPO_DIR)/hostfile-torus-2-4-9.txt -platform $(TOPO_DIR)/torus-2-4-9.xml -np 72 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) runif[-1,1]  torus-2-4-9 auto
	smpirun -hostfile $(TOPO_DIR)/hostfile-torus-2-2-4.txt -platform $(TOPO_DIR)/torus-2-2-4.xml -np 4 --cfg=smpi/host-speed:$(FLOPS) --cfg=smpi/reduce:ompi ./dotprod_mpi $(VECLEN) runif[-1,1] torus-2-2-4 auto

.PHONY : quick sim
sim :
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
differ :
	smpirun -hostfile $(TOPO_DIR)/hostfile-torus-2-4-9.txt -platform $(TOPO_DIR)/torus-2-4-9.xml -np 72 --cfg=smpi/host-speed:3000000000f --cfg=smpi/reduce:mvapich2_knomial --log=root.thres:critical ./dotprod_mpi 720 torus-2-4-9 mvapich2_knomial

