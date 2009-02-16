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
    my $t = Simo::Wrapper->create( obj => T1->new );
    
    my( $x, $y ) = $t->get_attrs( 'x', 'y' );
    is_deeply( [ $x, $y ], [ 1, 2 ], 'pass array, list context' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    my( $x, $y ) = $t->get_attrs( [ 'x', 'y' ] );
    is_deeply( [ $x, $y ], [ 1, 2 ], 'pass array ref, list context' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    
    my $x = $t->get_attrs( 'x' );
    is( $x, 1, 'pass array ref, scalar context' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    
    eval{ $t->get_attrs( 'z' ) };
    
    like( $@, qr/Invalid key 'z' is passed to get_attrs/, 'no exist key' );
}

{
    my $t = Simo::Wrapper->create( obj => '###' );
    eval{ $t->get_attrs( 'T' ) };
    
    like( $@, qr/'get_attrs' must be called from object/, 'not object' );
}


