#!./perl
#
# define.t - Net::Dict testsuite for define() method
#

use Net::Dict;
use lib qw(. ./blib/lib ../blib/lib ./t);
require 'test_host.cfg';

$^W = 1;

my $WARNING;
my %TESTDATA;
my $defref;
my $section;
my $string;
my $dbinfo;

print "1..16\n";

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
# call define() with no arguments - should die
#-----------------------------------------------------------------------
eval { $defref = $dict->define(); };
if ($@ && $@ =~ /takes at least one argument/)
{
    print "ok 3\n";
}
else
{
    print "not ok 3\n";
}

#-----------------------------------------------------------------------
# try and get a definition of something which won't have a definition
# note: at this point we're using the default of '*' for dicts - ie all
#-----------------------------------------------------------------------
eval { $defref = $dict->define('asdfghijkl'); };
if (!$@
    && defined $defref
    && int(@{$defref}) == 0)
{
    print "ok 4\n";
}
else
{
    print "not ok 4\n";
}

#-----------------------------------------------------------------------
# METHOD: define
# get definitions for biscuit, using the default of '*' for DBs
#-----------------------------------------------------------------------
$string = '';
eval { $defref = $dict->define('biscuit'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $entry->[1] =~ s/\r//sg;
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    }
    && $string eq $TESTDATA{'*-biscuit'})
{
    print "ok 5\n";
}
else
{
    print STDERR "\nresult is \"$string\", expected \"",
        $TESTDATA{'*-biscuit'}, "\"\n";
    print "not ok 5\n";
}

#-----------------------------------------------------------------------
# METHOD: define
# get definitions for biscuit, having set user dbs to (), and not
# giving any as args - should croak
#-----------------------------------------------------------------------
$dict->setDicts();
eval { $defref = $dict->define('biscuit'); };
if ($@
    && $@ =~ /select some dictionaries/)
{
    print "ok 6\n";
}
else
{
    print "not ok 6\n";
}

#-----------------------------------------------------------------------
# METHOD: define
# get definitions for biscuit, specifying '*' explicitly for dicts
#-----------------------------------------------------------------------
$string = '';
eval { $defref = $dict->define('biscuit', '*'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $entry->[1] =~ s/\r//sg;
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    }
    && $string eq $TESTDATA{'*-biscuit'})
{
    print "ok 7\n";
}
else
{
    print STDERR "\nresult is \"$string\", expected \"",
        $TESTDATA{'*-biscuit'}, "\"\n";
    print "not ok 7\n";
}

#-----------------------------------------------------------------------
# METHOD: define
# get definitions for biscuit, specifying '!' explicitly for dicts
#-----------------------------------------------------------------------
$string = '';
eval { $defref = $dict->define('biscuit', '!'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    }
    && $string eq $TESTDATA{'!-biscuit'})
{
    print "ok 8\n";
}
else
{
    print STDERR "\nresult is \"$string\", expected \"",
        $TESTDATA{'!-biscuit'}, "\"\n";
    print "not ok 8\n";
}

#-----------------------------------------------------------------------
# METHOD: define
# get definition for noun phrase (more than one word, separated
# by spaces), specifying all dicts ('*')
#-----------------------------------------------------------------------
$string = '';
eval { $defref = $dict->define('antispasmodic agent', '*'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    }
    && $string eq $TESTDATA{'*-antispasmodic_agent'})
{
    print "ok 9\n";
}
else
{
    print STDERR "\nresult is \"$string\", expected \"",
        $TESTDATA{'*-antispasmodic_agent'}, "\"\n";
    print "not ok 9\n";
}

#-----------------------------------------------------------------------
# METHOD: define
# get definition a soemthing containing an apostrophe ("ko'd")
# specifying all dicts ('*')
#-----------------------------------------------------------------------
$string = '';
eval { $defref = $dict->define("ko'd", '*'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    }
    && $string eq $TESTDATA{'*-kod'})
{
    print "ok 10\n";
}
else
{
    print STDERR "\nresult is \"$string\", expected \"",
        $TESTDATA{'*-kod'}, "\"\n";
    print "not ok 10\n";
}

