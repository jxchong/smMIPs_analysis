#$ -S /bin/bash
#$ -V
#$ -m eas
#$ -cwd
#$ -q old.q
##$ -l mem_requested=4G

#$ -o logs_queue/DOCperMIP
#$ -e logs_queue/DOCperMIP

#$ -N combinesummaryMIPs
#$ -hold_jid summaryMIPs

# arguments should be:
# 1 = design file
# 2 = project name

headref='/labdata6/allabs/mips/references'
noderef='/labdata6/allabs/mips/references'
headbin='/labdata6/allabs/mips/pipeline_v0.1'
nodebin='/labdata6/allabs/mips/pipeline_v0.1'

INTERVAL=$(awk -v linenum=$SGE_TASK_ID 'NR==linenum { print $1; exit }' MIPtargets112bp.GATKDepthOfCoverage.intervals)


set -e
set -o pipefail

NOW=$(date +"%c")
printf "Running step 6c, summary MIPs job: $NOW\n" >> $2.MIPspipeline.log.txt


# Merge GATK DOC files for each 112bp MIP target interval into a single file
printf "Merging GATK Depth of Coverage for each MIP into summary.$2.DepthOfCoverage.MIPtargets112bp.sample_interval_summary..."
head -1 DOCperMIP/summary.$2.DepthOfCoverage.MIPtargets112bp.1.sample_interval_summary > summary.$2.DepthOfCoverage.MIPtargets112bp.sample_interval_summary
awk 'FNR != 1' DOCperMIP/summary.$2.DepthOfCoverage.MIPtargets112bp.*.sample_interval_summary >> summary.$2.DepthOfCoverage.MIPtargets112bp.sample_interval_summary
# for DOCfile in DOCperMIP/summary.$2.DepthOfCoverage.MIPtargets112bp.*.sample_interval_summary; do
	# cat "$DOCfile" >> summary.$2.DepthOfCoverage.MIPtargets112bp.sample_interval_summary
# done
printf "done\n"



# add MIP name to each interval
printf "Adding MIP name to each interval in summary.$2.DepthOfCoverage.MIPtargets112bp.sample_interval_summary..."
perl $nodebin/label_DOC_MIPtarget112.pl --designfile $1 --DOCfilein summary.$2.DepthOfCoverage.MIPtargets112bp.sample_interval_summary --DOCfileout summary.$2.DepthOfCoverage.MIPtargets112bp.sample_interval_summary.MIPnames.txt
printf "done\n"


# NOTES on GATK Depth of Coverage (DOC)
# 
# The total_coverage column is the total depth per base in that interval across all samples
# The average_coverage column is the mean depth per base in that interval across all samples
#
# Each row in the DOC file corresponds to a single MIP target region.  However, there can be reads from multiple MIPs in 
# a single target region, so you can have weird overlap where you end up with data from multiple MIPs contributing to the callable data.
# This is ok for the purpose of calculating the % callable bases but not as good for calculating spike-ins because a failed MIP 
# could be partially rescued by the ends of reads from overlapping MIPs while you'd still be missing data from the parts of the target
# that are unique to the failed MIP
# 
# For each sample, there will be a mean_cvg column, which corresponds to the average depth per base within that target interval
# There will also be a total_cvg column which corresponds to the sum of the depths at each base.  This seems not at all useful for us.
# The quartiles (Q1,Q3,median, etc) are from the distribution of depths per base
# 
# GATK automatically applies a number of filters to the reads going into this pipeline, however the DuplicateReadFilter is not a problem 
# because we don't MarkDuplicates in our bam anyway and this filter reads upon MarkDuplicates





