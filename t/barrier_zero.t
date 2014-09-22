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
my $barrier_l = exp(-6);
my $barrier_h = 1.36;

# digitalcall
my $price_digitalcall = Math::Business::BlackScholes::Binaries::digitalcall(
    $S, $barrier_l, 7/365, 0.002, 0.001, 0.11
);
ok ( roundnear(0.01, $price_digitalcall) == 1, 
    'digitalcall (' . $price_digitalcall . ') -> 1');

# digitalput
my $price_digitalput = Math::Business::BlackScholes::Binaries::digitalput(
    $S, $barrier_l, 7/365, 0.002, 0.001, 0.11
);
ok ( roundnear(0.01, $price_digitalput) == 0, 
    'digitalput (' . $price_digitalput . ') -> 0');

# onetouch
my $price_onetouch = Math::Business::BlackScholes::Binaries::onetouch(
    $S, $barrier_l, 7/365, 0.002, 0.001, 0.11
);
ok ( roundnear(0.01, $price_onetouch) == 0, 
    'onetouch (' . $price_onetouch . ') -> 0');

# notouch
my $price_notouch = Math::Business::BlackScholes::Binaries::notouch(
    $S, $barrier_l, 7/365, 0.002, 0.001, 0.11
);
ok ( roundnear(0.01, $price_notouch) == 1, 
    'notouch (' . $price_notouch . ') -> 1');

# doubleonetouch
my $price_doubleonetouch = Math::Business::BlackScholes::Binaries::doubleonetouch(
    $S, $barrier_h, $barrier_l, 7/365, 0.002, 0.001, 0.11
);

# onetouch at higher barrier
my $price_onetouch_higher_barrier = Math::Business::BlackScholes::Binaries::onetouch(
    $S, $barrier_h, 7/365, 0.002, 0.001, 0.11
);

ok ( $price_doubleonetouch == $price_onetouch_higher_barrier,
    'doubleonetouch (lower barrier) -> onetouch (higher barrier)' );

# doublenotouch
my $price_doublenotouch =
Math::Business::BlackScholes::Binaries::doublenotouch(
    $S, $barrier_h, $barrier_l, 7/365, 0.002, 0.001, 0.11
);
# notouch at higher barrier
my $price_notouch_higher_barrier = Math::Business::BlackScholes::Binaries::notouch(
    $S, $barrier_h, 7/365, 0.002, 0.001, 0.11
);
ok ( $price_doublenotouch == $price_notouch_higher_barrier,
    'doublenotouch (lower barrier) -> notouch (higher barrier)' );

Test::NoWarnings::had_no_warnings();
done_testing();

