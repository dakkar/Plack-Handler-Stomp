package Plack::Handler::Stomp;
use Moose;
use List::MoreUtils qw/ uniq /;
use HTTP::Request;
use Net::Stomp;
use MooseX::Types::Moose qw/Bool Str Int HashRef CodeRef/;
use Moose::Util::TypeConstraints 'class_type';
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

    $self->connection($self->connection_builder->({
        hostname => 'localhost',
        port => 61613,
    }));
    $self->connection->connect();
}

1;
