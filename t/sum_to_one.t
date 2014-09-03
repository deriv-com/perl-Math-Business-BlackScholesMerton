#!/usr/bin/perl

use lib 'lib';
use Test::Most;
require Test::NoWarnings;
use Math::Business::BlackScholes::Binaries;

{

    #cf. Math::Round
    my $halfdec = do {
        my $halfhex = unpack( 'H*', pack( 'd', 0.5 ) );
        if (   substr( $halfhex, 0, 2 ) ne '00'
            && substr( $halfhex, -2 ) eq '00' )
        {
            substr( $halfhex, -4 ) = '1000';
        }
        else { substr( $halfhex, 0, 4 ) = '0010'; }
        unpack( 'd', pack( 'H*', $halfhex ) );
    };

    sub roundnear {
        my ( $targ, $input ) = @_;

        return $input if ( not defined $input );

        my $rounded = $input;

        # rounding to 0, doesnt really make sense, but viewing it as a limit 
        # process it means do not round at all
        if ( $targ != 0 ) {
            $rounded =
              ( $input >= 0 )
              ? $targ * int( ( $input + $halfdec * $targ ) / $targ )
              : $targ * ceil( ( $input - $halfdec * $targ ) / $targ );
        }

        # Avoid any possible -0 rounding situations.
        return 1 * $rounded;
    }
}

my $S     = 1.35;
my $t     = 7 / 365;
my $sigma = 0.11;
my $r     = 0.002;
my $q     = 0.001;

# digital_call + digital_put = 1
my $price_digital_call = Math::Business::BlackScholes::Binaries::digital_call(
    $S, 1.36, 7/365, 0.002, 0.001, 0.11
);
my $price_digital_put = Math::Business::BlackScholes::Binaries::digital_put(
    $S, 1.36, 7/365, 0.002, 0.001, 0.11
);

my $rounded_price_digital_call = roundnear(0.01, $price_digital_call);
my $rounded_price_digital_put = roundnear(0.01, $price_digital_put);
ok ($rounded_price_digital_call + $rounded_price_digital_put == 1, 
    'digital_call + digital_put = 1');


# one_touch + no_touch = 1
my $price_one_touch = Math::Business::BlackScholes::Binaries::one_touch(
    $S, 1.36, 7/365, 0.002, 0.001, 0.11
);
my $price_no_touch = Math::Business::BlackScholes::Binaries::no_touch(
    $S, 1.36, 7/365, 0.002, 0.001, 0.11
);

my $rounded_price_one_touch = roundnear(0.01, $price_one_touch);
my $rounded_price_no_touch = roundnear(0.01, $price_no_touch);
ok ($rounded_price_one_touch + $rounded_price_no_touch == 1, 
    'one_touch + no_touch = 1');


# ends_between + ends_outside = 1
my $price_ends_between = Math::Business::BlackScholes::Binaries::ends_between(
    $S, 1.36, 1.34, 7/365, 0.002, 0.001, 0.11
);
my $price_ends_outside = Math::Business::BlackScholes::Binaries::ends_outside(
    $S, 1.36, 1.34, 7/365, 0.002, 0.001, 0.11
);

my $rounded_price_ends_between = roundnear(0.01, $price_ends_between);
my $rounded_price_ends_outside = roundnear(0.01, $price_ends_outside);
ok ($rounded_price_ends_between + $rounded_price_ends_outside == 1, 
    'ends_between + ends_outside = 1');


# double_no_touch + double_one_touch = 1
my $price_double_no_touch = Math::Business::BlackScholes::Binaries::double_no_touch(
    $S, 1.36, 1.34, 7/365, 0.002, 0.001, 0.11
);
my $price_double_one_touch = Math::Business::BlackScholes::Binaries::double_one_touch(
    $S, 1.36, 1.34, 7/365, 0.002, 0.001, 0.11
);

my $rounded_price_double_no_touch = roundnear(0.01, $price_double_no_touch);
my $rounded_price_double_one_touch = roundnear(0.01, $price_double_one_touch);
ok ($rounded_price_double_no_touch + $rounded_price_double_one_touch == 1, 
    'double_no_touch + double_one_touch = 1');

Test::NoWarnings::had_no_warnings();
done_testing();

