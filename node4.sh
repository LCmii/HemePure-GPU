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

# ==================== 【性能分析配置】 ====================
# 性能分析输出目录
PROFILE_DIR=/home/r250119-u15/lc/profile_output
mkdir -p $PROFILE_DIR

# 性能分析文件名（带时间戳避免覆盖）
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PROFILE_NAME=hemepure_profile_${TIMESTAMP}

# ==================== 【最终运行命令】 ====================
# 使用 nsys 进行性能分析
# 追踪: CUDA API, NVTX(用于代码标注), OSRT(系统运行时), MPI
# GPU指标: 收集所有GPU的指标
nsys profile \
  -o $PROFILE_DIR/$PROFILE_NAME \
  --trace=cuda,nvtx,osrt,mpi \
  --gpu-metrics-device=all \
  --sample=cpu \
  --cpu-arch-arm=yes \
  --force-overwrite true \
  --wait=all \
  --stop-on-range-end=true \
  mpirun -np 16 \
  --bind-to numa \
  --mca mpi_preconnect_mpi 1 \
  --mca mpi_cuda_support 1 \
  /home/r250119-u15/lc/HemePure-GPU/src/build_PP_Benchmark/hemepure_gpu \
  -in /home/r250119-u15/lc/Aneurysm-VIRTUAL/input_PP.xml \
  -out /home/r250119-u15/lc/result/run4_pro

echo "性能分析完成！"
echo "输出文件: $PROFILE_DIR/${PROFILE_NAME}.qdrep"
echo ""
echo "===== 分析报告 ====="
echo "请运行以下命令查看性能报告:"
echo ""
echo "1. 命令行统计 (推荐先运行这个):"
echo "   nsys stats $PROFILE_DIR/${PROFILE_NAME}.qdrep"
echo ""
echo "2. 或使用 NVIDIA Nsight Systems GUI 打开:"
echo "   nsys-ui $PROFILE_DIR/${PROFILE_NAME}.qdrep"
echo ""
echo "3. 查看 GPU 利用率详情:"
echo "   nsys stats $PROFILE_DIR/${PROFILE_NAME}.qdrep --report gputrace"
echo ""
echo "4. 查看 MPI 通信统计:"
echo "   nsys stats $PROFILE_DIR/${PROFILE_NAME}.qdrep --report mpitrace"

