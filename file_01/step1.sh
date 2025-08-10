#!/bin/bash
#SBATCH --job-name=gvcfs_by_chr
#SBATCH --output=gvcfs_by_chr_%A_%a.out
#SBATCH --error=gvcfs_by_chr_%A_%a.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --time=48:00:00
#SBATCH --partition=CU

# 设置环境变量
export JAVA_HOME=/gpfs/hpc/home/chenchao/hanc/share_group_folder/tools/jdk-17
export PATH=$JAVA_HOME/bin:$PATH

# 设置工具路径和参考基因组
GATK_PATH=/gpfs/hpc/home/chenchao/share_group_folder/tools/gatk-4.5.0.0/gatk
REFERENCE=/gpfs/hpc/home/chenchao/share_group_folder/data/genomes/refresh/hg38.fa
TMP_DIR=/gpfs/hpc/home/chenchao/share_group_folder/data/CHFB/process/processing/tmp
OUTPUT_DIR=/gpfs/hpc/home/chenchao/share_group_folder/data/CHFB/process/processing/joint_calling_results

mkdir -p ${OUTPUT_DIR}/log

# 定义染色体数组
CHROMOSOMES=("chr1" "chr2" "chr3" "chr4" "chr5" "chr6" "chr7" "chr8" "chr9" "chr10" "chr11" "chr12" "chr13" "chr14" "chr15" "chr16" "chr17" "chr18" "chr19" "chr20" "chr21" "chr22" "chrX" "chrY")

# 根据 SLURM 任务 ID 获取当前染色体
CHR=${CHROMOSOMES[$SLURM_ARRAY_TASK_ID]}

# 寻找所有 GVCF 文件
GVCF_FILES=$(find /gpfs/hpc/home/chenchao/share_group_folder/data/CHFB/process/processing/sample/ -name "*.g.vcf.gz" | tr '\n' ' ')

# 检查是否找到 GVCF 文件
if [ -z "$GVCF_FILES" ]; then
    echo "Error: No GVCF files found in the specified directory." >&2
    exit 1
fi

# 合并当前染色体的 GVCF 文件
${GATK_PATH} --java-options "-Xmx120G -Djava.io.tmpdir=${TMP_DIR}" CombineGVCFs \
    -R ${REFERENCE} \
    -L ${CHR} \
    $(for file in $GVCF_FILES; do echo "-V ${file} "; done) \
    -O ${OUTPUT_DIR}/combined.${CHR}.g.vcf.gz \
    &> ${OUTPUT_DIR}/log/CombineGVCFs_${CHR}.log

# 检查 CombineGVCFs 是否成功
if [ $? -ne 0 ]; then
    echo "Error: CombineGVCFs failed for ${CHR}. Check the log file for details." >&2
    exit 1
fi

# 索引合并后的 GVCF 文件
${GATK_PATH} --java-options "-Xmx4G -Djava.io.tmpdir=${TMP_DIR}" IndexFeatureFile \
    -I ${OUTPUT_DIR}/combined.${CHR}.g.vcf.gz \
    &> ${OUTPUT_DIR}/log/IndexFeatureFile_${CHR}.log

# 检查 IndexFeatureFile 是否成功
if [ $? -ne 0 ]; then
    echo "Error: IndexFeatureFile failed for ${CHR}. Check the log file for details." >&2
    exit 1
fi

# 输出完成信息
echo "GVCF files for ${CHR} combined and indexed successfully."
