package Plack::Handler::Stomp;
use Moose;
use List::MoreUtils qw/ uniq /;
use HTTP::Request;
use Net::Stomp;
use MooseX::Types::Moose qw/Str Int HashRef/;
use namespace::autoclean;
use Encode;

# ABSTRACT: adapt STOMP to (almost) HTTP, via Plack

1;
