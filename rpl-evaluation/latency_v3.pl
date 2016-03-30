#!/usr/bin/perl

#set input file name
$logfile = @ARGV[0];
#set output file name
$latencyresult = @ARGV[1];
$node_number = 63;

#$rowlog = "rowlog.log";
#open ($fh_rowlog,">",$rowlog) or die $!;

#open the original log fiel.
open ($fh_logfile,$logfile) or die$!;
#open the energyresult log file.
open ($fh_latencyresult, ">", $latencyresult) or die $!;

sub calculate_hops {
	$nodenr= $_[0]; $hops= $_[1];
	$nodehops{$nodenr} =  $hops;
}

sub print_hops {
	foreach $key (sort keys %nodehops) {
				$value = $nodehops{$key};
				$averagehops = $averagehops + $value; 
			}
	return ($averagehops / $node_number);
}
sub total_latency {
	$sendtime = $_[0]; $recvtime = $_[1];
	return $totallatency = $totallatency + $recvtime - $sendtime;
}
foreach $line(<$fh_logfile>) {
	if ($line =~ m/(\d+):(\d+):DATA send to 1: seqno: (\d+)/)  { # sending lines
		#$nodenr=$2; $packetnr=$3; $time = $1; # save nodenr,packetnr,time	
		$noSendPackets = $noSendPackets + 1;
	}
	if ($line=~ m/\d+:\d:DATA recv from (\d+):\s*(\d+)\s*\d+\s*(\d+)\s*\d+\s*\d+\s*(\d+),\s*(\d+)/) { #receiving lines
		$nodenr = $1; $seqno = $2; $sendtime = $3; $hops = $4; $recvtime = $5;
		#$row = sprintf "  %u     %u    %u     %u     %u\n",$nodenr, $seqno, $sendtime, $hops,$recvtime;
		#print $fh_rowlog $row;
		calculate_hops($nodenr,$hops);
		$successpacket = $successpacket + 1;
		$totallatency = total_latency($sendtime,$recvtime);
	}
}
$averagehops = print_hops();
$packet_delivery_ratio =  $successpacket / $noSendPackets;
$averagelatency = $totallatency / $successpacket;

printf $fh_latencyresult "Average Latency(ms)". "\t" . "Packet Delivery Ratio". "\t"  . "Success Packets". "\t" . "Average Hops\n";
$row = sprintf "    %.2f                  %.5f                %.5f            %.2f",$averagelatency / 1000, $packet_delivery_ratio,$successpacket, $averagehops;
print $fh_latencyresult  $row;	
close $fh_latencyresult; close $fh_logfile;



