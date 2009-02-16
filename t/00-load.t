#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Simo::Wrapper' );
}

diag( "Testing Simo::Wrapper $Simo::Wrapper::VERSION, Perl $], $^X" );
