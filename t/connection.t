#!./perl
#
#

use Net::Dict;
use strict;
$^W = 1;

use Test::More 0.88 tests => 17;

use lib 't/lib';
use Net::Dict::TestConfig qw/ $TEST_HOST $TEST_PORT /;

my $WARNING;
my %TESTDATA;
my $section;
my @caps;
my $description;
my $dict;
my $string;

$SIG{__WARN__} = sub { $WARNING = join('', @_); };

#-----------------------------------------------------------------------
# Build the hash of test data from after the __DATA__ symbol
# at the end of this file
#-----------------------------------------------------------------------
while (<DATA>)
{
    if (/^==== END ====$/) {
        $section = undef;
        next;
    }

    if (/^==== (\S+) ====$/) {
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
ok(defined($TEST_HOST) && defined($TEST_PORT), "have a HOST and PORT defined");

#-----------------------------------------------------------------------
# constructor with no arguments - should result in a die()
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new(); };
ok((not defined $dict) && $@ =~ /takes at least a HOST/,
   "Not passing a DICT server name should croak");

#-----------------------------------------------------------------------
# pass a hostname of 'undef' we should get undef back
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new(undef); };
ok((not defined($dict)),
   "passing undef for hostname should fail");

#-----------------------------------------------------------------------
# pass a hostname of empty string, should get undef back
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new(''); };
ok(!$@ && !defined($dict),
   "Passing an empty hostname should result in undef");

#-----------------------------------------------------------------------
# Ok hostname given, but unknown argument passed.
#	=> return undef
#	=> doesn't die
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($TEST_HOST, Foo => 'Bar'); };
ok($@ && !defined($dict) && $@ =~ /unknown argument/,
   "passing an unknown argument to constructor should croak");

#-----------------------------------------------------------------------
# Ok hostname given, odd number of following arguments passed
#	=> return undef
#	=> doesn't die
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($TEST_HOST, 'Foo'); };
ok($@ =~ /odd number of arguments/,
   "Odd number of arguments after hostname should croak");

#-----------------------------------------------------------------------
# Valid hostname and port - should succeed
#-----------------------------------------------------------------------
$WARNING = undef;
eval { $dict = Net::Dict->new($TEST_HOST, Port => $TEST_PORT); };
ok(!$@ && defined $dict && !defined $WARNING,
   "valid hostname and port to constructor should return object");

