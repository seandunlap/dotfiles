#!/usr/bin/perl -w
#
# eCommander job submition script for RG and CM builds
#
# Authors: Gurpreet Malhotra
#
# History:
#         version 1.0
# Usage: usage: submitECJob.pl -p [project] -b [branch] -u [user] -jira [jiraID] -accurevId [accurevId] -t [transactionNum] -cloneInfo [cloneInfo] -hostname [hostname] -triggerPoint [pre|post] -VCT [GIT|AccuRev]\n"
#
#######################################

use strict;
use ElectricCommander ();

my $argCtr = $#ARGV;
if ($argCtr < 2) {
	usage();
        exit 1;
}

my $dum="rbbswbld";
my $dumdum="eEXvGP9rfA";
my $prjFlag="N";
my $branchFlag="N";
my $usrFlag="N";
my $jiraIdFlag="N";
my $transFlag="N";
my $acIdFlag="N";
my $cloneInfoFlag="N";
my $hostnameFlag="N";
my $triggerPointFlag="N";
my $VCTFlag="N";
my $project="";
my $branch="";
my $AccuRevId="";
my $cloneInfo="";
my $hostname="";
my $triggerPoint="";
my $VCT="";
my $JiraKey="";
my $user="";
my $transNum="";

foreach (@ARGV) {
	chomp($_);
	if ($prjFlag eq "Y") {
		$project = $_;
		$prjFlag = "N";
	} elsif ($branchFlag eq "Y") {
		$branch = $_;
		$branchFlag = "N";
	} elsif ($usrFlag eq "Y") {
		$user = $_;
		$usrFlag = "N";
	} elsif ($jiraIdFlag eq "Y") {
		$JiraKey = $_;
		$jiraIdFlag = "N";
	} elsif ($acIdFlag eq "Y") {
		$AccuRevId = $_;
		$acIdFlag = "N";
	} elsif ($cloneInfoFlag eq "Y") {
		$cloneInfo = $_;
		$cloneInfoFlag = "N";
	} elsif ($hostnameFlag eq "Y") {
		$hostname = $_;
		$hostnameFlag = "N";
	} elsif ($triggerPointFlag eq "Y") {
		$triggerPoint = $_;
		$triggerPointFlag = "N";
	} elsif ($VCTFlag eq "Y") {
		$VCT= $_;
		$VCTFlag = "N";
	} elsif ($transFlag eq "Y") {
		$transNum = $_;
		$transFlag = "N";
	} else {
		if ($_ eq "-p") {
			$prjFlag="Y";
		} elsif ($_ eq "-b") {
			$branchFlag = "Y";
		} elsif ($_ eq "-u") {
			$usrFlag = "Y";
		} elsif ($_ eq "-jira") {
			$jiraIdFlag = "Y";
		} elsif ($_ eq "-accurevId") {
			$acIdFlag = "Y";
		} elsif ($_ eq "-cloneInfo") {
			$cloneInfoFlag = "Y";
		} elsif ($_ eq "-hostname") {
			$hostnameFlag = "Y";
		} elsif ($_ eq "-triggerPoint") {
			$triggerPointFlag = "Y";
		} elsif ($_ eq "-VCT") {
			$VCTFlag = "Y";
		} elsif ($_ eq "-t") {
			$transFlag = "Y";
		} else {
			print "Invalid options $_\n";
			usage();
			exit 1;
		}
	}
}

#my $ec = new ElectricCommander->new("engsw-irva-03.broadcom.com");
#my $ec = new ElectricCommander->new("ecmdr-irva-01.broadcom.com");
my $ec = new ElectricCommander->new("commander.broadcom.com");

my $procedureName = $project ." sanity";

#print "project->$project\n";
#print "branch->$branch\n";
#print "user->$user\n";
#print "JiraKey->$JiraKey\n";
#print "AccuRevId->$AccuRevId\n";
#print "transNum->$transNum\n";
#print "procedureName->$procedureName\n";

if ($project eq "") {
	print "ERROR: project not defined\n";
	exit 1;
}

if ($JiraKey eq "") {
	print "ERROR: JiraKey not defined\n";
	exit 1;
}


$ec->login($dum, $dumdum);
$ec->saveSessionFile();
#$ec->runProcedure("CABMOD-BCG Common", {procedureName => "$procedureName"});
my $ECTestJobID = $ec->runProcedure("CABMOD_ATL",
                    {
                    procedureName => "$procedureName",
                    priority => 'high',
                    actualParameter => [
                    {actualParameterName => 'baseline', value => "$JiraKey"},
                    {actualParameterName => 'userID', value => "$user"},
                    {actualParameterName => 'buildType', value => "sanity"},
                    {actualParameterName => 'AccuRevId', value => "$AccuRevId"},
                    {actualParameterName => 'TransactionNum', value => "$transNum"},
                    {actualParameterName => 'myProjectName', value => "$project"},
                    {actualParameterName => 'cloneInfo', value => "$cloneInfo"},
                    {actualParameterName => 'hostname', value => "$hostname"},
                    {actualParameterName => 'triggerPoint', value => "$triggerPoint"},
                    {actualParameterName => 'VCT', value => "$VCT"},
                    {actualParameterName => 'branch', value => "$branch"}
]
                    })->findvalue('//jobId');

print "\nEC jobs has been created.";
print "\nEC job id is $ECTestJobID.";
exit 0;

sub usage {
	print "usage: submitECJob.pl -p [project] -b [branch] -u [user] -jira [jiraID] -accurevId [accurevId] -t [transactionNum] -cloneInfo [cloneInfo] -hostname [hostname] -triggerPoint [pre|post] -VCT [GIT|AccuRev]\n";
}
