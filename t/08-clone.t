use strict;
use warnings;
use Storable;

use Test::More 'no_plan';

package T1;
use Simo;

sub a1{ ac default => 1 }
sub a2{ ac default => 2 }



package main;
use Simo::Wrapper;

{
    my $obj = T1->new;
    $obj->a1; # a1 is initialize;
    
    my $t = Simo::Wrapper->create( obj => $obj );
    
    my $copy = $t->clone;
    my $copy_exp = Storable::dclone( $obj );
    
    is_deeply( $copy, $copy_exp, 'object data is same' );
    is( ref $copy, 'T1', 'blessed class' );
}

{
    my $t = Simo::Wrapper->create( obj => 'T1' );
    eval{ $t->clone };
    like( $@, qr/'clone' must be called from object/, 'must be callsed from object' );
}

__END__

