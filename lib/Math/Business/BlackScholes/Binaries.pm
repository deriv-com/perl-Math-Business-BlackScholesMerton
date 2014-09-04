package Math::Business::BlackScholes::Binaries;
use strict;
use warnings;

our $VERSION = '1.00';

my $SMALLTIME = 1 / ( 60 * 60 * 24 * 365 );    # 1 second in years;

use List::Util qw(max);
use Math::CDF qw(pnorm);
use Math::Trig;

=head1 NAME

Math::Business::BlackScholes::Binaries 

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use Math::Business::BlackScholes::Binaries;

    # price of a Call option
    my $price_call_option = Math::Business::BlackScholes::Binaries::digital_call(
        1.35,       # stock price
        1.36,       # barrier
        (7/365),    # time
        0.002,      # payout currency interest rate (0.05 = 5%)
        0.001,      # quanto drift adjustment (0.05 = 5%)
        0.11,       # volatility (0.3 = 30%)
    );

=head1 DESCRIPTION

Prices options using the GBM model, all closed formulas.

Important(a): Basically, one_touch, double_one_touch and double_touch have two cases of 
payoff either at end or at hit. We treat them differently. We use parameter 
$w to differ them.

$w = 0: payoff at hit time.
$w = 1: payoff at end.

Our current contracts pay rebate at hit time, so we set $w = 0 by default.

Important(b) :Furthermore, for all our contracts, we allow a different 
payout currency (Quantos).

Paying domestic currency (JPY if for USDJPY) = correlation coefficient is ZERO.
Paying foreign currency (USD if for USDJPY) = correlation coefficient is ONE.
Paying another currency = correlation is between negative ONE and positive ONE.

See [3] for Quanto formulas and examples

=head2 vanilla_call

    USAGE
    my $price = vanilla_call($S, $K, $t, $r_q, $mu, $sigma)

    DESCRIPTION
    Price of a Vanilla Call

=cut

sub vanilla_call {
    my ( $S, $K, $t, $r_q, $mu, $sigma ) = @_;

    my $d1 =
      ( log( $S / $K ) + ( $mu + $sigma * $sigma / 2.0 ) * $t ) /
      ( $sigma * sqrt($t) );
    my $d2 = $d1 - ( $sigma * sqrt($t) );

    return
      exp( -$r_q * $t ) *
      ( $S * exp( $mu * $t ) * pnorm($d1) - $K * pnorm($d2) );
}

=head2 vanilla_put

    USAGE
    my $price = vanilla_put($S, $K, $t, $r_q, $mu, sigma)

    DESCRIPTION
    Price a standard Vanilla Put

=cut

sub vanilla_put {
    my ( $S, $K, $t, $r_q, $mu, $sigma ) = @_;

    my $d1 =
      ( log( $S / $K ) + ( $mu + $sigma * $sigma / 2.0 ) * $t ) /
      ( $sigma * sqrt($t) );
    my $d2 = $d1 - ( $sigma * sqrt($t) );

    return -1 *
      exp( -$r_q * $t ) *
      ( $S * exp( $mu * $t ) * pnorm( -$d1 ) - $K * pnorm( -$d2 ) );
}

=head2 digital_call

    USAGE
    my $price = digital_call($S, $K, $t, $r_q, $mu, $sigma)

    PARAMS
    $S => stock price
    $K => barrier
    $t => time (1 = 1 year)
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

    DESCRIPTION
    Price a Call and remove the N(d2) part if the time is too small

    EXPLANATION 
    The definition of the contract is that if S > K, client wins
    full payout (1).  However the formula DC(T,K) = e^(-rT) N(d2) will not be
    correct when T->0 and K=S.  The value of DC(T,K) for this case will be 0.5. 
    
    The formula is actually "correct" because when T->0 and S=K, the probability
    should just be 0.5 that the contract wins, moving up or down is equally
    likely in that very small amount of time left. Thus the only problem is
    that the math cannot evaluate at T=0, where divide by 0 error occurs. Thus,
    we need this check that throws away the N(d2) part (N(d2) will evaluate
    "wrongly" to 0.5 if S=K).

    NOTE
    Note that we have digital_call = - dCall/dStrike
    pair Foreign/Domestic

    see [3] for $r_q and $mu for quantos

