#!/usr/bin/perl

use lib qw{ lib t/lib };
use Test::Most;
require Test::NoWarnings;
use Math::Business::BlackScholes::Binaries;
use Roundnear;

my $S     = 1.35;
my $S2    = 1.37;
my $barrier = 1.36;
my $t = 0.5 / ( 60 * 60 * 24 * 365 );    # 500 ms in years;
my $sigma = 0.11;
my $r     = 0.002;
my $q     = 0.001;

my $price_digitalcall = Math::Business::BlackScholes::Binaries::digitalcall(
    $S, $barrier, $t, $r, $r-$q, $sigma
);
ok ($price_digitalcall == 0, 'price_digitalcall');

my $price_digitalput = Math::Business::BlackScholes::Binaries::digitalput(
    $S, $barrier, $t, $r, $r-$q, $sigma
);
ok ( roundnear(0.01, $price_digitalput) == 1, 'price_digitalput');

$price_digitalcall = Math::Business::BlackScholes::Binaries::digitalcall(
    $S2, $barrier, $t, $r, $r-$q, $sigma
);
ok ( roundnear(0.01, $price_digitalcall) == 1, 'price_digitalcall');

$price_digitalput = Math::Business::BlackScholes::Binaries::digitalput(
    $S2, $barrier, $t, $r, $r-$q, $sigma
);
ok ( roundnear(0.01, $price_digitalput) == 0, 'price_digitalput');

Test::NoWarnings::had_no_warnings();
done_testing();

