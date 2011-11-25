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
            'message-id' => 123,
        },
        body => 'foo',
    }));

    $self->handler->run($self->psgi_test_app);

    my %expected = (
        # server
        SERVER_NAME => 'localhost',
        SERVER_PORT => 0,
        SERVER_PROTOCOL => 'STOMP',

        # client
        REQUEST_METHOD => 'POST',
        REQUEST_URI => 'stomp://localhost/queue/testing',
        SCRIPT_NAME => '',
        PATH_INFO => '/queue/testing',
        QUERY_STRING => '',

        # broker
        REMOTE_ADDR => 'localhost',

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

        # stomp
        'stomp.destination' => '/queue/testing',
        'stomp.message-id' => 123,

        # application
        'testapp.body' => 'foo',
    );

    is($self->requests_count,1,'one request handled');
    is_deeply($self->requests_received->[0],
              \%expected,
              'with expected content');

    is($self->sent_frames_count,1,'sent one frame');
    my $frame = $self->frames_sent->[0];
    is($frame->command,'ACK',q{it's an ack});
    is_deeply($frame->headers,
              { 'message-id' => 123 },
              'for the right message');
};

run_me;
done_testing;
