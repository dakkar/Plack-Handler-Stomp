#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
with 'HandlerTester';

test 'instantiate the handler' => sub {
    my ($self) = @_;

    ok($self->handler);
};

run_me;
done_testing;
