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
my $barrier_u = 1.36;
my $barrier_l = 1.34;
my $t = 7/365;
my $sigma = 0.11;
my $r     = 0.002;
my $q     = 0.001;

$Math::Business::BlackScholes::Binaries::MIN_ACCURACY_UPORDOWN_PELSSER_1997 
    = 10**10;

my $price_double_one_touch = Math::Business::BlackScholes::Binaries::double_one_touch(
    $S, $barrier_u, $barrier_l, $t, $r, $r-$q, $sigma
);
ok ($price_double_one_touch == 0, 'price_double_one_touch');

Test::NoWarnings::had_no_warnings();
done_testing();

