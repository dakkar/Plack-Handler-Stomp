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
            subscription => 2,
            JMSType => 'foo-message',
            broker_hostname => 'complicated',
        },
        body => 'foo',
    }));
    $self->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/testing-wrong-on-purpose',
            subscription => '0',
            JMSType => 'bar-message',
        },
        body => 'foo',
    }));
    $self->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/%{subscription}', # let's trick it
            subscription => 1,
            JMSType => 'foo-message',
            broker_hostname => 'complicated',
        },
        body => 'foo',
    }));

    $self->set_arg(
        subscriptions => [
            {
                destination => '/queue/testing',
                path_info => '/%{broker_hostname}%{destination}/%{subscription}/%{JMSType}/%{header.broker_hostname}',
            },
            {
                destination => '/queue/%{subscription}',
                path_info => '/plain/path',
            },
        ],
        servers => { hostname => 'first', port => 61613 },
    );

    $self->handler->run($self->psgi_test_app);
    my $req = $self->requests_received->[-1];
    is($req->{PATH_INFO},'/first/queue/testing/2/foo-message/complicated',
       'complex path mapped');

    $self->handler->run($self->psgi_test_app);
    $req = $self->requests_received->[-1];
    is($req->{PATH_INFO},'/first/queue/testing-wrong-on-purpose/0/bar-message/',
       'complex path mapped');

    $self->handler->run($self->psgi_test_app);
    $req = $self->requests_received->[-1];
    is($req->{PATH_INFO},'/plain/path',
       'no complex path mapping');
};

run_me;
done_testing;
