#!/bin/bash
#SBATCH -J HemePure-GH200
#SBATCH -o output_%j.log
#SBATCH -e error_%j.log
#SBATCH -p short
#SBATCH -N 4
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-node=4
#SBATCH --account=r250119
#SBATCH --time=12:00:00
#SBATCH --mem=240G
#SBATCH --constraint=armgpu

cd /home/r250119-u15/lc

# ==================== 【正确模块】不会再报错 ====================
module purge
module load cuda/12.6
module load openmpi/aarch64/4.1.7-cuda   # ✔ 这是你集群真正存在的名字
module load nvhpc/nvhpc/24.11
BASE=/home/r250119-u15/lc/HemePure-GPU
export LD_LIBRARY_PATH=${BASE}/dep/install/lib:$LD_LIBRARY_PATH


# ==================== 【UCX + IB + CUDA Aware】解决死锁核心 ====================
export OMPI_MCA_pml=ucx
export OMPI_MCA_btl=^tcp,vader,openib
export OMPI_MCA_coll=^hcoll
export OMPI_MCA_cuda_aware=1

export UCX_TLS=rc,sm,cuda_copy,cuda_ipc
export UCX_NET_DEVICES=mlx5_0:1
export UCX_CUDA_COPY_MAX_REGION=1G
export UCX_RC_VERBS_RX_QP_LEN=8192
export UCX_RC_VERBS_TX_QP_LEN=8192

# ==================== 【增大共享内存】解决 BTL shared memory 不足 ====================
export OMPI_MCA_btl_sm_max_mem_size=512
export TMPDIR=/tmp

export MPI_CUDA_AWARE=1
export CUDA_VISIBLE_DEVICES=0,1,2,3
export UCX_WARN_UNUSED_ENV_VARS=n
rm -rf /home/r250119-u15/lc/result/run4_pro

# ==================== 【最终运行命令】 ====================
mpirun -np 16 \
--bind-to numa \
--mca mpi_preconnect_mpi 1 \
--mca mpi_cuda_support 1 \
/home/r250119-u15/lc/HemePure-GPU/src/build_PP_Benchmark/hemepure_gpu \
-in /home/r250119-u15/lc/Aneurysm-VIRTUAL/input_PP.xml \
-out /home/r250119-u15/lc/result/run4_pro

