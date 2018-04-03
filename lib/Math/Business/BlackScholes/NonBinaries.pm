package Math::Business::BlackScholes::NonBinaries;

use strict;
use warnings;

use Math::Business::BlackScholes::Vanillas;

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
