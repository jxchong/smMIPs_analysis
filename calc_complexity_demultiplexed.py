# Create mipwise complexity file when the data is already demultiplexed into separate fastqs (i.e. from MiSeq)
# 
# Jessica Chong 2014-07-17

import sys
import os.path
from optparse import OptionParser
import collections
import optparse
import pprint
from genome_sam_collapser import output_mip_complexity


parser = optparse.OptionParser("%prog read.fq [options]")
parser.add_option("--samplekey", type="str", help="sample key file (tab-delimited with format: <sample number on plate><tab><sammple_name><tab>barcode)")
parser.add_option("--projectname", type="str", help="identifying name for this analysis run for this project, will be prefix of the output file")

(options, args) = parser.parse_args()

if not options.samplekey:
	parser.error('--samplekey not given')
if not options.projectname:
	parser.error('--projectname not given')
		

# initialize complexity_by_position hash of hash of list
complexity_by_position = collections.defaultdict(lambda : collections.defaultdict(int))


# read in list of per-sample complexity files
samplekeyfile = options.samplekey
with open(samplekeyfile, "rU") as samplekey_fh:
	for sampleline in samplekey_fh:
		sampleinfo = sampleline.rstrip().split("\t")
		complexityfile = sampleinfo[1] + '/' + sampleinfo[1] + '.indexed.sort.collapse.complexity.txt'
		# across all per-sample complexity files, sum up total count and unique count of reads per mip key
		with open(complexityfile) as input_fh:
			next(input_fh)
			for line in input_fh:
				mipwisedata = line.rstrip().split("\t")
				mip_key = mipwisedata[1]
				total_reads = mipwisedata[2]
				unique_reads = mipwisedata[3]
				complexity_by_position[mip_key][0] += int(total_reads)
				complexity_by_position[mip_key][1] += int(unique_reads)
		input_fh.close()
samplekey_fh.close()


# output complexity info
complexity_outfile = options.projectname + '.indexed.sort.collapse.complexity.txt'
with open(complexity_outfile, 'w') as output_fh:
	output_fh.write('sample\tmip\ttotal\tunique\tsaturation\n')
	output_mip_complexity(complexity_by_position, output_fh)
output_fh.close()




