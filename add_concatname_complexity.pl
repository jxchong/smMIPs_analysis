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


my $headbin = '/labdata6/allabs/mips/pipeline_smMIPS_v1.0';

my ($designfile, $complexityfile, $help);

GetOptions(
	'designfile=s' => \$designfile,
	'complexityfile=s' => \$complexityfile,
	'help|?' => \$help,
) or pod2usage(-verbose => 1) && exit;
pod2usage(-verbose=>2, -exitval=>1) if $help;

if (!defined $designfile) {
	pod2usage(-exitval=>2, -verbose=>1, -message => "$0: --designfile not given\n");
} elsif (!defined $complexityfile) {
	pod2usage(-exitval=>2, -verbose=>1, -message => "$0: --complexityfile not given\n");
}  


# read in mip_key => concantenated_name/mip_name mapping
my %mipkeynames;
open (my $designfile_fh, "$designfile") or die "Cannot read $designfile: $!.\n";
my $head = <$designfile_fh>;
$head =~ s/\s+$//;					# Remove line endings
my @header = split("\t", $head);
my ($mipkeycol, $prettynamecol) = (0, $#header);
for (my $i=0; $i<=$#header; $i++) {
	if ($header[$i] eq '>mip_key') {
		$mipkeycol = $i;
	} elsif ($header[$i] =~ /Concatenated_name/i || $header[$i] =~ /mip_name/i) {
		$prettynamecol = $i;
	}
}
while ( <$designfile_fh> ) {
	$_ =~ s/\s+$//;					# Remove line endings
	my @line = split("\t", $_);
	$mipkeynames{$line[$mipkeycol]} = $line[$prettynamecol];
}
close $designfile_fh;


my $complexityfileprefix = $complexityfile;
$complexityfileprefix =~ s/\.txt//;
my $outputfile = "$complexityfileprefix.withnames.txt";
open (my $complexityfile_fh, "$complexityfile") or die "Cannot read $complexityfile: $!.\n";
open (my $output_fh, ">", "$outputfile") or die "Cannot write to $outputfile: $!.\n";
$head = <$complexityfile_fh>;
$head =~ s/\s+$//;					# Remove line endings
print $output_fh "$head\tmip_name\n";
while ( <$complexityfile_fh> ) {
	$_ =~ s/\s+$//;					# Remove line endings
	my @data = split("\t", $_);
	if (defined $mipkeynames{$data[1]}) {
		print $output_fh join("\t", @data)."\t$mipkeynames{$data[1]}\n";
	} else {
		print $output_fh join("\t", @data)."\tNA\n";
	}
}
close $output_fh;
close $complexityfile_fh;



################################################################################################################
############################################ Documentation #####################################################
################################################################################################################


=head1 NAME


add_concatname_complexity.pl - Script to add a prettified, arbitrary name to MIP complexity QC files.  Will take value from a column named either "mip_name" or "Concatenated_name," match it to the complexity file based on the mip_key and then add an extra column.


=head1 SYNOPSIS


perl B<add_concatname_complexity.pl> I<[options]>


=head1 ARGUMENTS

=over 4

=item B<--designfile> F<design file>

	path to MIP design file; if the design file contains a column "Concatenated_name," then the QC complexity files will have an extra column added with the contents of that column matched to the official mip_name/mipkey value

=item B<--complexityfile> F<string>

	path to the MIP complexity file, which must be tab-delimited and contain a column called mip_key

=item B<--help> 

	print full documentation

=back


=head1 FILES


MIP design file: final output created by MIPGEN v1.0 design pipeline (The header of this file begins with >mip_key)
NOTE: Should have a column named Concatenated_name or mip_name containing the name for each MIP

>mip_key	svr_score	chr	ext_probe_start
13:101707601-101707762/19,26/+	2.21146	13	101707601
13:101707700-101707861/16,29/-	2.28919	13	101707846


=head1 EXAMPLES


perl add_concatname_complexity.pl --designfile PIEZO2_allMIPs.designfile.txt --projectname 2014-02-28-PIEZO2_analysis1

Also see /labdata6/allabs/mips/pipeline_smMIPS_v1.0/examples/


=head1 AUTHOR


Jessica Chong (jxchong@uw.edu, jxchong@gmail.com)


=cut
