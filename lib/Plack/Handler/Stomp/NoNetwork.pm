package Plack::Handler::Stomp::NoNetwork;
use Moose;
use namespace::autoclean;
use Try::Tiny;
use File::ChangeNotify;
use Net::Stomp::MooseHelpers::ReadTrace;
extends 'Plack::Handler::Stomp';

with 'Net::Stomp::MooseHelpers::TraceOnly';

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

            $frame->command('MESSAGE') if $frame->command eq 'SEND';

            $self->handle_stomp_frame($app, $frame);

            Plack::Handler::Stomp::Exceptions::OneShot->throw()
                  if $self->one_shot;
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
