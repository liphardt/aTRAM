#!/usr/bin/perl
use strict;
use File::Temp qw/ tempfile /;
use Module::Load;
load Assembler;

# Assembler modules need to know:
	# where to find the short reads (pass this in as a file name)
	# what the assembly parameters are. (pass this in as a hash)
# Assembler modules should return a file name for the resulting contigs.

package Trinity;

# perl ~/packages/trinityrnaseq_r20131110/Trinity.pl --seqType fa --single Pop_delt_psbA_atpA.1.blast.fasta --run_as_paired --JM 10G
sub assembler {
	my $self = shift;
	my $short_read_file = shift;
	my $params = shift;
	my $log_fh = shift;

	my ($saveout, $saveerr);

	print "hey, I found " . Assembler->find_bin("Trinity.pl");
	open $saveout, ">&STDOUT";
	open $saveerr, ">&STDERR";
	open STDOUT, '>', File::Spec->devnull();
	open STDERR, '>', File::Spec->devnull();

	my ($kmer, $tempdir, $longreads, $ins_length, $exp_cov, $min_contig_len) = 0;
	if ((ref $params) =~ /HASH/) {
        if (exists $params->{"jm"}) {
			$kmer = $params->{"jm"};
		}
		if (exists $params->{"tempdir"}) {
			$tempdir = $params->{"tempdir"};
		}
		if (exists $params->{"longreads"}) {
			$longreads = $params->{"longreads"};
		}
	}
	# using Trinity.pl
	print "\tassembling with Trinity...\n";
	if ($longreads != 0) {
		Assembler->system_call ("velveth $tempdir $kmer -fasta -shortPaired $short_read_file -long $longreads", $log_fh);
	} else {
		Assembler->system_call ("velveth $tempdir $kmer -fasta -shortPaired $short_read_file", $log_fh);
	}
	Assembler->system_call ("velvetg $tempdir -ins_length $ins_length -exp_cov $exp_cov -min_contig_lgth $min_contig_len", $log_fh);

	open STDOUT, ">&", $saveout;
	open STDERR, ">&", $saveerr;

	return "$tempdir/contigs.fa";
}

sub rename_contigs {
	my $self = shift;
	my $contigfile = shift;
	my $renamefile = shift;
	my $prefix = shift;

	if ($prefix) {
		$prefix = "$prefix.";
	} else {
		$prefix = "";
	}

	open FH, "<", $contigfile;
	open OUTFH, ">", $renamefile;
	while (my $line = readline FH) {
		if ($line =~ /^>/) {
			#NODE_41_length_2668_cov_4.901050
			$line =~ s/^>NODE_(\d+)_length_(\d+)_cov_(\d+\.\d).*$/>$prefix$1_len_$2_cov_$3/;
		}
		print OUTFH $line;
	}
}

sub system_call {
	my $cmd = shift;
	my $log_fh = shift;

	unless ($log_fh) {
		$log_fh = &STDOUT;
	}

	print $log_fh ("\t$cmd\n");
	my $exit_val = eval {
		system ($cmd);
	};

	if ($exit_val != 0) {
		print "System call \"$cmd\" exited with $exit_val\n";
		exit;
	}

	return $exit_val;
}


return 1;
