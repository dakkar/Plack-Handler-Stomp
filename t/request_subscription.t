#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
with 'HandlerTester','TestApp';

test 'a simple request' => sub {
    my ($self) = @_;

    $self->clear_frames_to_receive;
    $self->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing',
        },
        body => 'foo',
    }));
    $self->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing-wrong-on-purpose',
            subscription => '0',
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
    );

    $self->handler->run($self->psgi_test_app);

    my $req = $self->requests_received->[-1];
    is($req->{'stomp.destination'},'/queue/testing','destination passed through');
    is($req->{PATH_INFO},'/my/path','path mapped');

    $self->handler->run($self->psgi_test_app);

    $req = $self->requests_received->[-1];
    is($req->{'stomp.destination'},'/queue/testing-wrong-on-purpose','destination passed through');
    is($req->{PATH_INFO},'/my/path','path mapped');
};

run_me;
done_testing;
