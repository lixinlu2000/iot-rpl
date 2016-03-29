#analysis energy from the cooja powertrace logfile.
#@ARGV[0]:logfile from the cooja simulation.
#@ARGV[1]:output file, caculator the result from log, 
#including the energy consumption in rx,tx,cpu,lpm and the overhead,Radio on Time
#author: xinlu
#2015/11/05

#!/usr/bin/perl

#set input file name
$logfile = @ARGV[0];
#set output file name
$energyresult = @ARGV[1];

use constant RTIMER_SECOND => 32768;

#open the original log fiel.
open ($fh_logfile,$logfile) or die$!;
#open the energyresult log file.
open ($fh_energyresult, ">", $energyresult) or die $!;

#open ($fh_rowlog,">",$rowlog) or die $!;


foreach $line(<$fh_logfile>){
	# 30430435:8: 3848 P 0.18 0 29186 953862 11348 10053 31922172 31172 29186 953862 11348 10053 31922172 31172 (radio 2.17% / 2.17% tx 1.15% / 1.15% listen 1.02% / 1.02%)
	# select the node id and transmit,listen ticks using Perl regex
	if ($line =~ m/\d+:\d+:\w*\s+\d+\s+P\s+\d+\.\d+\s+(\d+\s+){7}(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/) {
		# $2-->cpu, $3-->lpm, $4-->transmit, $5-->listen
		#print $fh_powertace  $line;
		$totalcpu = $totalcpu + $2;
		$totallpm = $totallpm + $3;
		$totalTransmit = $totalTransmit + $4;	
		$totalListen = $totalListen + $5;
		}
}

#caculate the energy consumption of cpu,lpm,tx,rx, example for sky motes.
#Current:cpu:1.8mA,Tx:19.5mA,Rx:21.8mA, lpm:0.0545mA; Voltage:3v

$cpupower = $totalcpu * 1.8 * 3 / RTIMER_SECOND;
$lpmpower = $totallpm * 0.0545 * 3/ RTIMER_SECOND;
$txpower = $totalTransmit * 19.5 / RTIMER_SECOND;
$rxpower = $totalListen * 21.8 / RTIMER_SECOND;
$totalpower = $cpupower + $lpmpower + $txpower + $rxpower;
$radioontime = 100 * ($totalTransmit + $totalListen)/($totalcpu + $totallpm);

#print $cpupower;
#print "\n";
#print $lpmpower;
#print "\n";
#print $txpower;
#print "\n";
#print $rxpower;
#print "\n";
#print $totalpower;
#print "\n";
printf $fh_energyresult "Total_CPU_power". "\t" . "Total_LPM_power" . "\t" . "Radio_TX_power" . "\t" . "Radio_RX_power" . "\t" . "Power_consumption" . "\t". "%Radio ON Time\n";
$row = sprintf "    %.2f         %.2f         %.2f        %.2f        %.2f            %.5f",$cpupower, $lpmpower, $txpower, $rxpower, $totalpower, $radioontime;
print $fh_energyresult  $row;
$rowpercent = sprintf "\n    %.6f        %.6f        %.6f       %.6f       %.6f ",$cpupower / $totalpower, $lpmpower/$totalpower, $txpower/$totalpower, $rxpower/$totalpower, $totalpower/$totalpower;
print $fh_energyresult  $rowpercent;


