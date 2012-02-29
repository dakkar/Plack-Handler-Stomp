package Plack::Handler::Stomp::StupidLogger;
use strict;use warnings;

# ABSTRACT: dead-simple logger for Plack::Handler::Stomp

=method C<new>

Minimal constructor, no arguments.

=cut

sub new {
    return bless {}, shift;
}

=method C<debug>

No-op

=cut

sub debug { }

=method C<info>

No-op

=cut

sub info { }

=method C<warn>

Calls Perl's C<warn>.

=cut

sub warn {
    my ($self,@msg) = @_;
    CORE::warn "@msg\n";
}

=method C<error>

Calls Perl's C<warn>.

=cut

sub error {
    my ($self,@msg) = @_;
    CORE::warn "@msg\n";
}

1;
