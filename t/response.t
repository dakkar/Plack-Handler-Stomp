#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
with 'HandlerTester','TestApp';

test 'a simple response' => sub {
    my ($self) = @_;

    $self->clear_frames_to_receive;
    $self->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing',
            subscription => 0,
            'message-id' => '1234',
        },
        body => 'please reply',
    }));

    $self->set_arg(
        subscriptions => [
            {
                destination => '/queue/testing',
            },
        ],
    );

    $self->handler->run($self->psgi_test_app);

    is($self->sent_frames_count,2,
       'ACK & reply');
    my ($reply,$ack) = @{$self->frames_sent};
    is($reply->command,'SEND',
       'reply is a send');
    is($reply->body,'hello',
       'reply has correct body');
    is($reply->headers->{destination},
       '/remote-temp-queue/reply_queue',
       'reply has correct destination');
    is($reply->headers->{foo},
       'something',
       'reply has correct headers');
    is($ack->command,'ACK',
       'ack is an ack');
    is($ack->headers->{'message-id'},'1234',
       'ack with correct message-id');
};

run_me;
done_testing;
