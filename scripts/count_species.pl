#!/usr/local/bin/perl

$ecut = 1e-20;
if($ARGV[1] ne "")
{
	$ecut = $ARGV[1];
}
open(in,$ARGV[0]);
while($line=<in>)
{
	chomp $line;
	@aux = split "\t", $line;
	$spec = $aux[13];
	$allreads{$aux[0]}++;
	if($readused{$aux[0]} eq "" && $aux[10] < $ecut)
	{
		$cnt{$spec}++;
		$readused{$aux[0]}++;
	}
}
close in;

$reads = scalar keys %readused ;
$reads += 1;
$Nallreads = scalar keys %allreads;
$Nallreads += 1;

print "--------------------------------------\n";
print "Table below reports the numbers and percentages\n";
print "of reads with best BLAST hit to a given species\n"; 
print "--------------------------------------\n";
print "Total number of reads with BLAST hits to nt (e-value<$ecut): $reads\n";
print "--------------------------------------\n\n";
print "Read distribution over species:\n\n";
print "Species\t#Reads\t%Reads\n";
print "--------------------------------------\n";
for $spec (reverse sort {$cnt{$a} <=> $cnt{$b}} keys %cnt)
{
	if($cnt{$spec} eq "") { next; }
	$perc = 100*$cnt{$spec}/$reads;
	$perc = sprintf("%.3f",$perc);
	print "$spec\t$cnt{$spec}\t$perc\n";
}
print "-----------------------------------\n";

