package HandlerTester;
use Test::Routine;
use MyTesting;
use Moose::Util::TypeConstraints 'class_type';
use MooseX::Types::Moose qw(ArrayRef HashRef);
use namespace::autoclean;
use FakeStomp;
use Plack::Handler::Stomp;

has handler => (
    is => 'rw',
    isa => class_type('Plack::Handler::Stomp'),
    builder => 'setup_handler',
);

has frames_sent => (
    is => 'rw',
    isa => ArrayRef[class_type('Net::Stomp::Frame')],
    default => sub { [ ] },
    traits => ['Array'],
    handles => {
        queue_sent_frame => 'push',
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
    },
);

has connection_calls => (
    is => 'rw',
    isa => ArrayRef[HashRef],
    default => sub { [ ] },
    traits => ['Array'],
    handles => {
        queue_connection_call => 'push',
    },
);

has disconnection_calls => (
    is => 'rw',
    isa => ArrayRef[HashRef],
    default => sub { [ ] },
    traits => ['Array'],
    handles => {
        queue_disconnection_call => 'push',
    },
);

has subscription_calls => (
    is => 'rw',
    isa => ArrayRef[HashRef],
    default => sub { [ ] },
    traits => ['Array'],
    handles => {
        queue_subscription_call => 'push',
    },
);

has unsubscription_calls => (
    is => 'rw',
    isa => ArrayRef[HashRef],
    default => sub { [ ] },
    traits => ['Array'],
    handles => {
        queue_unsubscription_call => 'push',
    },
);

sub setup_handler {
    my ($self) = @_;

    return Plack::Handler::Stomp->new({
        connection_builder => sub {
            my (undef,$params) = @_;
            my $fs = FakeStomp->new($params);
            $fs->{__fakestomp__callbacks} = {
                connect => sub { $self->queue_connection_call(shift) },
                disconnect => sub { $self->queue_disconnection_call(shift) },
                subscribe => sub { $self->queue_subscription_call(shift) },
                unsubscribe => sub { $self->queue_unsubscription_call(shift) },
                send_frame => sub { $self->queue_sent_frame(shift) },
                receive_frame => sub { $self->next_frame_to_receive() },
            };
        },
    })
}

1;
