#!/bin/bash
if [ ! command -v smpirun ]; then
	echo "No simgrid found on PATH please install at"
	echo "http://simgrid.gforge.inria.fr/simgrid/3.20/doc/install.html"
	exit 2
fi
ROOT_DIR=$(pwd)

# Spack stuff
# Run this on artemis to ensure all the packages are loaded correctly
# Install these however you want. Gcc version shouldn't matter.
spack load openmpi%gcc@7.4.0
spack load netlib-scalapack%gcc@7.4.0
spack load eigen%gcc@7.4.0

# ELPA
# spack load elpa%gcc@7.4.0 # Installing elpa errored out for me
# If you want vectorization, do
export CFLAGS="-march=skylake-avx512"
# ELPA 2020 isn't supported with eigenvector
# ELPA=elpa-2020.05.001.rc1
ELPA=elpa-2018.05.001
ELPA_DATE=${ELPA#elpa-}
ELPA_VERSION=${ELPA_DATE//./}
# From https://elpa.mpcdf.mpg.de/elpa-tar-archive
# https://elpa.mpcdf.mpg.de/html/Releases/2018.05.001/elpa-2018.05.001.tar.gz
wget https://elpa.mpcdf.mpg.de/html/Releases/$ELPA_DATE/$ELPA.tar.gz
# Configure elpa without vectorization (more portable):
# ./configure --disable-avx --disable-sse --disable-avx2 --disable-avx512
tar -xvf "$ELPA".tar.gz
cd "$ELPA"
./configure --disable-openmp
make
cd ..

# Get eigenkernel. Currently still bugged.
git clone git@github.com:eigenkernel/eigenkernel.git
cd eigenkernel
sed -e "s/mpif90/smpif90/g" \
    -e "s/WITH_EIGENEXA=1/WITH_EIGENEXA=0/g" \
    -e "s?FFLAGS =.*?FFLAGS = -g -O2 -Wall -fopenmp -I$ROOT_DIR/$ELPA/modules -I$ROOT_DIR/$ELPA?g" \
    -e 's?-L$(HOME)/lib/?-L'$ROOT_DIR/$ELPA?g \
    -e "s?LIBS = .*?LIBS = -L$ROOT_DIR/$ELPA/modules -lscalapack -llapack -lblas -lgomp?g" \
	-e "6 i ELPA_VERSION = $ELPA_VERSION" \
    Makefile.inc.gfortran.withext > Makefile.inc
make

