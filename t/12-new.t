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
    my $t = Simo::Wrapper->create( obj => 'T1' );
    $t->new( x => 1, y => 2 );
    isa_ok( $t->obj, 'T1', 'isa ok' );
    is_deeply( $t->obj, { x => 1, y => 2 }, 'date ok' );
}

{
    my $t = Simo::Wrapper->create( obj => [] );
    eval{ $t->new };
    like( $@, qr/'new' must be called form class or object/, 'called not object or Class' );
}

