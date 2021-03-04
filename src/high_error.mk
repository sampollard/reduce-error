
ifeq ($(USE_MPI), 1)
$(error "make clean, then rerun with USE_MPI=0 make high_error")
endif

.PHONY : subn_dot all

all : subn_dot

subn_dot :
	./calc_bounds