=cut

sub digital_call {
    my ( $S, $K, $t, $r_q, $mu, $sigma ) = @_;

    if ( $t < $SMALLTIME ) {
        return ( $S > $K ) ? exp( -$r_q * $t ) : 0;
    }

    return exp( -$r_q * $t ) * pnorm( d2( $S, $K, $t, $r_q, $mu, $sigma ) );
}

=head2 digital_put

    USAGE
    my $price = digital_put($S, $K, $t, $r_q, $mu, $sigma)

    PARAMS
    $S => stock price
    $K => barrier
    $t => time (1 = 1 year)
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

    DESCRIPTION
    Price a standard Digital Put

=cut

sub digital_put {
    my ( $S, $K, $t, $r_q, $mu, $sigma ) = @_;

    if ( $t < $SMALLTIME ) {
        return ( $S < $K ) ? exp( -$r_q * $t ) : 0;
    }

    return
      exp( -$r_q * $t ) * pnorm( -1 * d2( $S, $K, $t, $r_q, $mu, $sigma ) );
}

=head2 d2

returns the DS term common to many BlackScholes formulae.

=cut

sub d2 {
    my ( $S, $K, $t, $r_q, $mu, $sigma ) = @_;

    return ( log( $S / $K ) + ( $mu - $sigma * $sigma / 2.0 ) * $t ) /
      ( $sigma * sqrt($t) );
}

=head2 ends_outside

    USAGE
    my $price = ends_outside($S, $U, $D, $t, $r_q, $mu, $sigma)

    PARAMS
    $S => stock price
    $t => time (1 = 1 year)
    $U => barrier
    $D => barrier
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

    DESCRIPTION
    Price an expiry miss contract (1 Call + 1 Put)

    [3] for $r_q and $mu for quantos

=cut

sub ends_outside {
    my ( $S, $U, $D, $t, $r_q, $mu, $sigma ) = @_;

    my ($call_price) = digital_call( $S, $U, $t, $r_q, $mu, $sigma );
    my ($put_price) = digital_put( $S, $D, $t, $r_q, $mu, $sigma );

    return $call_price + $put_price;
}

=head2 ends_between

    USAGE
    my $price = ends_between($S, $U, $D, $t, $r_q, $mu, $sigma)

    PARAMS
    $S => stock price
    $U => barrier
    $D => barrier
    $t => time (1 = 1 year)
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

    DESCRIPTION
    Price an Expiry Range contract as Foreign/Domestic.

    [3] for $r_q and $mu for quantos

=cut

sub ends_between {
    my ( $S, $U, $D, $t, $r_q, $mu, $sigma ) = @_;

    return exp( -$r_q * $t ) - ends_outside( $S, $U, $D, $t, $r_q, $mu, $sigma );
}

=head2 one_touch

    PARAMS
    $S => stock price
    $H => barrier
    $t => time (1 = 1 year)
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

    [3] for $r_q and $mu for quantos

=cut

sub one_touch {
    my ( $S, $U, $t, $r_q, $mu, $sigma, $w ) = @_;

    # w = 0, rebate paid at hit (good way to remember is that waiting 
    #   time to get paid = 0)
    # w = 1, rebate paid at end.

    # When the contract already reached it expiry and not yet reach it
    # settlement time, it is consider an unexpired contract but will come to
    # here with t=0 and it will caused the formula to die hence set it to the
    # SMALLTIME which is 1 second
    $t = max( $SMALLTIME, $t );

    $w ||= 0;

    # eta = -1, one touch up
    # eta = 1, one touch down
    my $eta = ( $S < $U ) ? -1 : 1;

    my $sqrt_t = sqrt($t);

    my $theta  = ( ($mu) / $sigma ) + ( 0.5 * $sigma );
    my $theta_ = ( ($mu) / $sigma ) - ( 0.5 * $sigma );

    my $v_ = sqrt( ( $theta_ * $theta_ ) + ( 2 * ( 1 - $w ) * $r_q ) );

    my $e = ( log( $S / $U ) - ( $sigma * $v_ * $t ) ) / ( $sigma * $sqrt_t );
    my $e_ = ( -log( $S / $U ) - ( $sigma * $v_ * $t ) ) / ( $sigma * $sqrt_t );

    my $price =
      ( ( $U / $S )**( ( $theta_ + $v_ ) / $sigma ) ) * pnorm( -$eta * $e ) +
      ( ( $U / $S )**( ( $theta_ - $v_ ) / $sigma ) ) * pnorm( $eta * $e_ );

    return exp( -$w * $r_q * $t ) * $price;
}

