use strict;
use warnings;

use Test::More 'no_plan';

package T1;
use Simo;

sub a1{ ac default => '1' }
sub a2{ ac default =>  [ '1', '2' ] }
sub a3{ ac default => { a => '1', b => '2' } }

package main;
use Simo::Wrapper;

my $info_list = [];
sub f1{
    my ( $val, $info )  = @_;
    push @{ $info_list }, $info;
    return $val * 2;
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    $info_list = [];
    
    $t->filter_values( \&f1, 'a1' );
    is( $t->obj->a1, 2, 'string filter' );
    is_deeply( $info_list, [ { type => 'SCALAR', attr => 'a1', self => $t->obj } ], 'string filter info' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    $info_list = [];
    
    $t->filter_values( \&f1, 'a2' );
    is_deeply( $t->obj->a2, [ 2, 4 ], 'array string filter' );
    is_deeply( 
        $info_list, 
        [ { type => 'ARRAY', attr => 'a2', index => 0, self => $t->obj },
          { type => 'ARRAY', attr => 'a2', index => 1, self => $t->obj } ],
        'array string filter info' 
    );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    $info_list = [];

    $t->filter_values( \&f1, 'a3' );
    is_deeply( $t->obj->a3, { a => 2, b => 4 }, 'hash string filter' );
    
    $info_list = [ sort { $a->{ key } cmp $b->{ key } } @{ $info_list } ];
    is_deeply( 
        $info_list, 
        [ { type => 'HASH', attr => 'a3', key => 'a', self => $t->obj },
          { type => 'HASH', attr => 'a3', key => 'b', self => $t->obj } ],
        'hash string filter info' 
    );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    $t->filter_values( \&f1, qw( a1 a2 a3 ) );
    is( $t->obj->a1, 2, 'mutil attrs filter 1' );
    is_deeply( $t->obj->a2, [ 2, 4 ], 'mutil attrs filter 2' );
    is_deeply( $t->obj->a3, { a => 2, b => 4 }, 'mutil attrs filter 3' );
}

{
    my $t = Simo::Wrapper->create( obj => 'Book' );
    eval{ $t->filter_values( \&f1, 'a1' ) };
    like( $@, qr/'filter_values' must be called from object/, 'called from not object' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    eval{ $t->filter_values( {}, 'a1' ) };
    like( $@, qr/First argument must be code reference/, 'not pass code ref' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    eval{ $t->filter_values( \&f1, 'noexist' ) };
    like( $@, qr/'noexist' is not exist./, 'called from not object' );
}

__END__

