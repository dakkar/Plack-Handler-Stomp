package Test::Plack::Handler::Stomp::FakeStomp;
use strict;
use warnings;
use parent 'Net::Stomp';
use Net::Stomp::Frame;

# ABSTRACT: subclass of L<Net::Stomp>, half-mocked for testing

=head1 DESCRIPTION

This class is designed to be used in conjuction with
L<Test::Plack::Handler::Stomp>. It expects a set of callbacks that
will be invoked whenever a method is called. It also does not talk to
the network at all.

=cut

sub _get_connection {
    return 1;
}

=method C<new>

  my $stomp = Test::Plack::Handler::Stomp::FakeStomp->new({
    new => sub { $self->queue_constructor_call(shift) },
    connect => sub { $self->queue_connection_call(shift) },
    disconnect => sub { $self->queue_disconnection_call(shift) },
    subscribe => sub { $self->queue_subscription_call(shift) },
    unsubscribe => sub { $self->queue_unsubscription_call(shift) },
    send_frame => sub { $self->queue_sent_frame(shift) },
    receive_frame => sub { $self->next_frame_to_receive() },
  },$params);

The first parameter must be a hashref with all those keys pointing to
coderefs. Each coderef will be invoked when the corresponding method
is called, and will receive all the parameters of that call (minus the
invocant).

The parameters (to this C<new>) after the first will be passed to
L<Net::Stomp>'s C<new>.

The C<new> callback I<is> called by this method, just before
delegating to the inherited constructor. This callback does not
receive the callback hashref (i.e. it receives C<< @_[2..*] >>.

=cut

sub new {
    my $class = shift;
    my $callbacks = shift;
    $callbacks->{new}->(@_);
    my $self = $class->SUPER::new(@_);
    $self->{__fakestomp__callbacks} = $callbacks;
    return $self;
}

=method C<connect>

Calls the C<connect> callback, and returns 1.

=cut

sub connect {
    my ( $self, $conf ) = @_;

    $self->{__fakestomp__callbacks}{connect}->($conf);
    return Net::Stomp::Frame->new({
        command => 'CONNECTED',
        headers => {
            session => 'ID:foo',
        },
        body => '',
    });
}

=method C<disconnect>

Calls the C<disconnect> callback, and returns 1.

=cut

sub disconnect {
    my ( $self ) = @_;

    $self->{__fakestomp__callbacks}{disconnect}->();
    return 1;
}

=method C<can_read>

Returns 1.

=cut

sub can_read { return 1 }
sub _connected { return 1 }


=method C<subscribe>

Calls the C<subscribe> callback, and returns 1.

=cut

sub subscribe {
    my ( $self, $conf ) = @_;

    $self->{__fakestomp__callbacks}{subscribe}->($conf);
    return 1;
}

=method C<unsubscribe>

Calls the C<unsubscribe> callback, and returns 1.

=cut

sub unsubscribe {
    my ( $self, $conf ) = @_;

    $self->{__fakestomp__callbacks}{unsubscribe}->($conf);
    return 1;
}

=method C<send_frame>

Calls the C<send_frame> callback.

=cut

sub send_frame {
    my ( $self, $frame ) = @_;

    $self->{__fakestomp__callbacks}{send_frame}->($frame);
}

=method C<receive_frame>

Calls the C<receive_frame> callback, and returns whatever that
returned.

=cut

sub receive_frame {
    my ( $self, $conf ) = @_;

    return $self->{__fakestomp__callbacks}{receive_frame}->($conf);
}

1;
