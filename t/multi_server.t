#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Test::Plack::Handler::Stomp;
with 'TestApp';

has t => (
    is => 'rw',
    default => sub { Test::Plack::Handler::Stomp->new() }
);

before run_test => sub {
    my ($self) = @_;

    my $t = $self->t;

    $t->clear_calls_and_queues;
    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing',
        },
        body => 'foo',
    }));
    $t->set_arg(
        subscriptions => [
            {
                destination => '/queue/testing',
                path_info => '/my/path',
            },
        ],
        servers => [
            { hostname => 'first', port => 61613 },
            { hostname => 'second', port => 61613 },
        ],
    );
};

test 'two servers, first one dies on connection' => sub {
    my ($self) = @_;

    my $t = $self->t;

    $t->handler->clear_connection;
    $t->handler->connection->{__fakestomp__callbacks}{connect} = sub {
        my $args = shift;
        $t->queue_connection_call($args);
        die "Can't connect\n"
            if $t->handler->current_server->{hostname} eq 'first';
    };

    $t->handler->run($self->psgi_test_app);
    is($t->connection_calls_count,2,
       'connected twice');
    is($t->subscription_calls_count,1,
       'subscribed once');
    is($t->frames_left_to_receive,0,
       'message consumed');
    is($t->sent_frames_count,1,
       'message ACKed');
};

test 'two servers, first one dies on subscribe' => sub {
    my ($self) = @_;

    my $t = $self->t;

    $t->handler->clear_connection;
    $t->handler->connection->{__fakestomp__callbacks}{subscribe} = sub {
        my $args = shift;
        $t->queue_subscription_call($args);
        die "Can't subscribe\n"
            if $t->handler->current_server->{hostname} eq 'first';
    };

    $t->handler->run($self->psgi_test_app);

    is($t->connection_calls_count,2,
       'connected twice');
    is($t->subscription_calls_count,2,
       'subscribed twice');
    is($t->frames_left_to_receive,0,
       'message consumed');
    is($t->sent_frames_count,1,
       'message ACKed');
};

run_me;
done_testing;
