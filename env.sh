export OMPI_CC=gcc
export OMPI_CXX=g++
export CC=mpicc
export CXX=mpicxx
export BASE=$PWD
module load nvhpc/nvhpc/24.11
module load cuda/12.6
module load openmpi/aarch64/4.1.7-cuda
