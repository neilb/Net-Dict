#
# Net::Dict.pm
#
# Copyright (c) 2006-2013 Helmut Wollmersdorfer <helmut.wollmersdorfer@gmx.at>
# Copyright (C) 2001-2003 Neil Bowers <neil@bowers.com>
# Copyright (c) 1998 Dmitry Rubinstein <dimrub@wisdom.weizmann.ac.il>.
#
# All rights reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
#-----------------------------------------------------------
# changes based on Dict.pm,v 2.7 2003/05/05 23:55:14 neilb
#
# 2006-10-06: Wollmersdorfer
# added methods ldbs, lstrategies which return lists instead of hashes
#
# 2007-05-27: Wollmersdorfer
# removed double quotes from _DEFINE and _MATCH for Serpento
#
# 2007-06-05: Wollmersdorfer
# use _unline() instead of chomp() to remove CRLF at end of line
# cache the results of dbs() and strategies()
#
# 2007-06-07: Wollmersdorfer
# removed autoflush(1), which is default in IO::Socket
#-----------------------------------------------------------

=note

TODO:

nprefix

Like prefix but returns the specified range of matches. For
example, when prefix strategy returns 1000 matches, you can
get only 100 ones skipping the first 800 matches.  This is
made by specified these limits in a query like this:
800#100#app, where 800 is skip count, 100 is a number of
matches you want to get and "app" is your query.  This
strategy allows to implement DICT client with fast
autocompletion (although it is not trivial) just like many
standalone dictionary programs do.

NOTE: If you access the dictionary "*" (or virtual one) with
nprefix strategy, the same range is set for each database in
it, but globally for all matches found in all databases.

NOTE: In case you access non-english dictionary the returned
matches may be (and mostly will be) NOT ordered in alphabetic
order.


=cut

package Net::Dict;

use strict;
use IO::Socket;
use Net::Cmd;
use Carp;

use vars qw(@ISA $debug);
our $VERSION = '2.10';

#-----------------------------------------------------------------------
# Default values for arguments to new(). We also use this to
# determine valid argument names - if it's not a key of this hash,
# then it's not a valid argument.
#-----------------------------------------------------------------------
my %ARG_DEFAULT =
(
 Port    => 2628,
 Timeout => 120,
 Debug   => 0,
 Client  => "Net::Dict v$VERSION",
);

@ISA = qw(Net::Cmd IO::Socket::INET);

#=======================================================================
#
# new()
#
# constructor - open connection to host, get a list of databases,
# and send CLIENT identification command.
#
#=======================================================================
sub new
{
    @_ > 1 or croak 'usage: Net::Dict->new() takes at least a HOST name';
    my $class  = shift;
    my $host   = shift;
    int(@_) % 2 == 0 or croak 'Net::Dict->new(): odd number of arguments';
    my %inargs = @_;

    my $self;
    my $argref;


    return undef unless defined $host;

    #-------------------------------------------------------------------
    # Process arguments, setting defaults if needed
    #-------------------------------------------------------------------
    $argref = {};
    foreach my $arg (keys %ARG_DEFAULT)
    {
        $argref->{$arg} = exists $inargs{$arg}
                          ? $inargs{$arg}
                          : $ARG_DEFAULT{$arg};
        delete $inargs{$arg};
    }
    if (keys(%inargs) > 0)
    {
        croak "Net::Dict->new(): unknown argument - ",
            join(', ', keys %inargs);
    }

    #-------------------------------------------------------------------
    # Make the connection
    #-------------------------------------------------------------------
    $self = $class->SUPER::new(PeerAddr => $host,
                               PeerPort => $argref->{Port},
                               Proto    => 'tcp',
                               Timeout  => $argref->{Timeout}
                               );

    return undef
    	unless defined $self;

    ${*$self}{'net_dict_host'} = $host;

    $self->autoflush(1);
    $self->debug($argref->{Debug});

    if ($self->response() != CMD_OK)
    {
        $self->close();
        return undef;
    }

    # parse the initial 220 response
    $self->_parse_banner($self->message);

    #-------------------------------------------------------------------
    # Send the CLIENT command which identifies the connecting client
    #-------------------------------------------------------------------
    $self->_CLIENT($argref->{Client});

    #-------------------------------------------------------------------
    # The default - search ALL dictionaries
    #-------------------------------------------------------------------
    $self->setDicts('*');

    return $self;
}

