package Math::Business::BlackScholes::NonBinaries;

use strict;
use warnings;

use Math::CDF qw(pnorm);

## VERSION

=head1 NAME

Math::Business::BlackScholes::NonBinaries

=head1 SYNOPSIS

    use Math::Business::BlackScholes::NonBinaries;

    # price of a Call spread option
    my $price_call_option = Math::Business::BlackScholes::NonBinaries::vanilla_call(
        1.35,       # stock price
        1.34,       # barrier
        (7/365),    # time
        0.002,      # payout currency interest rate (0.05 = 5%)
        0.001,      # quanto drift adjustment (0.05 = 5%)
        0.11,       # volatility (0.3 = 30%)
    );

=cut

=head2 vanilla_call

    USAGE
    my $price = vanilla_call($S, $K, $t, $r_q, $mu, $sigma)

    DESCRIPTION
    Price of a Vanilla Call

=cut

sub vanilla_call {
    my ($S, $K, $t, $r_q, $mu, $sigma) = @_;

    my $d1 = (log($S / $K) + ($mu + $sigma * $sigma / 2.0) * $t) / ($sigma * sqrt($t));
    my $d2 = $d1 - ($sigma * sqrt($t));

    return exp(-$r_q * $t) * ($S * exp($mu * $t) * pnorm($d1) - $K * pnorm($d2));
}

=head2 vanilla_put

    USAGE
    my $price = vanilla_put($S, $K, $t, $r_q, $mu, sigma)

    DESCRIPTION
    Price a standard Vanilla Put

=cut

sub vanilla_put {
    my ($S, $K, $t, $r_q, $mu, $sigma) = @_;

    my $d1 = (log($S / $K) + ($mu + $sigma * $sigma / 2.0) * $t) / ($sigma * sqrt($t));
    my $d2 = $d1 - ($sigma * sqrt($t));

    return -1 * exp(-$r_q * $t) * ($S * exp($mu * $t) * pnorm(-$d1) - $K * pnorm(-$d2));
}

=head2 callspread

    USAGE
    my $price = callspread($S, $U, $D, $t, $r_q, $mu, $sigmaU, $sigmaD);

    DESCRIPTION
    Price of a CALL SPREAD

=cut

sub callspread {
    my ($S, $U, $D, $t, $r_q, $mu, $sigmaU, $sigmaD) = @_;

    return vanilla_call($S, $D, $t, $r_q, $mu, $sigmaD) - vanilla_call($S, $U, $t, $r_q, $mu, $sigmaU);
}

=head2 putspread

    USAGE
    my $price = putspread($S, $U, $D, $t, $r_q, $mu, $sigmaU, $sigmaD);

    DESCRIPTION
    Price of a PUT SPREAD

=cut

sub putspread {
    my ($S, $U, $D, $t, $r_q, $mu, $sigmaU, $sigmaD) = @_;

    return vanilla_put($S, $U, $t, $r_q, $mu, $sigmaU) - vanilla_put($S, $D, $t, $r_q, $mu, $sigmaD);
}

1;
