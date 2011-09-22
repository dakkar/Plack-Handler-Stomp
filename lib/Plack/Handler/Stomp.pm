package Plack::Handler::Stomp;
use Moose;
use List::MoreUtils qw/ uniq /;
use HTTP::Request;
use Net::Stomp;
use MooseX::Types::Moose qw/Bool Str Int ArrayRef HashRef CodeRef/;
use Moose::Util::TypeConstraints 'class_type';
use MooseX::Types::Structured qw(Dict Optional);
use namespace::autoclean;
use Encode;

# ABSTRACT: adapt STOMP to (almost) HTTP, via Plack

has connection => (
    is => 'rw',
    isa => class_type('Net::Stomp'),
);

has connection_builder => (
    is => 'rw',
    isa => CodeRef,
    default => sub { sub { Net::Stomp->new($_[0]) } },
);

has servers => (
    is => 'ro',
    isa => ArrayRef[Dict[
        hostname => Str,
        port => Int,
        connect_headers => Optional[HashRef],
    ]],
    lazy => 1,
    builder => '_default_servers',
    traits => ['Array'],
    handles => {
        _shift_servers => 'shift',
        _push_servers => 'push',
    },
);
sub _default_servers {
    [ { hostname => 'localhost', port => 61613 } ]
};
sub next_server {
    my ($self) = @_;

    my $ret = $self->_shift_servers;
    $self->_push_servers($ret);
    return $ret;
}

has connect_headers => (
    is => 'ro',
    isa => HashRef,
    lazy => 1,
    builder => '_default_connect_headers',
);
sub _default_connect_headers { { } }

has one_shot => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

sub run {
    my ($self, $app) = @_;

    $self->_connect();
    while (1) {
        last if $self->one_shot;
    }
}

sub _connect {
    my ($self) = @_;

    my $server = $self->next_server;

    $self->connection($self->connection_builder->({
        hostname => $server->{hostname},
        port => $server->{port},
    }));

    my %headers = (
        %{$self->connect_headers},
        %{$server->{connect_headers} || {}},
    );
    $self->connection->connect(\%headers);
}

1;
