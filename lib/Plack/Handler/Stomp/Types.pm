package Plack::Handler::Stomp::Types;
use MooseX::Types -declare =>
    [qw(
           NetStompish
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

duck_type NetStompish, [qw(connect
                           subscribe unsubscribe
                           receive_frame ack
                           send)];

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
