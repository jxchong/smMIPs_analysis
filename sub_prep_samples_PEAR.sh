#$ -S /bin/bash
##$ -V
##$ -m eas
#$ -cwd
#$ -q new.q
##$ -l mem_requested=14G

#$ -o logs_queue/prep_samples
#$ -e logs_queue/prep_samples

#$ -N smMIP_prep_samples

# arguments should be:
# $1 = sample ID key text file for all samples, tab-delimited
	# sampleIDkey format: 
	# 1st column: numeric ID (1 through x)
	# 2nd column: sample name
	# additional columns don't matter
# $2 = MIP design file




# NOTE: if MIPGEN/tools was built on a different system/using a different version of Python, may need to run this once:
## python setup.py build_ext --inplace

# location of Pediatrics analysis pipeline bin
pipelinebin='/labdata6/allabs/mips/pipeline_smMIPS_v1.0/smMIPs_analysis'
# location of MIPGEN/tools script directory
mipgentoolsbin='/labdata6/allabs/mips/pipeline_smMIPS_v1.0/MIPGEN/tools'
# location of executables
executbin='/labdata6/allabs/mips/pipeline_smMIPS_v1.0/executables'
# directory to reference files (reference genome fasta and various indexes)
refdir='/labdata6/allabs/mips/references/b37/BWA0.7.8'


################### only necessary if using modules environment #######################
source /cm/local/apps/environment-modules/3.2.10/Modules/3.2.10/init/bash
module load shared Tools/common dos2unix/6.0.5 plink/1.07 sge pear/0.9.0 BWA/0.7.8
#######################################################################################
export PYTHONPATH=/labdata6/allabs/mips/pipeline_smMIPS_v1.0/MIPGEN/tools/
#######################################################################################

set -e
set -o pipefail

SAMPLENUM=$(awk -v linenum=$SGE_TASK_ID 'NR==linenum { print $1; exit }' $1)
SAMPLENAME=$(awk -v linenum=$SGE_TASK_ID 'NR==linenum { print $2; exit }' $1)


NOW=$(date +"%c")
if (( $SGE_TASK_ID == 1 )); then
	printf "Running step 1, smMIP_prep_samples job: $NOW\n" >> $2.smMIPspipeline.log.txt
fi


printf "Unzipping fastqs for sample ${SAMPLENAME} (sample # ${SAMPLENUM}) for combining with PEAR\n"
zcat "${SAMPLENAME}_S${SAMPLENUM}_L001_R1_001.fastq.gz" > "${SAMPLENAME}_S${SAMPLENUM}.R1.fastq"
zcat "${SAMPLENAME}_S${SAMPLENUM}_L001_R2_001.fastq.gz" > "${SAMPLENAME}_S${SAMPLENUM}.R2.fastq"


printf "Combining paired-end reads with PEAR and removing unzipped fastqs\n"
pear -f "${SAMPLENAME}_S${SAMPLENUM}.R1.fastq" -r "${SAMPLENAME}_S${SAMPLENUM}.R2.fastq" -o ${SAMPLENAME}
rm "${SAMPLENAME}_S${SAMPLENUM}.R1.fastq"
rm "${SAMPLENAME}_S${SAMPLENUM}.R2.fastq"
printf "done\n"


printf "Running mipgen_fq_cutter_se.py to cut out molecular tags\n"
python $mipgentoolsbin/mipgen_fq_cutter_se.py ${SAMPLENAME}.assembled.fastq -m 0,5 -o ${SAMPLENAME}
printf "done\n"


printf "Aligning with BWA\n"
$executbin/bwa mem -R "@RG\tID:${SAMPLENAME}_RG\tSM:${SAMPLENAME}" $refdir/Homo_sapiens_assembly19.fasta ${SAMPLENAME}.indexed.fq > ${SAMPLENAME}.indexed.sam
printf "done\n"


printf "Sorting aligned sam file\n"
$executbin/samtools view -bS ${SAMPLENAME}.indexed.sam | $executbin/samtools sort - ${SAMPLENAME}.indexed.sort
printf "done\n"


printf "Collapsing unique capture events\n"
$executbin/samtools view -h ${SAMPLENAME}.indexed.sort.bam | python $mipgentoolsbin/mipgen_smmip_collapser.py 5 ${SAMPLENAME}.indexed.sort.collapse -m $2 -f 1 -s
printf "done\n"


printf "Making sorted bam of unique capture events\n"
$executbin/samtools view -bS ${SAMPLENAME}.indexed.sort.collapse.all_reads.unique.sam | $executbin/samtools sort - ${SAMPLENAME}.indexed.sort.collapse.all_reads.unique.sort
printf "done\n"


printf "Indexing sorted bam of unique capture events\n"
$executbin/samtools index ${SAMPLENAME}.indexed.sort.collapse.all_reads.unique.sort.bam
printf "done\n"


printf "Recalculating the MD and NM values in the bam of unique capture events and indexing resulting bam\n"
$executbin/samtools calmd ${SAMPLENAME}.indexed.sort.collapse.all_reads.unique.sort.bam $refdir/Homo_sapiens_assembly19.fasta | samtools view -Sb - > ${SAMPLENAME}.indexed.sort.collapse.all_reads.unique.sort.calmd.bam
$executbin/samtools index ${SAMPLENAME}.indexed.sort.collapse.all_reads.unique.sort.calmd.bam
printf "done\n"


printf "Editing complexity and samplewise-summary files to change sample name column from N to ${SAMPLENAME}\n"
sed -i "s/^N\t/${SAMPLENAME}\t/" ${SAMPLENAME}.indexed.sort.collapse.complexity.txt
sed -i "s/^ALL_SAMPLES\t/${SAMPLENAME}\t/" ${SAMPLENAME}.indexed.sort.collapse.samplewise_summary.txt
printf "done\n"


printf "Moving all files for ${SAMPLENAME} into separate folder\n"
mkdir ${SAMPLENAME}
mv ${SAMPLENAME}.* ${SAMPLENAME}/.
printf "done\n"

