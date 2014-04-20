#!./perl
#
# database.t - Net::Dict testsuite for database related methods
#

use Net::Dict;
use lib 't/lib';
use Net::Dict::TestConfig qw/ $TEST_HOST $TEST_PORT /;

$^W = 1;

my $WARNING;
my %TESTDATA;
my $section;
my $string;
my $dbinfo;

print "1..13\n";

$SIG{__WARN__} = sub { $WARNING = join('', @_); };

#-----------------------------------------------------------------------
# Build the hash of test data from after the __DATA__ symbol
# at the end of this file
#-----------------------------------------------------------------------
while (<DATA>)
{
    if (/^==== END ====$/)
    {
        $section = undef;
        next;
    }

    if (/^==== (\S+) ====$/)
    {
        $section = $1;
        $TESTDATA{$section} = '';
        next;
    }

    next unless defined $section;

    $TESTDATA{$section} .= $_;
}

#-----------------------------------------------------------------------
# Make sure we have HOST and PORT specified
#-----------------------------------------------------------------------
if (defined($TEST_HOST) && defined($TEST_PORT))
{
    print "ok 1\n";
}
else
{
    print "not ok 1\n";
}

#-----------------------------------------------------------------------
# connect to server
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($TEST_HOST, Port => $TEST_PORT); };
if (!$@ && defined $dict)
{
    print "ok 2\n";
}
else
{
    print "not ok 2\n";
}

#-----------------------------------------------------------------------
# call dbs() with an argument - it doesn't take any, and should die
#-----------------------------------------------------------------------
eval { %dbhash = $dict->dbs('foo'); };
if ($@ && $@ =~ /takes no arguments/)
{
    print "ok 3\n";
}
else
{
    print "not ok 3\n";
}

#-----------------------------------------------------------------------
# pass a hostname of empty string, should get undef back
#-----------------------------------------------------------------------
$string = '';
eval { %dbhash = $dict->dbs(); };
if (!$@
    && %dbhash
    && do { foreach my $db (sort keys %dbhash) { $string .= "${db}:$dbhash{$db}\n"; }; 1; }
    && $string eq $TESTDATA{dblist})
{
    print "ok 4\n";
}
else
{
    print STDERR "TEST 4 failed\nExpected:\n$TESTDATA{dblist}\nBut got:\n$string\n";
    print "not ok 4\n";
}

#-----------------------------------------------------------------------
# call dbInfo() method with no arguments
#-----------------------------------------------------------------------
$dbinfo = undef;
eval { $dbinfo = $dict->dbInfo(); };
if ($@ && $@ =~ /one argument only/)
{
    print "ok 5\n";
}
else
{
    print "not ok 5\n";
}

#-----------------------------------------------------------------------
# call dbInfo() method with more than one argument
#-----------------------------------------------------------------------
$dbinfo = undef;
eval { $dbinfo = $dict->dbInfo('wn', 'web1913'); };
if ($@ && $@ =~ /one argument only/)
{
    print "ok 6\n";
}
else
{
    print "not ok 6\n";
}

#-----------------------------------------------------------------------
# call dbInfo() method with one argument, but it's a non-existent DB
#-----------------------------------------------------------------------
$dbinfo = undef;
eval { $dbinfo = $dict->dbInfo('web1651'); };
if (!$@ && !defined($dbinfo))
{
    print "ok 7\n";
}
else
{
    print STDERR "DBINFO: $dbinfo\n" if defined $dbinfo;
    print "not ok 7\n";
}

#-----------------------------------------------------------------------
# get the database info for the wordnet db, and compare with expected
#-----------------------------------------------------------------------
$string = '';
$dbinfo = undef;
eval { $dbinfo = $dict->dbInfo('wn'); };
if (!$@
    && defined($dbinfo)
    && $dbinfo eq $TESTDATA{'dbinfo-wn'})
{
    print "ok 8\n";
}
else
{
    print STDERR "TEST 8 failed\nExpected:\n$TESTDATA{'dbinfo-wn'}\nBut got:\n--------\n$dbinfo\n--------\n";
    print "not ok 8\n";
}

