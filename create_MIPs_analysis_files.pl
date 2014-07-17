#!/usr/bin/env perl
#
# Description: This script will copy over the current MIPs analysis pipeline queue submission files to the current directory and prompt the user with instructions on how to submit job or edit the GATK commands and then submit.
#
#
# Created by Jessica Chong on 2014-07-16.

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;


my $headbin = '/labdata6/allabs/mips/pipeline_Shendure_v0.9.7';

my ($samplesheet, $designfile, $mipbedfile, $readlength, $email, $projectname, $sequencer, $mipbedfilenochr, $help);

GetOptions(
	'samplesheet=s' => \$samplesheet, 
	'designfile=s' => \$designfile,
	'MIPbed=s' => \$mipbedfile,
	'readlength=i' => \$readlength,
	'email=s' => \$email,
	'projectname=s' => \$projectname,
	'sequencer=s' => \$sequencer,
	'help|?' => \$help,
) or pod2usage(-verbose => 1) && exit;
pod2usage(-verbose=>2, -exitval=>1) if $help;

if (!defined $samplesheet) {
	 pod2usage(-exitval=>2, -verbose=>1, -message => "$0: --samplesheet not defined.\n")
} elsif (!defined $designfile) {
	pod2usage(-exitval=>2, -verbose=>1, -message => "$0: --designfile not defined\n");
} elsif (!defined $mipbedfile) {
	pod2usage(-exitval=>2, -verbose=>1, -message => "$0: --MIPbed not defined\n");
} elsif (!defined $readlength) {
	pod2usage(-exitval=>2, -verbose=>1, -message => "$0: --readlength not defined\n");
} elsif (!defined $email) {
	pod2usage(-exitval=>2, -verbose=>1, -message => "$0: --email not defined\n");
} elsif (!defined $projectname) {
	pod2usage(-exitval=>2, -verbose=>1, -message => "$0: --projectname not defined\n");
} elsif (!defined $sequencer) {
	pod2usage(-exitval=>2, -verbose=>1, -message => "$0: --sequencer not defined\n");
}

print "\n\n";

my $hostname = `hostname`;
chomp $hostname;
if ($hostname =~ /compute-/) {
	die "You should be on the head node to run this script and to start the pipeline but you are on $hostname instead\n";
}

print "Checking formatting of input files you provided...\n";
my $inputcheck = validateInputs();
if ($inputcheck == 1) {
	print "PASSED:\n";
	print "--samplesheet $samplesheet\n";
	print "--designfile $designfile\n";
	print "--MIPbed $mipbedfile\n";
	print "--readlength $readlength\n";
	print "--projectname $projectname\n";
	print "--sequencer $sequencer\n";
} else {
	die "FAILED: $inputcheck.  Check formatting\n";
}

print "\n\n";



my $samplekey = makeSampleKey($samplesheet);


# copy all the relevant Bash, queue submission scripts to current directory.
if ($readlength >= 110) {
	`cp $headbin/v2kit/sub_*.sh .`;
} elsif ($readlength <= 80) {
	# specific pipeline not written yet since Bamshad lab doesn't use v3 kits
	`cp $headbin/v3kit/sub_*.sh .`;
}


# create a log file
open (my $log_handle, ">", "$projectname.smMIPspipeline.log.txt") or die "Cannot write to smMIPspipeline.log.txt: $!.\n";
print $log_handle "Scripts from MIPs analysis pipeline_Shendure_v0.9.7 created on ".scalar(localtime())."\n";
print $log_handle "pipeline_Shendure_v0.9.7 uses version 0.7.8-r455 of BWA\n";
print $log_handle "pipeline_Shendure_v0.9.7 uses version 3.1-1-g07a4bf8 of GATK\n";
print $log_handle "pipeline_Shendure_v0.9.7 uses version 0.1.19-44428cd of samtools\n";
print $log_handle "pipeline_Shendure_v0.9.7 uses version Version 4.07b of Tandem Repeats Finder\n";
print $log_handle "pipeline_Shendure_v0.9.7 uses version 0.9.0 of pear\n";
close $log_handle;



# edit run_MIP_analysis.sh and insert input values
open (my $output_handle, ">", "run_MIP_analysis.sh") or die "Cannot write to run_MIP_analysis.sh: $!.\n";
open (my $input_handle, "$headbin/run_MIP_analysis.sh") or die "Cannot read $headbin/run_MIP_analysis.sh: $!.\n";
while ( <$input_handle> ) {
	my $line = $_;
	$line =~ s/ \$1/ $samplekey/g;					# 1 = filename of sample key (2+ columns, see below)
	$line =~ s/ \$2/ $designfile/g;					# 2 = filename of MIP design file
	$line =~ s/ \$3/ $mipbedfile/g;					# 3 = filename of BED file containing final MIP regions of each gene
	$line =~ s/ \$4/ $readlength/g;					# 4 = read length
	$line =~ s/ \$5/ $email/g;						# 5 = your email address
	$line =~ s/ \$6/ $projectname/g;				# 6 = an identifying name for this project (e.g. "2013-01-01-My_MIPS_Project")
	$line =~ s/ \$7/ $sequencer/g;					# 7 = the sequencer used to generate the fastqs (MiSeq or HiSeq)
	print $output_handle "$line";
}
close $input_handle;
close $output_handle;



