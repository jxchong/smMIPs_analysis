#!/bin/bash -e


################################################################################################################
###################################################### README ##################################################
################################################################################################################
# Run the MIPS pipeline with:
# bash run_MIP_analysis.sh <ARG_1> <ARG_2> <ARG_3> <ARG_4> <ARG_5> <ARG_6> <ARG_7> <ARG_8>

# where those arguments are:
# 1 = filename of sample key (3 columns, see below)
# 2 = filename of MIP design file
# 3 = filename of BED file containing final MIP regions of each gene
# 4 = number of bases overlapping between forward and reverse reads (determines whether or not to use PEAR)
# 5 = your email address
# 6 = an identifying name for this project (e.g. "2013-01-01-My_MIPS_Project")
# 7 = sequencer used (HiSeqDorschner|HiSeqNickerson|MiSeq)

# Description of input file formats:
#
# File #1 = Sample key:
# 1st column: numeric ID (1 through x)
# 2nd column: barcode (reverse complement)
# 3rd column: sample name

# File #2 = MIP design file; final output created by design pipeline
# (header begins with >mip_pick_count)

# File #3 = BED file with MIPs
# BED file with final MIP regions for each gene; created in design pipeline
# 1st column: chromosome
# 2nd column: start
# 3rd column: stop
# 4th column: region name
# 5th column: strand

################################################################################################################
################################################################################################################

################### only necessary if using modules environment #######################
.  /cm/local/apps/environment-modules/3.2.10/Modules/3.2.10/init/bash
module load shared Tools/common dos2unix/6.0.5 plink/1.07 sge python/2.7.6 conda/4.3.22
#######################################################################################


printf "Setting default permissions for files and folders in this directory so that your group has read/write access\n"
setfacl -dm u::rwx,g::rwx,o::r .
printf "done\n"


# making sure sample sheet and bed file have UNIX line endings
dos2unix $2
dos2unix $3

mac2unix $2
mac2unix $3


# making sure bed file doesn't contain "chr" in the chromosome number column
sed -i "s/^chr//" $3


# delete *Undetermined*.fastq* files
find -type f -iname '*Undetermined*.fastq*' -exec rm -f {} \;


# make directories to store logs
bash -c '[ -d logs_queue ] || mkdir logs_queue'
bash -c '[ -d logs_queue/prep_samples ] || mkdir logs_queue/prep_samples'
bash -c '[ -d logs_queue/UnifiedGenotyper ] || mkdir logs_queue/UnifiedGenotyper'
# bash -c '[ -d logs_queue/SeattleSeq ] || mkdir logs_queue/SeattleSeq'
bash -c '[ -d multisample_calls ] || mkdir multisample_calls'
# bash -c '[ -d singlesample_calls ] || mkdir singlesample_calls'
bash -c '[ -d QC_data ] || mkdir QC_data'


# if HiSeq, then rename files so that the index (barcode) aka read2 file is s_1_3 and the original s_1_3 file which contains the reverse reads is renamed to read2
# this fits into the existing read1 read2 format better
# if [ "$7" == "HiSeqDorschner" ] || [ "$7" == "HiSeqNickerson" ]; then
# 	mv s_1_3.fastq.gz s_1_read2.fastq.gz
# 	mv s_1_2.fastq.gz s_1_3.fastq.gz
# 	mv s_1_read2.fastq.gz s_1_2.fastq.gz
#
# 	# printf "Uncompressing s_1_x.fastq..."
# 	# zcat s_1_1.fastq.gz > s_1_1.fastq
# 	# zcat s_1_2.fastq.gz > s_1_2.fastq
# 	# zcat s_1_3.fastq.gz > s_1_3.fastq
# 	# printf "done\n"
# fi


# step 1)
qsub -M $5 -t 1-`wc -l $1 | cut -f1 -d' '`:1 sub_prep_samples.sh $1 $2


# step 2)
# use Evan's script to generate capture events summary files (complexity files)
qsub -M $5 sub_calccomplexity.sh $1 $6 $2


# step 3a) Disabling as of 2017-11-08 because there's no point in running HC since HaplotypeCaller doesn't work on MIP data (all reads have exact same start and stop)
# multi-sample calling with HaplotypeCaller
# annotation: VEP to annotate VCF. SeattleSeq138 to produce a tab-delimited file with annotations
# uses Evan's script to generate capture events summary files
# qsub -M $5 sub_GATK_HC.sh $1 $6 $3 $5


# step 3b)
# make MIPtargets.interval (GATK interval file)
perl -anF'\t' -e '$F[0] =~ s/chr//; print "$F[0]:$F[1]-$F[2]\n";' $3 > MIPtargets.intervals
# indel realignment
# multi-sample calling with Unified Genotyper
# annotation: SeattleSeq138 to produce a tab-delimited file with annotations
# eventually will submit to VEP as well
qsub -M $5 -t 1-`wc -l $1 | cut -f1 -d' '`:1 sub_GATK_UG_indelrealign.sh $1 $6 $3
qsub -M $5 sub_GATK_UG.sh $1 $6 $5





NOW=$(date +"%c")
printf "###########################################\n" >> $6.smMIPspipeline.log.txt
printf "Submitted analysis jobs: $NOW\n" >> $6.smMIPspipeline.log.txt
