#!/etc/rmg/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warn;
use Test::Exception;
use Math::Business::BlackScholesMerton::NonBinaries;
use Format::Util::Numbers qw(roundnear);

subtest 'test_price' => sub {

    test_price({    # Fixed strike lookback call
            type          => 'lbfixedcall',
            strike        => 101,
            spot          => 100,
            discount_rate => 0.4,
            t             => 0.1,
            mu            => 0.3,
            vol           => 0.1,
            spot_max      => 102,
            spot_min      => undef
        },
        3.5007
    );

    test_price({    # Fixed strike lookback put
            type          => 'lbfixedput',
            strike        => 105,
            spot          => 100,
            discount_rate => 0.4,
            t             => 0.1,
            mu            => 0.3,
            vol           => 0.1,
            spot_max      => undef,
            spot_min      => 95
        },
        9.62282
    );

    test_price({    # Floating strike lookback call
            type          => 'lbfloatcall',
            strike        => 100,
            spot          => 100,
            discount_rate => 0.4,
            t             => 0.1,
            mu            => 0.3,
            vol           => 0.1,
            spot_max      => undef,
            spot_min      => 95
        },
        7.74492
    );

    test_price({    # Floating strike lookback put
            type          => 'lbfloatput',
            strike        => 100,
            spot          => 100,
            discount_rate => 0.4,
            t             => 0.1,
            mu            => 0.3,
            vol           => 0.1,
            spot_max      => 105,
            spot_min      => undef
        },
        2.68164
    );

    test_price({    # High low lookback
            type          => 'lbhighlow',
            strike        => 100,
            spot          => 100,
            discount_rate => 0.4,
            t             => 0.1,
            mu            => 0.3,
            vol           => 0.1,
            spot_max      => 105,
            spot_min      => 95
        },
        10.42656
    );

    test_price({    # sharkfin call
            type          => 'sharkfincall',
            strike        => 100,
            spot          => 100,
            barrier1      => 10,
            discount_rate => 0.4,
            t             => 0.1,
            mu            => 0.3,
            vol           => 0.1,
            rebate        => 0
        },
        0.28305
    );

    test_price({    # sharkfin put
            type          => 'sharkfinput',
            strike        => 70,
            spot          => 100,
            barrier1      => 90,
            discount_rate => 0.4,
            t             => 0.1,
            mu            => 0.3,
            vol           => 0.1,
            rebate        => 0
        },
        -14.19232
    );
};

#$S, $K, $t, $r_q, $mu, $sigma, $S_min or $S_min or both.

sub test_price {
    my $args     = shift;
    my $expected = shift;

    my $type          = $args->{type};
    my $strike        = $args->{strike};
    my $spot          = $args->{spot};
    my $discount_rate = $args->{discount_rate};
    my $t             = $args->{t};
    my $mu            = $args->{mu};
    my $sigma         = $args->{vol};
    my $s_max         = $args->{spot_max} // 0;
    my $s_min         = $args->{spot_min} // 0;
    my $ko_barrier    = $args->{barrier1} // 0;
    my $rebate        = $args->{rebate} // 0;

    my $price;

    my $formula = 'Math::Business::BlackScholesMerton::NonBinaries::' . $type;

    my $func = \&$formula;

    my $param_1 = $s_max;
    my $param_2 = $s_min;

    if (($type eq 'sharkfinput') or ($type eq 'sharkfincall')) {
        $param_1 = $ko_barrier if $type eq 'sharkfinput' or $type eq 'sharkfincall';
        $param_2 = $rebate if $type eq 'sharkfinput' or $type eq 'sharkfincall';
    }

    $price = $func->($spot, $strike, $t, $discount_rate, $mu, $sigma, $param_1, $param_2);

    is roundnear(0.00001, $price), roundnear(0.00001, $expected), "correct price for " . $type;
}

done_testing;

