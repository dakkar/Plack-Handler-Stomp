#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
with 'HandlerTester','TestApp';

test 'custom logger' => sub {
    my ($self) = @_;

    $self->clear_frames_to_receive;
    $self->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing',
            subscription => 0,
        },
        body => 'error please',
    }));
    $self->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'RECEIPT',
        headers => {
            'receipt-id' => 1234,
        },
        body => '',
    }));
    $self->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'ERROR',
        headers => {
            message => 'testing error',
        },
        body => '',
    }));

    $self->set_arg(
        subscriptions => [
            {
                destination => '/queue/testing',
            },
        ],
    );

    $self->handler->run($self->psgi_test_app);
    my $msg = $self->log_messages->[-1];
    is_deeply($msg,
              ['error','your error'],
              'app error logged');

    $self->handler->run($self->psgi_test_app);
    $msg = $self->log_messages->[-1];
    is_deeply($msg,
              ['debug','ignored RECEIPT frame for 1234'],
              'receipt debug logged');

    $self->handler->run($self->psgi_test_app);
    $msg = $self->log_messages->[-1];
    is_deeply($msg,
              ['warn','testing error'],
              'STOMP ERROR frame logged');
};

run_me;
done_testing;
