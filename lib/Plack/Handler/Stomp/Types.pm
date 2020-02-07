package Plack::Handler::Stomp::Types;
use MooseX::Types -declare =>
    [qw(
           Logger
           PathMapKey Path
           PathMap
   )];
use MooseX::Types::Moose qw(Str);
use MooseX::Types::Structured qw(Map);
use MooseX::Types::Common::String qw(NonEmptySimpleStr);
use namespace::autoclean;

# ABSTRACT: type definitions for Plack::Handler::Stomp

=head1 TYPES

=head2 C<Logger>

Any object that can C<trace>, C<debug>, C<info>, C<warn>, C<error>.

=cut

duck_type Logger, [qw(trace debug info
                      warn error)];

=head2 C<PathMapKey>

A string starting with C</queue/>, C</topic/> or C</subscription/>.

=cut

subtype PathMapKey, as Str,
    where { m{^/(?:queue|topic|subscription)/} };

=head2 C<Path>

A non-empty string.

=cut

subtype Path, as NonEmptySimpleStr;

=head2 C<PathMap>

A hashref with keys maching L</PathMapKey> and values maching L</Path>.

=cut

subtype PathMap, as Map[PathMapKey,Path];

1;
