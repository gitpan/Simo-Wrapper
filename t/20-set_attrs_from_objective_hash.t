use strict;
use warnings;
use Test::More 'no_plan';

package T1;
use Simo;

sub x{ ac }
sub y{ ac }
sub m1{ ac }
sub m2{ ac }
sub m3{ ac }
sub m4{ ac }
sub m5{ ac }

package T2;
use Simo;

sub create{
    return shift->SUPER::new( @_ );
}

sub m1{ ac }
sub m2{ ac }

package main;
use Simo::Wrapper;

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    my $ret = $t->set_attrs_from_objective_hash( x => 1, y => 2 );
    
    is_deeply( $t->obj, { x => 1, y => 2 }, 'pass hash' );
    
    $t->set_attrs_from_objective_hash( { x => 3, y => 4 } );
    is_deeply( $t->obj, { x => 3, y => 4 }, 'pass hash ref' );
    
    eval{ $t->set_attrs_from_objective_hash( 1 ) };
    like( $@, qr/key-value pairs must be passed to 'set_attrs_from_objective_hash'/, 'no key value pairs' );
    
    eval{ $t->set_attrs_from_objective_hash( z => 1 ) };
    like( $@, qr/Invalid key 'z' is passed to 'set_attrs_from_objective_hash'/, 'invalid key' );
    
    is( ref $t->set_attrs_from_objective_hash, 'Simo::Wrapper', 'retrun value is Simo::Wrapper' );
}

{
    my $t = Simo::Wrapper->create( obj => '###' );
    eval{ $t->set_attrs_from_objective_hash( x => 1 ) };
    
    like( $@, qr/'set_attrs_from_objective_hash' must be called from object/, 'not object' );
}

{
    my $hash = {
        __CLASS => 'Dummy',
        __CLASS_CONSTRUCTOR => 'Dummy',
        m1 => 1,
        m2 => { a => 2, b => 3 },
        m3 => 4,
        m4 => { __CLASS => 'T2', __CLASS_CONSTRUCTOR => 'create',  m1 => 1, m2 => 2 },
        m5 => 5
    };
    
    my $t1 = T1->new;
    my $wrapper = Simo::Wrapper->create( obj => $t1 ) ;
    $wrapper->set_attrs_from_objective_hash( $hash );
    
    is_deeply( $t1, { m1 => 1, m2 => { a => 2, b => 3 }, m3 => 4, m4 => { m1 => 1, m2 => 2 }, m5 => 5 }, 'internal data' );
    isa_ok( $t1, 'T1' );
    isa_ok( $t1->m4, 'T2' );
    
}

