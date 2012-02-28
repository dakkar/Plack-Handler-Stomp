package Plack::Handler::Stomp::StupidLogger;
{
  $Plack::Handler::Stomp::StupidLogger::VERSION = '0.001_01';
}
{
  $Plack::Handler::Stomp::StupidLogger::DIST = 'Plack-Handler-Stomp';
}
use strict;use warnings;

sub new {
    return bless {}, shift;
}

sub log_debug { }

sub log_info { }

sub log_warn {
    my ($self,@msg) = @_;
    warn "@msg\n";
}
sub log_error {
    my ($self,@msg) = @_;
    warn "@msg\n";
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Plack::Handler::Stomp::StupidLogger

=head1 VERSION

version 0.001_01

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

