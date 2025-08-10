#!/bin/bash
#SBATCH --job-name=merge_chr_vcf
#SBATCH --output=merge_%j.out
#SBATCH --error=merge_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=10:00:00
#SBATCH --partition=CU

cd /gpfs/hpc/home/chenchao/share_group_folder/data/CHFB/process/processing/joint_calling_results

# 1. 生成染色体VCF列表
echo joint_genotyped.chr{1..22}.vcf.gz joint_genotyped.chrX.vcf.gz joint_genotyped.chrY.vcf.gz | tr ' ' '\n' > vcf_list.txt

# 2. 确保每个VCF都有索引
for f in $(cat vcf_list.txt); do
  [ -f ${f}.tbi ] || bcftools index $f
done

# 3. 合并为全基因组VCF
bcftools concat -Oz -o final.joint.vcf.gz -f vcf_list.txt

# 4. 生成索引
bcftools index final.joint.vcf.gz

echo "VCF合并完成，结果为 final.joint.vcf.gz"
