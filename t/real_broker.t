#!perl
package Test::Plack::Handler::Stomp::RealBroker;
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use JSON::XS;
use Net::Stomp::MooseHelpers::ReadTrace;
with 'RunTestApp';

sub send_message {
    my ($self,$case) = @_;

    my $message = {
        payload => $case->{payload},
        reply_to => $self->reply_to,
        type => 'testaction',
    };

    $self->server_conn->send( {
        destination => $case->{destination},
        body => JSON::XS::encode_json($message),
        JMSType => $case->{JMSType},
        custom_header => $case->{custom_header},
    } );
}

sub check_reply {
    my ($self,$case) = @_;

    my $reply_frame = $self->server_conn->receive_frame();
    cmp_ok($reply_frame->command,'eq','MESSAGE','received the response');

    my $response = JSON::XS::decode_json($reply_frame->body);
    cmp_ok(
        $response->{path_info},'eq',$case->{path_info},
        'correct response path',
    );
    cmp_deeply(
        $response->{payload},
        $case->{payload},
        'correct response payload',
    );
}

has cases => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
);

sub _build_cases {
    return [
        {
            destination => '/queue/plack-handler-stomp-test',
            payload => { foo => 1, bar => 2 },
            JMSType => 'anything',
            custom_header => '3',
            path_info => '/queue/plack-handler-stomp-test',
        },
        {
            destination => '/topic/plack-handler-stomp-test',
            payload => { foo => 2, bar => 3 },
            JMSType => 'test_foo',
            custom_header => '3',
            path_info => '/topic/ch1',
        },
        {
            destination => '/topic/plack-handler-stomp-test',
            payload => { foo => 3, bar => 4 },
            JMSType => 'anything',
            custom_header => '1',
            path_info => '/topic/ch1',
        },
        {
            destination => '/topic/plack-handler-stomp-test',
            payload => { foo => 4, bar => 5 },
            JMSType => 'test_bar',
            custom_header => '3',
            path_info => '/topic/ch2',
        },
        {
            destination => '/topic/plack-handler-stomp-test',
            payload => { foo => 5, bar => 6 },
            JMSType => 'anything',
            custom_header => '2',
            path_info => '/topic/ch2',
        },
    ];
}

sub case_comparers {
    my ($self) = @_;

    return (
        methods(command=>'CONNECT'),
        methods(command=>'CONNECTED'),
        (methods(command=>'SUBSCRIBE')) x 3,
        map {
            my %h=%$_;
            $h{type}=delete $h{JMSType};
            my $pi=delete $h{path_info};
            delete $h{payload};

            (
                methods(command=>'MESSAGE',
                        headers=>superhashof(\%h),
                    ),
                methods(command=>'SEND',
                        headers=>{
                            destination=>re(qr{^/remote-temp-queue/}),
                        },
                        body => re(qr{"path_info":"\Q$pi\E"}),
                    ),
                methods(command=>'ACK'),
            )
        } @{$self->cases},
    );
}

sub check_trace {
    my ($self,$frames) = @_;

    my @case_comparers = $self->case_comparers;

    cmp_deeply(
        $frames,
        \@case_comparers,
        'tracing works'
    ) or explain $frames;
}

test 'talk to the app' => sub {
    my ($self) = @_;

    subtest 'send & reply' => sub {
        for my $case (@{$self->cases}) {
            $self->send_message($case);
            $self->check_reply($case);
        }
    };
    sleep(1); # let's wait a bit in case the app needs to read some
              # more frames, we need this to make
              # real_broker_receipt.t work a bit more reliably

    subtest 'tracing' => sub {
        my $reader = Net::Stomp::MooseHelpers::ReadTrace->new({
            trace_basedir => $self->trace_dir,
        });
        my @frames = $reader->sorted_frames();
        $self->check_trace(\@frames);
    };
};

unless (caller) {
    run_me;
    done_testing();
}
