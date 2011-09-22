#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
with 'HandlerTester';

test 'subscriptions with headers' => sub {
    my ($self) = @_;

    $self->set_arg(
        servers => [
            {
                hostname => 'foo',
                port => 12345,
                subscribe_headers => {
                    this => 'that',
                    from => 'server',
                },
            },
        ],
        subscribe_headers => {
            foo => 'bar',
            from => 'global',
        },
        subscriptions => [
            { destination => '/queue/foo', },
            { destination => '/topic/bar',
              headers => { some => 'more', from => 'destination' } },
        ],
    );

    my @expected = (
        {
            destination => '/queue/foo',
            this => 'that',
            foo => 'bar',
            from => 'server',
            ack => 'client',
            id => 0,
        },
        {
            destination => '/topic/bar',
            this => 'that',
            foo => 'bar',
            some => 'more',
            from => 'destination',
            ack => 'client',
            id => 1,
        },
    );

    $self->handler->run();

    is_deeply($self->subscription_calls,
              \@expected,
              'subscribed correctly');
};

run_me;
done_testing;
