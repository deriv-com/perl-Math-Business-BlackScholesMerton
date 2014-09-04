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
my $barrier_h = exp(6);
my $barrier_l = 1.34;

# digital_call
my $price_digital_call = Math::Business::BlackScholes::Binaries::digital_call(
    $S, $barrier_h, 7/365, 0.002, 0.001, 0.11
);
ok ( roundnear(0.01, $price_digital_call) == 0, 
    'digital_call (' . $price_digital_call . ') -> 0');

# digital_put
my $price_digital_put = Math::Business::BlackScholes::Binaries::digital_put(
    $S, $barrier_h, 7/365, 0.002, 0.001, 0.11
);
ok ( roundnear(0.01, $price_digital_put) == 1, 
    'digital_put (' . $price_digital_put . ') -> 1');

# one_touch
my $price_one_touch = Math::Business::BlackScholes::Binaries::one_touch(
    $S, $barrier_h, 7/365, 0.002, 0.001, 0.11
);
ok ( roundnear(0.01, $price_one_touch) == 0, 
    'one_touch (' . $price_one_touch . ') -> 0');

# no_touch
my $price_no_touch = Math::Business::BlackScholes::Binaries::no_touch(
    $S, $barrier_h, 7/365, 0.002, 0.001, 0.11
);
ok ( roundnear(0.01, $price_no_touch) == 1, 
    'no_touch (' . $price_no_touch . ') -> 1');

# double_one_touch
my $price_double_one_touch = Math::Business::BlackScholes::Binaries::double_one_touch(
    $S, $barrier_h, $barrier_l, 7/365, 0.002, 0.001, 0.11
);
# one_touch at lower barrier
my $price_one_touch_lower_barrier = Math::Business::BlackScholes::Binaries::one_touch(
    $S, $barrier_l, 7/365, 0.002, 0.001, 0.11
);
ok ( $price_double_one_touch == $price_one_touch_lower_barrier,
    'double_one_touch (higher barrier) -> one_touch (lower barrier)' );

# double_no_touch
my $price_double_no_touch =
Math::Business::BlackScholes::Binaries::double_no_touch(
    $S, $barrier_h, $barrier_l, 7/365, 0.002, 0.001, 0.11
);
# no_touch at lower barrier
my $price_no_touch_lower_barrier = Math::Business::BlackScholes::Binaries::no_touch(
    $S, $barrier_l, 7/365, 0.002, 0.001, 0.11
);
ok ( $price_double_no_touch == $price_no_touch_lower_barrier,
    'double_no_touch (higher barrier) -> no_touch (lower barrier)' );

Test::NoWarnings::had_no_warnings();
done_testing();

