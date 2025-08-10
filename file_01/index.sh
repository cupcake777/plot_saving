#!/bin/bash
#SBATCH --job-name=index_gvcfs
#SBATCH --output=index_gvcfs.out
#SBATCH --error=index_gvcfs.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=15
#SBATCH --mem=64G
#SBATCH --time=36:00:00
#SBATCH --partition=CU

# Set environment variables
export JAVA_HOME=/gpfs/hpc/home/chenchao/hanc/share_group_folder/tools/jdk-17
export PATH=$JAVA_HOME/bin:$PATH

# Set GATK path
GATK_PATH=/gpfs/hpc/home/chenchao/hanc/share_group_folder/tools/gatk-4.5.0.0/gatk

# Directory containing GVCF files
GVCF_DIR=/gpfs/hpc/home/chenchao/hanc/share_group_folder/data/CHFB/process/processing/sample

# Generate index for each GVCF file
for file in "${GVCF_DIR}"/*.g.vcf.gz; do
    if [[ ! -f "${file}.tbi" ]]; then
        echo "Indexing ${file}..."
        ${GATK_PATH} --java-options "-Xmx4G" IndexFeatureFile -I "${file}"
        if [[ $? -ne 0 ]]; then
            echo "Error indexing ${file}" >> index_errors.log
        fi
    else
        echo "Index already exists for ${file}"
    fi
done

echo "Indexing completed."
