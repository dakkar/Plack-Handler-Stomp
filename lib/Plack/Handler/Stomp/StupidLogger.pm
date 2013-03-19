package Plack::Handler::Stomp::StupidLogger;
{
  $Plack::Handler::Stomp::StupidLogger::VERSION = '1.06_01';
}
{
  $Plack::Handler::Stomp::StupidLogger::DIST = 'Plack-Handler-Stomp';
}
use strict;use warnings;

# ABSTRACT: dead-simple logger for Plack::Handler::Stomp


sub new {
    return bless {}, shift;
}


sub debug { }


sub info { }


sub warn {
    my ($self,@msg) = @_;
    CORE::warn "@msg\n";
}


sub error {
    my ($self,@msg) = @_;
    CORE::warn "@msg\n";
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Plack::Handler::Stomp::StupidLogger - dead-simple logger for Plack::Handler::Stomp

=head1 VERSION

version 1.06_01

=head1 METHODS

=head2 C<new>

Minimal constructor, no arguments.

=head2 C<debug>

No-op

=head2 C<info>

No-op

=head2 C<warn>

Calls Perl's C<warn>.

=head2 C<error>

Calls Perl's C<warn>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
