#!perl
package Test::Plack::Handler::Stomp::RealBroker::Receipt;
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
require 't/real_broker.t';
with 'Test::Plack::Handler::Stomp::RealBroker';

sub _build_receipt_for_ack { 1 }

sub check_trace {
    my ($self,$frames) = @_;

    my @case_comparers = $self->case_comparers;
    my %acks_without_receipt;

    for my $frame (@$frames) {
        if ($frame->command eq 'RECEIPT') {
            my $ack = $frame->headers->{'receipt-id'};
            ok(delete $acks_without_receipt{$ack},'got receipt for ack');
        }
        else {
            if ($frame->command eq 'ACK') {
                my $ack = $frame->headers->{'receipt'};
                $acks_without_receipt{$ack} = 1;
            }
            my $should_match = shift @case_comparers;
            cmp_deeply(
                $frame,
                $should_match,
                'tracing works',
            ) or explain $frame;
        }
    }
    ok(!%acks_without_receipt,'all ack receipted');
}

test 'all messages up front, with receipts on ack' => sub {
    my ($self) = @_;

    # we need to send all messages on the same destination, otherwise
    # they'll be delivered in a random order and the tests will
    # sometimes fail
    my @cases = map {
        {
            %{$_},
            destination => '/queue/plack-handler-stomp-test',
            path_info => '/queue/plack-handler-stomp-test',
        },
    } @{$self->cases};

    subtest 'send & reply' => sub {
        for my $case (@cases) {
            $self->send_message($case);
        }
        for my $case (@cases) {
            $self->check_reply($case);
        }
    };
};

unless (caller) {
    run_me;
    done_testing();
}
