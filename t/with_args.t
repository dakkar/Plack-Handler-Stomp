#!perl
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
use MyTesting;
use Net::Stomp::Frame;
with 'HandlerTester';

test 'connecting with supplied params' => sub {
    my ($self) = @_;

    my $new_params = {
        hostname => 'foo',
        port => 12345,
    };
    my $conn_head = {
        login => 'myuser',
        password => 'mypass',
    };

    $self->set_arg(
        servers => [
            {
                %$new_params,
                connect_headers => $conn_head,
            },
        ],
    );

    $self->handler->run();

    is($self->constructor_calls_count,1,'built once');
    my $call = $self->constructor_calls->[0];
    is_deeply($call,$new_params,'custom host used');

    is($self->connection_calls_count,1,'connected once');
    $call = $self->connection_calls->[0];
    is_deeply($call,$conn_head,'custom connect headers used');
};

run_me;
done_testing;
