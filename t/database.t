#!./perl
#
# database.t - Net::Dict testsuite for database related methods
#

use Net::Dict;
use lib qw(. ./blib/lib ../blib/lib ./t);
require 'test_host.cfg';

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
if (defined($HOST) && defined($PORT))
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
eval { $dict = Net::Dict->new($HOST, Port => $PORT); };
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
    && defined %dbhash
    && do { foreach my $db (sort keys %dbhash) { $string .= "${db}:$dbhash{$db}\n"; }; 1; }
    && $string eq $TESTDATA{dblist})
{
    print "ok 4\n";
}
else
{
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
devils:THE DEVIL'S DICTIONARY ((C)1911 Released April 15 1993)
easton:Easton's 1897 Bible Dictionary
elements:Elements database 20001107
foldoc:The Free On-line Dictionary of Computing (09 FEB 02)
gazetteer:U.S. Gazetteer (1990)
hitchcock:Hitchcock's Bible Names Dictionary (late 1800's)
jargon:Jargon File (4.3.0, 30 APR 2001)
vera:V.E.R.A. -- Virtual Entity of Relevant Acronyms December 2001
web1913:Webster's Revised Unabridged Dictionary (1913)
wn:WordNet (r) 1.7
world95:The CIA World Factbook (1995)
==== dbtitle-wn ====
WordNet (r) 1.7
==== dbinfo-wn ====
00-database-info
     This file was converted from the original database on:
                Sat Jun 23 14:21:23 2001

      
      The original data is available from:
         http://www.cogsci.princeton.edu/~wn/
      
      The original data was distributed with the notice shown
      below.  No additional restrictions are claimed.  Please
      redistribute this changed version under the same conditions
      and restriction that apply to the original version.
      
         This software and database is being provided to you, the
         LICENSEE, by Princeton University under the following
         license.  By obtaining, using and/or copying this
         software and database, you agree that you have read,
         understood, and will comply with these terms and
         conditions.:
         
         Permission to use, copy, modify and distribute this
         software and database and its documentation for any
         purpose and without fee or royalty is hereby granted,
         provided that you agree to comply with the following
         copyright notice and statements, including the
         disclaimer, and that the same appear on ALL copies of the
         software, database and documentation, including
         modifications that you make for internal use or for
         distribution.
         
         WordNet 1.7 Copyright 2001 by Princeton University.  All
         rights reserved.
         
         THIS SOFTWARE AND DATABASE IS PROVIDED "AS IS" AND
         PRINCETON UNIVERSITY MAKES NO REPRESENTATIONS OR
         WARRANTIES, EXPRESS OR IMPLIED.  BY WAY OF EXAMPLE, BUT
         NOT LIMITATION, PRINCETON UNIVERSITY MAKES NO
         REPRESENTATIONS OR WARRANTIES OF MERCHANT- ABILITY OR
         FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE OF THE
         LICENSED SOFTWARE, DATABASE OR DOCUMENTATION WILL NOT
         INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS
         OR OTHER RIGHTS.
         
         The name of Princeton University or Princeton may not be
         used in advertising or publicity pertaining to
         distribution of the software and/or database.  Title to
         copyright in this software, database and any associated
         documentation shall at all times remain with Princeton
         University and LICENSEE agrees to preserve same.

==== END ====