=head2 no_touch

    USAGE
    my $price = no_touch($S, $U, $t, $r_q, $mu, $sigma, $w)

    PARAMS
    $S => stock price
    $H => barrier
    $t => time (1 = 1 year)
    $r_q => payout currency interest rate (0.05 = 5%)
    $mu => quanto drift adjustment (0.05 = 5%)
    $sigma => volatility (0.3 = 30%)

    DESCRIPTION
    Price a No touch contract.

    Payoff with domestic currency
    Identity:
    price of no_touch = exp(- r t) - price of one_touch(rebate paid at end)

    [3] for $r_q and $mu for quantos

=cut

sub no_touch {
    my ( $S, $U, $t, $r_q, $mu, $sigma ) = @_;

    # No touch contract always pay out at end
    my $w = 1;

    return exp( -$r_q * $t ) - one_touch( $S, $U, $t, $r_q, $mu, $sigma, $w );
}

my $MAX_ITERATIONS_UPORDOWN_PELSSER_1997 = 1000;
my $MIN_ITERATIONS_UPORDOWN_PELSSER_1997 = 16;

#
# This variable requires 'our' only because it needs to be
# accessed via test script.
# Min accuracy. Accurate to 1 dollar for 100,000 notional
#
our $MIN_ACCURACY_UPORDOWN_PELSSER_1997 = 1.0 / 100000.0;
our $SMALL_VALUE_MU                     = 1e-10;

# The smallest (in magnitude) floating-point number which,
# when added to the floating-point number 1.0, produces a
# floating-point result different from 1.0 is termed the
# machine accuracy, e.
#
# This value is very important for knowing stability to
# certain formulas used. e.g. Pelsser formula for UPORDOWN
# and RANGE contracts.
#
my $MACHINE_ACCURACY = machine_accuracy();

=head2 machine_accuracy

    determine the floating point accuracy of this machine for the numerical approximations

=cut

sub machine_accuracy {

    # Machine accuracy for 32-bit floating point number
    my $ma_32bit_23mantissa = 1.0 / ( 2**23 );

    # Machine accuracy for 64-bit floating point number
    my $ma_64bit_52mantissa = 1.0 / ( 2**52 );

    # Machine accuracy for 128-bit floating point number (e.g. IBM AIX)
    my $ma_128bit_105mantissa = 1.0 / ( 2**105 );

    # Always start with a power of 2 to avoid roundoff errors!!
    my $e = 1.0;
    while (1) {
        if ( 1.0 + $e / 2 == 1.0 ) { last; }
        $e = $e / 2.0;

        # Accuracy already better than a 128-bit machine!!
        if ( $e < $ma_128bit_105mantissa ) {
            warn
"Machine accuracy seems too good to be true!! Do we have such a powerful machine? Assuming that something isn't right, and returning machine accuracy for 64 bit double.";
            $e = $ma_64bit_52mantissa;
            last;
        }
    }

    # If accuracy is very bad, we return the minimum accuracy for a 32-bit double
    if ( $e > $ma_32bit_23mantissa ) {
        warn
"Machine accuracy ($e greater than $ma_32bit_23mantissa) seems worse than the
primitive 32-bit double representation. Setting to minimum accuracy of
$ma_32bit_23mantissa. This is NOT GOOD because it means that there are some
contracts than we can't price on this machine, that we otherwise can on a higher precision machine. Please UPGRADE THIS MACHINE!!";
        return $ma_32bit_23mantissa;
    }

    return $e;
}

=head2 double_one_touch

    USAGE
    my $price = double_one_touch(($S, $U, $D, $t, $r_q, $mu, $sigma, $w))

    PARAMS
    $S stock price
    $U barrier
    $D barrier
    $t time (1 = 1 year)
    $r_q payout currency interest rate (0.05 = 5%)
    $mu quanto drift adjustment (0.05 = 5%)
    $sigma volatility (0.3 = 30%)

    see [3] for $r_q and $mu for quantos

    DESCRIPTION
    Price an Up or Down contract

