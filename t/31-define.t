use strict;
use warnings;

use Test::More 'no_plan';

use Simo::Wrapper;

{
    my $w = Simo::Wrapper->create( obj => 'T1' );
    $w->define( 'm1', 'm2' );
    
    my $t1 = T1->new( m1 => 1, m2 => 2 );
    is_deeply( $t1, { m1 => 1, m2 => 2 }, 'define ok' );
    isa_ok( $t1, 'T1' );
}

{
    my $w = Simo::Wrapper->create( obj => '&' );
    eval{ $w->define };
    like( $@, qr/'define' must be called from class name/, 'not class name' );
}

{
    my $w = Simo::Wrapper->create( obj => 'T2' );
    eval{ $w->define( '3' ) };
    like( $@, qr/accessor must be method name/, 'not method name' );
}

