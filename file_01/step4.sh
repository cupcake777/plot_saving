#!/bin/bash
#SBATCH --job-name=vqsr
#SBATCH --output=vqsr_%j.out
#SBATCH --error=vqsr_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --time=72:00:00
#SBATCH --partition=CU

source /gpfs/hpc/home/chenchao/liyc/bin/miniconda3/etc/profile.d/conda.sh
conda activate gatk_vqsr

set -euo pipefail

export JAVA_HOME=/gpfs/hpc/home/chenchao/share_group_folder/tools/jdk-17
export PATH=$JAVA_HOME/bin:$PATH

GATK_PATH=/gpfs/hpc/home/chenchao/share_group_folder/tools/gatk-4.5.0.0/gatk
REFERENCE=/gpfs/hpc/home/chenchao/share_group_folder/data/genomes/refresh/hg38.fa
DATA_DIR=/gpfs/hpc/home/chenchao/share_group_folder/data/CHFB/process/processing/joint_calling_results
OUTPUT_DIR=/gpfs/hpc/home/chenchao/share_group_folder/data/CHFB/process/processing/VQSR
TMP_DIR=/gpfs/hpc/home/chenchao/share_group_folder/data/CHFB/process/processing/tmp

HAPMAP=/gpfs/hpc/home/chenchao/share_group_folder/data/genomes/refresh/hapmap_3.3.hg38.vcf.gz
OMNI=/gpfs/hpc/home/chenchao/share_group_folder/data/genomes/refresh/1000G_omni2.5.hg38.vcf.gz
PHASE1_1000G=/gpfs/hpc/home/chenchao/share_group_folder/data/genomes/refresh/1000G_phase1.snps.high_confidence.hg38.vcf.gz
DBSNP=/gpfs/hpc/home/chenchao/share_group_folder/data/genomes/refresh/Homo_sapiens_assembly38.dbsnp138.vcf.gz
MILLS=/gpfs/hpc/home/chenchao/share_group_folder/data/genomes/refresh/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz

mkdir -p "${TMP_DIR}" "${OUTPUT_DIR}"

# 1. SNP VQSR
${GATK_PATH} --java-options "-Xmx60G -Djava.io.tmpdir=${TMP_DIR}" VariantRecalibrator \
    -R ${REFERENCE} \
    -V ${DATA_DIR}/raw.all.chr.vcf.gz \
    --resource:hapmap,known=false,training=true,truth=true,prior=15.0 ${HAPMAP} \
    --resource:omni,known=false,training=true,truth=false,prior=12.0 ${OMNI} \
    --resource:1000G,known=false,training=true,truth=false,prior=10.0 ${PHASE1_1000G} \
    --resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ${DBSNP} \
    -an QD -an MQRankSum -an ReadPosRankSum -an FS -an SOR -an DP \
    -mode SNP \
    -O ${OUTPUT_DIR}/recal_SNP.recal \
    --tranches-file ${OUTPUT_DIR}/recal_SNP.tranches \
    --rscript-file ${OUTPUT_DIR}/recal_SNP_plots.R \
    --tranche 90.0 --tranche 93.0 --tranche 95.0 --tranche 97.0 --tranche 99.0 --tranche 99.9 --tranche 100.0

if [ -f "${OUTPUT_DIR}/recal_SNP_plots.R" ]; then
    sed -i 's/space = "rgb"/space = "Lab"/g' "${OUTPUT_DIR}/recal_SNP_plots.R"
    set +e
    Rscript "${OUTPUT_DIR}/recal_SNP_plots.R"
    set -e
fi

# 2. SNP ApplyVQSR
${GATK_PATH} --java-options "-Xmx60G -Djava.io.tmpdir=${TMP_DIR}" ApplyVQSR \
    -R ${REFERENCE} \
    -V ${DATA_DIR}/raw.all.chr.vcf.gz \
    -mode SNP \
    --recal-file ${OUTPUT_DIR}/recal_SNP.recal \
    --tranches-file ${OUTPUT_DIR}/recal_SNP.tranches \
    -O ${OUTPUT_DIR}/recal_snp.vcf.gz

# 3. INDEL VQSR
${GATK_PATH} --java-options "-Xmx60G -Djava.io.tmpdir=${TMP_DIR}" VariantRecalibrator \
    -R ${REFERENCE} \
    -V ${OUTPUT_DIR}/recal_snp.vcf.gz \
    --resource:mills,known=false,training=true,truth=true,prior=12.0 ${MILLS} \
    --resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ${DBSNP} \
    -an QD -an MQRankSum -an ReadPosRankSum -an FS -an SOR -an DP \
    -mode INDEL \
    --max-gaussians 4 \
    -O ${OUTPUT_DIR}/recal_INDEL.recal \
    --tranches-file ${OUTPUT_DIR}/recal_INDEL.tranches \
    --rscript-file ${OUTPUT_DIR}/recal_INDEL_plots.R \
    --tranche 90.0 --tranche 93.0 --tranche 95.0 --tranche 97.0 --tranche 99.0 --tranche 99.9 --tranche 100.0

if [ -f "${OUTPUT_DIR}/recal_INDEL_plots.R" ]; then
    sed -i 's/space = "rgb"/space = "Lab"/g' "${OUTPUT_DIR}/recal_INDEL_plots.R"
    set +e
    Rscript "${OUTPUT_DIR}/recal_INDEL_plots.R"
    set -e
fi

# 4. INDEL ApplyVQSR
${GATK_PATH} --java-options "-Xmx60G -Djava.io.tmpdir=${TMP_DIR}" ApplyVQSR \
    -R ${REFERENCE} \
    -V ${OUTPUT_DIR}/recal_snp.vcf.gz \
    -mode INDEL \
    --recal-file ${OUTPUT_DIR}/recal_INDEL.recal \
    --tranches-file ${OUTPUT_DIR}/recal_INDEL.tranches \
    -O ${OUTPUT_DIR}/vqsr.vcf.gz

echo "VQSR completed successfully."
