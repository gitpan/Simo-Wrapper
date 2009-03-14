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
    
    my $point = $t->get_attrs_as_hash( 'x', 'y' );
    is_deeply( $point, { x => 1, y => 2 }, 'scalar context' );
}

{
    my $t = Simo::Wrapper->create( obj => '###' );
    eval{ $t->get_attrs_as_hash( 'x' ) };
    
    like( $@, qr/'get_hash' must be called from object/, 'not object' );
}

