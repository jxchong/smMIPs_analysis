#$ -S /bin/bash
#$ -V
#$ -m eas
#$ -cwd
#$ -q new.q
##$ -l mem_requested=34G

#$ -o logs_queue/
#$ -e logs_queue/

#$ -N load_GEMINI
#$ -hold_jid GATK_UGmulti

# arguments should be:
# $1 = project name

# NOTE: you must have a file ~/.gemini/gemini-config.yaml already existing. The file contents should point to the GEMINI annotation dir, e.g. containing a line like:
# annotation_dir: /cm/shared/apps/gemini/gemini_data/



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
module load shared Tools/common dos2unix/6.0.5 sge java/1.7.0_55 python/2.7.6 conda/4.5.0 perl/5.20.2 vep/89 vt/0.57.0 gemini/0.20.1
#######################################################################################
export PYTHONPATH=/labdata6/allabs/mips/pipeline_smMIPS_v1.1/MIPGEN/tools/
#######################################################################################


set -e
set -o pipefail


NOW=$(date +"%c")
printf "Running step 4, generating basic stats and loading VEP-annotated file into GEMINI database. NOTE: ~/.gemini/gemini-config.yaml file must exist $NOW\n" >> $1.smMIPspipeline.log.txt

THISSCRIPT=$(basename $0)
NODENAME=$(hostname)
printf "Running $0 on cluster node $NODENAME\n"

bcftools query -l multisample_calls/$1.UG.multisample.realigned.polymorphic.filtered.VT.VEP.vcf.gz > multisample_calls/$1.UG.multisample.realigned.polymorphic.filtered.VT.VEP.samplelist.txt

gemini load -v multisample_calls/$1.UG.multisample.realigned.polymorphic.filtered.VT.VEP.vcf.gz -t VEP --cores 4 multisample_calls/$1.UG.multisample.realigned.polymorphic.filtered.VT.VEP.db

printf "done with loading gemini database\n"