sub dbs
{
    @_ == 1 or croak 'usage: $dict->dbs() - takes no arguments';
    my $self = shift;


    $self->_get_database_list();
    return %{${*$self}{'net_dict_dbs'}};
}

sub ldbs
{
    @_ == 1 or croak 'usage: $dict->ldbs()';
    my $self = shift;

    $self->_get_database_list();
    return \@{${*$self}{'net_dict_ldbs'}};
}

sub setDicts
{
    my $self = shift;

    @{${*$self}{'net_dict_userdbs'}} = @_;
}

sub serverInfo
{
    @_ == 1 or croak 'usage: $dict->serverInfo()';
    my $self = shift;

    return 0
        unless $self->_SHOW_SERVER();
    my $info = join('', @{$self->read_until_dot()});
    $self->getline();
    $info;
}

sub dbInfo
{
    @_ == 2 or croak 'usage: $dict->dbInfo($dbname) - one argument only';
    my $self = shift;

    if ($self->_SHOW_INFO(@_))
    {
        return join('', @{$self->read_until_dot()});
    }
    else
    {
        return undef;
    }
}

sub dbTitle
{
    @_ == 2 or croak 'dbTitle() method expects one argument - DB name';
    my $self   = shift;
    my $dbname = shift;


    $self->_get_database_list();
    if (exists ${${*$self}{'net_dict_dbs'}}{$dbname})
    {
        return ${${*$self}{'net_dict_dbs'}}{$dbname};
    }
    else
    {
        carp 'dbTitle(): unknown database name' if $self->debug;
        return undef;
    }
}

sub strategies
{
    @_ == 1 or croak 'usage: $dict->strategies()';
    my $self = shift;

    $self->_get_strategies_list();
    return %{${*$self}{'net_dict_strats'}};
}

sub lstrategies
{
    @_ == 1 or croak 'usage: $dict->lstrategies()';
    my $self = shift;

    $self->_get_strategies_list();
    \@{${*$self}{'net_dict_lstrats'}};
}

sub define
{
    @_ >= 2 or croak 'usage: $dict->define($word [, @dbs]) - takes at least one argument';
    my $self = shift;
    my $word = shift;
    my @dbs = (@_ > 0) ? @_ : @{${*$self}{'net_dict_userdbs'}};
    croak 'select some dictionaries with setDicts or supply as argument to define'
        unless @dbs;
    my($db, @defs);


    #-------------------------------------------------------------------
    # check whether we got an empty word
    #-------------------------------------------------------------------
    if (!defined($word) || $word eq '')
    {
        carp "empty word passed to define() method";
        return undef;
    }

    foreach $db (@dbs)
    {
        next
            unless $self->_DEFINE($db, qq{"$word"});

        my ($defNum) = ($self->message =~ /^\d{3} (\d+) /);
        foreach (0..$defNum-1)
        {
            my ($d) = ($self->getline =~ /^\d{3} ".*" (\w+) /);
            my ($def) = join '', @{$self->read_until_dot()};
            push @defs, [$d, $def];
        }
        $self->getline();
    }
    \@defs;
}

sub match
{
    @_ >= 3 or croak 'usage: $self->match($word, $strat [, @dbs]) - takes at least two arguments';
    my $self = shift;
    my $word = shift;
    my $strat = shift;
    my @dbs = (@_ > 0) ? @_ : @{${*$self}{'net_dict_userdbs'}};
    croak 'define some dictionaries by setDicts or supply as argument to define'
        unless @dbs;
    my ($db, @matches);

    #-------------------------------------------------------------------
    # check whether we got an empty pattern
    #-------------------------------------------------------------------
    if (!defined($word) || $word eq '')
    {
        carp "empty pattern passed to match() method";
        return undef;
    }

    foreach $db (@dbs)
    {
        next unless $self->_MATCH($db, $strat, qq{"$word"});

        my ($db, $w);
        foreach (@{$self->read_until_dot()}) {
            ($db, $w) = split(/\s+/, $_, 2);
            push @matches, [$db, _unquote(_unline($w))];
        }
        $self->getline();
    }
    \@matches;
}

