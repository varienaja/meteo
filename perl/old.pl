#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use CGI;
use File::Slurp;
use Time::Piece;

sub PrintStationLink {
	my $code = $_[0];
	print "<a href='?code=$code'>$code</a>";
}


my $count = 10;
my $q = CGI->new;
my $location = $q->param('code');
if (!$location) { $location="PSI"; }

print $q->header('text/html');
print <<header;
<html>
  <title>Meteo $location</title>
  <body>

<style>
.small {
//  font: 1vw sans-serif;
  fill: black;
  text-anchor: middle;
}
.big {
//  font: 1vw sans-serif;
  fill: black;
  text-anchor: middle;
}
.legend {
  fill: black;
  text-anchor: end;
}

\@media (min-width: 0px) {
  .small {
     display: initial;
  }
  .big {
    display: none;
  }
}

\@media (min-width: 1300px) {
  .small {
     display: none;
  }
  .big {
    display: initial;
  }
}

div {
  float: left;
}
.right {
  width: 45px;
}
.left {
  width: 45px;
}
.middle {
  width: calc(100% - 45px - 45px);
}
</style>



header

my $dbh = DBI->connect("dbi:Pg:dbname=meteo;host=127.0.0.1","meteo","meteo");



# Temperature graphic (TODO nicer!!)
my $query = read_file('/home/varienaja/workspace/meteo/perl/combined_station_measurements2.sql');
my $sth = $dbh->prepare($query);
$sth->bind_param(1, "$location");
my $moment;
my $hh;
my $mm;
my $value;
my $unit;
my $windscale = "";
my $tempscale = "";
$sth->execute();
$sth->bind_columns(\$moment,\$hh,\$mm,\$value,\$unit);
my $t = 50;
$tempscale = $tempscale."<text class=\"legend\" x=40 y=15>\xB0C</text>";
$windscale = $windscale."<text class=\"legend\" x=100% y=15>km/h</text>";
for (my $y=0;$y<230;$y+=30) {
	my $yy = $y+5;
	if ($y>0) {
		$tempscale = $tempscale."<text class=\"legend\" x=\"40\" y=\"$yy\">$t</text>";
		if ($t>=-20) {
			my $windspeed = $t*2+40;
			$windscale = $windscale."<text class=\"legend\" x=\"100%\" y=\"$yy\">$windspeed</text>";
		}
	}
	$t-=10;
}
print '<div class="left"><svg width="100%" height="244">';
print '<rect x=0 y=0 width=100% height=100% fill=lightgray></rect>';
print "$tempscale";
print '</svg></div>';

print '<div class="middle"><svg width=100% height="244">';
print '<rect x=0 y=0 width=100% height=100% fill=lightgray></rect>';
print "<style>rect:hover {stroke: blue}";

print "circle:hover {stroke: red}</style>";

print '<line x1=0% y1=0 x2=0% y2=240 stroke=gray />';
print '<line x1=100% y1=0 x2=100% y2=240 stroke=gray />';
$t = 50;
for (my $y=0;$y<230;$y+=30) {
	print "<line x1=0% y1=$y x2=100% y2=$y stroke=gray />";
}

my $pct = 100 / 24;

$t = 1;
for (my $x=$pct;$x<=100;$x+=$pct) {
	print "<line x1=$x% y1=0 x2=$x% y2=210 stroke=gray />";
	
#	my $hex = sprintf("%X", $t-1);
#	if ($t>12) {
#		$hex = sprintf("%X", $t-13);
#	}
# print "&#x1f55$hex;"
	print "<text class=small x=$x% y=240>$t</text> <text class=\"big\" x=$x% y=240>$t:00</text>";
	$t+=1;
}

my $timestamp;
my $M = 'mm';
my $H = '%';
my $W = 'km/h';
my $R = "W/m\xB2";
my $S = 'min';
my $P = 'hPa';
my $T = "\xB0C";
my $desc = 'desc';
my $icon = 'icon';
my $min = 'min';
my $max = 'max';
my $time = 'min';
my $mintime = 'mintime';
my $maxtime = 'maxtime';
my $minx = 'minx';
my $maxx = 'maxx';
my $sum = 'sum';
my $cnt = 'count';

