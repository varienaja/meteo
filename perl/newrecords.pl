#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use CGI;

my $q = CGI->new;
print $q->header('application/json');

my $dbh = DBI->connect("dbi:Pg:dbname=meteo;host=127.0.0.1","meteo","meteo");
my $query ="
select array_to_json(array_agg(json_build_object('code', code, 'name', name, 'unit', unit, 'type', type, 'recordvalue', recordvalue, 'age', age, 'moment', moment))) from (select code, name, unit, type, case when type='min' then min(recordvalue) else max(recordvalue) end as recordvalue, sum(age) as age, max(moment) as moment from records where moment >= current_date-1 group by code, name, unit, type order by unit, recordvalue desc ) a";
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

