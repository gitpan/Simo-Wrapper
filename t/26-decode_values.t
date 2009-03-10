use strict;
use warnings;

use Test::More 'no_plan';

package T1;
use Simo;

sub a1{ ac default => 'あ' }
sub a2{ ac default =>  [ 'あ', 'い' ] }
sub a3{ ac default => { a => 'あ', b => 'い' } }
sub a4{ ac default => qr// }
sub a5{ ac default => [ [] ] }
sub a6{ ac default => { a => {} }, }

package main;
use utf8;
use Simo::Wrapper;

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    $t->decode_values( 'utf8', 'a1' );
    is( $t->obj->a1, 'あ', 'string decode' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    $t->decode_values( 'utf8', 'a2' );
    is_deeply( $t->obj->a2, [ 'あ', 'い' ], 'array string decode' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    $t->decode_values( 'utf8', 'a3' );
    is_deeply( $t->obj->a3, { a => 'あ', b => 'い' }, 'hash string decode' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    $t->decode_values( 'utf8', qw( a1 a2 a3 ) );
    is( $t->obj->a1, 'あ', 'mutil attrs decode 1' );
    is_deeply( $t->obj->a2, [ 'あ', 'い' ], 'mutil attrs decode 2' );
    is_deeply( $t->obj->a3, { a => 'あ', b => 'い' }, 'mutil attrs decode 3' );
}

{
    my $t = Simo::Wrapper->create( obj => 'Book' );
    eval{ $t->decode_values( 'utf8', 'a1' ) };
    like( $@, qr/'decode_values' must be called from object/, 'called from not object' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    eval{ $t->decode_values( 'utf8', 'noexist' ) };
    like( $@, qr/'noexist' is not exist./, 'called from not object' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    my $warn;
    local $SIG{__WARN__} = sub{
        $warn = shift;
    };
    
    $t->decode_values( 'utf8', 'a4' );
    like( $warn, qr/\$self->{ 'a4' } must be string or array ref or hash ref\. Decode is not done/, 'not string' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    my $warn;
    local $SIG{__WARN__} = sub{
        $warn = shift;
    };
    
    $t->decode_values( 'utf8', 'a5' );
    like( $warn, qr/\$self->{ 'a5' }\[ 0 \] must be string\. Decode is not done/, 'not string' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    my $warn;
    local $SIG{__WARN__} = sub{
        $warn = shift;
    };
    
    $t->decode_values( 'utf8', 'a6' );
    like( $warn, qr/\$self->{ 'a6' }{ 'a' } must be string\. Decode is not done/, 'not string' );
}

__END__

