package Plack::Handler::Stomp::NoNetwork;
{
  $Plack::Handler::Stomp::NoNetwork::VERSION = '0.1_01';
}
{
  $Plack::Handler::Stomp::NoNetwork::DIST = 'Plack-Handler-Stomp';
}
use Moose;
use namespace::autoclean;
use Try::Tiny;
use File::ChangeNotify;
use Net::Stomp::MooseHelpers::ReadTrace;
extends 'Plack::Handler::Stomp';

# ABSTRACT: like L<Plack::Handler::Stomp>, but without a network


with 'Net::Stomp::MooseHelpers::TraceOnly';

sub _default_servers {
    [ {
        hostname => 'not.using.the.network',
        port => 9999,
    } ]
}


has file_watcher => (
    is => 'ro',
    isa => 'File::ChangeNotify::Watcher',
    lazy_build => 1,
);
sub _build_file_watcher {
    my ($self) = @_;

    return File::ChangeNotify->instantiate_watcher(
        directories => [ $self->trace_basedir->stringify ],
        filter => qr{^\d+\.\d+-send-},
    );
}


has frame_reader => (
    is => 'ro',
    lazy_build => 1,
);
sub _build_frame_reader {
    my ($self) = @_;

    return Net::Stomp::MooseHelpers::ReadTrace->new({
        trace_basedir => $self->trace_basedir,
    });
}


sub frame_loop {
    my ($self,$app) = @_;

    while (1) {
        my @events = $self->file_watcher->wait_for_events();
        for my $event (@events) {
            next unless $event->type eq 'create';
            next unless -f $event->path;
            my $frame = $self->frame_reader
                ->read_frame_from_filename($event->path);

            # messages sent will be of type "SEND", but they would
            # come back ask "MESSAGE" if they passed through a broker
            $frame->command('MESSAGE') if $frame->command eq 'SEND';

            $self->handle_stomp_frame($app, $frame);

            Plack::Handler::Stomp::Exceptions::OneShot->throw()
                  if $self->one_shot;
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Plack::Handler::Stomp::NoNetwork - like L<Plack::Handler::Stomp>, but without a network

=head1 VERSION

version 0.1_01

=head1 SYNOPSIS

  my $runner = Plack::Handler::Stomp::NoNetwork->new({
    trace_basedir => '/tmp/mq',
    subscriptions => [
      { destination => '/queue/plack-handler-stomp-test' },
      { destination => '/topic/plack-handler-stomp-test',
        headers => {
            selector => q{custom_header = '1' or JMSType = 'test_foo'},
        },
        path_info => '/topic/ch1', },
      { destination => '/topic/plack-handler-stomp-test',
        headers => {
            selector => q{custom_header = '2' or JMSType = 'test_bar'},
        },
        path_info => '/topic/ch2', },
    ],
  });
  $runner->run(MyApp->get_app());

=head1 DESCRIPTION

Just like L<Plack::Handler::Stomp>, but instead of using a network
connection, we get our frames from a directory.

This class uses L<File::ChangeNotify> to monitor the
L<trace_basedir|Net::Stomp::MooseHelpers::TraceOnly/trace_basedir>,
and L<Net::Stomp::MooseHelpers::ReadTrace> to read the frames.

It also consumes L<Net::Stomp::MooseHelpers::TraceOnly> to make sure
that every reply we try to send is actually written to disk instead of
a broker.

=head2 WARNING!

This class does not implement subscription selectors. If you have
multiple subscriptions for the same destination, a random one will be
used.

=head1 ATTRIBUTES

=head2 C<file_watcher>

Instance of L<File::ChangeNotify::Watcher>, set up to monitor
C<trace_basedir> for sent messages.

=head2 C<frame_reader>

Instance of L<Net::Stomp::MooseHelpers::ReadTrace> used to parse
frames from disk.

=head1 METHODS

=head2 C<frame_loop>

This method ovverrides the corresponding one from
L<Plack::Handler::Stomp>.

Loop forever, collecting C<create> events from the
L</file_watcher>. Each new file is parsed by the L</frame_reader>,
then passed to
L<handle_stomp_frame|Plack::Handler::Stomp/handle_stomp_frame> as
usual.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

