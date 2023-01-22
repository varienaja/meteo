#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use CGI;
use File::Slurp;
use Time::Piece;

my $max = 10;

my $q = CGI->new;
print $q->header('text/html');
print <<header;
<html>
  <title>Meteo</title>
  <body>

<style>
.small {
  font: 1vw sans-serif;
  fill: black;
  text-anchor: middle;
}
.big {
  font: 1vw sans-serif;
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

\@media (min-width: 1200px) {
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
  width: 75px;
}
.left {
  width: 55px;
}
.middle {
  width: calc(100% - 75px - 55px);
}
</style>



header

my $dbh = DBI->connect("dbi:Pg:dbname=meteo;host=127.0.0.1","meteo","meteo");



# Temperature graphic (TODO nicer!!)
my $sth = $dbh->prepare("select m.moment, extract(hour from m.moment), extract(minute from m.moment), m.value, s.unit from measurement m, sensor s where m.sensor_id = s.id and s.code='PSI' and m.moment>=current_date order by m.moment");
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
for (my $y=0;$y<230;$y+=30) {
	my $yy = $y+5;
	if ($y>0) {
		$tempscale = $tempscale."<text class=\"legend\" x=\"50\" y=\"$yy\">$t\xB0C</text>";
		if ($t>=0) {
			my $windspeed = $t*2;
			$windscale = $windscale."<text class=\"legend\" x=\"100%\" y=\"$yy\">$windspeed km/h&nbsp;</text>";
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
	print "<text class=small x=$x% y=240>$t</text> <text class=\"big\" x=$x% y=240>$t:00</text>";
	$t+=1;
}

my $x = 0;
my $lx = -1;
my $ly = -1;
my $lwx = -1;
my $lwy = -1;
my $width=10;
my $mintemp = 1000;
my $maxtemp = -1000;
my $minwind = 1000;
my $maxwind = -1000;
while ($sth->fetch()) {
	if ($mm eq 0) {
		$mm = "00";
	}
	$x = $pct*($hh+$mm/60);
	if ($unit eq "km/h" && $value>0) {
		if ($value>$maxwind) {
			$maxwind = $value;
		}
		if ($value<$minwind) {
			$minwind = $value;
		}
		my $v = 1.6667*$value;
		my $y = 150-$v;
		print "<circle cx=$x% cy=$y r=2 fill=green><title>$hh:$mm $value km/h</title></circle>";
		if ($lwx > -1) {
			print "<line x1=$lwx% y1=$lwy x2=$x% y2=$y stroke=green />";
		}
		$lwx = $x;
		$lwy = $y;
	}
	if ($unit eq "mm" && $value>0) {
		my $v = 100*$value;
		my $y = 150-$v;
		$x -= .166667;
		print "<rect x=$x% y=$y width=.5% height=$v fill=blue><title>$hh:$mm $value mm</title></rect>";
	}
	if ($unit eq "W/m\xB2" && $value>5) { # >5 to filter out weird small values
		my $v = $value / 3;
		$x -= .166667;
		print "<rect x=$x% y=0 width=.5% height=$v fill=orange ><title>$hh:$mm $value W/m2</title></rect>";
	}
	if ($unit eq "min" && $value>0) {
		$x -= .33333;
		my $v = $value/14.4;
		print "<rect x=$x% y=202 width=$v% height=8 fill=yellow><title>$hh:$mm $value min</title></rect>";
	}
	if ($unit eq "\xB0C") {
		if ($value>$maxtemp) {
			$maxtemp = $value;
		}
		if ($value<$mintemp) {
			$mintemp = $value;
		}
		my $v = 3.3333*$value;
		my $y = 150-$v;
		print "<circle cx=$x% cy=$y r=3 fill=red ><title>$hh:$mm $value C</title></circle>";
		if ($lx > -1) {
			print "<line x1=$lx% y1=$ly x2=$x% y2=$y stroke=red />";
		}
		$lx = $x;
		$ly = $y;
	} 
}
my $y1 = 150-3.3333*$mintemp;
my $y2 = 150-3.3333*$maxtemp;
print "<line x1=0 y1=$y1 x2=0 y2=$y2 stroke=red stroke-width=8><title>Temperature: $mintemp..$maxtemp</title> </line>";
$y1 = 150-1.67*$minwind;
$y2 = 150-1.67*$maxwind;
print "<line x1=100% y1=$y1 x2=100% y2=$y2 stroke=green stroke-width=8><title>Wind $minwind..$maxwind</title> </line>";
print "</svg></div>";
$sth->finish();

print '<div class="right"><svg width="100%" height="244">';
print '<rect x=0 y=0 width=100% height=100% fill=lightgray></rect>';
print "$windscale";
print '</svg></div>';

my %unit2desc = (
	'mm' => 'Precipitation',
	'%' => 'Humidity',
	'km/h' => 'Wind',
	"W/m\xB2" => 'Radiation',
	'min' => 'Sunshine',
	'hPa' => 'Pressure',
	"\xB0C" => 'Temperature'
);

# Current station measurements
print "<h2>Measurements in PSI on ";
print localtime->strftime('%d-%m-%Y');
print "</h2>";
print "<table>";
my $id;
my $code;
my $name;
my $minvalue;
my $avgvalue;
my $maxvalue;
my $sumvalue;
my $query = read_file('/home/varienaja/workspace/meteo/perl/current_station_measurements.sql');
$sth = $dbh->prepare($query);
$sth->execute();
$sth->bind_columns(\$id,\$code,\$name,\$unit,\$moment,\$value,\$minvalue,\$avgvalue,\$maxvalue,\$sumvalue);
print "<tr><th>Type</th><th>Time</th><th colspan=2>Measurement</th><th colspan=2>Minimum</th><th colspan=2>Maximum</th><th colspan=2>Average</th><th colspan=2>Total</th></tr>";
while ($sth->fetch()) {
	my @parts = split(' ', $moment);
	$avgvalue = sprintf("%.1f", $avgvalue);
	print "<tr><td>$unit2desc{$unit}</td><td>$parts[1]</td><td align=right>$value</td><td align=left>$unit</td>";
	print "<td align=right>$minvalue</td><td align=left>$unit</td>";
	print "<td align=right>$maxvalue</td><td align=left>$unit</td>";
	if ($unit eq "mm" || $unit eq "min") {
		print "<td align=right></td><td align=left></td>";
	} else {
		print "<td align=right>$avgvalue</td><td align=left>$unit</td>";
	}
	if ($unit eq "mm" || $unit eq "min") {
		print "<td align=right>$sumvalue</td><td align=left>$unit</td>";
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
$query = read_file('/home/varienaja/workspace/meteo/perl/extremes.sql');
$sth = $dbh->prepare($query);
$sth->execute();
$sth->bind_columns(\$unit,\$code1,\$name1,\$minmoment,\$minvalue,\$code2,\$name2,\$maxmoment,\$maxvalue);
print "<tr><th>Type</th><th colspan=2>Station</th><th>Time</th><th colspan=2>Minimum</th><th colspan=2>Station</th><th>Time</th><th colspan=2>Maximum</th></tr>";
while ($sth->fetch()) {
	my @parts1 = split(' ', $minmoment);
	my @parts2 = split(' ', $maxmoment);
	print "<tr><td>$unit2desc{$unit}</td>";
	print "<td>$code1</td><td>$name1</td><td>$parts1[1]<td align=right>$minvalue</td><td align=left>$unit</td>";
	print "<td>$code2</td><td>$name2</td><td>$parts2[1]<td align=right>$maxvalue</td><td align=left>$unit</td>";
	print "</tr>";
}
print "</table>";


# Yesterday's new records
print "<h2>New records since yesterday</h2>";
print "<table>";
$query = read_file('/home/varienaja/workspace/meteo/perl/newrecords.sql');
my $type;
my $age;
$sth = $dbh->prepare($query);
$sth->execute();
$sth->bind_columns(\$code,\$name,\$unit,\$type,\$value,\$age,\$moment);
print "<tr><th>Type</th><th colspan=2>Station</th><th>m/m</th><th>Time</th><th colspan=2>Value</th><th>Age</th></tr>";
while ($sth->fetch()) {
#	my @parts = split(' ', $moment);
	print "<tr><td>$unit2desc{$unit}</td><td>$code</td><td>$name</td><td>$type</td><td>$moment</td><td align=right>$value</td><td>$unit</td><td align=right>$age</td></tr>";
}
print "</table>";




my $rowno = 0;
my $delta;
my $timedelta;
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
	$rows{$rowno}{'minmoment'} = $minmoment;
	$rows{$rowno}{'mintemp'} = 0 + $mintemp;
	$rows{$rowno}{'maxmoment'} = $maxmoment;
	$rows{$rowno}{'maxtemp'} = 0 + $maxtemp;
	$rows{$rowno}{'delta'} = 0 + $delta;
	$rows{$rowno}{'timedelta'} = $timedelta;
}
$sth->finish();

my %views;
$views{1}{name} = "Lowest $max temperatures";
$views{1}{keys} = [sort { $rows{$a}{'mintemp'} <=> $rows{$b}{'mintemp'} } keys (%rows)];

$views{2}{name} = "Highest $max temperatures";
$views{2}{keys} = [reverse sort { $rows{$a}{'maxtemp'} <=> $rows{$b}{'maxtemp'} } keys (%rows)];

$views{3}{name} = "Biggest $max temperature differences";
$views{3}{keys} = [reverse sort { $rows{$a}{'delta'} <=> $rows{$b}{'delta'} } keys (%rows)];

$views{4}{name} = "Smallest $max temperature differences";
$views{4}{keys} = [sort { $rows{$a}{'delta'} <=> $rows{$b}{'delta'} } keys (%rows)];

print "<table>";
my @ix = (1..4);
for (@ix) {
	$rowno=0;
	print "<td colspan=100%><h2>$views{$_}{name}</h2></td>";
	print "<tr><th>Nr</th><th>Code</th><th>Station</th><th colspan=2>Time and min. temp.</th><th colspan=2>Time and max. temp.</th><th colspan=2>Delta</th></tr>";
	for my $i ( 0 .. length $views{$_}{keys} ) {
		my $key = $views{$_}{keys}[$i];
       		$rowno++;
	        if ($rowno>$max) {
	                last;
	        }
	        print "<tr>";
	        print "<td>$rowno</td>";
        	print "<td>$rows{$key}{'code'}</td>";
	        print "<td>$rows{$key}{'name'}</td>";
		my @parts = split(' ', $rows{$key}{'minmoment'});
        	print "<td>$parts[1]</td>";
	        print "<td align=right>$rows{$key}{'mintemp'}\xB0C</td>";
		@parts = split(' ', $rows{$key}{'maxmoment'});
        	print "<td>$parts[1]</td>";
	        print "<td align=right>$rows{$key}{'maxtemp'}\xB0C</td>";
	        print "<td align=right>$rows{$key}{'timedelta'}</td>";
        	print "<td align=right>$rows{$key}{'delta'}\xB0C</td>";
        	print "</tr>";
	}
}
print "</table>";




print <<footer;
  </body>
</html>
footer

$dbh->disconnect();