#-----------------------------------------------------------------------
# METHOD: define
# get definition of something with apostrophe and a space.
# specifying all dicts ('*')
#-----------------------------------------------------------------------
$string = '';
eval { $defref = $dict->define("oboe d'amore", '*'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    }
    && $string eq $TESTDATA{'*-oboe_damore'})
{
    print "ok 11\n";
}
else
{
    print STDERR "\nresult is \"$string\", expected \"",
        $TESTDATA{'*-oboe_damore'}, "\"\n";
    print "not ok 11\n";
}

#-----------------------------------------------------------------------
# METHOD: define
# Very long entry, which also happens to have multiple spaces
#-----------------------------------------------------------------------
$string = '';
eval { $defref = $dict->define("Pityrogramma calomelanos aureoflava", '*'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    }
    && $string eq $TESTDATA{'*-pityrogramma_calomelanos_aureoflava'})
{
    print "ok 12\n";
}
else
{
    print STDERR "\nresult is \"$string\", expected \"",
        $TESTDATA{'*-pityrogramma_calomelanos_aureoflava'}, "\"\n";
    print "not ok 12\n";
}

#-----------------------------------------------------------------------
# METHOD: define
# Valid word, invalid dbname - should return no entries
#-----------------------------------------------------------------------
eval { $defref = $dict->define('banana', 'web1651'); };
if (!$@
    && defined($defref)
    && int(@{$defref}) == 0)
{
    print "ok 13\n";
}
else
{
    print "not ok 13\n";
}

#-----------------------------------------------------------------------
# METHOD: define
# Call setDicts to select web1913, but then explicitly specify
# "wn" as the dictionary to search when calling define.
# the word ("banana") is in both dictionaries, but we should only
# get the definition for wn
#-----------------------------------------------------------------------
$string = '';
$dict->setDicts('web1913');
eval { $defref = $dict->define('banana', 'wn'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    }
    && $string eq $TESTDATA{'wn-banana'})
{
    print "ok 14\n";
}
else
{
    print STDERR "\nresult is \"$string\", expected \"",
        $TESTDATA{'wn-banana'}, "\"\n";
    print "not ok 14\n";
}

#-----------------------------------------------------------------------
# METHOD: define
# Call define, passing undef for the word, and '*' for dicts
#-----------------------------------------------------------------------
$WARNING = '';
eval { $defref = $dict->define(undef, '*'); };
if (!$@
    && !defined($defref)
    && $WARNING =~ /empty word passed to define/)
{
    print "ok 15\n";
}
else
{
    print "not ok 15\n";
}

#-----------------------------------------------------------------------
# METHOD: define
# Call define, passing empty string for the word, and '*' for dicts
#-----------------------------------------------------------------------
$WARNING = '';
eval { $defref = $dict->define('', '*'); };
if (!$@
    && !defined($defref)
    && $WARNING =~ /empty word passed to define/)
{
    print "ok 16\n";
}
else
{
    print "not ok 16\n";
}


exit 0;

__DATA__
==== *-biscuit ====

52 Moby Thesaurus words for "biscuit":
   Brussels biscuit, Melba toast, adobe, bisque, bone, bowl, brick,
   brownie, cement, ceramic ware, ceramics, china, cookie, cracker,
   crock, crockery, date bar, dust, enamelware, firebrick, fruit bar,
   ginger snap, gingerbread man, glass, graham cracker, hardtack, jug,
   ladyfinger, macaroon, mummy, parchment, pilot biscuit, porcelain,
   pot, pottery, pretzel, refractory, rusk, saltine, sea biscuit,
   ship biscuit, shortbread, sinker, soda cracker, stick,
   sugar cookie, tile, tiling, urn, vase, wafer, zwieback


gcide
Biscuit \Bis"cuit\, n. [F. biscuit (cf. It. biscotto, Sp.
   bizcocho, Pg. biscouto), fr. L. bis twice + coctus, p. p. of
   coquere to cook, bake. See {Cook}, and cf. {Bisque} a kind of
   porcelain.]
   1. A kind of unraised bread, of many varieties, plain, sweet,
      or fancy, formed into flat cakes, and bakes hard; as, ship
      biscuit.
      [1913 Webster]

            According to military practice, the bread or biscuit
            of the Romans was twice prepared in the oven.
                                                  --Gibbon.
      [1913 Webster]

   2. A small loaf or cake of bread, raised and shortened, or
      made light with soda or baking powder. Usually a number
      are baked in the same pan, forming a sheet or card.
      [1913 Webster]

   3. Earthen ware or porcelain which has undergone the first
      baking, before it is subjected to the glazing.
      [1913 Webster]

   4. (Sculp.) A species of white, unglazed porcelain, in which
      vases, figures, and groups are formed in miniature.
      [1913 Webster]

   {Meat biscuit}, an alimentary preparation consisting of
      matters extracted from meat by boiling, or of meat ground
      fine and combined with flour, so as to form biscuits.
      [1913 Webster]
