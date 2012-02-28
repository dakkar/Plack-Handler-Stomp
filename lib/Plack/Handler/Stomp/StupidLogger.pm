package Plack::Handler::Stomp::StupidLogger;
use strict;use warnings;

# ABSTRACT: dead-simple logger for Plack::Handler::Stomp

sub new {
    return bless {}, shift;
}

sub debug { }

sub info { }

sub warn {
    my ($self,@msg) = @_;
    warn "@msg\n";
}
sub error {
    my ($self,@msg) = @_;
    warn "@msg\n";
}

1;
