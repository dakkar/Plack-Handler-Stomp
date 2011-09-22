package Plack::Handler::Stomp;
use Moose;
use HTTP::Request;
use Net::Stomp;
use MooseX::Types::Moose qw(Bool Str Value Int ArrayRef HashRef CodeRef);
use Moose::Util::TypeConstraints 'class_type';
use MooseX::Types::Structured qw(Dict Optional Map);
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
        subscribe_headers => Optional[HashRef],
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
sub current_server {
    my ($self) = @_;

    return $self->servers->[-1];
}

has connect_headers => (
    is => 'ro',
    isa => Map[Str,Value],
    lazy => 1,
    builder => '_default_connect_headers',
);
sub _default_connect_headers { { } }

has subscribe_headers => (
    is => 'ro',
    isa => Map[Str,Value],
    lazy => 1,
    builder => '_default_subscribe_headers',
);
sub _default_subscribe_headers { { } }

has subscriptions => (
    is => 'ro',
    isa => ArrayRef[Dict[
        destination => Str,
        headers => Optional[Map[Str,Value]],
    ]],
    lazy => 1,
    builder => '_default_subscriptions',
);
sub _default_subscriptions { [] }

has one_shot => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

sub run {
    my ($self, $app) = @_;

    $self->_connect();
    $self->_subscribe();
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

sub _subscribe {
    my ($self) = @_;

    my %headers = (
        %{$self->subscribe_headers},
        %{$self->current_server->{subscribe_headers} || {}},
    );
    for my $sub (@{$self->subscriptions}) {
        my $destination = $sub->{destination};
        my $more_headers = $sub->{headers} || {};
        $self->connection->subscribe({
            destination => $destination,
            %headers,
            %$more_headers,
            ack => 'client',
        });
    }
}

1;
