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
    my $org_obj = T1->new;
    $org_obj->a1; # a1 is initialize;
    
    my $freezed = Storable::freeze( $org_obj );
    
    my $obj = Simo::Wrapper->thaw( $freezed );
    my $obj_exp = Storable::thaw( $freezed );
    
    is_deeply( $obj, $obj_exp, 'thawed data is same' );
    is( ref $obj, 'T1', 'thawed class is same' );
    
}

__END__

