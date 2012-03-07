package Plack::Handler::Stomp::NoNetwork;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use File::ChangeNotify;
use Net::Stomp::MooseHelpers::ReadTrace;
extends 'Plack::Handler::Stomp';

# ABSTRACT: like L<Plack::Handler::Stomp>, but without a network

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

=cut

with 'Net::Stomp::MooseHelpers::TraceOnly';

sub _default_servers {
    [ {
        hostname => 'not.using.the.network',
        port => 9999,
    } ]
}

=attr C<file_watcher>

Instance of L<File::ChangeNotify::Watcher>, set up to monitor
C<trace_basedir> for sent messages.

=cut

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

=attr C<frame_reader>

Instance of L<Net::Stomp::MooseHelpers::ReadTrace> used to parse
frames from disk.

=cut

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

=method C<frame_loop>

This method ovverrides the corresponding one from
L<Plack::Handler::Stomp>.

Loop forever, collecting C<create> events from the
L</file_watcher>. Each new file is parsed by the L</frame_reader>,
then passed to
L<handle_stomp_frame|Plack::Handler::Stomp/handle_stomp_frame> as
usual.

=cut

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