=cut

sub double_one_touch {
    my ( $S, $U, $D, $t, $r_q, $mu, $sigma, $w ) = @_;

    # When the contract already reached it's expiry and not yet reach it settlement time,
    # it is considered an unexpired contract but will come to here with t=0 and 
    # it will caused the formula to die
    # hence set it to the SMALLTIME whiich is 1 second
    $t = max( $t, $SMALLTIME );

    # $w = 0, paid at hit
    # $w = 1, paid at end
    if ( not defined $w ) { $w = 0; }

    # spot is outside [$D, $U] --> contract is expired with full payout, 
    # one barrier is already hit (can happen due to shift markup):
    if ( $S >= $U or $S <= $D ) {
        return $w ? exp( -$t * $r_q ) : 1;
    }

#
# SANITY CHECKS
#
# For extreme cases, the price will be wrong due the values in the
# infinite series getting too large or too small, which causes
# roundoff errors in the computer. Thus no matter how many iterations
# you make, the errors will never go away.
#
# For example try this:
#
#   my ($S, $U, $D, $t, $r, $q, $vol, $w) 
#       = (100.00, 118.97, 99.00, 30/365, 0.1, 0.02, 0.01, 1);
#   $up_price = Math::Business::BlackScholes::Binaries::ot_up_ko_down_pelsser_1997(
#       $S,$U,$D,$t,$r,$q,$vol,$w);
#   $down_price= Math::Business::BlackScholes::Binaries::ot_down_ko_up_pelsser_1997(
#       $S,$U,$D,$t,$r,$q,$vol,$w);
#
# Thus we put a sanity checks here such that
#
#   CONDITION 1:    UPORDOWN[U,D] < ONETOUCH[U] + ONETOUCH[D]
#   CONDITION 2:    UPORDOWN[U,D] > ONETOUCH[U]
#   CONDITION 3:    UPORDOWN[U,D] > ONETOUCH[D]
#   CONDITION 4:    ONETOUCH[U] + ONETOUCH[D] >= $MIN_ACCURACY_UPORDOWN_PELSSER_1997
#
    my $onetouch_up_prob   = one_touch( $S, $U, $t, $r_q, $mu, $sigma, $w );
    my $onetouch_down_prob = one_touch( $S, $D, $t, $r_q, $mu, $sigma, $w );

    my $upordown_prob;

    if ( $onetouch_up_prob + $onetouch_down_prob <
        $MIN_ACCURACY_UPORDOWN_PELSSER_1997 )
    {

        # CONDITION 4:
        #   The probability is too small for the Pelsser formula to be correct.
        #   Do this check first to avoid PELSSER stability condition to be
        #   triggered.
        #   Here we assume that the ONETOUCH formula is perfect and never give
        #   wrong values (e.g. negative).
        return 0;
    }
    elsif ( $onetouch_up_prob xor $onetouch_down_prob ) {

        # One of our ONETOUCH probabilities is 0.
        # That means our upordown prob is equivalent to the other one.
        # Pelsser recompute will either be the same or wrong.
        # Continuing to assume the ONETOUCH is perfect.
        $upordown_prob = max( $onetouch_up_prob, $onetouch_down_prob );
    }
    else {

        # THIS IS THE ONLY PLACE IT SHOULD BE!
        $upordown_prob =
          ot_up_ko_down_pelsser_1997( $S, $U, $D, $t, $r_q, $mu, $sigma, $w ) +
          ot_down_ko_up_pelsser_1997( $S, $U, $D, $t, $r_q, $mu, $sigma, $w );
    }

    # CONDITION 4:
    #   Now check on the other end, when the contract is too close to payout.
    #   Not really needed to check for payout at hit, because RANGE is
    #   always at end, and thus the value (DISCOUNT - UPORDOWN) is not
    #   evaluated.
    if ( $w == 1 ) {

        # Since the difference is already less than the min accuracy,
        # the value [payout - upordown], which is the RANGE formula
        # can become negative.
        if (
            abs( exp( -$r_q * $t ) - $upordown_prob ) <
            $MIN_ACCURACY_UPORDOWN_PELSSER_1997 )
        {
            $upordown_prob = exp( -$r_q * $t );
        }
    }

# CONDITION 1-3
#   We use hardcoded small value of $SMALL_TOLERANCE, because if we were to increase
#   the minimum accuracy, and this small value uses that min accuracy, it is
#   very hard for the conditions to pass.
    my $SMALL_TOLERANCE = 0.00001;
    if (
        not( $upordown_prob <
            $onetouch_up_prob + $onetouch_down_prob + $SMALL_TOLERANCE )
        or not( $upordown_prob + $SMALL_TOLERANCE > $onetouch_up_prob )
        or not( $upordown_prob + $SMALL_TOLERANCE > $onetouch_down_prob )
      )
    {
        die
"UPORDOWN price sanity checks failed for S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, sigma=$sigma, w=$w. UPORDOWN PROB=$upordown_prob , ONETOUCH_UP PROB=$onetouch_up_prob , ONETOUCH_DOWN PROB=$onetouch_down_prob";
    }

    return $upordown_prob;
}

