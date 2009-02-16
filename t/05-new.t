use Test::More 'no_plan';
use strict;
use warnings;

package T1;
use Simo;

sub a1{ ac }

package main;
use Simo::Wrapper;

{
    my $t = Simo::Wrapper->create( obj => 'T1' );
    my $o = $t->new;
    
    is( ref $o, 'Simo::Wrapper' );
    is( ref $o->obj, 'T1' );
}

{
    my $t = Simo::Wrapper->create( obj => [] );
    eval{ $t->new };
    like( $@, qr/'new' must be called form class or object/, 'obj is not object' );
}

{
    my $t = Simo::Wrapper->create( obj => '###' );
    eval{ $t->new };
    like( $@, qr/'new' must be called form class or object/, 'obj is not class name' );
}

