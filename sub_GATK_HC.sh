#$ -S /bin/bash
##$ -V
##$ -m eas
#$ -cwd
#$ -q new.q
##$ -l mem_requested=8G

#$ -o logs_queue
#$ -e logs_queue

#$ -N GATK_HC
#$ -hold_jid calccomplexity

# arguments should be:
# $1 = sample ID key text file for all samples
	# sampleIDkey format: 
	# 1st column: numeric ID (1 through x)
	# 2nd column: sample name
	# 3rd column optional
# $2 = project name
# $3 = MIP bed file
# $4 = your email address
# $5 = MIP design file

# location of Pediatrics analysis pipeline bin
pipelinebin='/labdata6/allabs/mips/pipeline_smMIPS_v1.0'
# location of MIPGEN/tools script directory
mipgentoolsbin='/labdata6/allabs/mips/pipeline_smMIPS_v1.0/MIPGEN/tools'
# location of executables
executbin='/labdata6/allabs/mips/pipeline_smMIPS_v1.0/executables'
# directory to reference files (reference genome fasta and various indexes)
refdir='/labdata6/allabs/mips/references/b37/BWA0.7.8'





################### only necessary if using modules environment #######################
source /cm/local/apps/environment-modules/3.2.10/Modules/3.2.10/init/bash
module load shared Tools/common dos2unix/6.0.5 sge java/1.7.0_55
#######################################################################################
export PYTHONPATH=/labdata6/allabs/mips/pipeline_smMIPS_v1.0/MIPGEN/tools/
#######################################################################################


set -e
set -o pipefail



printf "Multisample calling with HaplotypeCaller\n"
java -jar $executbin/GenomeAnalysisTK.jar \
-T HaplotypeCaller \
-R $refdir/Homo_sapiens_assembly19.fasta \
-L $3 \
-I bam.list \
--filter_bases_not_stored \
-rf BadCigar \
-allowPotentiallyMisencodedQuals \
-o multisample_calls/$2.HC.multisample.vcf
printf "done\n"


printf "Submitting multisample vcf to SeattleSeq138\n"
# this will put SeattleSeq annotations in separate tab-delimited file
java -Xmx4g -jar $executbin/getAnnotationSeattleSeq138.031014.jar \
-i multisample_calls/$2.HC.multisample.vcf \
-o multisample_calls/$2.HC.multisample.SS138.tsv \
-m $4
printf "done\n"


printf "Submitting multisample vcf to VEP\n"
# this will insert VEP annotations into the vcf file for later importing into Gemini
### you can also easily use vcftools or bcftools to parse this out into a tab-delimited format, e.g.
### ~/bin/bcftools query -H --f '%CHROM\t%POS\t%REF\t%ALT\t%TYPE\t%ID\t%FILTER\t%INFO/VEPNAME[\t%TGT]\n'
# java -Xmx4g -jar $executbin/getAnnotationSeattleSeq138.031014.jar \
# -i multisample_calls/$2.HC.multisample.vcf \
# -o multisample_calls/$2.HC.multisample.SS138.tsv \
# -m $4
printf "done\n"


# clean up all the original fastq.gz files
printf "Making raw_combined_reads directory and cleaning up files..."
bash -c '[ -d raw_data ] || mkdir raw_data' 
bash -c '[ -d raw_data ] && mv *fastq.gz raw_data/.'
printf "done\n"


# make a bgzip compressed version of the vcfs
$executbin/bgzip -c multisample_calls/$2.HC.multisample.vcf > multisample_calls/$2.HC.multisample.vcf.gz
$executbin/tabix -p vcf multisample_calls/$2.HC.multisample.vcf.gz

