#!/usr/local/bin/perl

# Take a fastq file and select $reqseq reads extracted uniformly
# from the whole file

$file=$ARGV[0];
$reqseq=$ARGV[1];
$outformat = lc $ARGV[2]; # may be fastq or fasta

# Count sequences in the file
if($file =~ m/\.gz$/)
{
	$nseq = `gzip -d -c $file | wc -l`;
}
else
{
	$nseq = `wc -l $file`;
}
chomp $nseq;
$nseq /= 4;

$stride = int($nseq/$reqseq);

#print "$reqseq out of $nseq sequences will be selected using stride $stride\n";

if($file =~ m/\.gz/)
{
	open(in,"gzip -d -c $file |");
}
else
{
	open(in,$file);
}
$counter=0;
$countext = 0;
while($line1=<in>)
{
	$line2=<in>;
	$line3=<in>;
	$line4=<in>;

	if($counter % $stride == 0)
	{
		if($outformat eq "fasta")
		{
			$line1 =~ s/\@/>/;
		}
		print $line1;
		print $line2;
		if($outformat eq "fastq")
                {
			print $line3;
			print $line4;
		}
		$countext++;
	}

	$counter++;
}
close in;

#print "$countext sequences extracted\n";
