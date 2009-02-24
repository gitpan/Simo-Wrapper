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
    my $t = Simo::Wrapper->create( obj => T1->new );
    
    $@ = undef;
    $t->validate( m1 => sub{ 1 }, m2 => sub{ 1 } );
    ok( !$@, 'value is valid' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    
    eval{ $t->validate( m1 => sub{ $_[1]->{a} = 1; $_[1]->{b} = $_[0]; return 0 } ) };
    isa_ok( $@, 'Simo::Error' );
    is_deeply( [ $@->type, $@->msg, $@->pkg, $@->attr, $@->val, $@->info->{ a }, $@->info->{ b } ],
               [ 'value_invalid', 'T1::m1 must be valid value', 'T1', 'm1', 5, 1, 5 ],
               'valdate' );
} 

{
    my $t = Simo::Wrapper->create( obj => 'T1' );
    eval{ $t->validate };
    like( $@, qr/Cannot call 'validate' from class/, 'called from pkg' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    eval{ $t->validate( 'm1' ) };
    like( $@, qr/key-value pairs must be passed to 'validate'/, 'called from pkg' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    eval{ $t->validate( noexist => sub{} ) };
    like( $@, qr/Attr 'noexist' is not exist/, 'called from pkg' );
}

{
    my $t = Simo::Wrapper->create( obj => T1->new );
    eval{ $t->validate( m1 => [] ) };
    like( $@, qr/Value must be code reference/, 'called from pkg' );
}


