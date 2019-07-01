#!/usr/bin/perl -w
#
# GIT sanity check script
#
# Authors: Gurpreet Malhotra
#
# History:
#         version 1.0
# Usage: sanity_check.pl -commitId <git_commit_id>
#
#######################################
# Parameter:
#  -commitId <Git_commit_id> -force
#


# GLOBAL CONFIGURABLE OPTIONS
#
use Data::Dumper;
use Cwd;
use DBI;
use DBD::mysql;
use warnings;


my $git_branch = undef;
my $userId = undef;
my $commitId = undef;
my $git="/tools/bin/git";
my $bin="/tools/brcmutils/";

my $argCtr = $#ARGV;
#print "$argCtr\n";

#if (($argCtr ne -1) and (argCtr ne 1)) {
if (($argCtr ne "-1") && ($argCtr ne "1") && ($argCtr ne "2")) {
	usage();
	exit 1;
}

my $commitIdFlag="N";
my $commmitId="";
my $forceFlag="N";

foreach (@ARGV) {
	chomp($_);
	if ($commitIdFlag eq "Y") {
		$commitId=$_;
		$commitIdFlag="N";
	} else {
		if ($_ eq "-commitId") {
			$commitIdFlag = "Y";
		} elsif ($_ eq "-force") {
			$forceFlag = "Y";
		} else {
			print "Invalid options $_\n";
			usage();
		}
	}
}

#Checking for git repository directory by looking into branch name
my $cmd="$git rev-parse --abbrev-ref HEAD";
$git_branch=`$cmd`;
rValCheck($cmd);
chomp($git_branch);
#print "git_branch-$git_branch\n";

#Looking for pending commits in git
if (! $commitId) {
	$cmd="$git log --grep=\"refs #\" origin/$git_branch..$git_branch --pretty=format:%H\\|%aE\\|%b";

} else {
#	$cmd="$git log --grep=\"refs #\" origin/$git_branch..$git_branch --pretty=format:%H\\|%aE\\|%b | grep \"^$commitId\"";
	$cmd="$git log --grep=\"refs #\" --pretty=format:%H\\|%aE\\|%b | grep \"^$commitId\"";
}
#print "$cmd\n";
my @commitAry=`$cmd`;
rValCheck($cmd);
#print "commitAry-@commitAry\n";

if (! @commitAry) {
	print "There are no commits in this clone to process.\n";
	exit;
}

#Getting clone root directory
$cmd="$git rev-parse --show-toplevel";
#print "$cmd\n";
my $cRoot=`$cmd`;
chomp($cRoot);
#print "cRoot-$cRoot\n";
my @ary=split(/\//, $cRoot);
my $rDir=pop(@ary);
chomp($rDir);
if ($rDir!~m/linux|rg_apps|aeolus|tools/) {
#	print "In root dir\n";
	$cloneInfo="$cRoot";
} else {
	chdir "$cRoot/.." or die "Couldn't change dir: [$cRoot/..] ($!)";
	system("pwd");
	$cloneInfo=`pwd`;
	chomp($cloneInfo);
}
my $gitCheckDir="$cloneInfo" . "/\.git";
#print "gitCheckDir-$gitCheckDir\n";
if (! -e $gitCheckDir) {
	print "ERROR: Not a git repository $cloneInfo.\n";
	exit 1;
}
#print "cloneInfo-$cloneInfo\n";

#my $cloneInfo=`pwd`;
chomp($cloneInfo);
my $triggerPoint="pre-commit";
my $VCT="GIT";

foreach(@commitAry) {
	chomp($_);
	$_=~s/\@/\|/g;
	print ("$_\n");
	my($commitId,$userId,$hostname,$JiraId) = split(/\|/,$_);
	$hostname=`hostname -A`;
	chomp($hostname);
	chomp($commitId);
	chomp($userId);
	chomp($JiraId);
	$JiraId=~s/refs #//g;

	# Looking for commitId in database.
	my $rows=dbCommitLookUp($commitId);
	if ($rows gt 0) {
		if ($forceFlag eq "N") {
			print "ERROR: Database entry already exist for $commitId\n";
			print "       Please user -force to re-submit this commitId again.\n";
			usage();
		} else {
			print "Database entry already exist for $commitId\n";
			print "Will re-submit this commitId again.\n";
		}
	}

#	print "commitId-$commitId\n";
#	print "userId-$userId\n";
#	print "hostname-$hostname\n";
#	print "JiraId-$JiraId\n";
	if ($JiraId eq "") {
		print "ERROR: Unable to get retrive JiraId from comments.\n";
		print "\tPlease make sure your have refs #<JiraId> formated corectly in commit comments.\n";
		usage();
	}
	if ($git_branch eq "develop") {
		my $project=$git_branch;
		my $cmd="/tools/ecloud/commander/bin/ec-perl $bin/submitECJob.pl -p $project -b $git_branch -jira $JiraId -u $userId -accurevId 0 -t $commitId -cloneInfo $cloneInfo -hostname $hostname -triggerPoint $triggerPoint -VCT $VCT -b $git_branch";
		print "$cmd\n";
		system("$cmd");

	#	my $project="develop-3390";
	#	my $cmd="/tools/ecloud/commander/bin/ec-perl $bin/submitECJob.pl -p $project -b $git_branch -jira $JiraId -u $userId -accurevId 0 -t $commitId -cloneInfo $cloneInfo -hostname $hostname -triggerPoint $triggerPoint -VCT $VCT -b $git_branch";
	#	print "$cmd\n";
	#	system("$cmd");
	#	$project="develop-3384";
	#	$cmd="/tools/ecloud/commander/bin/ec-perl $bin/submitECJob.pl -p $project -b $git_branch -jira $JiraId -u $userId -accurevId 0 -t $commitId -cloneInfo $cloneInfo -hostname $hostname -triggerPoint $triggerPoint -VCT $VCT -b $git_branch";
	#	print "$cmd\n";
	#	system("$cmd");
	}
}
exit 0;

sub dbCommitLookUp {
	my $commit=shift(@_);
	chomp($commit);
	my $database = "rbbu_sanity";
	my $host = "www-atl-03.atl.broadcom.com";
	my $user = "rbbu_sanity";
	my $userp = "br0adc0M";
	my $port = 3324;
	chomp ($database, $host, $user, $userp, $port);

	my $dbh = DBI->connect("DBI:mysql:database=$database;host=$host;port=$port",$user,$userp) or die "Cannot connect to MySQL server\n";
	my $query = "select count(*) from sanity_check where commitNum='$commit'";
	my $sqlQuery  = $dbh->prepare($query) or die "Can't prepare $query: $dbh->errstr\n";
	my $rv=$sqlQuery->execute or die "can't execute the query: $sqlQuery->errstr";
	my @record=$sqlQuery->fetchrow_array;
	my $count=$record[0];
	chomp($count);
#	print "record->$count\n";
	$rv = $sqlQuery->finish;
	return($count);
}

sub usage {
        print "usage: sanityCheck.pl -commitId <git_commit_id> -force\n";
	exit 1;
}

sub rValCheck {
        my $command=shift(@_);
        my $rVal;
        $rVal=$?;
        chomp($rVal);
	if ($rVal ne "0") {
		print "rVal-$rVal\n";
	}
        if ($rVal ne 0) {
                print "ERROR:$command failed.\n";
		print "Make sure you are in GIT repository.\n";
		print "Make sure you have Jira Id refs in commit comment.\n";
		print "Make sure commit id is valid.\n";
                exit 1;
        }
}

sub pause {
	print "Press enter to continue..\n";
	my $repl=<STDIN>;
}