my %unit2properties = ();
my @spans = ($H, $T, $P, $W, $S, $M, $R);
foreach $unit (@spans) {
	$unit2properties{$unit}{$min} = 10000;
	$unit2properties{$unit}{$mintime} = "";
	$unit2properties{$unit}{$minx} = 0;
	$unit2properties{$unit}{$max} = -10000;
	$unit2properties{$unit}{$maxtime} = "";
	$unit2properties{$unit}{$maxx} = 0;
	$unit2properties{$unit}{$sum} = 0;
	$unit2properties{$unit}{$cnt} = 0;
	$unit2properties{$unit}{'prevx'} = -1;
}

$unit2properties{$M}{$desc} = 'Precipitation'; 
$unit2properties{$M}{$icon} = '&#x1F327;';
$unit2properties{$M}{'offsety'} = 210;
$unit2properties{$M}{'offsetx'} = .166667;
$unit2properties{$M}{'factor'} = 60;
$unit2properties{$M}{'colour'} = "blue";
$unit2properties{$M}{'width'} = ".5%";

$unit2properties{$H}{$desc} = 'Humidity';
$unit2properties{$H}{$icon} = '&#x1f4a7';
$unit2properties{$H}{'x'} = '100%';
$unit2properties{$H}{'offsety'} = 150;
$unit2properties{$H}{'factor'} = 1.5;
$unit2properties{$H}{'colour'} = "deepskyblue";
$unit2properties{$H}{'r'} = 2;
$unit2properties{$H}{'connect'} = 'true';

$unit2properties{$W}{$desc} = 'Wind';
$unit2properties{$W}{$icon} = '&#x1f4a8';
$unit2properties{$W}{'x'} = '100%';
$unit2properties{$W}{'offsety'} = 210;
$unit2properties{$W}{'factor'} = 1.5;
$unit2properties{$W}{'colour'} = "green";
$unit2properties{$W}{'r'} = 3;
$unit2properties{$W}{'connect'} = 'true';

$unit2properties{$R}{$desc} = 'Radiation';
$unit2properties{$R}{$icon} = '&#x1f506';
$unit2properties{$R}{'offsety'} = 0;
$unit2properties{$R}{'offsetx'} = .166667;
$unit2properties{$R}{'factor'} = .12;
$unit2properties{$R}{'colour'} = "orange";
$unit2properties{$R}{'width'} = ".5%";
$unit2properties{$R}{'fixedy'} = '1';
$unit2properties{$R}{'fixedheight'} = 0;

$unit2properties{$S}{$desc} = 'Sunshine';
$unit2properties{$S}{$icon} = '&#x1f31e';
$unit2properties{$S}{'offsety'} = 0;
$unit2properties{$S}{'offsetx'} = .33333;
$unit2properties{$S}{'factor'} = 1/14.4;
$unit2properties{$S}{'colour'} = 'yellow';
$unit2properties{$S}{'fixedy'} = '202';
$unit2properties{$S}{'fixedheight'} = 8;

$unit2properties{$P}{$desc} = 'Pressure';
$unit2properties{$P}{$icon} = '&#x23F2;';
$unit2properties{$P}{'offsety'} = 330;
$unit2properties{$P}{'factor'} = 3/10;
$unit2properties{$P}{'colour'} = "black";
$unit2properties{$P}{'r'} = 2;
$unit2properties{$P}{'connect'} = 'true';

$unit2properties{$T}{$desc} = 'Temperature';
$unit2properties{$T}{$icon} = '&#x1f321';
$unit2properties{$T}{'x'} = '0%';
$unit2properties{$T}{'offsety'} = 150;
$unit2properties{$T}{'factor'} = 3;
$unit2properties{$T}{'colour'} = "red";
$unit2properties{$T}{'r'} = 3;
$unit2properties{$T}{'connect'} = 'true';