print "\n\n";

print "If you would like edit the GATK settings used for calling/filtering, edit or uncomment/comment relevant parts of sub_GATK_HC_summarize.sh as desired\n";
print "When finished, begin the analysis with:\nbash run_MIP_analysis.sh\n\n";


print "You can monitor the overall log of what you've been doing by viewing $projectname.MIPspipeline.log.txt\n.  You can also check the cluster job log files in the logs_queue directory\n\n";









sub validateInputs {
	my $inputcheck = 1;
	
	if ($projectname =~ m/\!\/ \\:/) {
		$inputcheck = "--projectname $projectname contains problematic characters (! / \ : [space])";
	} elsif ($readlength < 20) {
		$inputcheck = "--readlength $readlength under 20 bases, are you sure?\n";
	}	
	
	system("dos2unix $designfile");
	system("mac2unix $designfile");
	my $designheadvals = getHeader($designfile);
	
	if (!defined ${$designheadvals}{'chr'}) {
		$inputcheck = "--designfile $designfile is missing a column named 'chr'\n";
	} elsif (!defined ${$designheadvals}{'lig_probe_sequence'}) {
		$inputcheck = "--designfile $designfile is missing a column named 'lig_probe_sequence'\n";
	} elsif (!defined ${$designheadvals}{'ext_probe_sequence'}) {
		$inputcheck = "--designfile $designfile is missing a column named 'ext_probe_sequence'\n";
	} elsif (!defined ${$designheadvals}{'probe_strand'}) {
		$inputcheck = "--designfile $designfile is missing a column named 'probe_strand'\n";
	} elsif (!defined ${$designheadvals}{'lig_probe_start'}) {
		$inputcheck = "--designfile $designfile is missing a column named 'lig_probe_start'\n";
	} elsif (!defined ${$designheadvals}{'ext_probe_start'}) {
		$inputcheck = "--designfile $designfile is missing a column named 'ext_probe_start'\n";
	} elsif (!defined ${$designheadvals}{'Concatenated_name'} && !defined ${$designheadvals}{'mip_name'}) {
		$inputcheck = "--designfile $designfile is missing a column named 'Concatenated_name' or 'mip_name'\n";
	}

	system("dos2unix $mipbedfile");
	system("mac2unix $mipbedfile");
	my $mipbedvals = getHeader($mipbedfile);
	if (scalar keys %{$mipbedvals} < 5) {
		$inputcheck = "--MIPbed $mipbedfile is missing columns (should have columns chr,start,stop,name,strand)\n";
	}
	
	if ($sequencer =~ /^MiSeq$/i) {
		$sequencer = 'MiSeq';
	} elsif ($sequencer =~ /^HiSeqDorschner$/i) {
		$sequencer = 'HiSeqDorschner';
	} elsif ($sequencer =~ /^HiSeqNickerson$/i) {
		$sequencer = 'HiSeqNickerson';
	} else {
		$inputcheck = "--sequencer $sequencer is not a recognized sequencer type (HiSeqDorschner, HiSeqNickerson, or MiSeq)\n";
	}
	return $inputcheck;
}


sub getHeader {
	my $filename = $_[0];
	
	open (my $filehandle, "$filename") or die "Cannot read $filename: $!.\n";
	my $firstline = <$filehandle>;
	close $filehandle;
	
	$firstline =~ s/\s+$//;					# Remove line endings
    chomp($firstline);
    chop($firstline) if ($firstline =~ m/\r$/);		# get rid of stupid Excel carriage return line endings
	my @line = split("\t", $firstline);
	my %values;
	@values{@line} = @line;	
	
	return \%values;
}



