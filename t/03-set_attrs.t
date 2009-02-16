use strict;
use warnings;
use Test::More 'no_plan';

package T1;
use Simo;

sub x{ ac }
sub y{ ac }

package main;
use Simo::Wrapper;

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    my $ret = $t->set_attrs( x => 1, y => 2 );
    
    is_deeply( $t->obj, { x => 1, y => 2 }, 'pass hash' );
    
    $t->set_attrs( { x => 3, y => 4 } );
    is_deeply( $t->obj, { x => 3, y => 4 }, 'pass hash ref' );
    
    eval{ $t->set_attrs( 1 ) };
    like( $@, qr/key-value pairs must be passed to set_attrs/, 'no key value pairs' );
    
    eval{ $t->set_attrs( z => 1 ) };
    like( $@, qr/Invalid key 'z' is passed to set_attrs/, 'invalid key' );
    
    is( ref $t->set_attrs, 'Simo::Wrapper', 'retrun value is Simo::Wrapper' );
}

{
    my $t = Simo::Wrapper->create( obj => '###' );
    eval{ $t->set_attrs( x => 1 ) };
    
    like( $@, qr/'set_attrs' must be called from object/, 'not object' );
}

