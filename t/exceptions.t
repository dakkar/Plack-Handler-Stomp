#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
with 'HandlerTester','TestApp';

test 'unknown frames' => sub {
    my ($self) = @_;

    $self->clear_frames_to_receive;
    $self->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'WRONG',
        headers => { },
        body => 'boom',
    }));
    $self->set_arg(
        subscriptions => [
            {
                destination => '/queue/testing',
                path_info => '/my/path',
            },
        ],
    );

    my $exception = exception {
        $self->handler->run($self->psgi_test_app)
    };
    isa_ok($exception,'Plack::Handler::Stomp::Exceptions::UnknownFrame',
           'correct exception thrown');
    is($exception->frame->command,'WRONG',
       'frame reported');
};

test 'app error' => sub {
    my ($self) = @_;

    $self->clear_calls_and_queues;
    $self->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing',
        },
        body => 'die now',
    }));

    my $exception = exception {
        $self->handler->run($self->psgi_test_app)
    };
    isa_ok($exception,'Plack::Handler::Stomp::Exceptions::AppError',
           'correct exception thrown');
    is($exception->previous_exception,"I died\n",
       'exception was saved');
    is($self->sent_frames_count,0,
       'the message was not ACKed');
};

test 'stomp error on connect' => sub {
    my ($self) = @_;

    $self->clear_calls_and_queues;
    $self->handler->clear_connection;
    $self->handler->connection->{__fakestomp__callbacks}{connect} = sub {
        die "Can't connect\n";
    };

    my $exception = exception {
        $self->handler->run($self->psgi_test_app)
    };
    isa_ok($exception,'Plack::Handler::Stomp::Exceptions::Stomp',
           'correct exception thrown');
    is($exception->previous_exception,"Can't connect\n",
       'exception was saved');
    is($self->subscription_calls_count,0,
       'nothing was done after connect died');
};

test 'stomp error on subscribe' => sub {
    my ($self) = @_;

    $self->clear_calls_and_queues;
    $self->handler->clear_connection;
    $self->handler->connection->{__fakestomp__callbacks}{subscribe} = sub {
        die "Can't subscribe\n";
    };

    my $exception = exception {
        $self->handler->run($self->psgi_test_app)
    };
    isa_ok($exception,'Plack::Handler::Stomp::Exceptions::Stomp',
           'correct exception thrown');
    is($exception->previous_exception,"Can't subscribe\n",
       'exception was saved');
};

run_me;
done_testing;