sub makeSampleKey {
	$samplesheet =~ s/"//g;
	system("dos2unix \"$samplesheet\"");
	system("mac2unix \"$samplesheet\"");
	
	my @sampledata;
	my $headerpassed = 0;
	open (my $samplesheet_handle, "$samplesheet") or die "Cannot read $samplesheet: $!.\n";
	while ( <$samplesheet_handle> ) {
		my $line = $_;
		$line =~ s/\s+$//;						# Remove line endings
	   	chomp($line);
	    chop($line) if ($line =~ m/\r$/);			# get rid of stupid Excel carriage return line endings
		if ($headerpassed == 1) {
			my @sampleentry;
			my @testdelimcomma = split(",", $line);
			my @testdelimtab = split("\t", $line);
			if (scalar(@testdelimcomma) == 4) {
				@sampleentry = @testdelimcomma;
			} elsif (scalar(@testdelimtab) == 4) {
				@sampleentry = @testdelimtab;
			} else {
				die "The samplesheet $samplesheet has a format I cannot handle (possibly: not csv, not tab-delimited, doesn't have 4 columns (Sample_ID,Sample_Name,GenomeFolder,index) in the sample section)\n";
			}
			push(@sampledata, "$sampleentry[0]\t$sampleentry[1]\t$sampleentry[3]");	
		}
		if ($line =~ /Sample_ID/i) {
			$headerpassed = 1;
		}
	}
	close $samplesheet_handle;
	
	if ($headerpassed == 0) {
		die "Something is wrong with the samplesheet $samplesheet because I could not find the sample area containing a Sample_ID column\n";
	}
	
	open (my $samplekey_handle, ">", "sample_key.txt") or die "Cannot write sample_key.txt: $!.\n";
	foreach my $line (@sampledata) {
		print $samplekey_handle "$line\n";
	}
	close $samplekey_handle;
	
	return "sample_key.txt";
}




################################################################################################################
############################################ Documentation #####################################################
################################################################################################################


=head1 NAME


create_MIPs_analysis_files.pl - Script to copy over current version of MIPs analysis pipeline files and make some input files.  This script should be run while you are on the head node.


=head1 SYNOPSIS


perl B<create_MIPs_analysis_files.pl> I<[options]>


=head1 ARGUMENTS

=over 4

=item B<--samplesheet> F<sample sheet file>	

	path to MIP Sample Sheet (if you don't know how to deal with spaces in the filename, remove the spaces first)

=item B<--designfile> F<design file>

	path to MIP design file

=item B<--MIPbed> F<bed file>

	path to BED file containing all MIP regions

=item B<--readlength> F<integer>

	desired read length to trim to (probably 76 to 110 bp)

=item B<--sequencer> F<HiSeqDorschner|HiSeqNickerson|MiSeq>

	name of sequencer used to generate the fastqs (MiSeq or HiSeqDorschner or HiSeqNickerson)

=item B<--email> F<email address>

	email address to get notifications from cluster on job progress

=item B<--projectname> F<string>

	identifying name for this analysis run for this project (I recommend including the date in case you want to try multiple analysis settings: "2013-01-01-My_MIPS_Project")

=item B<--help> 

	print full documentation

=back


=head1 FILES


Sample sheet: the Sample Sheet used by the MiSeq for this run (includes barcodes, etc)

 [Header],,,
 Investigator Name,Kati Buckingham,,
 Project Name,HIV_Pool_2_Equimolar ,,
 Experiment Name,MS2038609-300V2,,
 [...]
 Sample_ID,Sample_Name,GenomeFolder,index
 1,1738_FS,C:\Illumina\MiSeq Reporter\Genomes\Homo_sapiens\UCSC\hg19\Sequence\Chromosomes,CGTTATGC
 2,1787_FS,C:\Illumina\MiSeq Reporter\Genomes\Homo_sapiens\UCSC\hg19\Sequence\Chromosomes,TCCGAGAA


MIP design file: final output created by design pipeline (The header of this file begins with >mip_pick_count)
NOTE: Should have a column named Concatenated_name containing the name for each MIP

 >mip_pick_count	gene	region covered	rank_score	chr	ext_probe_start [...]
 1	CD101	UTR_5'_Ex1	5	1	117544332
 2	CD101	Ex1	5	1	117544573
 3	CD101	Ex2	5	1	117552442


BED file with MIPs: merged BED file with final MIP regions for each gene; created in design pipeline

 chr1	117544361	117544492	NM_004258_exon_0_10_chr1_117544372_f	+
 chr1	117552461	117552862	NM_004258_exon_1_10_chr1_117552472_f	+
 chr1	117554161	117554598	NM_004258_exon_2_10_chr1_117554172_f	+


=head1 EXAMPLES


perl create_MIPs_analysis_files.pl --samplesheet PIEZO2.samplekey.txt --designfile PIEZO2_allMIPs.designfile.txt --MIPbed PIEZO2_mips.bed --readlength 110 --email jxchong@uw.edu --projectname 2014-02-28-PIEZO2_analysis1

Also see /labdata6/allabs/mips/pipeline_Shendure_v0.9.7/examples/


=head1 AUTHOR


Jessica Chong (jxchong@uw.edu, jxchong@gmail.com)


=cut
