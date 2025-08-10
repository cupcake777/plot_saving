#!/bin/bash
#SBATCH --job-name=joint_chr
#SBATCH --output=joint_chr_%A_%a.out
#SBATCH --error=joint_chr_%A_%a.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --time=48:00:00
#SBATCH --partition=CU

export JAVA_HOME=/gpfs/hpc/home/chenchao/share_group_folder/tools/jdk-17
export PATH=$JAVA_HOME/bin:$PATH

GATK_PATH=/gpfs/hpc/home/chenchao/share_group_folder/tools/gatk-4.5.0.0/gatk
REFERENCE=/gpfs/hpc/home/chenchao/share_group_folder/data/genomes/refresh/hg38.fa
TMP_DIR=/gpfs/hpc/home/chenchao/share_group_folder/data/CHFB/process/processing/tmp
OUTPUT_DIR=/gpfs/hpc/home/chenchao/share_group_folder/data/CHFB/process/processing/joint_calling_results

CHROMOSOMES=("chr1" "chr2" "chr3" "chr4" "chr5" "chr6" "chr7" "chr8" "chr9" "chr10" "chr11" "chr12" "chr13" "chr14" "chr15" "chr16" "chr17" "chr18" "chr19" "chr20" "chr21" "chr22" "chrX" "chrY")
CHR=${CHROMOSOMES[$SLURM_ARRAY_TASK_ID]}

${GATK_PATH} --java-options "-Xmx120G -Djava.io.tmpdir=${TMP_DIR}" GenotypeGVCFs \
  -R ${REFERENCE} \
  -V ${OUTPUT_DIR}/combined.${CHR}.g.vcf.gz \
  -O ${OUTPUT_DIR}/joint_genotyped.${CHR}.vcf.gz \
  &> ${OUTPUT_DIR}/log/GenotypeGVCFs_${CHR}.log

if [ $? -ne 0 ]; then
    echo "Error: GenotypeGVCFs failed for ${CHR}. Check the log file for details." >&2
    exit 1
else
    rm -f ${OUTPUT_DIR}/combined.${CHR}.g.vcf.gz
    rm -f ${OUTPUT_DIR}/combined.${CHR}.g.vcf.gz.tbi
    echo "Intermediate files for ${CHR} deleted."
fi

echo "Joint genotyping for ${CHR} finished successfully."

