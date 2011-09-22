package MyTesting;

sub import {
    my $caller = caller();

    ## no critic ProhibitStringyEval
    eval <<"MAGIC" or die "Couldn't set up testing policy: $@";
package $caller;
use Test::Most '-Test::Deep';
use Test::Deep '!blessed';
use Data::Printer;
1;
MAGIC
    return 1;
}

1;
