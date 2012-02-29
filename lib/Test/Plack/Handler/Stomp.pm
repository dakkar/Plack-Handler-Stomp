package Test::Plack::Handler::Stomp;
use Moose;
use Moose::Util::TypeConstraints 'class_type';
use MooseX::Types::Moose qw(ArrayRef HashRef Maybe);

use namespace::autoclean;
use Test::Plack::Handler::Stomp::FakeStomp;
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
        clear_sent_frames => 'clear',
    }
);

has frames_to_receive => (
    is => 'rw',
    isa => ArrayRef[class_type('Net::Stomp::Frame')],
    default => sub { [ Net::Stomp::Frame->new({
        command => 'ERROR',
        headers => {
            message => 'placeholder from ' . __PACKAGE__,
        },
        body => '',
    }) ] },
    traits => ['Array'],
    handles => {
        queue_frame_to_receive => 'push',
        next_frame_to_receive => 'shift',
        frames_left_to_receive => 'count',
        clear_frames_to_receive => 'clear',
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
        clear_constructor_calls => 'clear',
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
        clear_connection_calls => 'clear',
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
        clear_disconnection_calls => 'clear',
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
        clear_subscription_calls => 'clear',
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
        clear_unsubscription_calls => 'clear',
    },
);

has log_messages => (
    is => 'rw',
    isa => ArrayRef,
    traits => ['Array'],
    handles => {
        add_log_message => 'push',
        log_messages_count => 'count',
        clear_log_messages => 'clear',
    },
);

sub setup_handler {
    my ($self) = @_;

    return Plack::Handler::Stomp->new({
        logger => $self,
        %{$self->handler_args},
        connection_builder => sub {
            my ($params) = @_;
            return Test::Plack::Handler::Stomp::FakeStomp->new({
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

sub debug {
    my ($self,@msg) = @_;
    $self->add_log_message(['debug',@msg]);
}
sub info {
    my ($self,@msg) = @_;
    $self->add_log_message(['info',@msg]);
}
sub warn {
    my ($self,@msg) = @_;
    $self->add_log_message(['warn',@msg]);
}
sub error {
    my ($self,@msg) = @_;
    $self->add_log_message(['error',@msg]);
}

sub clear_calls_and_queues {
    my ($self) = @_;
    $self->clear_sent_frames;
    $self->clear_frames_to_receive;
    $self->clear_constructor_calls;
    $self->clear_connection_calls;
    $self->clear_disconnection_calls;
    $self->clear_subscription_calls;
    $self->clear_unsubscription_calls;
    $self->clear_log_messages;
    return;
}

1;
