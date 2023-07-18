#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use CGI;
use File::Slurp;

my $q = CGI->new;
my $location = $q->param('code');
my $id = $q->param('id');
if (!$id) {
	$id = 0;
}
print $q->header('application/json');

my $dbh = DBI->connect("dbi:Pg:dbname=meteo;host=127.0.0.1","meteo","meteo");
my $query = read_file('/home/varienaja/workspace/meteo/perl/combined_station_measurements.sql');
# my $query ="select array_to_json(array_agg(json_build_object('id', m.id, 'sensor_id', s.id, 'code', s.code, 'value', m.value, 'unit', s.unit, 'hh', extract(hour from m.moment), 'mm', extract(minute from m.moment) ))) from measurement m, sensor s where s.id=m.sensor_id and m.moment>=current_date and m.id>?";
if ($location) {
	$query = $query =~ s/where moment>=current_date/where moment>=current_date and sensor_id in (select id from sensor where code = ?)/r;
}

my $sth = $dbh->prepare($query);
if ($location) {
	$sth->bind_param(1, "$location");
	$sth->bind_param(2, "$id");
} else {
	$sth->bind_param(1, "$id");
}
my $xx;
$sth->execute();
$sth->bind_columns(\$xx);
if ($sth->fetch()) {
	print "$xx";
} else {
	print "[]";
}
$sth->finish();
$dbh->disconnect();

