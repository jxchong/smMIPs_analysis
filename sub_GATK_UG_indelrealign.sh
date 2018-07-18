#$ -S /bin/bash
#$ -V
#$ -m es
#$ -cwd
#$ -q new.q
##$ -l mem_requested=8G

#$ -o logs_queue/UnifiedGenotyper
#$ -e logs_queue/UnifiedGenotyper

#$ -N indel_realign
#$ -hold_jid smMIP_prep_samples


# arguments should be:
# 1 = file containing prefixes for all samples
# 2 = project name

# arguments should be:
# $1 = sample ID key text file for all samples
	# sampleIDkey format:
	# 1st column: numeric ID (1 through x)
	# 2nd column: sample name
	# 3rd column optional
# $2 = project name
# $3 = MIP bed file


# location of Pediatrics analysis pipeline bin
pipelinebin='/labdata6/allabs/mips/pipeline_smMIPS_v1.1/smMIPs_analysis'
# location of MIPGEN/tools script directory
mipgentoolsbin='/labdata6/allabs/mips/pipeline_smMIPS_v1.1/MIPGEN/tools'
# location of executables
executbin='/labdata6/allabs/mips/pipeline_smMIPS_v1.1/executables'
# directory to reference files (reference genome fasta and various indexes)
refdir='/labdata6/allabs/mips/references/b37/BWA0.7.8'

################### only necessary if using modules environment #######################
.  /cm/local/apps/environment-modules/3.2.10/Modules/3.2.10/init/bash
module load shared Tools/common dos2unix/6.0.5 sge java/1.7.0_55 python/2.7.6 conda/4.5.0
#######################################################################################
export PYTHONPATH=/labdata6/allabs/mips/pipeline_smMIPS_v1.1/MIPGEN/tools/
#######################################################################################


set -e
set -o pipefail

NOW=$(date +"%c")
if (( $SGE_TASK_ID == 1 )); then
	printf "Running step 3b, indel realignment: $NOW\n" >> $2.smMIPspipeline.log.txt
fi

SAMPLENUM=$(awk -v linenum=$SGE_TASK_ID 'NR==linenum { print $1; exit }' $1)
SAMPLENAME=$(awk -v linenum=$SGE_TASK_ID 'NR==linenum { print $2; exit }' $1)

THISSCRIPT=$(basename $0)
NODENAME=$(hostname)
printf "Running $0 on sample $SAMPLENAME on cluster node $NODENAME\n"


# create target for indel realignment
printf "Create indel realignment interval file for ${SAMPLENAME}..."
java -d64 -Xmx88g \
-jar $executbin/GenomeAnalysisTK.jar \
-T RealignerTargetCreator \
-R $refdir/Homo_sapiens_assembly19.fasta \
-rf BadCigar \
-allowPotentiallyMisencodedQuals \
-L MIPtargets.intervals \
-I ${SAMPLENAME}/${SAMPLENAME}.indexed.sort.collapse.all_reads.unique.sort.calmd.bam \
-o ${SAMPLENAME}/${SAMPLENAME}.indexed.sort.collapse.all_reads.unique.sort.calmd.IndelRealigner.intervals \
-dcov 5000 \
-dt NONE \
-l INFO \
-nt 16
printf "done\n"


# do indel realignment
printf "Do indel realignment for ${SAMPLENAME}..."
java -d64 -Xmx80g -jar $executbin/GenomeAnalysisTK.jar \
-T IndelRealigner \
-L MIPtargets.intervals \
-R $refdir/Homo_sapiens_assembly19.fasta \
-rf BadCigar \
-allowPotentiallyMisencodedQuals \
-I ${SAMPLENAME}/${SAMPLENAME}.indexed.sort.collapse.all_reads.unique.sort.calmd.bam \
-targetIntervals ${SAMPLENAME}/${SAMPLENAME}.indexed.sort.collapse.all_reads.unique.sort.calmd.IndelRealigner.intervals \
-dcov 5000 \
-dt NONE \
-o ${SAMPLENAME}/${SAMPLENAME}.realigned.bam
printf "done\n"
