package Test::Plack::Handler::Stomp;
use Moose;
use Moose::Util::TypeConstraints 'class_type';
use MooseX::Types::Moose qw(ArrayRef HashRef Maybe);

use namespace::autoclean;
use Test::Plack::Handler::Stomp::FakeStomp;
use Plack::Handler::Stomp;

# ABSTRACT: testing library for Plack::Handler::Stomp

=head1 SYNOPSIS

  my $t = Test::Plack::Handler::Stomp->new();
  $t->set_arg(
    subscriptions => [
      { destination => '/queue/input_queue',
        path_info => '/input_queue', },
    ],
  );
  $t->clear_frames_to_receive;

  $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/input_queue',
            subscription => 0,
            type => 'my_type',
            'message-id' => 356,
        },
        body => '{"foo":"bar"}',
    }));

    $t->handler->run($app);

    check($t->frames_sent);

=head1 DESCRIPTION

Testing a PSGI application that expects JMS/STOMP messages can be a
pain. This library helps reduce that pain.

It wraps a L<Plack::Handler::Stomp>, connecting it to a
L<Test::Plack::Handler::Stomp::FakeStomp> instead of a real STOMP
connection, and allows you to inspect everything that happens to the
connection.

=cut

=attr C<handler_args>

Hashref, arguments to pass to L<Plack::Handler::Stomp>'s
constructor. You can add to this via the L</set_arg> method. Defaults
to C<< { one_shot => 1 } >>, to avoid having L<Plack::Handler::Stomp>
loop forever.

=method C<set_arg>

  $handler->set_arg(foo=>'bar',some=>'thing');

Sets arguments for L<Plack::Handler::Stomp>'s constructor, see
C</handler_args>.

=cut

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

=attr C<handler>

A L<Plack::Handler::Stomp> instance. It's built on-demand via
L</setup_handler>. You can clear it with L</clear_handler> to have it
rebuilt (for example, if you have changed L</handler_args>)

=method C<clear_handler>

Destroys the L</handler>, forcing it to be rebuilt next time it's
needed.

=cut

has handler => (
    is => 'ro',
    isa => class_type('Plack::Handler::Stomp'),
    lazy => 1,
    builder => 'setup_handler',
    clearer => 'clear_handler',
);

=attr C<frames_sent>

Arrayref of L<Net::Stomp::Frame> objects that L<Plack::Handler::Stomp>
sent. Can be edited via L</queue_sent_frame>, L</sent_frames_count>,
L</clear_sent_frames>. Defaults to the empty array.

=method C<queue_sent_frame>

Adds a frame to the end of L</frames_sent>.

=method C<sent_frames_count>

Returns the number of elements in L</frames_sent>.

=method C<clear_sent_frames>

Removes all elements from L</frames_sent>.

=cut

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

=attr C<frames_to_receive>

Arrayref of L<Net::Stomp::Frame> objects that L<Plack::Handler::Stomp>
will consume. Can be edited via L</queue_frame_to_receive>,
L</next_frame_to_receive>, L</frames_left_to_receive>,
L</clear_frames_to_receive>.

Defaults to an array with a single C<ERROR> frame.

=method C<queue_frame_to_receive>

Adds a frame to the end of L</frames_to_receive>.

=method C<next_frame_to_receive>

Removes a frame from the beginning of L</frames_to_receive> and
returns it.

=method C<frames_left_to_receive>

Returns the number of elements in L</frames_to_receive>.

=method C<clear_frames_to_receive>

Removes all elements from L</frames_to_receive>.

=cut

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

=attr C<constructor_calls>

Arrayref of whatever was passed to the
L<Test::Plack::Handler::Stomp::FakeStomp> constructor.

=cut

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
