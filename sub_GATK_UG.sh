#$ -S /bin/bash
#$ -V
#$ -m eas
#$ -cwd
#$ -q new.q
##$ -l mem_requested=34G

#$ -o logs_queue/UnifiedGenotyper
#$ -e logs_queue/UnifiedGenotyper

#$ -N GATK_UGmulti
#$ -hold_jid indel_realign

# arguments should be:
# 1 = file containing prefixes for all samples
# 2 = project name
# 3 = email address

# arguments should be:
# $1 = sample ID key text file for all samples
	# sampleIDkey format:
	# 1st column: numeric ID (1 through x)
	# 2nd column: sample name
	# 3rd column optional
# $2 = project name
# $3 = your email address

# location of Pediatrics analysis pipeline bin
pipelinebin='/labdata6/allabs/mips/pipeline_smMIPS_v1.1/smMIPs_analysis'
# location of MIPGEN/tools script directory
mipgentoolsbin='/labdata6/allabs/mips/pipeline_smMIPS_v1.1/MIPGEN/tools'
# location of executables
executbin='/labdata6/allabs/mips/pipeline_smMIPS_v1.1/executables'
# directory to reference files (reference genome fasta and various indexes)
refdir='/labdata6/allabs/mips/references/b37/BWA0.7.8'


################### only necessary if using modules environment #######################
source /cm/local/apps/environment-modules/3.2.10/Modules/3.2.10/init/bash
module load shared Tools/common dos2unix/6.0.5 sge java/1.7.0_55 python/2.7.6 conda/4.3.22 perl/5.20.2 vep/89
#######################################################################################
export PYTHONPATH=/labdata6/allabs/mips/pipeline_smMIPS_v1.1/MIPGEN/tools/
#######################################################################################


set -e
set -o pipefail


NOW=$(date +"%c")
printf "Running step 3b, multisample Unified Genotyper calling and SeattleSeq job: $NOW\n" >> $2.smMIPspipeline.log.txt


printf "Making list of all .bam files..."
find */* -name "*.realigned.bam" > bam.realigned.list
printf "done\n"


# multi-sample call **POLYMORPHIC** sites on indel realigned samples
printf "Run Unified Genotyper for multisample calling..."
java -Xmx32g -jar $executbin/GenomeAnalysisTK.jar \
-R $refdir/Homo_sapiens_assembly19.fasta \
-T UnifiedGenotyper \
-L MIPtargets.intervals \
-rf BadCigar \
-allowPotentiallyMisencodedQuals \
-I bam.realigned.list \
-o multisample_calls/$2.multisample.realigned.polymorphic.raw.snv.indel.vcf \
-nt 8 \
-nct 4 \
-dcov 5000 \
-dt NONE \
-glm both \
-A AlleleBalance \
-rf BadCigar \
-stand_emit_conf 10 \
-minIndelFrac 0.005 \
-G Standard
printf "done\n"


# Adding filter flags to multi-sample vcf **POLYMORPHIC** sites
# NOTE!!!  The cutoffs for the coverage filter is now much lower because with smMIPs, we know each read is from a unique capture event
printf "Add GATK filter flags for multisample calling..."
java -Xmx8g -jar $executbin/GenomeAnalysisTK.jar \
-T VariantFiltration \
-R $refdir/Homo_sapiens_assembly19.fasta \
-rf BadCigar \
-allowPotentiallyMisencodedQuals \
-V multisample_calls/$2.multisample.realigned.polymorphic.raw.snv.indel.vcf \
-o multisample_calls/$2.UG.multisample.realigned.polymorphic.filtered.vcf \
-window 20 \
-cluster 5 \
-filterName ABFilter \
-filter "ABHet > 0.75" \
-filterName QDFilter \
-filter "QD < 5.0" \
-filterName QUALFilter \
-filter "QUAL < 30.0" \
-filterName LowCoverage \
-filter "DP < 5"
printf "done\n"


printf "Submitting multisample vcf to SeattleSeq138\n"
# this will put SeattleSeq annotations in separate tab-delimited file
java -Xmx4g -jar $executbin/getAnnotationSeattleSeq138.031014.jar \
-i multisample_calls/$2.UG.multisample.realigned.polymorphic.filtered.vcf \
-o multisample_calls/$2.UG.multisample.realigned.polymorphic.filtered.SS138.tsv \
-m $3
printf "done\n"


# make a bgzip compressed version of the vcfs
$executbin/bgzip -c multisample_calls/$2.UG.multisample.realigned.polymorphic.filtered.vcf > multisample_calls/$2.UG.multisample.realigned.polymorphic.filtered.vcf.gz
$executbin/tabix -p vcf multisample_calls/$2.UG.multisample.realigned.polymorphic.filtered.vcf.gz


printf "Variant decomposition with VT\n"
zcat multisample_calls/$2.UG.multisample.realigned.polymorphic.filtered.vcf.gz | sed 's/ID=AD,Number=./ID=AD,Number=R/' | vt decompose -s - | vt normalize -r $refdir/Homo_sapiens_assembly19.fasta - | bgzip -c > multisample_calls/$2.UG.multisample.realigned.polymorphic.filtered.VT.vcf.gz


printf "Annotating multisample vcf with VEP v89\n"
# this will insert VEP annotations into the vcf file for later importing into Gemini
### you can also easily use vcftools or bcftools to parse this out into a tab-delimited format, e.g.
### ~/bin/bcftools query -H --f '%CHROM\t%POS\t%REF\t%ALT\t%TYPE\t%ID\t%FILTER\t%INFO/VEPNAME[\t%TGT]\n'

vep \
-i multisample_calls/$2.UG.multisample.realigned.polymorphic.filtered.VT.vcf.gz \
-o multisample_calls/$2.UG.multisample.realigned.polymorphic.filtered.VT.VEP.vcf.gz \
--compress_output \
bgzip --exclude_predicted --domain _--nearest symbol --vcf --offline \
--cache --dir_cache /cm/shared/apps/vep/vep89/ \
--species homo_sapiens --assembly GRCh37 \
--fasta $refdir/Homo_sapiens_assembly19.fasta \
--fork 8 --force_overwrite --sift b --polyphen b --symbol --numbers \
--biotype --total_length --canonical --ccds --hgvs --shift_hgvs 1 \
--gene_phenotype --check_existing --af_1kg --af_gnomad --regulatory \
--fields Consequence,Codons,Amino_acids,Gene,SYMBOL,Feature,Feature_type,EXON,cDNA_position,CDS_position,Protein_position,Existing_variation,PolyPhen,SIFT,BIOTYPE,CANONICAL,CCDS,HGVSc,HGVSp,AFR_AF,AMR_AF,ASN_AF,EUR_AF,EAS_AF,SAS_AF,ExAC_AFR,ExAC_AMR,ExAC_EAS,ExAC_NFE,ExAC_SAS,ExAC_Adj,PHENO,GENE_PHENO,NEAREST,DOMAINS


tabix -p vcf multisample_calls/$2.UG.multisample.realigned.polymorphic.filtered.VT.VEP.vcf.gz
printf "done\n"
