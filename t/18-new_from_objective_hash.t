use strict;
use warnings;

use Test::More 'no_plan';

package T1;
use Simo;

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
    my $hash = {
        __CLASS => 'T1',
        m1 => 1,
        m2 => { a => 2, b => 3 },
        m3 => 4,
        m4 => { __CLASS => 'T2', __CLASS_CONSTRUCTOR => 'create',  m1 => 1, m2 => 2 },
        m5 => 5
    };
    my $wrapper = Simo::Wrapper->create;
    my $obj = $wrapper->new_from_objective_hash( $hash );
    
    is_deeply( $obj, { m1 => 1, m2 => { a => 2, b => 3 }, m3 => 4, m4 => { m1 => 1, m2 => 2 }, m5 => 5 }, 'internal data' );
    isa_ok( $obj, 'T1' );
    isa_ok( $obj->m4, 'T2' );
}

{
    my %hash = (
        m1 => 1,
        m2 => { a => 2, b => 3 },
        m3 => 4,
        m4 => { __CLASS => 'T2', __CLASS_CONSTRUCTOR => 'create',  m1 => 1, m2 => 2 },
        m5 => 5
    );
    my $wrapper = Simo::Wrapper->create( obj => 'T1' );
    my $obj = $wrapper->new_from_objective_hash( %hash );
    
    is_deeply( $obj, { m1 => 1, m2 => { a => 2, b => 3 }, m3 => 4, m4 => { m1 => 1, m2 => 2 }, m5 => 5 }, 'internal data' );
    isa_ok( $obj, 'T1' );
    isa_ok( $obj->m4, 'T2' );
}


{
    my @hash = (
        1
    );
    my $wrapper = Simo::Wrapper->create;
    eval{ $wrapper->new_from_objective_hash( @hash ) };
    like( $@, qr/key-value pairs must be passed to 'new_from_objective_hash'/, 'not key-value pair' );
}

{
    my $hash = {
        __CLASS => 'T1',
        __CLASS_CONSTRUCTOR => 'noexist',
        m1 => 1,
        m2 => { a => 2, b => 3 },
        m3 => 4,
        m4 => { __CLASS => 'T2', __CLASS_CONSTRUCTOR => 'create',  m1 => 1, m2 => 2 },
        m5 => 5
    };
    my $wrapper = Simo::Wrapper->create;
    eval{ $wrapper->new_from_objective_hash( $hash ) };
    like( $@, qr/'T1' do not have 'noexist' method/, 'not exist constructor' );
    
}