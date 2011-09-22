#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
with 'HandlerTester';

test 'instantiate the handler' => sub {
    my ($self) = @_;

    ok($self->handler);
};

test 'connecting with defaults' => sub {
    my ($self) = @_;

    $self->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'OK',
    }));

    $self->handler->run();

    is($self->constructor_calls_count,1,'connected once');
    my $call = $self->constructor_calls->[0];
    is_deeply($call,
              {
                  hostname => 'localhost',
                  port => 61613,
              },
              'default parameters');

    is($self->connection_calls_count,1,'connected once');
    my $call = $self->connection_calls->[0];
    ok(!defined $call,'no connection headers');
};

#    $self->handler_args({
#        hostname => 'foo',
#        port => 12345,
#    });
#}

run_me;
done_testing;
