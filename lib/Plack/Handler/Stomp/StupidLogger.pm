package Plack::Handler::Stomp::StupidLogger;
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