my $x = 0;
my $width=10;
while ($sth->fetch()) {
	$timestamp = $mm == 0 ? "$hh:0$mm" : "$hh:$mm";
	$x = $pct*($hh+$mm/60);

	if ($value<$unit2properties{$unit}{$min}) {
		$unit2properties{$unit}{$min} = $value;
		$unit2properties{$unit}{$mintime} = $timestamp;
		$unit2properties{$unit}{$minx} = $x;
	}
	if ($value>$unit2properties{$unit}{$max}) {
		$unit2properties{$unit}{$max} = $value;
		$unit2properties{$unit}{$maxtime} = $timestamp;
		$unit2properties{$unit}{$maxx} = $x;
	}
	$unit2properties{$unit}{$sum} = $unit2properties{$unit}{$sum} + $value;
	$unit2properties{$unit}{$cnt}++;
	if ($mm eq 0) {
		$mm = "00";
	}

	my $v = $unit2properties{$unit}{'factor'} * $value;
	my $y = $unit2properties{$unit}{'fixedy'} ? $unit2properties{$unit}{'fixedy'} : $unit2properties{$unit}{'offsety'}-$v;
	if ($unit2properties{$unit}{'connect'}) {
		print "<circle cx=$x% cy=$y r=$unit2properties{$unit}{'r'} fill=$unit2properties{$unit}{'colour'}><title>$timestamp $value$unit</title></circle>";
		if ($unit2properties{$unit}{'prevx'}>-1) {
			print "<line x1=$unit2properties{$unit}{'prevx'}% y1=$unit2properties{$unit}{'prevy'} x2=$x% y2=$y stroke=$unit2properties{$unit}{'colour'} />";
		}
		$unit2properties{$unit}{'prevx'} = $x;
		$unit2properties{$unit}{'prevy'} = $y;
	} else {
		$x -= $unit2properties{$unit}{'offsetx'};
		print "<rect x=$x% y=$y width=";

		if ($unit2properties{$unit}{'fixedheight'}) {
			print "$v% height=$unit2properties{$unit}{'fixedheight'}";
		} else {
			print "$unit2properties{$unit}{'width'} height=$v";
		}
		print " fill=$unit2properties{$unit}{'colour'}><title>$timestamp $value$unit</title></rect>";
	}
}

# Indicators of min--max at the sides of the image
@spans = ($T, $W, $H);
foreach $unit (@spans) {
	next if ($unit2properties{$unit}{$cnt} == 0); # Don't show rows for units we don't have measurements for

	my $y1 = $unit2properties{$unit}{'offsety'}-$unit2properties{$unit}{'factor'}*$unit2properties{$unit}{$min};
	my $y2 = $unit2properties{$unit}{'offsety'}-$unit2properties{$unit}{'factor'}*$unit2properties{$unit}{$max};
	print "<line x1=$unit2properties{$unit}{'x'} y1=$y1 x2=$unit2properties{$unit}{'x'} y2=$y2 stroke=$unit2properties{$unit}{'colour'} stroke-width=8><title>$unit2properties{$unit}{$desc}: $unit2properties{$unit}{$min}..$unit2properties{$unit}{$max}$unit</title></line>";
}


# Minima and maxima
@spans = ($T, $W, $H, $P, $R);
foreach $unit (@spans) {
	next if ($unit2properties{$unit}{$cnt} == 0); # Don't show rows for units we don't have measurements for

	my $y = $unit2properties{$unit}{'offsety'}-$unit2properties{$unit}{'factor'}*$unit2properties{$unit}{$min};
	print "<text text-anchor=middle font-size=14 x=$unit2properties{$unit}{$minx}% y=225>$unit2properties{$unit}{$icon}<title>Minimum $unit2properties{$unit}{$desc} $unit2properties{$unit}{$min}$unit at $unit2properties{$unit}{$mintime}</title></text>";

	$y = $unit2properties{$unit}{'offsety'}-$unit2properties{$unit}{'factor'}*$unit2properties{$unit}{$max};
	print "<text text-anchor=middle font-size=18 x=$unit2properties{$unit}{$maxx}% y=225>$unit2properties{$unit}{$icon}<title>Maximum $unit2properties{$unit}{$desc} $unit2properties{$unit}{$max}$unit at $unit2properties{$unit}{$maxtime}</title></text>";

#	print "<rect x=$unit2properties{$unit}{$minx}% y=218 width=.5% height=8 fill=$unit2properties{$unit}{'colour'}><title>Minimum $unit2properties{$unit}{$desc} $unit2properties{$unit}{$min}$unit at $unit2properties{$unit}{$mintime}</title></rect>";
#	print "<rect x=$unit2properties{$unit}{$maxx}% y=210 width=.5% height=8 fill=$unit2properties{$unit}{'colour'}><title>Maximum $unit2properties{$unit}{$desc} $unit2properties{$unit}{$max}$unit at $unit2properties{$unit}{$maxtime}</title></rect>";

#$unit2properties{$unit}{$icon}
}
print "</svg></div>";


