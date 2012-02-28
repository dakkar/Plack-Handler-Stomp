package Plack::Handler::Stomp::Exceptions;

{package Plack::Handler::Stomp::Exceptions::Stringy;
 use Moose::Role;
 use overload
  q{""}    => 'as_string',
  fallback => 1;
 requires 'as_string';
}

{package Plack::Handler::Stomp::Exceptions::UnknownFrame;
 use Moose;with 'Throwable','Plack::Handler::Stomp::Exceptions::Stringy';
 has frame => ( is => 'ro', required => 1 );

 sub as_string {
     sprintf q{Received a STOMP frame we don't know how to handle (%s)},
         shift->frame->command;
 }
}

{package Plack::Handler::Stomp::Exceptions::AppError;
 use Moose;with 'Throwable','Plack::Handler::Stomp::Exceptions::Stringy';
 has '+previous_exception' => (
     init_arg => 'app_error',
 );
 sub as_string {
     return 'The application died:'.$_[0]->previous_exception;
 }
}

{package Plack::Handler::Stomp::Exceptions::Stomp;
 use Moose;with 'Throwable','Plack::Handler::Stomp::Exceptions::Stringy';
 has '+previous_exception' => (
     init_arg => 'stomp_error',
 );
 sub as_string {
     return 'STOMP protocol/network error:'.$_[0]->previous_exception;
 }
}

{package Plack::Handler::Stomp::Exceptions::OneShot;
 use Moose;with 'Throwable';
}

1;
