#!/usr/bin/perl

use lib qw{ lib t/lib };
use Test::Most;
require Test::NoWarnings;
use Math::Business::BlackScholes::Binaries;
use Roundnear;

my $S     = 1.35;
my $t     = 7 / 365;
my $sigma = 0.11;
my $r     = 0.002;
my $q     = 0.001;
my $barrier_h = exp(6);
my $barrier_l = 1.34;

# digitalcall
my $price_digitalcall = Math::Business::BlackScholes::Binaries::digitalcall(
    $S, $barrier_h, 7/365, 0.002, 0.001, 0.11
);
ok ( roundnear(0.01, $price_digitalcall) == 0, 
    'digitalcall (' . $price_digitalcall . ') -> 0');

# digitalput
my $price_digitalput = Math::Business::BlackScholes::Binaries::digitalput(
    $S, $barrier_h, 7/365, 0.002, 0.001, 0.11
);
ok ( roundnear(0.01, $price_digitalput) == 1, 
    'digitalput (' . $price_digitalput . ') -> 1');

# onetouch
my $price_onetouch = Math::Business::BlackScholes::Binaries::onetouch(
    $S, $barrier_h, 7/365, 0.002, 0.001, 0.11
);
ok ( roundnear(0.01, $price_onetouch) == 0, 
    'onetouch (' . $price_onetouch . ') -> 0');

# notouch
my $price_notouch = Math::Business::BlackScholes::Binaries::notouch(
    $S, $barrier_h, 7/365, 0.002, 0.001, 0.11
);
ok ( roundnear(0.01, $price_notouch) == 1, 
    'notouch (' . $price_notouch . ') -> 1');

# doubleonetouch
my $price_doubleonetouch = Math::Business::BlackScholes::Binaries::doubleonetouch(
    $S, $barrier_h, $barrier_l, 7/365, 0.002, 0.001, 0.11
);
# onetouch at lower barrier
my $price_onetouch_lower_barrier = Math::Business::BlackScholes::Binaries::onetouch(
    $S, $barrier_l, 7/365, 0.002, 0.001, 0.11
);
ok ( $price_doubleonetouch == $price_onetouch_lower_barrier,
    'doubleonetouch (higher barrier) -> onetouch (lower barrier)' );

# doublenotouch
my $price_doublenotouch =
Math::Business::BlackScholes::Binaries::doublenotouch(
    $S, $barrier_h, $barrier_l, 7/365, 0.002, 0.001, 0.11
);
# notouch at lower barrier
my $price_notouch_lower_barrier = Math::Business::BlackScholes::Binaries::notouch(
    $S, $barrier_l, 7/365, 0.002, 0.001, 0.11
);
ok ( $price_doublenotouch == $price_notouch_lower_barrier,
    'doublenotouch (higher barrier) -> notouch (lower barrier)' );

Test::NoWarnings::had_no_warnings();
done_testing();

