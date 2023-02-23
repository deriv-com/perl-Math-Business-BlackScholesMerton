use strict;
use warnings;

use Test::Most;
use Test::Warnings;
use Test::Exception;

use Math::Business::BlackScholesMerton::NonBinaries;
use Format::Util::Numbers qw(roundnear);
use Text::CSV::Slurp;

my $pricing_parameters = Text::CSV::Slurp->load(file => 't/test_data/sharkfin_data.csv');

my $filename = 'qinfeng_test_run.csv';
open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
print $fh "spot,t,sigma,strike,ko_barrier,rebate,sharkfin_call_price_alex,sharkfin_call_price_qinfeng,is_same\n";

subtest 'sharkfin price test' => sub {
    foreach my $line (@$pricing_parameters) {
        my $spot               = $line->{spot};
        my $strike             = $line->{strike};
        my $duration           = $line->{duration};
        my $r_q                = 0;
        my $mu                 = 0;
        my $rebate             = $line->{rebate};
        my $vol                = $line->{vol};
        my $ko_barrier_call    = $line->{barrier_for_call};
        my $ko_barrier_put     = $line->{barrier_for_put};
        my $sharkfincall_price = $line->{sharkfin_call_price};
        my $sharkfinput_price  = $line->{sharkfin_put_price};

        test_price({
                type          => 'sharkfincall',
                strike        => $strike,
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
                type          => 'sharkfinput',
                strike        => $strike,
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

    my $s = "price $price | exp $expected";
    use Data::Printer;
    p $s;
    my $filename = 'qinfeng_test_run.csv';
    open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";

    my $is_same = 1;
    $is_same = 0 if $diff > 0.01;
    print $fh "$spot,$t,$sigma,$strike,$ko_barrier,$rebate,$expected,$price,$is_same\n";

    cmp_ok($diff, '<', 0.01, 'Diff is within permissible range');
}

done_testing;

