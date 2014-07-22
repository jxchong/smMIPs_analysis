smMIPs_analysis
===============
#### Description

This set of scripts will copy over current version of MIPs analysis pipeline files and automatically make input files and queue submission scripts so that all samples can be processed in parallel.  When you run

This pipeline makes assumptions about the format of your data/MIP designs.  In particular, it currently assumes:

1. The data has already been demultiplexed
2. The fastq.gz files were produced on Genetic Medicine/Pediatrics MiSeq (have not tested other sequencers)
3. You are using a 5-bp molecular tag on the extension arm and 0-bp (no tag) on the ligation arm
4. Because the data was produced on a MiSeq, there are no readgroups

If some of these assumptions are not true, you will need to edit sub_prep_samples*.sh to make adjustments.

You may have to run Evan Boyle's MIPGEN/tools/mipgen_pipeline_builder.py to help you generate the correct commands to replace in sub_prep_samples*.sh.  MIPGEN can be found here: [http://github.com/shendurelab/MIPGEN](http://github.com/shendurelab/MIPGEN)


#### To Use

perl create_MIPs_analysis_files.pl --samplesheet SampleSheet.csv --designfile MYGENE_allMIPs.designfile.txt --MIPbed MYGENE_mips.bed --readoverlapbp 20 --email xxxx@uw.edu --projectname 2014-02-28-MYGENE_analysis1

* --samplesheet
	* path to MIP Sample Sheet (if you don't know how to deal with spaces in the filename, remove the spaces first)
* --designfile
	* path to MIP design file; if the design file contains a column "Concatenated_name," then the QC complexity files will have an extra column added with the contents of that column matched to the official mip_name/mipkey value
* --MIPbed
	* path to BED file containing all MIP regions
* --readoverlapbp
	* number of bases overlapping between forward and reverse reads (if <10, pear cannot be used)
* --sequencer
	* name of sequencer used to generate the fastqs (currently only MiSeq is supported; other options may eventually be: HiSeqDorschner or HiSeqNickerson)
* --email
	* email address to get notifications from cluster on job progress

* --projectname
	* identifying name for this analysis run for this project (I recommend including the date in case you want to try multiple analysis settings: "2013-01-01-My_MIPS_Project")


Then, begin the analysis with:

	bash run_MIP_analysis.sh


You can monitor the overall log of what you've been doing by viewing projectname.MIPspipeline.log.txt.  Don't forget to check the cluster job log files in the logs_queue directory to make sure all commands completed successfully.

#### Input Files
##### Sample sheet: the Sample Sheet used by the MiSeq for this run (includes barcodes, etc)

	[Header],,,
	Investigator Name,John Smith,,
	Project Name,MYGENE_Equimolar ,,
	Experiment Name,MS2038609-300V2,,
	[...]
	Sample_ID,Sample_Name,GenomeFolder,index
	1,1738_FS,C:\Illumina\MiSeq Reporter\Genomes\Homo_sapiens\UCSC\hg19\Sequence\Chromosomes,CGTTATGC
	2,1787_FS,C:\Illumina\MiSeq Reporter\Genomes\Homo_sapiens\UCSC\hg19\Sequence\Chromosomes,TCCGAGAA


##### MIP design file: final output created by MIPGEN v1.0 design pipeline (The header of this file begins with >mip_key)
If this file contains an extra column named "Concatenated_name" or "mip_name", the pipeline will automatically add that prettified name to the mip-wise complexity files.

	>mip_key	svr_score	chr	ext_probe_start
	9:101707601-101707762/19,26/+	2.21146	13	101707601
	9:101707700-101707861/16,29/-	2.28919	13	101707846


##### BED file with MIPs: merged BED file with final MIP regions for each gene; created in design pipeline

	chr1	117544361	117544492	NM_004258_exon_0_10_chr1_117544372_f	+
	chr1	117552461	117552862	NM_004258_exon_1_10_chr1_117552472_f	+
	chr1	117554161	117554598	NM_004258_exon_2_10_chr1_117554172_f	+

or 

	1	117544361	117544492	NM_004258_exon_0_10_chr1_117544372_f	+
	1	117552461	117552862	NM_004258_exon_1_10_chr1_117552472_f	+
	1	117554161	117554598	NM_004258_exon_2_10_chr1_117554172_f	+

#### Notes

While HaplotypeCaller may give fewer false positive variant calls, it appears that HaplotypeCaller is fundamentally not well-suited for MIPS data, see [this ref](http://gatkforums.broadinstitute.org/discussion/3499/haplotypecaller-doesn-t-call-true-variants-which-are-located-on-the-outside-of-duplicated-reads).  Per the GATK developers in the linked thread:

	I think it's simply that this data type really just doesn't work well in the world of assembly. Having short, non-overlapping reads means that you won't be able to build a connected graph without ambiguous cycles. I would recommend that you not use the HC if you are forced to use this constrained data type.

We have confirmed this issue with our own smMIP data, in which a Sanger-confirmed variant that is 16 bp from the end of the MIP read and is covered well (AD=19,20) was not called at all by HaplotypeCaller but called correctly by UnifiedGenotyper.  Therefore, this pipeline will automatically generate multisample calls with both HaplotypeCaller AND UnifiedGenotyper.