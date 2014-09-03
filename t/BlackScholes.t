#!/usr/bin/perl

use lib 'lib';
use Test::More tests => 25;
use Test::NoWarnings;
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

# These are compared with Bloomberg standards...
# except EXPIRYMISS and UPORDOWN which are computed as opposing
# EXPIRYRANGE and RANGE respectively.

my @test_cases = (
    {
        type     => 'digital_call',
        barriers => [1.36],
        foreign  => 0.3172,
        domestic => 0.3118,
    },
    {
        type     => 'digital_put',
        barriers => [1.34],
        foreign  => 0.3096,
        domestic => 0.315,
    },
    {
        type     => 'vanilla_call',
        barriers => [1.34],
        foreign  => 0.0140,
        domestic => 0.0141,
    },
    {
        type     => 'vanilla_put',
        barriers => [1.34],
        foreign  => 0.0040,
        domestic => 0.0040,
    },
    {
        type     => 'one_touch',
        barriers => [1.36],
        foreign  => 0.6307,
        domestic => 0.6261,
    },
    {
        type     => 'no_touch',
        barriers => [1.36],
        foreign  => 0.3692,
        domestic => 0.3739,
    },
    {
        type     => 'ends_between',
        barriers => [ 1.36, 1.34 ],
        foreign  => 0.3732,
        domestic => 0.3732,
    },
    {
        type     => 'ends_outside',
        barriers => [ 1.36, 1.34 ],
        foreign  => 0.6268,
        domestic => 0.6268,
    },
    {
        type     => 'double_no_touch',
        barriers => [ 1.36, 1.34 ],
        foreign  => 0.006902,
        domestic => 0.006902,
    },
    {
        type     => 'double_one_touch',
        barriers => [ 1.36, 1.34 ],
        foreign  => 0.993093,
        domestic => 0.993088,
    },
    {
        type     => 'double_no_touch',
        barriers => [ 1.35, 1.34 ],
        foreign  => 0,
        domestic => 0,
    },
    {
        type     => 'double_one_touch',
        barriers => [ 1.36, 1.35 ],
        foreign  => 1,
        domestic => 1,
    },

);

foreach my $test_case (@test_cases) {
    my $formula_name = 'Math::Business::BlackScholes::Binaries::'
      . $test_case->{type};
    my %probs = (
        domestic => &$formula_name(
            $S, @{ $test_case->{barriers} },
            $t, $r, $r - $q, $sigma
        ),
        foreign => &$formula_name(
            $S, @{ $test_case->{barriers} },
            $t, $q, $r - $q + $sigma**2, $sigma
        ),
    );

    foreach my $curr ( sort keys %probs ) {
        my $length = length( $test_case->{$curr} );
        my $precision = ( $length < 2 ) ? 1 : 10**( -1 * ( $length - 2 ) );
        is( roundnear( $precision, $probs{$curr} ),
            $test_case->{$curr}, $test_case->{type} . ' ' . $curr );
    }
}

