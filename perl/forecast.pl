#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use HTTP::Tiny;
use JSON;
use Time::Piece;
use File::Slurp;

my $q = CGI->new;
print $q->header('application/json');

my $filename = "/tmp/meteo_forecast_5303_".localtime->strftime('%d-%m-%Y').".json";
unless (-e $filename) { # Download from meteoschweiz.ch at most once per day
	print "ll";
	my $url = "https://www.meteoschweiz.admin.ch/product/output/versions.json";
	my $httpVariable = HTTP::Tiny->new;
	my $response = $httpVariable->get($url);
	my $versionData = "{}";
	if ($response -> {success}) {
		$versionData = $response->{content};
	}
	my $json = from_json($versionData);
	my $fc = $json->{'forecast-chart'};

	my $forecasturl = "https://www.meteoschweiz.admin.ch/product/output/forecast-chart/version__".$fc."/de/530300.json";
	$response = $httpVariable->get($forecasturl);
	
	open(FH, ">", $filename) or die $!;
	if ($response -> {success}) {
		print FH $response->{content};
	} else {
		print FH "{}";
	}
	close(FH);
}

my $content = read_file($filename);
print $content;
