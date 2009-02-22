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
    
    isa_ok( $t, 'Simo::Wrapper' );
    is( $t->obj, 'T1' );
}


