#$ -S /bin/bash
#$ -V
#$ -m eas
#$ -cwd
#$ -q old.q
##$ -l mem_requested=4G

#$ -o logs_queue/DOCperMIP
#$ -e logs_queue/DOCperMIP

#$ -N summaryMIPs
#$ -hold_jid prep_samples

# arguments should be:
# 1 = project name

headref='/labdata6/allabs/mips/references'
noderef='/labdata6/allabs/mips/references'
headbin='/labdata6/allabs/mips/pipeline_v0.1'
nodebin='/labdata6/allabs/mips/pipeline_v0.1'

INTERVAL=$(awk -v linenum=$SGE_TASK_ID 'NR==linenum { print $1; exit }' MIPtargets112bp.GATKDepthOfCoverage.intervals)


set -e
set -o pipefail


NOW=$(date +"%c")
if (( $SGE_TASK_ID == 1 )); then
	printf "Running step 6b, summary MIPs job: $NOW\n" >> $1.MIPspipeline.log.txt
fi


# It turns out to be not possible to have DepthofCoverage report for individual intervals if the intervals overlap (multiple threads on GATK forums)
# GATK automatically merges any intervals that overlap, but MIP target regions definitely overlap and we want to get DOC by MIP target
# Therefore we need to run GATK DOC once for each interval and the merge the results.  On the bright side, this is parallelizable!


# Run GATK Depth of Coverage for a single interval
printf "Running GATK Depth of Coverage and creating summary.$1.DepthOfCoverage.MIPtargets112.$SGE_TASK_ID ..."

java -Xmx4g -jar $nodebin/executables/GenomeAnalysisTK.jar \
-T DepthOfCoverage \
-R $noderef/b37/Homo_sapiens_assembly19.fasta \
-I bam.realigned.list \
-o DOCperMIP/summary.$1.DepthOfCoverage.MIPtargets112bp.$SGE_TASK_ID \
-L $INTERVAL \
-omitBaseOutput \
-omitLocusTable \
-rf BadCigar \
-dt NONE \
-ct 8 \
-ct 25 \
-ct 50 \
-ct 100 \
	
printf "done\n"


