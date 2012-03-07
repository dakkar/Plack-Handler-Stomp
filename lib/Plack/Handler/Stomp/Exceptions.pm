package Plack::Handler::Stomp::Exceptions;
use Net::Stomp::MooseHelpers::Exceptions;

# ABSTRACT: exception classes for Plack::Handler::Stomp

=head1 DESCRIPTION

This file defines the following exception classes:

=over 4

=item C<Plack::Handler::Stomp::Exceptions::UnknownFrame>

Thrown whenever we receive a frame we don't know how to handle; has a
C<frame> attribute containing the frame in question.

=item C<Plack::Handler::Stomp::Exceptions::AppError>

Thrown whenever the PSGI application dies; has a C<previous_exception>
attribute containing the exception that the application threw.

=item C<Plack::Handler::Stomp::Exceptions::OneShot>

Thrown to stop the C<run> loop after receiving a message, if
C<one_shot> is true (see L<Plack::Handler::Stomp/run>).

=back

=cut

{
package Plack::Handler::Stomp::Exceptions::UnknownFrame;
use Moose;with 'Throwable','Net::Stomp::MooseHelpers::Exceptions::Stringy';
use namespace::autoclean;
has frame => ( is => 'ro', required => 1 );

sub as_string {
    sprintf q{Received a STOMP frame we don't know how to handle (%s)},
        shift->frame->command;
}
__PACKAGE__->meta->make_immutable;
}

{
package Plack::Handler::Stomp::Exceptions::AppError;
use Moose;with 'Throwable','Net::Stomp::MooseHelpers::Exceptions::Stringy';
use namespace::autoclean;
has '+previous_exception' => (
    init_arg => 'app_error',
);
sub as_string {
    return 'The application died:'.$_[0]->previous_exception;
}
__PACKAGE__->meta->make_immutable;
}

{
package Plack::Handler::Stomp::Exceptions::OneShot;
use namespace::autoclean;
use Moose;with 'Throwable';
__PACKAGE__->meta->make_immutable;
}

1;
