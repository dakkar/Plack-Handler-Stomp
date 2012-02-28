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

=func C<munge_path_info>

  my $str = munge_path_info($format_string,$server_config,$stomp_frame);

Interprets the C<$format_string> in a C<printf>-like way: every C<
%{something} > is replaced with a value from the C<$server_config> or
the C<$stomp_frame>. In particular:

=over 4

=item C<%{broker_hostname}>

is replaced by the value of C<< $server_config->{hostname} >>

=item C<%{broker_port}>

is replaced by the value of C<< $server_config->{port} >>

=item C<%{header.something}>

is replaced by the value of C<< $stomp_frame->headers->{something} >>
(of course C<something> in this example can be replaced by whatever
string you want).

=item anything else

is replaced by an empty string (i.e. it's removed).

=back

=cut

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
