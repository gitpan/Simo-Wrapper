use strict;
use warnings;

use Test::More 'no_plan';

package T1;
use Simo;

sub connect{
    return shift->SUPER::new( @_ );
}

sub x{ ac default => 1 }
sub y{ ac default => 2 }

package main;
use Simo::Wrapper;

{
    my $t = Simo::Wrapper->create( obj => 'T1' );
    my $obj = $t->connect( x => 1, y => 2 );
    isa_ok( $obj, 'T1', 'isa ok' );
    is_deeply( $obj, { x => 1, y => 2 }, 'date ok' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    my $obj = $t->connect( x => 1, y => 2 );
    isa_ok( $obj, 'T1', 'isa ok' );
    is_deeply( $obj, { x => 1, y => 2 }, 'object ok' );
}

{
    my $t = Simo::Wrapper->create( obj => [] );
    eval{ $t->connect };
    like( $@, qr/'connect' must be called from class or object/, 'called not object or Class' );
}

{
    my $t = Simo::Wrapper->create( obj => 'Carp' );
    eval{ $t->connect };
    like( $@, qr/'Carp' must be have 'connect'/, 'called not object or Class' );
}