$sth->finish();

print '<div class="right"><svg width="100%" height="244">';
print '<rect x=0 y=0 width=100% height=100% fill=lightgray></rect>';
print "$windscale";
print '</svg></div>';


# Current station measurements
print "<h2>Measurements in $location on ";
print localtime->strftime('%d-%m-%Y');
print "</h2>";
print "<table>";
print "<tr><th colspan=2>Type</th><th>Time</th><th colspan=2>Minimum</th><th>Time</th><th colspan=2>Maximum</th><th colspan=2>Average</th><th colspan=2>Total</th></tr>";
@spans = ($H, $T, $P, $W, $S, $M, $R);
foreach $unit (@spans) {
	next if ($unit2properties{$unit}{$cnt} == 0); # Don't show rows for units we don't have measurements for
	print "<tr><td align=center>$unit2properties{$unit}{$icon}</td><td>$unit2properties{$unit}{$desc}</td>";
	print "<td align=right>$unit2properties{$unit}{$mintime}</td><td align=right>$unit2properties{$unit}{$min}</td><td align=left>$unit</td>";
	print "<td align=right>$unit2properties{$unit}{$maxtime}</td><td align=right>$unit2properties{$unit}{$max}</td><td align=left>$unit</td>";
	if ($unit eq $M || $unit eq $S) {
		print "<td align=right></td><td align=left></td>";
	} else {
		my $avg = $unit2properties{$unit}{$sum} / $unit2properties{$unit}{$cnt};
		my $avgrounded = sprintf("%.1f", $avg);
		print "<td align=right>$avgrounded</td><td align=left>$unit</td>";
	}
	if ($unit eq $M || $unit eq $S) {
		print "<td align=right>$unit2properties{$unit}{$sum}</td><td align=left>$unit</td>";
	} else {
		print "<td align=right></td><td align=left></td>";
	}
	print "</tr>";
}
print "</table>";

# Extremes
print "<h2>Extremes of today</h2>";
print "<table>";
my $code1;
my $code2;
my $name1;
my $name2;
my $minmoment,
my $maxmoment;
my $minvalue;
my $maxvalue;
my $code;
my $name;
$query = read_file('/home/varienaja/workspace/meteo/perl/extremes.sql');
$sth = $dbh->prepare($query);
$sth->execute();
$sth->bind_columns(\$unit,\$code1,\$name1,\$minmoment,\$minvalue,\$code2,\$name2,\$maxmoment,\$maxvalue);
print "<tr><th colspan=2>Type</th><th colspan=2>Station</th><th>Time</th><th colspan=2>Minimum</th><th colspan=2>Station</th><th>Time</th><th colspan=2>Maximum</th></tr>";
while ($sth->fetch()) {
	my @parts1 = split(' ', $minmoment);
	my @parts2 = split(' ', $maxmoment);
	print "<tr><td align=center>$unit2properties{$unit}{$icon}</td>";
	print "<td>$unit2properties{$unit}{$desc}</td>";
	print "<td>";
	PrintStationLink($code1);
	my $nicetime = substr $parts1[1], 0, -3;
	print "</td><td>$name1</td><td>$nicetime<td align=right>$minvalue</td><td align=left>$unit</td>";
	print "<td>";
	PrintStationLink($code2);
	$nicetime = substr $parts2[1], 0, -3;
	print "</td><td>$name2</td><td>$nicetime<td align=right>$maxvalue</td><td align=left>$unit</td>";
	print "</tr>";
}
print "</table>";
$sth->finish();


