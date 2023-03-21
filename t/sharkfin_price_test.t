use strict;
use warnings;

use Test::Most;
use Test::Warnings;
use Test::Exception;

use Math::Business::BlackScholesMerton::NonBinaries;
use Format::Util::Numbers qw(roundnear);
use Text::CSV::Slurp;

my $pricing_parameters = Text::CSV::Slurp->load(file => 't/test_data/Sharkfin_prices.csv');

subtest 'sharkfin price test' => sub {
    foreach my $line (@$pricing_parameters) {
        my $spot                 = $line->{Spot};
        my $strike_call          = $line->{Strike_call};
        my $strike_put           = $line->{Strike_put};
        my $duration             = $line->{Maturity};
        my $r_q                  = 0;
        my $mu                   = 0;
        my $rebate               = $line->{Rebate};
        my $vol                  = $line->{Volatility};
        my $ko_barrier_call      = $line->{Barrier_call};
        my $ko_barrier_put       = $line->{Barrier_put};
        my $sharkfinko_call_price = $line->{Sharkfin_KO_call};
        my $sharkfincall_price   = $line->{Sharkfin_XP_call};
        my $sharkfinko_put_price  = $line->{Sharkfin_KO_put};
        my $sharkfinput_price    = $line->{Sharkfin_XP_put};

        test_price({
                type          => 'sharkfinkocall',
                strike        => $strike_call,
                spot          => $spot,
                discount_rate => $r_q,
                t             => $duration,
                mu            => $mu,
                vol           => $vol,
                ko_barrier    => $ko_barrier_call,
                rebate        => $rebate
            },
            $sharkfinko_call_price
        );

        test_price({
                type          => 'sharkfincall',
                strike        => $strike_call,
                spot          => $spot,
                discount_rate => $r_q,
                t             => $duration,
                mu            => $mu,
                vol           => $vol,
                ko_barrier    => $ko_barrier_call,
                rebate        => $rebate
            },
            $sharkfincall_price
        );

        test_price({
                type          => 'sharkfinkoput',
                strike        => $strike_put,
                spot          => $spot,
                discount_rate => $r_q,
                t             => $duration,
                mu            => $mu,
                vol           => $vol,
                ko_barrier    => $ko_barrier_put,
                rebate        => $rebate
            },
            $sharkfinko_put_price
        );

        test_price({
                type          => 'sharkfinput',
                strike        => $strike_put,
                spot          => $spot,
                discount_rate => $r_q,
                t             => $duration,
                mu            => $mu,
                vol           => $vol,
                ko_barrier    => $ko_barrier_put,
                rebate        => $rebate
            },
            $sharkfinput_price
        );
    };
};

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
    my $ko_barrier    = $args->{ko_barrier};
    my $rebate        = $args->{rebate};

    my $price;

    my $formula = 'Math::Business::BlackScholesMerton::NonBinaries::'.$type;

    my $func = \&$formula;

    $price = $func->($spot, $ko_barrier, $strike, $t, $discount_rate, $mu, $sigma, $rebate);

    my $diff = abs($price - $expected) / $expected;
    cmp_ok($diff, '<', 0.01, 'Diff is within permissible range');
}

done_testing;