#-----------------------------------------------------------------------
# METHOD: dbTitle
# Call method with no arguments - should result in die()
#-----------------------------------------------------------------------
eval { $string = $dict->dbTitle(); };
if ($@ && $@ =~ /method expects one argument/)
{
    print "ok 9\n";
}
else
{
    print "not ok 9\n";
}

#-----------------------------------------------------------------------
# METHOD: dbTitle
# Call method with too many arguments - should result in die()
#-----------------------------------------------------------------------
eval { $string = $dict->dbTitle('wn', 'foldoc'); };
if ($@ && $@ =~ /method expects one argument/)
{
    print "ok 10\n";
}
else
{
    print "not ok 10\n";
}

#-----------------------------------------------------------------------
# METHOD: dbTitle
# Call method with non-existent DB - should result in undef
#-----------------------------------------------------------------------
$WARNING = '';
eval { $string = $dict->dbTitle('web1651'); };
if (!$@
    && !defined($string)
    && $WARNING eq '')
{
    print "ok 11\n";
}
else
{
    print "not ok 11\n";
}

#-----------------------------------------------------------------------
# METHOD: dbTitle
# Call method with non-existent DB - should result in undef
# We set debug level to 1, should result in a warning message as
# well as undef. The Net::Cmd::debug() line is needed to suppress
# some verbosity from Net::Cmd when we turn on debugging.
# This is done so that the "make test" *looks* clean as well as being clean.
#-----------------------------------------------------------------------
Net::Dict->debug(0);
$dict->debug(1);
$WARNING = '';
eval { $string = $dict->dbTitle('web1651'); };
if (!$@
    && !defined($string)
    && $WARNING =~ /unknown database/)
{
    print "ok 12\n";
}
else
{
    print "not ok 12\n";
}
$dict->debug(0);

#-----------------------------------------------------------------------
# METHOD: dbTitle
# Call method with an OK DB name
#-----------------------------------------------------------------------
eval { $string = $dict->dbTitle('wn'); };
if (!$@
    && defined($string)
    && $string."\n" eq $TESTDATA{'dbtitle-wn'})
{
    print "ok 13\n";
}
else
{
    print STDERR "\ngot back \"$string\"\nwas expexting \"",
        $TESTDATA{'dbtitle-wn'}, "\"\n";
    print "not ok 13\n";
}

exit 0;