# Yesterday's new records
print "<h2>New records since yesterday</h2>";
print "<table>";
$query = read_file('/home/varienaja/workspace/meteo/perl/newrecords.sql');
my $type;
my $age;
$sth = $dbh->prepare($query);
$sth->execute();
$sth->bind_columns(\$code,\$name,\$unit,\$type,\$value,\$age,\$moment);
print "<tr><th colspan=2>Type</th><th colspan=2>Station</th><th>m/m</th><th>Time</th><th colspan=2>Value</th><th>Age</th></tr>";
while ($sth->fetch()) {
	print "<tr><td align=center>$unit2properties{$unit}{$icon}</td><td>$unit2properties{$unit}{'desc'}</td><td>";
	PrintStationLink($code);
	my $nicemoment = substr $moment, 0, -3;
	my $niceage = substr $age, 0, -3;
	print "</td><td>$name</td><td>$type</td><td>$nicemoment</td><td align=right>$value</td><td>$unit</td><td align=right>$niceage</td></tr>";
}
print "</table>";
$sth->finish();



my $rowno = 0;
my $delta;
my $timedelta;
my $mintemp;
my $maxtemp;
$query = read_file('/home/varienaja/workspace/meteo/perl/top.sql');
$sth = $dbh->prepare($query);
$sth->execute();
$sth->bind_columns(\$code,\$name,\$minmoment,\$mintemp,\$maxmoment,\$maxtemp,\$delta,\$timedelta);


# When a temp goes over the previous maximum: show?
# When a temp goes below a previous minimum: show?
# Show nice SVGs for temperature, sunshine, rainfall, humidity, etc. for certain station(s) -> PSI.
#

#Put values into a hash
my %rows = ();

#print "<table>";
while ($sth->fetch()) {
	$rowno++;
	$rows{$rowno}{'code'} = $code;
	$rows{$rowno}{'name'} = $name;
	$rows{$rowno}{'minmoment'} = substr $minmoment, 0, -3;
	$rows{$rowno}{'mintemp'} = 0 + $mintemp;
	$rows{$rowno}{'maxmoment'} = substr $maxmoment, 0, -3;
	$rows{$rowno}{'maxtemp'} = 0 + $maxtemp;
	$rows{$rowno}{'delta'} = 0 + $delta;
	$rows{$rowno}{'timedelta'} = substr $timedelta, 0, -3;
}
$sth->finish();

my %views;
$views{1}{name} = "Lowest $count temperatures";
$views{1}{keys} = [sort { $rows{$a}{'mintemp'} <=> $rows{$b}{'mintemp'} } keys (%rows)];

$views{2}{name} = "Highest $count temperatures";
$views{2}{keys} = [reverse sort { $rows{$a}{'maxtemp'} <=> $rows{$b}{'maxtemp'} } keys (%rows)];

$views{3}{name} = "Biggest $count temperature differences";
$views{3}{keys} = [reverse sort { $rows{$a}{'delta'} <=> $rows{$b}{'delta'} } keys (%rows)];

$views{4}{name} = "Smallest $count temperature differences";
$views{4}{keys} = [sort { $rows{$a}{'delta'} <=> $rows{$b}{'delta'} } keys (%rows)];

print "<table>";
my @ix = (1..4);
for (@ix) {
	$rowno=0;
	print "<td colspan=100%><h2>$views{$_}{name}</h2></td>";
	print "<tr><th>Nr</th><th>Code</th><th>Station</th><th colspan=2>Time and min.</th><th colspan=2>Time and max.</th><th colspan=2>Delta</th></tr>";
	for my $i ( 0 .. length $views{$_}{keys} ) {
		my $key = $views{$_}{keys}[$i];
       		$rowno++;
	        if ($rowno>$count) {
	                last;
	        }
	        print "<tr>";
	        print "<td>$rowno</td>";
        	print "<td>";
		PrintStationLink($rows{$key}{'code'});
        	print "</td>";
	        print "<td>$rows{$key}{'name'}</td>";
		my @parts = split(' ', $rows{$key}{'minmoment'});
        	print "<td align=right>$parts[1]</td>";
	        print "<td align=right>$rows{$key}{'mintemp'}$T</td>";
		@parts = split(' ', $rows{$key}{'maxmoment'});
        	print "<td align=right>$parts[1]</td>";
	        print "<td align=right>$rows{$key}{'maxtemp'}$T</td>";
	        print "<td align=right>$rows{$key}{'timedelta'}</td>";
		my $delta = sprintf("%.1f", $rows{$key}{'delta'});
        	print "<td align=right>$delta$T</td>";
        	print "</tr>";
	}
}
print "</table>";




print <<footer;
  </body>
</html>
footer

$dbh->disconnect();