sub auth
{
    @_ == 3 or croak 'usage: $dict->auth() - takes two arguments';
    my $self        = shift;
    my $user        = shift;
    my $pass_phrase = shift;
    my $auth_string;
    my $string;
    my $ctx;


    require Digest::MD5;
    $string = $self->msg_id().$pass_phrase;
    $auth_string = Digest::MD5::md5_hex($string);

    if ($self->_AUTH($user, $auth_string))
    {
        #---------------------------------------------------------------
        # clear the cache of database names
        # next time a method needs them, this will cause us to go
        # back to the server, and thus pick up any AUTH-restricted DBs
        #---------------------------------------------------------------
        delete ${*$self}{'net_dict_dbs'};
    }
    else
    {
        carp "auth() failed with error code ".$self->code() if $self->debug();
        return;
    }
}

sub status
{
    @_ == 1 or croak 'usage: $dict->status() - takes no arguments';
    my $self = shift;
    my $message;


    $self->_STATUS() || return 0;
    chomp($message = $self->message);
    $message =~ s/^\d{3} //;
    return $message;
}

sub capabilities
{
    @_ == 1 or croak 'usage: $dict->capabilities() - takes no arguments';
    my $self = shift;


    return @{ ${*$self}{'net_dict_capabilities'} };
}

sub has_capability
{
    @_ == 2 or croak 'usage: $dict->has_capability() - takes one argument';
    my $self = shift;
    my $cap  = shift;


    return grep(lc($cap) eq $_, $self->capabilities());
}

sub msg_id
{
    @_ == 1 or croak 'usage: $dict->msg_id() - takes no arguments';
    my $self = shift;


    return ${*$self}{'net_dict_msgid'};
}


sub _DEFINE { shift->command('DEFINE', @_)->response() == CMD_INFO }
sub _MATCH { shift->command('MATCH', @_)->response() == CMD_INFO }
sub _SHOW_DB { shift->command('SHOW DB')->response() == CMD_INFO }
sub _SHOW_STRAT { shift->command('SHOW STRAT')->response() == CMD_INFO }
sub _SHOW_INFO { shift->command('SHOW INFO', @_)->response() == CMD_INFO }
sub _SHOW_SERVER { shift->command('SHOW SERVER')->response() == CMD_INFO }
sub _CLIENT { shift->command('CLIENT', @_)->response() == CMD_OK }
sub _STATUS { shift->command('STATUS')->response() == CMD_OK }
sub _HELP { shift->command('HELP')->response() == CMD_INFO }
sub _QUIT { shift->command('QUIT')->response() == CMD_OK }
sub _OPTION_MIME { shift->command('OPTION MIME')->response() == CMD_OK }
sub _AUTH { shift->command('AUTH', @_)->response() == CMD_OK }
sub _SASLAUTH { shift->command('SASLAUTH', @_)->response() == CMD_OK }
sub _SASLRESP { shift->command('SASLRESP', @_)->response() == CMD_OK }

sub quit
{
    my $self = shift;

    $self->_QUIT;
    $self->close;
}

sub DESTROY
{
    my $self = shift;

    if (defined fileno($self)) {
        $self->quit;
    }
}

sub response_text {
    @_ == 1 or croak 'usage: $dict->msg_id() - takes no arguments';
    my $self = shift;

    return ${*$self}{'net_cmd_resp'};
}

