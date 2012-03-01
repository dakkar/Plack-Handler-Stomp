package Test::Plack::Handler::Stomp::FakeStomp;
{
  $Test::Plack::Handler::Stomp::FakeStomp::VERSION = '0.001_01';
}
{
  $Test::Plack::Handler::Stomp::FakeStomp::DIST = 'Plack-Handler-Stomp';
}
use strict;
use warnings;
use parent 'Net::Stomp';

sub _get_connection {
    return 1;
}

sub new {
    my $class = shift;
    my $callbacks = shift;
    $callbacks->{new}->(@_);
    my $self = $class->SUPER::new(@_);
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

__END__
=pod

=encoding utf-8

=head1 NAME

Test::Plack::Handler::Stomp::FakeStomp

=head1 VERSION

version 0.001_01

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

