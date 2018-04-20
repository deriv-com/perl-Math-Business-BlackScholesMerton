package Math::Business::BlackScholes;

use strict;
use warnings;
our $VERSION = '1.22';

# ABSTRACT: Algorithm of Math::Business::BlackScholes for binary and non-binary options

=head1 NAME

Math::Business::BlackScholes

=head1 DESCRIPTION

Please refer to documentions in L<Math::Business::BlackScholes::Binaries> and L<Math::Business::BlackScholes::NonBinaries> for more details.

=cut

=head1 DEPENDENCIES

    * Math::CDF
    * Machine::Epsilon

=head1 SOURCE CODE

    https://github.com/binary-com/perl-math-business-blackscholes

=head1 REFERENCES

[1] P.G Zhang [1997], "Exotic Options", World Scientific
    Another good refernce is Mark rubinstein, Eric Reiner [1991], "Binary Options", RISK 4, pp 75-83

[2] Anlong Li [1999], "The pricing of double barrier options and their variations".
    Advances in Futures and Options, 10, 1999. (paper).

[3] Uwe Wystup. FX Options and  Strutured Products. Wiley Finance, England, 2006. pp 93-96 (Quantos)

[4] Antoon Pelsser, "Pricing Double Barrier Options: An Analytical Approach", Jan 15 1997.
    http://repub.eur.nl/pub/7807/1997-0152.pdf

[5] Espen Gaarder Haug, PhD
    The Complete Guide to Option Pricing Formulas p141-p144

=head1 AUTHOR

binary.com, C<< <rohan at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-business-blackscholes at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Business-BlackScholes>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Business::BlackScholes


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Business-BlackScholes>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Business-BlackScholes>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Business-BlackScholes>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Business-BlackScholes/>

=back

=cut

1;