__DATA__
==== dblist ====
afr-deu:Afrikaans-German Freedict dictionary
all:All Dictionaries (English-Only and Translating)
ara-eng:Arabic-English FreeDict Dictionary
bouvier:Bouvier's Law Dictionary, Revised 6th Ed (1856)
cro-eng:Croatian-English Freedict Dictionary
cze-eng:Czech-English Freedict dictionary
dan-eng:Danish-English Freedict dictionary
deu-eng:German-English Freedict dictionary
deu-fra:German-French Freedict dictionary
deu-ita:German-Italian Freedict dictionary
deu-nld:German-Dutch Freedict dictionary
deu-por:German-Portuguese Freedict dictionary
devil:The Devil's Dictionary (1881-1906)
easton:Easton's 1897 Bible Dictionary
elements:The Elements (07Nov00)
eng-ara:English-Arabic FreeDict Dictionary
eng-cro:English-Croatian Freedict Dictionary
eng-cze:English-Czech fdicts/FreeDict Dictionary
eng-deu:English-German Freedict dictionary
eng-fra:English-French Freedict dictionary
eng-hin:English-Hindi Freedict Dictionary
eng-hun:unknown
eng-iri:English-Irish Freedict dictionary
eng-ita:English-Italian Freedict dictionary
eng-lat:English-Latin Freedict dictionary
eng-nld:English-Dutch Freedict dictionary
eng-por:English-Portuguese Freedict dictionary
eng-rom:English-Romanian FreeDict dictionary
eng-rus:English-Russian Freedict dictionary
eng-scr:English-Serbo-Croat Freedict dictionary
eng-spa:English-Spanish Freedict dictionary
eng-swa:English-Swahili xFried/FreeDict Dictionary
eng-swe:English-Swedish Freedict dictionary
eng-tur:English-Turkish FreeDict Dictionary
eng-wel:English-Welsh Freedict dictionary
english:English Monolingual Dictionaries
foldoc:The Free On-line Dictionary of Computing (26 July 2010)
fra-deu:French-German Freedict dictionary
fra-eng:French-English Freedict dictionary
fra-nld:French-Dutch Freedict dictionary
gaz2k-counties:U.S. Gazetteer Counties (2000)
gaz2k-places:U.S. Gazetteer Places (2000)
gaz2k-zips:U.S. Gazetteer Zip Code Tabulation Areas (2000)
gcide:The Collaborative International Dictionary of English v.0.48
gla-deu:Scottish Gaelic-German Freedict dictionary
hin-eng:English-Hindi Freedict Dictionary [reverse index]
hitchcock:Hitchcock's Bible Names Dictionary (late 1800's)
hun-eng:unknown
iri-eng:Irish-English Freedict dictionary
ita-deu:Italian-German Freedict dictionary
ita-eng:Italian-English Freedict dictionary
jargon:The Jargon File (version 4.4.7, 29 Dec 2003)
jpn-deu:Japanese-German Freedict dictionary
lat-deu:Latin-German Freedict dictionary
lat-eng:Latin-English Freedict dictionary
moby-thes:Moby Thesaurus II by Grady Ward, 1.0
nld-deu:Dutch-German Freedict dictionary
nld-eng:Dutch-English Freedict dictionary
nld-fra:Dutch-French Freedict dictionary
por-deu:Portuguese-German Freedict dictionary
por-eng:Portuguese-English Freedict dictionary
scr-eng:Serbo-Croat-English Freedict dictionary
slo-eng:Slovak-English Freedict dictionary
spa-eng:Spanish-English Freedict dictionary
swa-eng:Swahili-English xFried/FreeDict Dictionary
swe-eng:Swedish-English Freedict dictionary
trans:Translating Dictionaries
tur-deu:Turkish-German Freedict dictionary
tur-eng:English-Turkish FreeDict Dictionary [reverse index]
vera:V.E.R.A. -- Virtual Entity of Relevant Acronyms (June 2006)
wel-eng:Welsh-English Freedict dictionary
wn:WordNet (r) 3.0 (2006)
world02:CIA World Factbook 2002
world95:The CIA World Factbook (1995)
==== dbtitle-wn ====
WordNet (r) 3.0 (2006)
==== dbinfo-wn ====
============ wn ============
00-database-info
This file was converted from the original database on:
          2010-10-06T15:55:24

The original data is available from:
     ftp://ftp.cogsci.princeton.edu/pub/wordnet/2.0

The original data was distributed with the notice shown below. No
additional restrictions are claimed.  Please redistribute this changed
version under the same conditions and restriction that apply to the
original version.


This software and database is being provided to you, the LICENSEE, by  
Princeton University under the following license.  By obtaining, using  
and/or copying this software and database, you agree that you have  
read, understood, and will comply with these terms and conditions.:  

Permission to use, copy, modify and distribute this software and  
database and its documentation for any purpose and without fee or  
royalty is hereby granted, provided that you agree to comply with  
the following copyright notice and statements, including the disclaimer,  
and that the same appear on ALL copies of the software, database and  
documentation, including modifications that you make for internal  
use or for distribution.  

WordNet 3.0 Copyright 2006 by Princeton University.  All rights reserved.  

THIS SOFTWARE AND DATABASE IS PROVIDED "AS IS" AND PRINCETON  
UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR  
IMPLIED.  BY WAY OF EXAMPLE, BUT NOT LIMITATION, PRINCETON  
UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES OF MERCHANT-  
ABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE  
OF THE LICENSED SOFTWARE, DATABASE OR DOCUMENTATION WILL NOT  
INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR  
OTHER RIGHTS.  

The name of Princeton University or Princeton may not be used in  
advertising or publicity pertaining to distribution of the software  
and/or database.  Title to copyright in this software, database and  
any associated documentation shall at all times remain with  
Princeton University and LICENSEE agrees to preserve same.  


==== END ====