=head2 common_function_pelsser_1997

    USAGE
    my $c = common_function_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $sigma, $w, $eta)

    DESCRIPTION
    Return the common function from Pelsser's Paper (1997)

=cut

sub common_function_pelsser_1997 {

    # h: normalized high barrier, log(U/L)
    # x: normalized spot, log(S/L)
    my ( $S, $U, $D, $t, $r_q, $mu, $sigma, $w, $eta ) = @_;

    my $pi = Math::Trig::pi;

    my $h = log( $U / $D );
    my $x = log( $S / $D );

    # $eta = 1, onetouch up knockout down
    # $eta = 0, onetouch down knockout up
    # This variable used to check stability
    if ( not defined $eta ) {
        die
"Wrong usage of this function for S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, sigma=$sigma, w=$w, eta not defined.";
    }
    if ( $eta == 0 ) { $x = $h - $x; }

    # $w = 0, paid at hit
    # $w = 1, paid at end

    my $mu_new = $mu - ( 0.5 * $sigma * $sigma );
    my $mu_dash = sqrt(
        ( $mu_new * $mu_new ) + ( 2 * $sigma * $sigma * $r_q * ( 1 - $w ) ) );

    my $series_part = 0;
    my $hyp_part    = 0;

    # These constants will determine whether or not this contract can be
    # evaluated to a predefined accuracy. It is VERY IMPORTANT because
    # if these conditions are not met, the prices can be complete nonsense!!
    my $stability_constant =
      get_stability_constant_pelsser_1997( $S, $U, $D, $t, $r_q, $mu, $sigma,
        $w, $eta, 1 );

    # The number of iterations is important when recommending the
    # range of the upper/lower barriers on our site. If we recommend
    # a range that is too big and our iteration is too small, the
    # price will be wrong! We must know the rate of convergence of
    # the formula used.
    my $iterations_required =
      get_min_iterations_pelsser_1997( $S, $U, $D, $t, $r_q, $mu, $sigma, $w );

    for ( my $k = 1 ; $k < $iterations_required ; $k++ ) {
        my $lambda_k_dash = (
            0.5 * (
                ( $mu_dash * $mu_dash ) / ( $sigma * $sigma ) +
                  ( $k * $k * $pi * $pi * $sigma * $sigma ) / ( $h * $h )
            )
        );

        my $phi =
          ( $sigma * $sigma ) /
          ( $h * $h ) *
          exp( -$lambda_k_dash * $t ) *
          $k /
          $lambda_k_dash;

        $series_part += $phi * $pi * sin( $k * $pi * ( $h - $x ) / $h );

        #
        # Note that greeks may also call this function, and their
        # stability constant will differ. However, for simplicity
        # we will not bother (else the code will get messy), and
        # just use the price stability constant.
        #
        if ( $k == 1 and ( not( abs($phi) < $stability_constant ) ) ) {
            die
"PELSSER VALUATION formula for S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, vol=$sigma, w=$w, eta=$eta, cannot be evaluated because PELSSER VALUATION stability conditions ($phi less than $stability_constant) not met. This could be due to barriers too big, volatilities too low, interest/dividend rates too high, or machine accuracy too low. Machine accuracy is "
              . $MACHINE_ACCURACY . ".";
        }
    }

    #
    # Some math basics: When A -> 0,
    #
    #    sinh(A) -> 0.5 * [ (1 + A) - (1 - A) ] = 0.5 * 2A = A
    #    cosh(A) -> 0.5 * [ (1 + A) + (1 - A) ] = 0.5 * 2  = 1
    #
    # Thus for sinh(A)/sinh(B) when A & B -> 0, we have
    #
    #    sinh(A) / sinh(B) -> A / B
    #
    # Since the check of the spot == lower/upper barrier has been done in the
    # _upordown subroutine, we can assume that $x and $h will never be 0.
    # So we only need to check that $mu_dash is too small. Also note that
    # $mu_dash is always positive.
    #
    # For example, even at 0.0001 the error becomes small enough
    #
    #    0.0001 - Math::Trig::sinh(0.0001) = -1.66688941837835e-13
    #
    # Since h > x, we only check for (mu_dash * h) / (vol * vol)
    #
    if ( abs( $mu_dash * $h / ( $sigma * $sigma ) ) < $SMALL_VALUE_MU ) {
        $hyp_part = $x / $h;
    }
    else {
        $hyp_part =
          Math::Trig::sinh( $mu_dash * $x / ( $sigma * $sigma ) ) /
          Math::Trig::sinh( $mu_dash * $h / ( $sigma * $sigma ) );
    }

    return ( $hyp_part - $series_part ) * exp( -$r_q * $t * $w );
}

