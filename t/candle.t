#!/usr/bin/perl

use lib qw{ lib t/lib };
use Test::More tests => 25;
use Test::NoWarnings;
use Math::Business::BlackScholes::Binaries;
use Roundnear;

# These are compared with Bloomberg standards...
# except EXPIRYMISS and UPORDOWN which are computed as opposing
# EXPIRYRANGE and RANGE respectively.

my @test_cases = (
    {
        spot        => 0.3172,
        range       => 0.3172,
        duration    => 0.3172,
        sigma       => 0.3172,
        prob        => 0.3172,
    },
);

foreach my $test_case (@test_cases) {

    my $actual_prob = Math::Business::BlackScholes::Binaries::candle_in(
        $test_case->{spot},
        $test_cast->{range},
        $test_case->{duration},
        $test_case->{sigma}
    );

    is( $actual_prob, $test_case->{prob});
}

