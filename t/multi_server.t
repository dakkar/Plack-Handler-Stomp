#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
with 'HandlerTester','TestApp';

before run_test => sub {
    my ($self) = @_;

    $self->clear_calls_and_queues;
    $self->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing',
        },
        body => 'foo',
    }));
    $self->set_arg(
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

    $self->handler->clear_connection;
    $self->handler->connection->{__fakestomp__callbacks}{connect} = sub {
        my $args = shift;
        $self->queue_connection_call($args);
        die "Can't connect\n"
            if $self->handler->current_server->{hostname} eq 'first';
    };

    $self->handler->run($self->psgi_test_app);
    is($self->connection_calls_count,2,
       'connected twice');
    is($self->subscription_calls_count,1,
       'subscribed once');
    is($self->frames_left_to_receive,0,
       'message consumed');
    is($self->sent_frames_count,1,
       'message ACKed');
};

test 'two servers, first one dies on subscribe' => sub {
    my ($self) = @_;

    $self->handler->clear_connection;
    $self->handler->connection->{__fakestomp__callbacks}{subscribe} = sub {
        my $args = shift;
        $self->queue_subscription_call($args);
        die "Can't subscribe\n"
            if $self->handler->current_server->{hostname} eq 'first';
    };

    $self->handler->run($self->psgi_test_app);

    is($self->connection_calls_count,2,
       'connected twice');
    is($self->subscription_calls_count,2,
       'subscribed twice');
    is($self->frames_left_to_receive,0,
       'message consumed');
    is($self->sent_frames_count,1,
       'message ACKed');
};

run_me;
done_testing;
