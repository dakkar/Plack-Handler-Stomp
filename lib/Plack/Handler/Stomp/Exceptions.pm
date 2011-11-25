package Plack::Handler::Stomp::Exceptions;
{
  $Plack::Handler::Stomp::Exceptions::VERSION = '0.001_01';
}
{
  $Plack::Handler::Stomp::Exceptions::DIST = 'Plack-Handler-Stomp';
}

{package Plack::Handler::Stomp::Exceptions::Stringy;
{
  $Plack::Handler::Stomp::Exceptions::Stringy::VERSION = '0.001_01';
}
{
  $Plack::Handler::Stomp::Exceptions::Stringy::DIST = 'Plack-Handler-Stomp';
}
 use Moose::Role;
 use overload
  q{""}    => 'as_string',
  fallback => 1;
 requires 'as_string';
}

{package Plack::Handler::Stomp::Exceptions::UnknownFrame;
{
  $Plack::Handler::Stomp::Exceptions::UnknownFrame::VERSION = '0.001_01';
}
{
  $Plack::Handler::Stomp::Exceptions::UnknownFrame::DIST = 'Plack-Handler-Stomp';
}
 use Moose;with 'Throwable','Plack::Handler::Stomp::Exceptions::Stringy';
 has frame => ( is => 'ro', required => 1 );

 sub as_string {
     sprintf q{Received a STOMP frame we don't know how to handle (%s)},
         shift->frame->command;
 }
}

{package Plack::Handler::Stomp::Exceptions::AppError;
{
  $Plack::Handler::Stomp::Exceptions::AppError::VERSION = '0.001_01';
}
{
  $Plack::Handler::Stomp::Exceptions::AppError::DIST = 'Plack-Handler-Stomp';
}
 use Moose;extends 'Throwable::Error';
 has '+previous_exception' => (
     init_arg => 'app_error',
 );
 has '+message' => (
     default => 'The application died',
 );
}

{package Plack::Handler::Stomp::Exceptions::Stomp;
{
  $Plack::Handler::Stomp::Exceptions::Stomp::VERSION = '0.001_01';
}
{
  $Plack::Handler::Stomp::Exceptions::Stomp::DIST = 'Plack-Handler-Stomp';
}
 use Moose;extends 'Throwable::Error';
 has '+previous_exception' => (
     init_arg => 'stomp_error',
 );
 has '+message' => (
     default => 'STOMP protocol/network error',
 );
}

{package Plack::Handler::Stomp::Exceptions::OneShot;
{
  $Plack::Handler::Stomp::Exceptions::OneShot::VERSION = '0.001_01';
}
{
  $Plack::Handler::Stomp::Exceptions::OneShot::DIST = 'Plack-Handler-Stomp';
}
 use Moose;with 'Throwable';
}

1;

__END__
=pod

=head1 NAME

Plack::Handler::Stomp::Exceptions

=head1 VERSION

version 0.001_01

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

