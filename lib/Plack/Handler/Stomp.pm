package Plack::Handler::Stomp;
use Moose;
use HTTP::Request;
use Net::Stomp;
use MooseX::Types::Moose qw(Bool CodeRef);
use Plack::Handler::Stomp::Types qw(NetStompish Logger
                                    ServerConfigList
                                    SubscriptionConfigList
                                    Headers
                                    PathMap
                               );
use Plack::Handler::Stomp::PathInfoMunger 'munge_path_info';
use MooseX::Types::Common::Numeric qw(PositiveInt);
use Plack::Handler::Stomp::Exceptions;
use namespace::autoclean;
use Try::Tiny;
use Plack::Util;

# ABSTRACT: adapt STOMP to (almost) HTTP, via Plack

=head1 DESCRIPTION

Sometimes you want to use your very nice web-application-framework
dispatcher, module loading mechanisms, etc, but you're not really
writing a web application, you're writing a ActiveMQ consumer. In
those cases, this module is for you.

This module is inspired by L<Catalyst::Engine::Stomp>, but aims to be
usable by any PSGI application.

=cut

has logger => (
    is => 'rw',
    isa => Logger,
    lazy_build => 1,
);
sub _build_logger {
    require Plack::Handler::Stomp::StupidLogger;
    Plack::Handler::Stomp::StupidLogger->new();
}

has connection => (
    is => 'rw',
    isa => NetStompish,
    lazy_build => 1,
);

has connection_builder => (
    is => 'rw',
    isa => CodeRef,
    default => sub { sub { Net::Stomp->new($_[0]) } },
);

