
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.06

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Plack/Handler/Stomp.pm',
    'lib/Plack/Handler/Stomp/Exceptions.pm',
    'lib/Plack/Handler/Stomp/NoNetwork.pm',
    'lib/Plack/Handler/Stomp/PathInfoMunger.pm',
    'lib/Plack/Handler/Stomp/StupidLogger.pm',
    'lib/Plack/Handler/Stomp/Types.pm',
    'lib/Test/Plack/Handler/Stomp.pm',
    'lib/Test/Plack/Handler/Stomp/FakeStomp.pm'
);

notabs_ok($_) foreach @files;
done_testing;
