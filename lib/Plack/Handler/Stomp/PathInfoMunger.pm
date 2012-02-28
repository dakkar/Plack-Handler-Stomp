package Plack::Handler::Stomp::PathInfoMunger;
{
  $Plack::Handler::Stomp::PathInfoMunger::VERSION = '0.001_01';
}
{
  $Plack::Handler::Stomp::PathInfoMunger::DIST = 'Plack-Handler-Stomp';
}
use strict;use warnings;
use Sub::Exporter -setup => {
    exports => ['munge_path_info'],
    groups => { default => ['munge_path_info'] },
};

# ABSTRACT: printf-style interpolations for PATH_INFO

my $regex = qr{
 (?:%\{
  (.*?)
 \})
}x;

sub munge_path_info {
    my ($fmt,$server,$frame) = @_;

    my $lookup = sub {
        my $key = shift;
        if ($key eq 'broker_hostname') {
            return $server->{hostname}
        }
        if ($key eq 'broker_port') {
            return $server->{port}
        }
        $key =~ s{^header\.}{};
        my $val = $frame->headers->{$key};
        if (defined $val) {
            return $val;
        }
        return '';
    };

    my $str = $fmt;
    $str =~ s{\G(.*?)$regex}{$1 . $lookup->($2)}ge;
    return $str;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Plack::Handler::Stomp::PathInfoMunger - printf-style interpolations for PATH_INFO

=head1 VERSION

version 0.001_01

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

