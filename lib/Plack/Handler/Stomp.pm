package Plack::Handler::Stomp;
BEGIN {
  $Plack::Handler::Stomp::VERSION = '0.001_01';
}
BEGIN {
  $Plack::Handler::Stomp::DIST = 'Plack-Handler-Stomp';
}
use Moose;
use HTTP::Request;
use Net::Stomp;
use MooseX::Types::Moose qw(Bool Str Value Int ArrayRef HashRef CodeRef);
use Moose::Util::TypeConstraints 'class_type';
use MooseX::Types::Structured qw(Dict Optional Map);
use namespace::autoclean;
use Try::Tiny;

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
        path_info => Optional[Str],
        headers => Optional[Map[Str,Value]],
    ]],
    lazy => 1,
    builder => '_default_subscriptions',
);
sub _default_subscriptions { [] }

has destination_path_map => (
    is => 'ro',
    isa => Map[Str,Str],
    default => sub { { } },
);

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
        my $frame = $self->connection->receive_frame();
        $self->handle_stomp_frame($app, $frame);

        last if $self->one_shot;
    }
}

sub handle_stomp_frame {
    my ($self, $app, $frame) = @_;

    my $command = $frame->command();
    if ($command eq 'MESSAGE') {
        $self->handle_stomp_message($app, $frame);
    }
    elsif ($command eq 'ERROR') {
        $self->handle_stomp_error($app, $frame);
    }
    else {
        # XXX logging
    }
}

sub handle_stomp_error {
    my ($self, $app, $frame) = @_;

    my $error = $frame->headers->{message};
    warn $error; # XXX logging
}

sub handle_stomp_message {
    my ($self, $app, $frame) = @_;

    my $env = $self->_build_psgi_env($frame);
    my $response = $app->($env);
    $self->connection->ack({ frame => $frame });
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

    my $sub_id = 0;

    for my $sub (@{$self->subscriptions}) {
        my $destination = $sub->{destination};
        my $more_headers = $sub->{headers} || {};
        $self->connection->subscribe({
            destination => $destination,
            %headers,
            %$more_headers,
            id => $sub_id,
            ack => 'client',
        });

        $self->destination_path_map->{$destination} =
        $self->destination_path_map->{"/subscription/$sub_id"} =
            $sub->{path_info} || $destination;

        ++$sub_id;
    }
}

sub _build_psgi_env {
    my ($self, $frame) = @_;

    my $destination = $frame->headers->{destination};
    my $sub_id = $frame->headers->{subscription};

    my $path_info;
    if ($sub_id) { $path_info = $self->destination_path_map->{"/subscription/$sub_id"} };
    $path_info ||= $self->destination_path_map->{$destination};
    $path_info ||= $destination; # should not really be needed

    my $env = {
        # server
        SERVER_NAME => 'localhost',
        SERVER_PORT => 0,
        SERVER_PROTOCOL => 'STOMP',

        # client
        REQUEST_METHOD => 'POST',
        REQUEST_URI => "stomp://localhost$path_info",
        SCRIPT_NAME => '',
        PATH_INFO => $path_info,
        QUERY_STRING => '',

        # broker
        REMOTE_ADDR => $self->current_server->{hostname},

        # http
        HTTP_USER_AGENT => 'Net::Stomp',

        # psgi
        'psgi.version' => [1,0],
        'psgi.url_scheme' => 'http',
        'psgi.multithread' => 0,
        'psgi.multiprocess' => 0,
        'psgi.run_once' => 0,
        'psgi.nonblocking' => 0,
        'psgi.streaming' => 0,
        'psgi.input' => do {
            open my $input, '<', \($frame->body);
            $input;
        },
        'psgi.errors' => do {
            my $foo;
            open my $errors, '>', \$foo; # XXX logging
            $errors;
        },
    };

    if ($frame->headers) {
        for my $header (keys %{$frame->headers}) {
            $env->{"stomp.$header"} = $frame->headers->{$header};
        }
    }

    return $env;
}

1;

__END__
=pod

=head1 NAME

Plack::Handler::Stomp - adapt STOMP to (almost) HTTP, via Plack

=head1 VERSION

version 0.001_01

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

