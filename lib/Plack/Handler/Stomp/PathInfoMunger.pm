package Plack::Handler::Stomp::PathInfoMunger;
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
