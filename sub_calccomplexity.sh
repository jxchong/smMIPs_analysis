#$ -S /bin/bash
##$ -V
##$ -m eas
#$ -cwd
#$ -q new.q
##$ -l mem_requested=8G

#$ -o logs_queue
#$ -e logs_queue

#$ -N calccomplexity
#$ -hold_jid smMIP_prep_samples

# arguments should be:
# $1 = sample ID key text file for all samples
	# sampleIDkey format: 
	# 1st column: numeric ID (1 through x)
	# 2nd column: sample name
	# 3rd column optional
# $2 = project name
# $3 = MIP design file

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
module load shared Tools/common dos2unix/6.0.5 sge java/1.7.0_55
#######################################################################################
export PYTHONPATH=/labdata6/allabs/mips/pipeline_smMIPS_v1.0/MIPGEN/tools/
#######################################################################################


set -e
set -o pipefail


NOW=$(date +"%c")
printf "Running step 2, calccomplexity job: $NOW\n" >> $2.smMIPspipeline.log.txt


printf "Making list of all bam files for this samplesheet\n"
find */* -name "*.indexed.sort.collapse.all_reads.unique.sort.bam" > bam.list
printf "done\n"


printf "Creating a master complexity file for all samples for all mips\n"
echo -e "sample\tmip\ttotal\tunique" > QC_data/$2.allsamplesallmips.indexed.sort.collapse.complexity.txt
find */* ! -path "QC_data/*" -name "*.indexed.sort.collapse.complexity.txt" -exec tail -n +2 {} \; >> QC_data/$2.allsamplesallmips.indexed.sort.collapse.complexity.txt
printf "done\n"


printf "Creating a mater mipwise complexity file\n"
python $pipelinebin/calc_complexity_demultiplexed.py --samplekey $1 --projectname QC_data/$2
printf "done\n"


printf "Creating a master samplewise-summary file for all samples\n"
echo -e "sample\tmip\ttotal\tunique\tsaturation" > QC_data/$2.indexed.sort.collapse.samplewise_summary.txt
find */* ! -path "QC_data/*" -name "*.indexed.sort.collapse.samplewise_summary.txt" -exec tail -n +2 {} \; >> QC_data/$2.indexed.sort.collapse.samplewise_summary.txt
printf "done\n"


printf "Adding Concatenated_name to QC files\n"
perl $pipelinebin/add_concatname_complexity.pl --designfile $3 --complexityfile QC_data/$2.allsamplesallmips.indexed.sort.collapse.complexity.txt
perl $pipelinebin/add_concatname_complexity.pl --designfile $3 --complexityfile QC_data/$2.indexed.sort.collapse.complexity.txt
printf "done\n"


