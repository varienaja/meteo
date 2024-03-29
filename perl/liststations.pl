#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use CGI;

my $q = CGI->new;
print $q->header('application/json');

my $dbh = DBI->connect("dbi:Pg:dbname=meteo;host=127.0.0.1","meteo","meteo");
my $query ="
select array_to_json(array_agg(json_build_object('code', code, 'name', name))) from (select distinct code, name from sensor where name <> 'dummy' order by name) a";
my $sth = $dbh->prepare($query);
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

