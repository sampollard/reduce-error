#!/bin/bash

# First, get nekbone and modify it to work with SimGrid
if [ ! -d "test" ]; then
	wget https://asc.llnl.gov/CORAL-benchmarks/Science/nekbone-2.3.4.tar.gz
	tar -xvf nekbone-2.3.4.tar.gz
	mv -f nekbone-2.3.4/* . && rmdir nekbone-2.3.4
	cp custom/cg.f src
	cp custom/makenek custom/nekpmpi test/example1/
fi

# Build then run lots of experiments
mkdir -p experiments
cd "test/example1/"
make -f ../../custom/exp-Makefile
cd -
