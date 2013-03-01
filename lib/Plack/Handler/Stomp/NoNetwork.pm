package Plack::Handler::Stomp::NoNetwork;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use File::ChangeNotify;
use Net::Stomp::MooseHelpers::ReadTrace 1.7;
use Path::Class;
extends 'Plack::Handler::Stomp';

# ABSTRACT: like L<Plack::Handler::Stomp>, but without a network

=head1 SYNOPSIS

  my $runner = Plack::Handler::Stomp::NoNetwork->new({
    trace_basedir => '/tmp/mq',
    subscriptions => [
      { destination => '/queue/plack-handler-stomp-test' },
      { destination => '/topic/plack-handler-stomp-test',
        path_info => '/topic/ch1', },
      { destination => '/topic/plack-handler-stomp-test',
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

has subscription_directory_map => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { { } },
);

after subscribe_single => sub {
    my ($self,$sub,$headers) = @_;

    my $dest_dir = $self->trace_basedir->subdir(
        $self->_dirname_from_destination(
            $headers->{destination}
        )
    );
    $dest_dir->mkpath;

    my $id = $headers->{id};

    $self->subscription_directory_map->{$dest_dir->stringify}=$id;

    return;
};

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

    my @directories = keys %{$self->subscription_directory_map};

    # File::ChangeNotify::Watcher::Default throws an exception if you
    # ask it to monitor non-existent directories; coupled with the
    # try/catch below, it would lead to an infinite loop. Let's make
    # sure it does not happen
    dir($_)->mkpath for @directories;

    return File::ChangeNotify->instantiate_watcher(
        directories => \@directories,
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
        my @events;
        # if someone deletes multiple directories while we're looking
        # at them, File::ChangeNotify::Watcher::Default gets very
        # confused and throws an exception. Let's catch it and just
        # re-build the watcher.
        try { @events = $self->file_watcher->wait_for_events() }
        catch {
            if (/File::ChangeNotify::Watcher::Default::/) {
                $self->clear_file_watcher;
            }
            else { die $_ }
        };
        for my $event (@events) {
            next unless $event->type eq 'create';
            next unless -f $event->path;
            # loop until the reader can get a complete frame, to work
            # around race conditions between the writer and us
            my $frame;
            while (!$frame) {
                $frame = $self->frame_reader
                    ->read_frame_from_filename($event->path);
            }

            # messages sent will be of type "SEND", but they would
            # come back ask "MESSAGE" if they passed through a broker
            $frame->command('MESSAGE') if $frame->command eq 'SEND';

            $frame->headers->{subscription} =
                $self->subscription_directory_map->{
                    file($event->path)->dir->stringify
                };

            $self->handle_stomp_frame($app, $frame);

            Plack::Handler::Stomp::Exceptions::OneShot->throw()
                  if $self->one_shot;
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
