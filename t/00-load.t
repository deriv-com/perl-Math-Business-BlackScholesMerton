#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use lib 'lib';

plan tests => 1;

BEGIN {
    use_ok( 'Math::Business::BlackScholes::Binaries' ) || print "Bail out!\n";
}

diag( "Testing Math::Business::BlackScholes::Binaries $Math::Business::BlackScholes::Binaries::VERSION, Perl $], $^X" );
