#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
with 'HandlerTester';

test 'instantiate the handler' => sub {
    my ($self) = @_;

    ok($self->handler,'built');
};

test 'connecting with defaults' => sub {
    my ($self) = @_;

    $self->handler->run();

    is($self->constructor_calls_count,1,'built once');
    my $call = $self->constructor_calls->[0];
    is_deeply($call,
              {
                  hostname => 'localhost',
                  port => 61613,
              },
              'default parameters');

    is($self->connection_calls_count,1,'connected once');
    $call = $self->connection_calls->[0];
    ok(!defined $call,'no connection headers');
};

run_me;
done_testing;
