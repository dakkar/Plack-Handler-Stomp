
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Plack handler for the STOMP protocol",
  "AUTHOR" => "Gianni Ceccarelli <gianni.ceccarelli\@net-a-porter.com>",
  "BUILD_REQUIRES" => {
    "Alien::ActiveMQ" => 0,
    "JSON::XS" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "Net::Stomp::Frame" => 0,
    "Test::More" => 0,
    "Test::Routine" => 0,
    "Test::Routine::Util" => 0,
    "parent" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Plack-Handler-Stomp",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Plack::Handler::Stomp",
  "PREREQ_PM" => {
    "HTTP::Request" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Common::Numeric" => 0,
    "MooseX::Types::Common::String" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Structured" => 0,
    "Net::Stomp" => 0,
    "Plack::Handler::Stomp::Exceptions::Stringy" => 0,
    "Plack::Util" => 0,
    "Sub::Exporter" => 0,
    "Throwable" => 0,
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.001_01",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