=head2 get_stability_constant_pelsser_1997

    USAGE
    my $constant = get_stability_constant_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $sigma, $w, $eta, $p)

    DESCRIPTION
    Get the stability constant (Pelsser 1997)

=cut

sub get_stability_constant_pelsser_1997 {
    my ( $S, $U, $D, $t, $r_q, $mu, $sigma, $w, $eta, $p ) = @_;

    # $eta = 1, onetouch up knockout down
    # $eta = 0, onetouch down knockout up

    if ( not defined $eta ) {
        die
"Wrong usage of this function for S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, sigma=$sigma, w=$w, Eta not defined.";
    }

    # p is the power of pi
    # p=1 for price/theta/vega/vanna/volga
    # p=2 for delta
    # p=3 for gamma
    if ( $p != 1 and $p != 2 and $p != 3 ) {
        die
"Wrong usage of this function for S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, sigma=$sigma, w=$w, Power of PI must be 1, 2 or 3. Given $p.";
    }

    my $h       = log( $U / $D );
    my $x       = log( $S / $D );
    my $mu_new  = $mu - ( 0.5 * $sigma * $sigma );
    my $mu_dash = sqrt(
        ( $mu_new * $mu_new ) + ( 2 * $sigma * $sigma * $r_q * ( 1 - $w ) ) );

    my $numerator = $MIN_ACCURACY_UPORDOWN_PELSSER_1997 *
      exp( 1.0 - $mu_new * ( ( $eta * $h ) - $x ) / ( $sigma * $sigma ) );
    my $denominator =
      ( exp(1) * ( Math::Trig::pi + $p ) ) +
      ( max( $mu_new * ( ( $eta * $h ) - $x ), 0.0 ) *
          Math::Trig::pi /
          ( $sigma**2 ) );
    $denominator *= ( Math::Trig::pi**( $p - 1 ) ) * $MACHINE_ACCURACY;

    my $stability_condition = $numerator / $denominator;

    return $stability_condition;
}

=head2 ot_up_ko_down_pelsser_1997

    USAGE
    my $price = ot_up_ko_down_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $sigma, $w)

    DESCRIPTION
    This is V_{RAHU} in paper [5], or ONETOUCH-UP-KNOCKOUT-DOWN,
    a contract that wins if it touches upper barrier, but expires
    worthless if it touches the lower barrier first.

=cut

sub ot_up_ko_down_pelsser_1997 {
    my ( $S, $U, $D, $t, $r_q, $mu, $sigma, $w ) = @_;

    my $mu_new = $mu - ( 0.5 * $sigma * $sigma );
    my $h      = log( $U / $D );
    my $x      = log( $S / $D );

    return
      exp( $mu_new * ( $h - $x ) / ( $sigma * $sigma ) ) *
      common_function_pelsser_1997( $S, $U, $D, $t, $r_q, $mu, $sigma, $w, 1 );
}