sub response
{
    my $self = shift;
    my $str = $self->getline() || return undef;


    if ($self->debug)
    {
        $self->debug_print(0,$str);
    }

    my($code) = ($str =~ /^(\d+) /);

    ${*$self}{'net_cmd_resp'} = [ $str ];
    ${*$self}{'net_cmd_code'} = $code;

    substr($code,0,1);
}

#=======================================================================
#
# _unquote
#
# Private function used to remove quotation marks from around
# a string.
#
#=======================================================================
sub _unquote
{
    my $string = shift;


    if ($string =~ /^"/)
    {
        $string =~ s/^"//;
        $string =~ s/"$//;
    }
    return $string;
}

#=======================================================================
#
# _unline
#
# Private function used to remove line separators at end of string
# NOTE: chomp() cannot be used, it does not conform to RFC
#
#=======================================================================

sub _unline
{
    my $string = shift;
    $string =~ s/[\x0A\x0D]+$//g;
    return $string;
}

#=======================================================================
#
# _parse_banner
#
# Parse the initial response banner the server sends when we connect.
# Hoping for:
#      220 blah blah <auth.mime> <msgid>
# The <auth.mime> string gives a list of supported extensions.
# The last bit is a msg-id, which identifies this connection,
# and is used in authentication, for example.
#
#=======================================================================
sub _parse_banner
{
    my $self   = shift;
    my $banner = shift;
    my ($code, $capstring, $msgid);


    ${*$self}{'net_dict_banner'} = $banner;
    ${*$self}{'net_dict_capabilities'} = [];
    if ($banner =~ /^(\d{3}) (.*) (<[^<>]*>)?\s+(<[^<>]+>)\s*$/)
    {
        ${*$self}{'net_dict_msgid'} = $4;
        ($capstring = $3) =~ s/[<>]//g;
        if (length($capstring) > 0)
        {
            ${*$self}{'net_dict_capabilities'} = [split(/\./, $capstring)];
        }
    }
    else
    {
        carp "unexpected format for welcome banner on connection:\n",
             $banner if $self->debug;
    }
}

#=======================================================================
#
# _get_database_list
#
# Get the list of databases on the remote server.
# We cache them in the instance data object, so that dbTitle()
# and databases() don't have to go to the server every time.
#
# We check to see whether we've already got the databases first,
# and do nothing if so. This means that this private method
# can just be invoked in the public methods.
#
#=======================================================================
sub _get_database_list
{
    my $self = shift;


    return if exists ${*$self}{'net_dict_dbs'};

    if ( $self->_SHOW_DB() ) {
        my($name, $desc);
        @{${*$self}{'net_dict_ldbs'}} = ();
        foreach ( @{$self->read_until_dot()} ) {
            ($name, $desc) = split(/\s+/, $_, 2);
            ${${*$self}{'net_dict_dbs'}}{$name} = _unquote(_unline($desc));
            push @{${*$self}{'net_dict_ldbs'}},
                [$name, _unquote(_unline($desc))];
        }
        $self->getline();
    }
}

#=======================================================================
#
# _get_strategies_list
#
# Get the list of strategies on the remote server.
# We cache them in the instance data object, so that dbTitle()
# and databases() don't have to go to the server every time.
#
# We check to see whether we've already got the strategies first,
# and do nothing if so. This means that this private method
# can just be invoked in the public methods.
#
#=======================================================================
sub _get_strategies_list {
    my $self = shift;

    return if exists ${*$self}{'net_dict_strats'};

    if ( $self->_SHOW_STRAT() ) {
        my($name, $desc);
        @{${*$self}{'net_dict_lstrats'}} = ();
        foreach (@{$self->read_until_dot()})
        {
            ($name, $desc) = split(/\s+/, $_, 2);
            ${${*$self}{'net_dict_strats'}}{$name} = _unquote(_unline($desc));
            push @{${*$self}{'net_dict_lstrats'}},
                    [$name, _unquote(_unline($desc))];
        }
        $self->getline();
    }
}

#-----------------------------------------------------------------------
# Method aliases for backwards compatibility
#-----------------------------------------------------------------------
*strats = \&strategies;

1;

