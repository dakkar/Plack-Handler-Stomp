package HandlerTester;
use Test::Routine;
use MyTesting;
use Moose::Util::TypeConstraints 'class_type';
use MooseX::Types::Moose qw(ArrayRef HashRef Maybe);

use namespace::autoclean;
use FakeStomp;
use Plack::Handler::Stomp;

has handler_args => (
    is => 'ro',
    isa => HashRef,
    default => sub { {
        one_shot => 1,
    } },
    traits => ['Hash'],
    handles => {
        set_arg => 'set',
    },
);

has handler => (
    is => 'ro',
    isa => class_type('Plack::Handler::Stomp'),
    lazy => 1,
    builder => 'setup_handler',
);

has frames_sent => (
    is => 'rw',
    isa => ArrayRef[class_type('Net::Stomp::Frame')],
    default => sub { [ ] },
    traits => ['Array'],
    handles => {
        queue_sent_frame => 'push',
        sent_frames_count => 'count',
    }
);

has frames_to_receive => (
    is => 'rw',
    isa => ArrayRef[class_type('Net::Stomp::Frame')],
    default => sub { [ ] },
    traits => ['Array'],
    handles => {
        queue_frame_to_receive => 'push',
        next_frame_to_receive => 'shift',
        frames_left_to_receive => 'count',
    },
);

has constructor_calls => (
    is => 'rw',
    isa => ArrayRef[HashRef],
    default => sub { [ ] },
    traits => ['Array'],
    handles => {
        queue_constructor_call => 'push',
        constructor_calls_count => 'count',
    },
);

has connection_calls => (
    is => 'rw',
    isa => ArrayRef[Maybe[HashRef]],
    default => sub { [ ] },
    traits => ['Array'],
    handles => {
        queue_connection_call => 'push',
        connection_calls_count => 'count',
    },
);

has disconnection_calls => (
    is => 'rw',
    isa => ArrayRef[Maybe[HashRef]],
    default => sub { [ ] },
    traits => ['Array'],
    handles => {
        queue_disconnection_call => 'push',
        disconnection_calls_count => 'count',
    },
);

has subscription_calls => (
    is => 'rw',
    isa => ArrayRef[Maybe[HashRef]],
    default => sub { [ ] },
    traits => ['Array'],
    handles => {
        queue_subscription_call => 'push',
        subscription_calls_count => 'count',
    },
);

has unsubscription_calls => (
    is => 'rw',
    isa => ArrayRef[Maybe[HashRef]],
    default => sub { [ ] },
    traits => ['Array'],
    handles => {
        queue_unsubscription_call => 'push',
        unsubscription_calls_count => 'count',
    },
);

sub setup_handler {
    my ($self) = @_;

    return Plack::Handler::Stomp->new({
        %{$self->handler_args},
        connection_builder => sub {
            my ($params) = @_;
            return FakeStomp->new({
                new => sub { $self->queue_constructor_call(shift) },
                connect => sub { $self->queue_connection_call(shift) },
                disconnect => sub { $self->queue_disconnection_call(shift) },
                subscribe => sub { $self->queue_subscription_call(shift) },
                unsubscribe => sub { $self->queue_unsubscription_call(shift) },
                send_frame => sub { $self->queue_sent_frame(shift) },
                receive_frame => sub { $self->next_frame_to_receive() },
            },$params);
        },
    })
}

1;
