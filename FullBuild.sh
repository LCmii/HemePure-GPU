#!/bin/bash
## Compilation/build script for HEMELB
MODULES(){

source env.sh
export OMPI_CC=gcc
export OMPI_CXX=g++
export CC=mpicc
export CXX=mpicxx
export BASE=$PWD

}

DEPbuild(){
cd dep
rm -rf build
mkdir build
cd build
cmake -DCMAKE_C_COMPILER=${CC} -DCMAKE_CXX_COMPILER=${CXX} ..
make -j  && echo "Done HemeLB Dependencies"

cd ../..
}

SRCbuild_Benchmark(){
cd src
FOLDER=build_PP_Benchmark

rm -rf $FOLDER
mkdir $FOLDER
cd $FOLDER

cmake -DCMAKE_C_COMPILER=mpicc \
-DCMAKE_CXX_COMPILER=mpicxx \
-DCMAKE_CXX_FLAGS="-std=c++11 -g -Wno-narrowing" \
-DCMAKE_EXE_LINKER_FLAGS="-L${BASE}/dep/install/lib -ltirpc" \
-DCMAKE_SHARED_LINKER_FLAGS="-L${BASE}/dep/install/lib -ltirpc" \
-DHEMELB_CUDA_AWARE_MPI=ON \
-DCMAKE_CUDA_ARCHITECTURES="90" \
-DCMAKE_CUDA_FLAGS="-I/opt/mpi/openmpi/aarch64/gnu/4.1.7-cuda/include -I${BASE}/dep/install/include/tirpc" \
-DHEMELB_USE_GMYPLUS=OFF \
-DHEMELB_USE_MPI_WIN=OFF \
-DHEMELB_USE_VELOCITY_WEIGHTS_FILE=OFF \
-DHEMELB_INLET_BOUNDARY=NASHZEROTHORDERPRESSUREIOLET \
-DHEMELB_WALL_INLET_BOUNDARY=NASHZEROTHORDERPRESSURESBB \
-DHEMELB_OUTLET_BOUNDARY=NASHZEROTHORDERPRESSUREIOLET \
-DHEMELB_WALL_OUTLET_BOUNDARY=NASHZEROTHORDERPRESSURESBB ..
make -j && echo "Done HemeLB Source"

cd ../..
}

MODULES
DEPbuild
SRCbuild_Benchmark