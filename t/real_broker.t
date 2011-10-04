#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use JSON::XS;
with 'RunTestApp';

test 'talk to the app' => sub {
    my ($self) = @_;

    my $child = $self->child;
    my $conn = $self->server_conn;
    my $reply_to = $self->reply_to;

    my @cases = (
        {
            destination => '/queue/plack-handler-stomp-test',
            JMSType => 'anything',
            custom_header => '3',
            path_info => '/queue/plack-handler-stomp-test',
        },
        {
            destination => '/topic/plack-handler-stomp-test',
            JMSType => 'test_foo',
            custom_header => '3',
            path_info => '/topic/ch1',
        },
        {
            destination => '/topic/plack-handler-stomp-test',
            JMSType => 'anything',
            custom_header => '1',
            path_info => '/topic/ch1',
        },
        {
            destination => '/topic/plack-handler-stomp-test',
            JMSType => 'test_bar',
            custom_header => '3',
            path_info => '/topic/ch2',
        },
        {
            destination => '/topic/plack-handler-stomp-test',
            JMSType => 'anything',
            custom_header => '2',
            path_info => '/topic/ch2',
        },
    );

    for my $case (@cases) {
        my $message = {
            payload => { foo => 1, bar => 2 },
            reply_to => $reply_to,
            type => 'testaction',
        };

        $conn->send( {
            destination => $case->{destination},
            body => JSON::XS::encode_json($message),
            JMSType => $case->{JMSType},
            custom_header => $case->{custom_header},
        } );

        my $reply_frame = $conn->receive_frame();
        ok($reply_frame, 'got a reply');

        my $response = JSON::XS::decode_json($reply_frame->body);
        ok($response, 'response ok');
        ok($response->{path_info} eq $case->{path_info}, 'worked');
    }
};

run_me;
done_testing;
