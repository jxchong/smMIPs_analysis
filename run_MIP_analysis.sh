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
# 4 = read length
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


printf "Setting default permissions for files and folders in this directory so that your group has read/write access"
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
# bash -c '[ -d logs_queue/UnifiedGenotyper ] || mkdir logs_queue/UnifiedGenotyper'
# bash -c '[ -d logs_queue/SeattleSeq ] || mkdir logs_queue/SeattleSeq'
bash -c '[ -d logs_queue/DOCperMIP ] || mkdir logs_queue/DOCperMIP'
bash -c '[ -d multisample_calls ] || mkdir multisample_calls'
# bash -c '[ -d singlesample_calls ] || mkdir singlesample_calls'
bash -c '[ -d DOCperMIP ] || mkdir DOCperMIP'


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
# multi-sample calling, also submits to SeattleSeq and produces a tab-delimited file with annotations
# eventually will submit to VEP as well
# uses Evan's script to generate capture events summary files
qsub -M $5 sub_GATK_HC_summarize.sh $1 $6 $3 $5


# # step 3)
# # Generate file with average coverage per MIP
# # make bam list
# # Run GATK Depth of Coverage
# qsub -M $5 sub_summary_data.sh $2 $6 $3
# # step 6b) generate DOC for each 112-bp MIP target interval
# qsub -t 1-`wc -l MIPtargets112bp.GATKDepthOfCoverage.intervals | cut -f1 -d' '`:1 -M $5 sub_DOC_MIPtargets.sh $6
# # step 6c) combine DOC for each 112-bp MIP target interval into one master file and add MIP names
# qsub -M $5 sub_combine_DOC_MIPtargets.sh $2 $6








NOW=$(date +"%c")
printf "Submitted analysis jobs: $NOW\n" >> $6.MIPspipeline.log.txt