has servers => (
    is => 'ro',
    isa => ServerConfigList,
    lazy => 1,
    coerce => 1,
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

has tries_per_server => (
    is => 'ro',
    isa => PositiveInt,
    default => 1,
);
has connect_retry_delay => (
    is => 'ro',
    isa => PositiveInt,
    default => 15,
);

has connect_headers => (
    is => 'ro',
    isa => Headers,
    lazy => 1,
    builder => '_default_connect_headers',
);
sub _default_connect_headers { { } }

has subscribe_headers => (
    is => 'ro',
    isa => Headers,
    lazy => 1,
    builder => '_default_subscribe_headers',
);
sub _default_subscribe_headers { { } }

has subscriptions => (
    is => 'ro',
    isa => SubscriptionConfigList,
    coerce => 1,
    lazy => 1,
    builder => '_default_subscriptions',
);
sub _default_subscriptions { [] }

has destination_path_map => (
    is => 'ro',
    isa => PathMap,
    default => sub { { } },
);

has one_shot => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

sub run {
    my ($self, $app) = @_;

    SERVER_LOOP:
    while (1) {
        my $exception;
        try {
            $self->_connect();
            $self->_subscribe();

            FRAME_LOOP:
            while (1) {
                my $frame = $self->connection->receive_frame();
                $self->handle_stomp_frame($app, $frame);

                Plack::Handler::Stomp::Exceptions::OneShot->throw()
                      if $self->one_shot;
            }
        } catch {
            $exception = $_;
        };
        if ($exception) {
            if (!blessed $exception) {
                die "unhandled exception $exception";
            }
            if ($exception->isa('Plack::Handler::Stomp::Exceptions::AppError')) {
                die $exception;
            }
            if ($exception->isa('Plack::Handler::Stomp::Exceptions::Stomp')) {
                $self->clear_connection;
                next SERVER_LOOP;
            }
            if ($exception->isa('Plack::Handler::Stomp::Exceptions::OneShot')) {
                last SERVER_LOOP;
            }
            if ($exception->isa('Plack::Handler::Stomp::Exceptions::UnknownFrame')) {
                die $exception;
            }
        }
    }
}

sub handle_stomp_frame {
    my ($self, $app, $frame) = @_;

    my $command = $frame->command();
    my $method = $self->can("handle_stomp_\L$command");
    if ($method) {
        $self->$method($app, $frame);
    }
    else {
        Plack::Handler::Stomp::Exceptions::UnknownFrame->throw(
            {frame=>$frame}
        );
    }
}

sub handle_stomp_error {
    my ($self, $app, $frame) = @_;

    my $error = $frame->headers->{message};
    $self->logger->warn($error);
}

sub handle_stomp_message {
    my ($self, $app, $frame) = @_;

    my $env = $self->_build_psgi_env($frame);
    try {
        my $response = $app->($env);

        $self->maybe_send_reply($response);

        $self->connection->ack({ frame => $frame });
    } catch {
        Plack::Handler::Stomp::Exceptions::AppError->throw({
            app_error => $_
        });
    };
}

sub handle_stomp_receipt {
    my ($self, $app, $frame) = @_;

    $self->logger->debug('ignored RECEIPT frame for '
                             .$frame->headers->{'receipt-id'});
}

sub maybe_send_reply {
    my ($self, $response) = @_;

    my $reply_to = $self->where_should_send_reply($response);
    if ($reply_to) {
        $self->send_reply($response,$reply_to);
    }

    return;
}

sub where_should_send_reply {
    my ($self, $response) = @_;

    return Plack::Util::header_get($response->[1],
                                   'X-STOMP-Reply-Address');
}

sub send_reply {
    my ($self, $response, $reply_address) = @_;

    my $reply_queue = '/remote-temp-queue/' . $reply_address;

    my $content = '';
    unless (Plack::Util::status_with_no_entity_body($response->[0])) {
        Plack::Util::foreach($response->[2],
                             sub{$content.=shift});
    }

    my %reply_hh = ();
    while (my ($k,$v) = splice @{$response->[1]},0,2) {
        $k=lc($k);
        next if $k eq 'x-stomp-reply-address';
        next unless $k =~ s{^x-stomp-}{};

        $reply_hh{lc($k)} = $v;
    }

    $self->connection->send({
        %reply_hh,
        destination => $reply_queue,
        body => $content
    });

    return;
}

sub _build_connection {
    my ($self) = @_;

    my $server = $self->next_server;

    return $self->connection_builder->({
        hostname => $server->{hostname},
        port => $server->{port},
    });
}

sub _connect {
    my ($self) = @_;

    try {
        # the connection will be created by the lazy builder
        $self->connection; # needed to make sure that 'current_server'
                           # is the right one
        my $server = $self->current_server;
        my %headers = (
            %{$self->connect_headers},
            %{$server->{connect_headers} || {}},
        );
        $self->connection->connect(\%headers);
    } catch {
        Plack::Handler::Stomp::Exceptions::Stomp->throw({
            stomp_error => $_
        });
    };
}

sub _subscribe {
    my ($self) = @_;

    my %headers = (
        %{$self->subscribe_headers},
        %{$self->current_server->{subscribe_headers} || {}},
    );

    my $sub_id = 0;

    try {
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
    } catch {
        Plack::Handler::Stomp::Exceptions::Stomp->throw({
            stomp_error => $_
        });
    };
}

sub _build_psgi_env {
    my ($self, $frame) = @_;

    my $destination = $frame->headers->{destination};
    my $sub_id = $frame->headers->{subscription};

    my $path_info;
    if (defined $sub_id) {
        $path_info = $self->destination_path_map->{"/subscription/$sub_id"}
    };
    $path_info ||= $self->destination_path_map->{$destination};
    if ($path_info) {
        $path_info = munge_path_info(
            $path_info,
            $self->current_server,
            $frame,
        );
    }
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
        'psgi.errors' => Plack::Util::inline_object(
            print => sub { $self->logger->error(@_) },
        ),
    };

    if ($frame->headers) {
        for my $header (keys %{$frame->headers}) {
            $env->{"stomp.$header"} = $frame->headers->{$header};
        }
    }

    return $env;
}

1;
