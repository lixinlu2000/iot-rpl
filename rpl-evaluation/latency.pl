#!/usr/bin/perl

#set input file name
$logfile = @ARGV[0];
#set output file name
$latencyresult = @ARGV[1];
$node_number = 50;

#$rowlog = "rowlog.log";
#open ($fh_rowlog,">",$rowlog) or die $!;

#open the original log fiel.
open ($fh_logfile,$logfile) or die$!;
#open the energyresult log file.
open ($fh_latencyresult, ">", $latencyresult) or die $!;


#---------------------------------------------------------------------------
# Network Latency outer block
{ 
	my $num = 0;
	sub saveSendTime {
		 # save nodenr,packetnr,time
		 $nodenr= $_[0]; $packetnr= $_[1]; $time = $_[2];
		 if (exists  $send{$nodenr}) {
		 	$send{$nodenr}->{$packetnr} = $time; # if the element exists in send hash then add it to the 2nd hash only
		 } else {
		 	$send{$nodenr}= {$packetnr => $time}; # if the element does not exist in send hash, then add to both hashes 
		 }	
	}

	sub printLostPackets {
		# $num = keys %send; printf "num of keys: " . $num . "\n";
		foreach $out (sort keys %send) {
			# printf "node: $out \n";
			foreach $key ( sort keys %{$send{$out}}) {
#				printf "node: $out packet: $key time: $send{$out}{$key}\n";
				$lostpackets = $lostpackets + 1;
			}
		}
		printf 
		return $lostpackets;
	}
	
	sub lookupSendTime {
		$nodenr= $_[0]; $packetnr= $_[1];  $time = $_[2];
		# look
		if (exists $send{$nodenr}{$packetnr}) { 
			$sendTime = $send{$nodenr}{$packetnr}; # for compute latency
			delete($send{$nodenr}{$packetnr}); # if matches then delete, no need to keep it any more
			return($sendTime);
		}
		return(-1);
	}
	sub saveHops {
		$nodenr= $_[0]; $hops= $_[1];
		$totoalhop{$nodenr} = $hops;
		}
	
	sub printAverageHops {
		foreach $key (sort keys %totoalhop) {
				$value = $totoalhop{$key};
				$averagehops = $averagehops + $value; 
			}
		return ($averagehops / $node_number);
		}
} # end of outer block

# General Idea: when we send the DATA we save node, seqno/packetnr, time to a table 'send'
# when we recv DATA we simply lookup send table and find the sendTime and then computes latency
# and delete that entry from send table, at the end printing send table gives lost packets
# 82074417:13:DATA send to 1 'Hello 1'
# 83095403:1:DATA recv 'Hello 1 from the client' from 13 hops 2 datalen 23

foreach $line(<$fh_logfile>){	
	if ($line =~ m/(\d+):(\d+):DATA send to 1 'Hello (\d+)'/)  { # sending lines
		#print $fh_rowlog  $line;
		$nodenr=$2; $packetnr=$3; $time = $1; # save nodenr,packetnr,time	
		#print $fh_rowlog $time;
		#print $fh_rowlog "\n";
		$noSendPackets = $noSendPackets + 1;
		saveSendTime($nodenr, $packetnr, $time ); # save this sending time of each packet to the hash %send
		} else { # line can be either sending or receiving
		# 91178334:1:DATA recv 'Hello 1 from the client' from 41 hops 3 datalen 23
		# m/(\d+):\d:DATA recv 'Hello (\d+) from the client' from (\d+) hops (\d+)/
		# 473605933:1:DATA recv from 4 'Hello 7'
			#if ($line=~ m/(\d+):\d+:DATA recv from (\d+) 'Hello (\d+)'/) {
			if ($line=~ m/(\d+):\d:DATA recv 'Hello (\d+) from the client' from (\d+) hops (\d+)/) {
				#print $fh_rowlog  $line;
				$nodenr=$3; $packetnr=$2; $time = $1; $hops = $4;# save nodenr,packetnr,time, hops
				
				saveHops($nodenr,$hops);
				
				# check if send table has a corresponding sendTime, if yes then calculate latency
				$sendTime = lookupSendTime($nodenr, $packetnr,$time);
				if ( $sendTime > -1) { # we have a match in sendTable
#					# printf "latency for node:$nodenr, packet:$packetnr = %d\n", $time - $sendTime;
					$counter = $counter + 1;
					$totalLatency = $totalLatency + ($time - $sendTime);
				}
			} 
		}
	} # end of foreach

# print loss packets
$lostpackets = printLostPackets();
$averagehops = printAverageHops();

#latency and packet delivery ratio average hops
$average_latency = $totalLatency / $counter;  #us 
$packet_delivery_ratio =  ($noSendPackets - $lostpackets) / $noSendPackets;
$successPackets = $noSendPackets - $lostpackets;

printf $fh_latencyresult "Average Latency(s)". "\t" . "Packet Delivery Ratio". "\t"  . "Success Packets". "\t" . "Average Hops\n";
$row = sprintf "    %.2f                  %.5f                %.5f            %.2f",$average_latency / 1000000, $packet_delivery_ratio,$successPackets, $averagehops;
print $fh_latencyresult  $row;	
close $fh_latencyresult; close $fh_logfile;

