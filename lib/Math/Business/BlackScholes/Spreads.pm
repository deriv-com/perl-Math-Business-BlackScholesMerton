package Math::Business::BlackScholes::Spreads;

use strict;
use warnings;

use Math::Business::BlackScholes::Vanillas;

## VERSION

=head1 NAME

Math::Business::BlackScholes::Spreads

=head1 SYNOPSIS

    use Math::Business::BlackScholes::Spreads;

    # price of a Call spread option
    my $price_call_option = Math::Business::BlackScholes::Spreads::callspread(
        1.35,       # stock price
        1.36,       # high barrier
        1.34,       # low barrier
        (7/365),    # time
        0.002,      # payout currency interest rate (0.05 = 5%)
        0.001,      # quanto drift adjustment (0.05 = 5%)
        0.11,       # volatility (0.3 = 30%)
    );

=cut

=head2 callspread

    USAGE
    my $price = callspread($S, $U, $D, $t, $r_q, $mu, $sigma);

    DESCRIPTION
    Price of a CALL SPREAD

=cut

sub callspread {
    my ($S, $U, $D, $t, $r_q, $mu, $sigma) = @_;

    return Math::Business::BlackScholes::Vanillas::vanilla_call($S, $D, $t, $r_q, $mu, $sigma) -
        Math::Business::BlackScholes::Vanillas::vanilla_call($S, $U, $t, $r_q, $mu, $sigma);
}

=head2 putspread

    USAGE
    my $price = putspread($S, $U, $D, $t, $r_q, $mu, $sigma);

    DESCRIPTION
    Price of a PUT SPREAD

=cut

sub putspread {
    my ($S, $U, $D, $t, $r_q, $mu, $sigma) = @_;

    return Math::Business::BlackScholes::Vanillas::vanilla_put($S, $U, $t, $r_q, $mu, $sigma) -
        Math::Business::BlackScholes::Vanillas::vanilla_put($S, $D, $t, $r_q, $mu, $sigma);
}

1;
