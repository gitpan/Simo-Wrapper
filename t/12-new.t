use strict;
use warnings;

use Test::More 'no_plan';

package T1;
use Simo;

sub x{ ac default => 1 }
sub y{ ac default => 2 }

package T2;
use Simo;

package main;
use Simo::Wrapper;

{
    my $t = Simo::Wrapper->create( obj => 'T1' );
    my $obj = $t->new( x => 1, y => 2 );
    isa_ok( $obj, 'T1', 'isa ok' );
    is_deeply( $obj, { x => 1, y => 2 }, 'date ok' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    my $obj = $t->new( x => 1, y => 2 );
    isa_ok( $obj, 'T1', 'isa ok' );
    is_deeply( $obj, { x => 1, y => 2 }, 'object ok' );
}

{
    my $t = Simo::Wrapper->create( obj => 'CGI' );
    my $q = $t->new;
    isa_ok( $q, 'CGI' );
}

{
    my $t = Simo::Wrapper->create( obj => 'CGI' );
    my $q = $t->new;
    isa_ok( $q, 'CGI' );
}

{
    my $t = Simo::Wrapper->create( obj => [] );
    eval{ $t->new };
    like( $@, qr/'new' must be called from class or object/, 'called not object or Class' );
}

{
    my $t = Simo::Wrapper->create( obj => 'Carp' );
    eval{ $t->new };
    like( $@, qr/'Carp' must be have 'new'/, 'called not object or Class' );
}