wn
biscuit
    n 1: small round bread leavened with baking-powder or soda
    2: any of various small flat sweet cakes (`biscuit' is the
       British term) [syn: {cookie}, {cooky}, {biscuit}]
==== !-biscuit ====
gcide
Biscuit \Bis"cuit\, n. [F. biscuit (cf. It. biscotto, Sp.
   bizcocho, Pg. biscouto), fr. L. bis twice + coctus, p. p. of
   coquere to cook, bake. See {Cook}, and cf. {Bisque} a kind of
   porcelain.]
   1. A kind of unraised bread, of many varieties, plain, sweet,
      or fancy, formed into flat cakes, and bakes hard; as, ship
      biscuit.
      [1913 Webster]

            According to military practice, the bread or biscuit
            of the Romans was twice prepared in the oven.
                                                  --Gibbon.
      [1913 Webster]

   2. A small loaf or cake of bread, raised and shortened, or
      made light with soda or baking powder. Usually a number
      are baked in the same pan, forming a sheet or card.
      [1913 Webster]

   3. Earthen ware or porcelain which has undergone the first
      baking, before it is subjected to the glazing.
      [1913 Webster]

   4. (Sculp.) A species of white, unglazed porcelain, in which
      vases, figures, and groups are formed in miniature.
      [1913 Webster]

   {Meat biscuit}, an alimentary preparation consisting of
      matters extracted from meat by boiling, or of meat ground
      fine and combined with flour, so as to form biscuits.
      [1913 Webster]
==== *-antispasmodic_agent ====
wn
antispasmodic agent
    n 1: a drug used to relieve or prevent spasms (especially of the
         smooth muscles) [syn: {antispasmodic}, {spasmolytic},
         {antispasmodic agent}]
==== *-oboe_damore ====
gcide
Oboe \O"boe\, n. [It., fr. F. hautbois. See {Hautboy}.] (Mus.)
   One of the higher wind instruments in the modern orchestra,
   yet of great antiquity, having a penetrating pastoral quality
   of tone, somewhat like the clarinet in form, but more
   slender, and sounded by means of a double reed; a hautboy.
   [1913 Webster]

   {Oboe d'amore} [It., lit., oboe of love], and {Oboe di
   caccia} [It., lit., oboe of the chase], are names of obsolete
      modifications of the oboe, often found in the scores of
      Bach and Handel.
      [1913 Webster]
wn
oboe d'amore
    n 1: an oboe pitched a minor third lower than the ordinary oboe;
         used to perform baroque music
==== *-kod ====
gcide
KO \KO\ v. t. [imp. & p. p. {KO'd}; p. pr. & vb. n. {KO'ing}.]
   To knock out; to deliver a blow that renders (the opponent)
   unconscious; -- used especially in boxing. [acronym]

   Syn: knockout.
        [WordNet 1.5]
gcide
KO'd \KO'd\ adj. [from {KO}, v. t.]
   rendered unconscious, usually by a blow.

   Syn: knocked out(predicate), kayoed, out(predicate), stunned.
        [WordNet 1.5]
wn
KO'd
    adj 1: knocked unconscious by a heavy blow [syn: {knocked
           out(p)}, {kayoed}, {KO'd}, {out(p)}, {stunned}]
==== *-pityrogramma_calomelanos_aureoflava ====
wn
Pityrogramma calomelanos aureoflava
    n 1: tropical American fern having fronds with light golden
         undersides [syn: {golden fern}, {Pityrogramma calomelanos
         aureoflava}]
==== wn-banana ====
wn
banana
    n 1: any of several tropical and subtropical treelike herbs of
         the genus Musa having a terminal crown of large entire
         leaves and usually bearing hanging clusters of elongated
         fruits [syn: {banana}, {banana tree}]
    2: elongated crescent-shaped yellow fruit with soft sweet flesh
==== END ====
