package Plack::Handler::Stomp::Types;
{
  $Plack::Handler::Stomp::Types::VERSION = '0.001_01';
}
{
  $Plack::Handler::Stomp::Types::DIST = 'Plack-Handler-Stomp';
}
use MooseX::Types -declare =>
    [qw(
           NetStompish Logger
           Hostname PortNumber
           ServerConfig ServerConfigList
           Headers
           SubscriptionConfig SubscriptionConfigList
           Destination PathMapKey Path
           PathMap
   )];
use MooseX::Types::Moose qw(Bool Str Value Int ArrayRef HashRef CodeRef);
use MooseX::Types::Structured qw(Dict Optional Map);
use MooseX::Types::Common::String qw(NonEmptySimpleStr);

# ABSTRACT: type definitions for Plack::Handler::Stomp

duck_type NetStompish, [qw(connect
                           subscribe unsubscribe
                           receive_frame ack
                           send)];

duck_type Logger, [qw(debug info
                      warn error)];

subtype Hostname, as Str; # maybe too lax?
subtype PortNumber, as Int,
    where { $_ > 0 and $_ < 65536 };

subtype ServerConfig, as Dict[
    hostname => Hostname,
    port => PortNumber,
    connect_headers => Optional[HashRef],
    subscribe_headers => Optional[HashRef],
];
subtype ServerConfigList, as ArrayRef[ServerConfig];
coerce ServerConfigList, from ServerConfig, via { [shift] };

subtype Headers, as Map[Str,Value];

subtype SubscriptionConfig, as Dict[
    destination => Str,
    path_info => Optional[Str],
    headers => Optional[Map[Str,Value]],
];
subtype SubscriptionConfigList, as ArrayRef[SubscriptionConfig];
coerce SubscriptionConfigList, from SubscriptionConfig, via { [shift] };

subtype Destination, as Str,
    where { m{^/(?:queue|topic)/} };

subtype PathMapKey, as Str,
    where { m{^/(?:queue|topic|subscription)/} };

subtype Path, as NonEmptySimpleStr;

subtype PathMap, as Map[PathMapKey,PathMap];

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Plack::Handler::Stomp::Types - type definitions for Plack::Handler::Stomp

=head1 VERSION

version 0.001_01

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

