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
    destination => Destination,
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


subtype PathMap, as Map[PathMapKey,Path];

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Plack::Handler::Stomp::Types - type definitions for Plack::Handler::Stomp

=head1 VERSION

version 0.001_01

=head1 TYPES

=head2 C<NetStompish>

Any object that can C<connect>, C<subscribe>, C<unsubscribe>,
C<receive_frame>, C<ack>, C<send>.

=head2 C<Logger>

Any object that can C<debug>, C<info>, C<warn>, C<error>.

=head2 C<Hostname>

A string.

=head2 C<PortNumber>

An integer between 1 and 65535.

=head2 C<ServerConfig>

A hashref having a C<hostname> key (with value matching L</Hostname>),
a C<port> key (value matching L</PortNumber>), and optionally a
C<connect_headers> key (with a hashref value) and a
C<subscribe_headers> key (with a hashref value). See
L<Plack::Handler::Stomp/connect> and
L<Plack::Handler::Stomp/subscribe>.

=head2 C<ServerConfigList>

An arrayref of L</ServerConfig> values. Can be coerced from a single
L</ServerConfig>.

=head2 C<Headers>

A hashref.

=head2 C<SubscriptionConfig>

A hashref having a C<destination> key (with a value matching
L</Destination>), and optionally a C<path_info> key (with value
matching L</Path>) and a C<headers> key (with a hashref value). See
L<Plack::Handler::Stomp/subscribe>.

=head2 C<SubscriptionConfigList>

An arrayref of L</SubscriptionConfig> values. Can be coerced from a
single L</SubscriptionConfig>.

=head2 C<Destination>

A string starting with C</queue/> or C</topic/>.

=head2 C<PathMapKey>

A string starting with C</queue/>, C</topic/> or C</subscription/>.

=head2 C<Path>

A non-empty string.

=head2 C<PathMap>

A hashref with keys maching L</PathMapKey> and values maching L</Path>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

