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

run_me;
done_testing;
