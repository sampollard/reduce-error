#!/bin/bash

# First, get
wget https://asc.llnl.gov/CORAL-benchmarks/Science/nekbone-2.3.4.tar.gz
tar -xvf nekbone-2.3.4.tar.gz
cd ..
patch -s -p0 < nek.patch
cd -
mv nekbone-2.3.4/* . && rmdir nekbone-2.3.4