#-----------------------------------------------------------------------
# Check the serverinfo string.
# We compare this with what we expect to get from dict.org
# We strip off the first two lines, because they have time-varying
# information; but we make sure they're the lines we think they are.
#-----------------------------------------------------------------------
$description = "check serverinfo string";
my $serverinfo = $dict->serverInfo();
if (exists $TESTDATA{serverinfo}
    && defined($serverinfo)
    && do { $serverinfo =~ s/^dictd.*?\n//s}
    && do { $serverinfo =~ s/^On pan\.alephnull\.com.*?[\n\r]+//s}
   )
{
    is($serverinfo, $TESTDATA{serverinfo}, $description);
}
else {
    fail($description);
}

#-----------------------------------------------------------------------
# METHOD: status
# call with an argument - should die since it takes no args.
#-----------------------------------------------------------------------
eval { $string = $dict->status('foo'); };
ok ($@ && $@ =~ /takes no arguments/,
    "status() with an argument should croak");

#-----------------------------------------------------------------------
# METHOD: status
# call with no args, and check that the general format of the string
# is what we expect
#-----------------------------------------------------------------------
eval { $string = $dict->status(); };
ok(!$@ && defined $string && $string =~ m!^status \[d/m/c.*\]$!,
   "status() with no args should result in a particular format string");

#-----------------------------------------------------------------------
# METHOD: capabilities
# call with an arg - doesn't take any, and should die
#-----------------------------------------------------------------------
eval { @caps = $dict->capabilities('foo'); };
ok($@ && $@ =~ /takes no arguments/,
   "passing an argument when getting capabilities should croak");

#-----------------------------------------------------------------------
# METHOD: capabilities
#-----------------------------------------------------------------------
$description = "capabilities() should return a lit of them";
if ($dict->can('capabilities')
    && eval { @caps = $dict->capabilities(); }
    && !$@
    && @caps > 0
    && do { $string = join(':', sort(@caps)); 1;}
   )
{
    is($string."\n", $TESTDATA{'capabilities'}, $description);
}
else {
    fail($description);
}

#-----------------------------------------------------------------------
# METHOD: has_capability
# no argument passed
#-----------------------------------------------------------------------
ok($dict->can('has_capability')
        && do { eval { $dict->has_capability(); }; 1;}
        && $@
        && $@ =~ /takes one argument/,
   "no argument passed to has_capability() should croak");

#-----------------------------------------------------------------------
# METHOD: has_capability
# pass two capability names - should also die()
#-----------------------------------------------------------------------
ok($dict->can('has_capability')
        && do { eval { $dict->has_capability('mime', 'auth'); }; 1; }
        && $@
        && $@ =~ /takes one argument/,
   "passing to arguments to has_capability() should croak");

#-----------------------------------------------------------------------
# METHOD: has_capability
#-----------------------------------------------------------------------
ok($dict->can('has_capability')
        && $dict->has_capability('mime')
        && $dict->has_capability('auth')
        && !$dict->has_capability('foobar'),
    "check valid use of has_capability()");

#-----------------------------------------------------------------------
# METHOD: msg_id
# with an argument - should cause it to die()
#-----------------------------------------------------------------------
ok($dict->can('msg_id')
        && do { eval { $string = $dict->msg_id('dict.org'); }; 1;}
        && $@
        && $@ =~ /takes no arguments/,
    "Passing an argument to msg_id() should croak");

#-----------------------------------------------------------------------
# METHOD: msg_id
# with no arguments, should get valid id back, of the form <...>
#-----------------------------------------------------------------------
ok($dict->can('msg_id')
    && do { eval { $string = $dict->msg_id(); }; 1;}
    && !$@
    && defined($string)
    && $string =~ /^<[^<>]+>$/,
   "calling msg_id() with no arguments should return id of form <...>");


exit 0;

__DATA__
==== serverinfo ====
Database      Headwords         Index          Data  Uncompressed
gcide              203645       3859 kB         12 MB         38 MB
wn                 147311       3002 kB       9247 kB         29 MB
moby-thes           30263        528 kB         10 MB         28 MB
elements              142          2 kB         17 kB         53 kB
vera                11028        124 kB        195 kB        651 kB
jargon               2314         40 kB        565 kB       1346 kB
foldoc              14861        294 kB       2172 kB       5314 kB
easton               3968         64 kB       1077 kB       2648 kB
hitchcock            2619         34 kB         33 kB         85 kB
bouvier              6797        128 kB       2338 kB       6185 kB
devil                1008         15 kB        161 kB        374 kB
world02               280          5 kB       1543 kB       7172 kB
gaz2k-counties      12875        269 kB        280 kB       1502 kB
gaz2k-places        51361       1006 kB       1711 kB         13 MB
gaz2k-zips          33249        454 kB       2122 kB         15 MB
--exit--                0          0 kB          0 kB          0 kB
eng-swe              5489         76 kB         77 kB        204 kB
nld-eng             22752        377 kB        354 kB       1009 kB
eng-cze            150010       2482 kB       1463 kB       8478 kB
eng-swa              1458         18 kB         11 kB         37 kB
ita-eng              3434         48 kB         36 kB        103 kB
tur-deu               947         12 kB         11 kB         26 kB
nld-fra             16776        270 kB        242 kB        692 kB
lat-eng              2311         31 kB         23 kB         65 kB
eng-fra              8805        129 kB        133 kB        369 kB
deu-fra              8174        120 kB         80 kB        232 kB
eng-hin             25647        419 kB       1062 kB       3274 kB
dan-eng              4003         54 kB         41 kB        107 kB
nld-deu             17230        277 kB        291 kB        807 kB
jpn-deu               458          6 kB          5 kB         12 kB
swa-eng              1554         19 kB         13 kB         43 kB
fra-deu              6120         90 kB        104 kB        268 kB
fra-eng              7837        120 kB        120 kB        322 kB
deu-ita              4460         64 kB         36 kB        107 kB
slo-eng               833         11 kB          9 kB         20 kB
eng-rom               996         14 kB         12 kB         31 kB
hin-eng             32971       1227 kB       1062 kB       3274 kB
spa-eng              4508         66 kB         52 kB        137 kB
eng-lat              3032         40 kB         39 kB        105 kB
por-deu              8300        124 kB        109 kB        292 kB
gla-deu               263          3 kB          3 kB          6 kB
swe-eng              5226         71 kB         51 kB        137 kB
scr-eng               401          6 kB          4 kB         11 kB
deu-nld             12818        200 kB        189 kB        546 kB
ita-deu              2929         40 kB         36 kB         92 kB
fra-nld              9610        152 kB        191 kB        515 kB
afr-deu              3806         52 kB         46 kB        127 kB
ara-eng             83875       1953 kB        662 kB       2383 kB
deu-por              8748        131 kB        105 kB        292 kB
tur-eng            143818       4459 kB       1687 kB       4238 kB
eng-spa              5913         84 kB         83 kB        228 kB
eng-ara             83879       1349 kB        667 kB       2466 kB
eng-rus              1699         23 kB         24 kB         71 kB
wel-eng               734          9 kB          7 kB         17 kB
hun-eng            139942       3346 kB       2240 kB       6612 kB
eng-cro             59211       1220 kB        971 kB       2706 kB
eng-por              9297        137 kB        164 kB        456 kB
world95               277          5 kB        936 kB       2796 kB
eng-wel              1066         13 kB         12 kB         31 kB
cro-eng             79821       1791 kB       1016 kB       2899 kB
lat-deu              1804         24 kB         20 kB         53 kB
por-eng             10404        161 kB        118 kB        323 kB
eng-nld              7720        120 kB        162 kB        450 kB
eng-deu             93284       1710 kB       1386 kB       4351 kB
iri-eng              1191         16 kB         11 kB         28 kB
eng-tur             36597        580 kB       1687 kB       4238 kB
eng-scr               605          7 kB          8 kB         21 kB
eng-iri              1365         17 kB         18 kB         45 kB
cze-eng               494          6 kB          5 kB         11 kB
deu-eng             81696       1623 kB       1379 kB       4603 kB
eng-ita              4521         59 kB         39 kB        123 kB
eng-hun             87964       1848 kB       1808 kB       4845 kB
english                 0          0 kB          0 kB          0 kB
trans                   0          0 kB          0 kB          0 kB
all                     0          0 kB          0 kB          0 kB

==== capabilities ====
auth:mime
==== END ====
