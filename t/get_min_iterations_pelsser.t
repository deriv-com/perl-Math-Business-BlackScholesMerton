#!/usr/bin/perl

use lib 'lib';
use Test::Most;
require Test::NoWarnings;
use Test::Exception;
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

my $min_iterations =
    Math::Business::BlackScholes::Binaries::get_min_iterations_pelsser_1997(
    $S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma, 0, );
ok ($min_iterations == 16, 'min_iterations (no accuracy specified)');

$min_iterations =
    Math::Business::BlackScholes::Binaries::get_min_iterations_pelsser_1997(
    $S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma, 0, 1);
ok ($min_iterations == 16, 'min_iterations (accuracy 1)');

$min_iterations =
    Math::Business::BlackScholes::Binaries::get_min_iterations_pelsser_1997(
    $S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma, 0, -1);
ok ($min_iterations == 16, 'min_iterations (accuracy 1)');

throws_ok {
    $min_iterations =
        Math::Business::BlackScholes::Binaries::_get_min_iterations_ot_up_ko_down_pelsser_1997(
        $S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma, 0);
} qr/accuracy required/, 'accuracy required';

throws_ok {
    $min_iterations =
        Math::Business::BlackScholes::Binaries::_get_min_iterations_ot_up_ko_down_pelsser_1997(
        $S, $barrier_u, $barrier_l, $t, $r, $r - $q, $sigma, 0, -1);
} qr/too many iterations required/, 'too many iterations required';


Test::NoWarnings::had_no_warnings();
done_testing();