=head2 ot_down_ko_up_pelsser_1997

    USAGE
    my $price = ot_down_ko_up_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $sigma, $w)

    DESCRIPTION
    This is V_{RAHL} in paper [5], or ONETOUCH-DOWN-KNOCKOUT-UP,
    a contract that wins if it touches lower barrier, but expires
    worthless if it touches the upper barrier first.

=cut

sub ot_down_ko_up_pelsser_1997 {
    my ( $S, $U, $D, $t, $r_q, $mu, $sigma, $w ) = @_;

    my $mu_new = $mu - ( 0.5 * $sigma * $sigma );
    my $h      = log( $U / $D );
    my $x      = log( $S / $D );

    return
      exp( -$mu_new * $x / ( $sigma * $sigma ) ) *
      common_function_pelsser_1997( $S, $U, $D, $t, $r_q, $mu, $sigma, $w, 0 );
}

=head2 get_min_iterations_pelsser_1997

    USAGE
    my $min = get_min_iterations_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $sigma, $w, $accuracy)

    DESCRIPTION
    An estimate of the number of iterations required to achieve a certain
    level of accuracy in the price.

=cut

sub get_min_iterations_pelsser_1997 {
    my ( $S, $U, $D, $t, $r_q, $mu, $sigma, $w, $accuracy ) = @_;

    if ( not defined $accuracy ) {
        $accuracy = $MIN_ACCURACY_UPORDOWN_PELSSER_1997;
    }

    if ( $accuracy > $MIN_ACCURACY_UPORDOWN_PELSSER_1997 ) {
        $accuracy = $MIN_ACCURACY_UPORDOWN_PELSSER_1997;
    }
    elsif ( $accuracy <= 0 ) {
        $accuracy = $MIN_ACCURACY_UPORDOWN_PELSSER_1997;
    }

    my $h = log( $U / $D );
    my $x = log( $S / $D );

    my $it_up =
      _get_min_iterations_ot_up_ko_down_pelsser_1997( $S, $U, $D, $t, $r_q, $mu,
        $sigma, $w, $accuracy );
    my $it_down =
      _get_min_iterations_ot_down_ko_up_pelsser_1997( $S, $U, $D, $t, $r_q, $mu,
        $sigma, $w, $accuracy );

    my $min = max( $it_up, $it_down );

    return $min;
}

=head2 _get_min_iterations_ot_up_ko_down_pelsser_1997

    USAGE
    my $k_min = _get_min_iterations_ot_up_ko_down_pelsser_1997($S, $U, $D, $t, $r_q, $mu, $sigma, $w, $accuracy)

    DESCRIPTION
    An estimate of the number of iterations required to achieve a certain
    level of accuracy in the price for ONETOUCH-UP-KNOCKOUT-DOWN.

=cut

sub _get_min_iterations_ot_up_ko_down_pelsser_1997 {
    my ( $S, $U, $D, $t, $r_q, $mu, $sigma, $w, $accuracy ) = @_;

    my $pi = Math::Trig::pi;

    my $h       = log( $U / $D );
    my $x       = log( $S / $D );
    my $mu_new  = $mu - ( 0.5 * $sigma * $sigma );
    my $mu_dash = sqrt(
        ( $mu_new * $mu_new ) + ( 2 * $sigma * $sigma * $r_q * ( 1 - $w ) ) );

    my $A = ( $mu_dash * $mu_dash ) / ( 2 * $sigma * $sigma );
    my $B = ( $pi * $pi * $sigma * $sigma ) / ( 2 * $h * $h );

    my $delta_dash = $accuracy;
    my $delta =
      $delta_dash *
      exp( -$mu_new * ( $h - $x ) / ( $sigma * $sigma ) ) *
      ( ( $h * $h ) / ( $pi * $sigma * $sigma ) );

    # This can happen when stability condition fails
    if ( $delta * $B <= 0 ) {
        warn
"(_get_min_iterations_up_first_pelsser_1997) Cannot evaluate minimum iterations because too many iterations required!! delta=$delta, B=$B for input parameters S=$S, U=$U, D=$D, t=$t, r_q=$r_q, mu=$mu, sigma=$sigma, w=$w, accuracy=$accuracy";
        return $MAX_ITERATIONS_UPORDOWN_PELSSER_1997;
    }

    # Check that condition is satisfied
    my $condition = max( exp( -$A * $t ) / ( $B * $delta ), 1 );

#
# This is the formula given by Pelsser paper, which is not as good
# as our own derived formula, and will miserably fail the test:
# /> su nobody -c 'prove -v /home/website/cgi/oop/Pricing/Engines/t/price_engine_black_scholes.t'
#
# $condition = max( exp(-$A * $t) / ($delta), 1 );

    my $k_min = log($condition) / ( $B * $t );
    $k_min = sqrt($k_min);

    if ( $k_min < $MIN_ITERATIONS_UPORDOWN_PELSSER_1997 ) {

        # print "$0: $k_min less than $MIN_ITERATIONS_UPORDOWN_PELSSER_1997";
        return $MIN_ITERATIONS_UPORDOWN_PELSSER_1997;
    }
    elsif ( $k_min > $MAX_ITERATIONS_UPORDOWN_PELSSER_1997 ) {

        # print "$0: $k_min greater than $MAX_ITERATIONS_UPORDOWN_PELSSER_1997";
        return $MAX_ITERATIONS_UPORDOWN_PELSSER_1997;
    }

    return int($k_min);
}

