use strict;
use warnings;

use Test::More 'no_plan';


package T1;
sub new{};

package main;
use Simo::Wrapper;

{
    my $t = Simo::Wrapper->create( obj => 'CGI' );
    my $loaded = $t->loaded;
    ok( !$loaded, 'not loaded' );
}

{
    require CGI;
    my $t = Simo::Wrapper->create( obj => 'CGI' );
    my $loaded = $t->loaded;
    ok( $loaded, 'loaded' );
}
{
    my $t = Simo::Wrapper->create( obj => 'T1' );
    my $loaded = $t->loaded;
    ok( $loaded, 'loaded' );
}

{
    my $t = Simo::Wrapper->create( obj => [] );
    eval{ $t->loaded };
    like( $@, qr/'loaded' must be called from class/, 'not class name' );
}


