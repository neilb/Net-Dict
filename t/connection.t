#!./perl
#
#

use Net::Dict;
use lib qw(. ./blib/lib ../blib/lib ./t);
require 'test_host.cfg';

$^W = 1;

my $WARNING;
my %TESTDATA;
my $section;
my @caps;

print "1..17\n";

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
# constructor with no arguments - should result in a die()
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new(); };
if ((not defined $dict) && $@ =~ /takes at least a HOST/)
{
    print "ok 2\n";
}
else
{
    print "not ok 2\n";
}

#-----------------------------------------------------------------------
# pass a hostname of 'undef' we should get undef back
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new(undef); };
if (not defined $dict)
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
eval { $dict = Net::Dict->new(''); };
if (!$@ && not defined $dict && $WARNING =~ /Bad peer address/)
{
    print "ok 4\n";
}
else
{
    print "not ok 4\n";
}

#-----------------------------------------------------------------------
# Ok hostname given, but unknown argument passed.
#	=> return undef
#	=> doesn't die
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($HOST, Foo => 'Bar'); };
if ($@ && !defined $dict && $@ =~ /unknown argument/)
{
    print "ok 5\n";
}
else
{
    print "not ok 5\n";
}

#-----------------------------------------------------------------------
# Ok hostname given, odd number of following arguments passed
#	=> return undef
#	=> doesn't die
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($HOST, 'Foo'); };
if ($@ =~ /odd number of arguments/)
{
    print "ok 6\n";
}
else
{
    print "not ok 6\n";
}

#-----------------------------------------------------------------------
# Ok hostname given, odd number of following arguments passed
#	=> return undef
#	=> doesn't die
#-----------------------------------------------------------------------
$WARNING = undef;
eval { $dict = Net::Dict->new($HOST, Port => $PORT); };
if (!$@ && defined $dict && !defined $WARNING)
{
    print "ok 7\n";
}
else
{
    print "not ok 7\n";
}

#-----------------------------------------------------------------------
# Check the serverinfo string.
# We compare this with what we expect to get from dict.org
# We strip off the first two lines, because they have time-varying
# information; but we make sure they're the lines we think they are.
#-----------------------------------------------------------------------
my $serverinfo = $dict->serverInfo();
if (exists $TESTDATA{serverinfo}
    && defined $serverinfo
    && do { $serverinfo =~ s/^dictd.*?\n//s}
    && do { $serverinfo =~ s/^On dega\.cs\.unc\.edu.*?\n//s}
    && $serverinfo eq $TESTDATA{serverinfo}
   )
{
    print "ok 8\n";
}
else
{
    print STDERR "GOT STRING: \"$serverinfo\"\n";
    print "not ok 8\n";
}

#-----------------------------------------------------------------------
# METHOD: status
# call with an argument - should die since it takes no args.
#-----------------------------------------------------------------------
eval { $string = $dict->status('foo'); };
if ($@
    && $@ =~ /takes no arguments/)
{
    print "ok 9\n";
}
else
{
    print "not ok 9\n";
}

#-----------------------------------------------------------------------
# METHOD: status
# call with no args, and check that the general format of the string
# is what we expect
#-----------------------------------------------------------------------
eval { $string = $dict->status(); };
if (!$@
    && defined $string
    && $string
    && $string =~ m!^status \[d/m/c.*\]$!
   )
{
    print "ok 10\n";
}
else
{
    print "not ok 10\n";
}

#-----------------------------------------------------------------------
# METHOD: capabilities
# call with an arg - doesn't take any, and should die
#-----------------------------------------------------------------------
eval { @caps = $dict->capabilities('foo'); };
if ($@
    && $@ =~ /takes no arguments/
   )
{
    print "ok 11\n";
}
else
{
    print "not ok 11\n";
}

#-----------------------------------------------------------------------
# METHOD: capabilities
#-----------------------------------------------------------------------
if ($dict->can('capabilities')
    && eval { @caps = $dict->capabilities(); }
    && do { $string = join(':', sort(@caps)); 1;}
    && $string
    && $string."\n" eq $TESTDATA{'capabilities'}
   )
{
    print "ok 12\n";
}
else
{
    print "not ok 12\n";
}

#-----------------------------------------------------------------------
# METHOD: has_capability
# no argument passed
#-----------------------------------------------------------------------
if ($dict->can('has_capability')
    && do { eval { $dict->has_capability(); }; 1;}
    && $@
    && $@ =~ /takes one argument/
   )
{
    print "ok 13\n";
}
else
{
    print "not ok 13\n";
}

#-----------------------------------------------------------------------
# METHOD: has_capability
# pass two capability names - should also die()
#-----------------------------------------------------------------------
if ($dict->can('has_capability')
    && do { eval { $dict->has_capability('mime', 'auth'); }; 1; }
    && $@
    && $@ =~ /takes one argument/
   )
{
    print "ok 14\n";
}
else
{
    print "not ok 14\n";
}

#-----------------------------------------------------------------------
# METHOD: has_capability
#-----------------------------------------------------------------------
if ($dict->can('has_capability')
    && $dict->has_capability('mime')
    && $dict->has_capability('auth')
    && !$dict->has_capability('foobar')
   )
{
    print "ok 15\n";
}
else
{
    print "not ok 15\n";
}

#-----------------------------------------------------------------------
# METHOD: msg_id
# with an argument - should cause it to die()
#-----------------------------------------------------------------------
if ($dict->can('msg_id')
    && do { eval { $string = $dict->msg_id('dict.org'); }; 1;}
    && $@
    && $@ =~ /takes no arguments/
   )
{
    print "ok 16\n";
}
else
{
    print "not ok 16\n";
}

#-----------------------------------------------------------------------
# METHOD: msg_id
# with no arguments, should get valid id back, of the form <...>
#-----------------------------------------------------------------------
if ($dict->can('msg_id')
    && do { eval { $string = $dict->msg_id(); }; 1;}
    && !$@
    && defined($string)
    && $string =~ /^<[^<>]+>$/
   )
{
    print "ok 17\n";
}
else
{
    print "not ok 17\n";
}


exit 0;

__DATA__
==== serverinfo ====

Database      Headwords         Index          Data  Uncompressed
elements            130          2 kB         14 kB         45 kB
web1913          185399       3438 kB         11 MB         30 MB
wn               136975       2763 kB       8173 kB         25 MB
gazetteer         52994       1087 kB       1754 kB       8351 kB
jargon             2373         42 kB        619 kB       1427 kB
foldoc            13533        262 kB       2016 kB       4947 kB
easton             3968         64 kB       1077 kB       2648 kB
hitchcock          2619         34 kB         33 kB         85 kB
devils              997         15 kB        161 kB        377 kB
world95             277          5 kB        936 kB       2796 kB
vera               8930        101 kB        154 kB        537 kB
==== capabilities ====
auth:mime
==== END ====
