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

# digitalcall + digitalput = 1
my $price_digitalcall = Math::Business::BlackScholes::Binaries::digitalcall(
    $S, 1.36, 7/365, 0.002, 0.001, 0.11
);
my $price_digitalput = Math::Business::BlackScholes::Binaries::digitalput(
    $S, 1.36, 7/365, 0.002, 0.001, 0.11
);

my $rounded_price_digitalcall = roundnear(0.01, $price_digitalcall);
my $rounded_price_digitalput = roundnear(0.01, $price_digitalput);
ok ($rounded_price_digitalcall + $rounded_price_digitalput == 1, 
    'digitalcall + digitalput = 1');


# onetouch + notouch = 1
my $price_onetouch = Math::Business::BlackScholes::Binaries::onetouch(
    $S, 1.36, 7/365, 0.002, 0.001, 0.11
);
my $price_notouch = Math::Business::BlackScholes::Binaries::notouch(
    $S, 1.36, 7/365, 0.002, 0.001, 0.11
);

my $rounded_price_onetouch = roundnear(0.01, $price_onetouch);
my $rounded_price_notouch = roundnear(0.01, $price_notouch);
ok ($rounded_price_onetouch + $rounded_price_notouch == 1, 
    'onetouch + notouch = 1');


# endsbetween + endsoutside = 1
my $price_endsbetween = Math::Business::BlackScholes::Binaries::endsbetween(
    $S, 1.36, 1.34, 7/365, 0.002, 0.001, 0.11
);
my $price_endsoutside = Math::Business::BlackScholes::Binaries::endsoutside(
    $S, 1.36, 1.34, 7/365, 0.002, 0.001, 0.11
);

my $rounded_price_endsbetween = roundnear(0.01, $price_endsbetween);
my $rounded_price_endsoutside = roundnear(0.01, $price_endsoutside);
ok ($rounded_price_endsbetween + $rounded_price_endsoutside == 1, 
    'endsbetween + endsoutside = 1');


# doublenotouch + doubleonetouch = 1
my $price_doublenotouch = Math::Business::BlackScholes::Binaries::doublenotouch(
    $S, 1.36, 1.34, 7/365, 0.002, 0.001, 0.11
);
my $price_doubleonetouch = Math::Business::BlackScholes::Binaries::doubleonetouch(
    $S, 1.36, 1.34, 7/365, 0.002, 0.001, 0.11
);

my $rounded_price_doublenotouch = roundnear(0.01, $price_doublenotouch);
my $rounded_price_doubleonetouch = roundnear(0.01, $price_doubleonetouch);
ok ($rounded_price_doublenotouch + $rounded_price_doubleonetouch == 1, 
    'doublenotouch + doubleonetouch = 1');

Test::NoWarnings::had_no_warnings();
done_testing();

