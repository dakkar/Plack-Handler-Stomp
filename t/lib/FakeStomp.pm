package FakeStomp;
use parent 'Net::Stomp';

sub _get_connection {
    return 1;
}

sub new {
    my $self = shift;
    my $callbacks = shift;
    $callbacks->{new}->(@_);
    my $self = $self->SUPER::new(@_);
    $self->{__fakestomp__callbacks} = $callbacks;
    return $self;
}

sub connect {
    my ( $self, $conf ) = @_;

    $self->{__fakestomp__callbacks}{connect}->($conf);
    return 1;
}

sub disconnect {
    my ( $self ) = @_;

    $self->{__fakestomp__callbacks}{disconnect}->();
    return 1;
}

sub can_read { return 1 }
sub _connected { return 1 }

sub subscribe {
    my ( $self, $conf ) = @_;

    $self->{__fakestomp__callbacks}{subscribe}->($conf);
    return 1;
}

sub unsubscribe {
    my ( $self, $conf ) = @_;

    $self->{__fakestomp__callbacks}{unsubscribe}->($conf);
    return 1;
}

sub send_frame {
    my ( $self, $frame ) = @_;

    $self->{__fakestomp__callbacks}{send_frame}->($frame);
}

sub receive_frame {
    my ( $self, $conf ) = @_;

    return $self->{__fakestomp__callbacks}{receive_frame}->($conf);
}

1;