=head2 _get_min_iterations_ot_down_ko_up_pelsser_1997

    USAGE

    DESCRIPTION
    An estimate of the number of iterations required to achieve a certain
    level of accuracy in the price for ONETOUCH-UP-KNOCKOUT-UP.

=cut

sub _get_min_iterations_ot_down_ko_up_pelsser_1997 {
    my ( $S, $U, $D, $t, $r_q, $mu, $sigma, $w, $accuracy ) = @_;

    my $h      = log( $U / $D );
    my $x      = log( $S / $D );
    my $mu_new = $mu - ( 0.5 * $sigma * $sigma );

    $accuracy = $accuracy * exp( $mu_new * $h / ( $sigma * $sigma ) );

    return _get_min_iterations_ot_up_ko_down_pelsser_1997( $S, $U, $D, $t, $r_q,
        $mu, $sigma, $w, $accuracy );
}

=head2 double_no_touch

    USAGE
    my $price = double_no_touch($S, $U, $D, $t, $r_q, $mu, $sigma, $w)

    PARAMS
    $S stock price
    $t time (1 = 1 year)
    $U barrier
    $D barrier
    $r_q payout currency interest rate (0.05 = 5%)
    $mu quanto drift adjustment (0.05 = 5%)
    $sigma volatility (0.3 = 30%)

    see [3] for $r_q and $mu for quantos

    DESCRIPTION
    Price a double_no_touch contract.

=cut

sub double_no_touch {

    # payout time $w is only a dummy. double_no_touch contracts always payout at end.
    my ( $S, $U, $D, $t, $r_q, $mu, $sigma, $w ) = @_;

    # double_no_touch always pay out at end
    $w = 1;

    return
      exp( -$r_q * $t ) - double_one_touch( $S, $U, $D, $t, $r_q, $mu, $sigma, $w );
}

=head1 REFERENCES

[1] P.G Zhang [1997], "Exotic Options", World Scientific
    Another good refernce is Mark rubinstein, Eric Reiner [1991], "Binary Options", RISK 4, pp 75-83

[2] Anlong Li [1999], "The pricing of double barrier options and their variations".
    Advances in Futures and Options, 10, 1999. (paper).

[3] Uwe Wystup. FX Options and  Strutured Products. Wiley Finance, England, 2006. pp 93-96 (Quantos)

[4] Antoon Pelsser, "Pricing Double Barrier Options: An Analytical Approach", Jan 15 1997.
    http://repub.eur.nl/pub/7807/1997-0152.pdf

=head1 AUTHOR

binary.com, C<< <rohan at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-business-blackscholes-binaries at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Business-BlackScholes-Binaries>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Business::BlackScholes::Binaries


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Business-BlackScholes-Binaries>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Business-BlackScholes-Binaries>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Business-BlackScholes-Binaries>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Business-BlackScholes-Binaries/>

=back


=head1 DEPENDENCIES

Math::CDF


=head1 LICENSE AND COPYRIGHT

Copyright 2014 binary.com.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;

