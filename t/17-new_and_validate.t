use strict;
use warnings;

use Test::More 'no_plan';

package T1;
use Simo;

sub m1{ ac default => 5 }
sub m2{ ac }

package main;
use Simo::Wrapper;

{
    my $w = Simo::Wrapper->create( obj => 'T1' );
    my $t1 = $w->new_and_validate(
        m1 => 1, sub{ 1 },
        m2 => 2, sub{ 1 },
    );
    
    isa_ok( $t1, 'T1' );
    is_deeply( $t1, { m1 => 1, m2 => 2 }, 'get instant' );
}

{
    my $w = Simo::Wrapper->create( obj => 'T1' );
    
    eval{
        my $t1 = $w->new_and_validate(
            1
        );
    };
    like( $@, qr/key-value-validator pairs must be passed to 'new_and_validate'./, 'args count is 1' );
}

{
    my $w = Simo::Wrapper->create( obj => 'T1' );
    
    eval{
        my $t1 = $w->new_and_validate(
            1, 2
        );
    };
    like( $@, qr/key-value-validator pairs must be passed to 'new_and_validate'./, 'args count is 2' );
}




