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

my $price_digital_call = Math::Business::BlackScholes::Binaries::digital_call(
    $S, $barrier, $t, $r, $r-$q, $sigma
);
ok ($price_digital_call == 0, 'price_digital_call');

my $price_digital_put = Math::Business::BlackScholes::Binaries::digital_put(
    $S, $barrier, $t, $r, $r-$q, $sigma
);
ok ( roundnear(0.01, $price_digital_put) == 1, 'price_digital_put');

$price_digital_call = Math::Business::BlackScholes::Binaries::digital_call(
    $S2, $barrier, $t, $r, $r-$q, $sigma
);
ok ( roundnear(0.01, $price_digital_call) == 1, 'price_digital_call');

$price_digital_put = Math::Business::BlackScholes::Binaries::digital_put(
    $S2, $barrier, $t, $r, $r-$q, $sigma
);
ok ( roundnear(0.01, $price_digital_put) == 0, 'price_digital_put');

Test::NoWarnings::had_no_warnings();
done_testing();

