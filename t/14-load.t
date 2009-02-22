use strict;
use warnings;

use Test::More 'no_plan';

package T1;
use Simo;

sub x{ ac default => 1 }
sub y{ ac default => 2 }

package main;
use Simo::Wrapper;

{
    my $t = Simo::Wrapper->create( obj => 'CGI' );
    my $ret = $t->load;
    ok( $t->loaded, 'load' );
    is( $ret, $t, 'return val' );
}

{
    my $t = Simo::Wrapper->create( obj => 'CGIasdfjajoijwoeiajflaksjdfoijeiojjasdf' );
    eval{ $t->load };
    like( $@, qr/Cannot load 'CGIasdfjajoijwoeiajflaksjdfoijeiojjasdf'/, 'cannot load class' );
}

{
    my $t = Simo::Wrapper->create( obj => [] );
    eval{ $t->load };
    like( $@, qr/'load' must be called from class/, 'not class name' );
}


