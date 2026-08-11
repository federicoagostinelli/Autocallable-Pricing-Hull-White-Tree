function printBlackModelSelectionReport( ...
    product, ...
    marketBlack, upfrontBlack, mtmABlack, legABlack, legBBlack, ...
    marketBlackCorrected, upfrontBlackCorrected, mtmABlackCorrected, legABlackCorrected, legBBlackCorrected)
%PRINTBLACKMODELSELECTIONREPORT Print Black vs corrected Black comparison.
%
%   PRINTBLACKMODELSELECTIONREPORT(product,
%       marketBlack, upfrontBlack, mtmABlack, legABlack, legBBlack,
%       marketBlackCorrected, upfrontBlackCorrected, mtmABlackCorrected,
%       legABlackCorrected, legBBlackCorrected)
%
%   prints a dedicated report for Assignment 6 Exercise 1.b.
%
%   The report compares:
%
%       1. Black model without smile correction.
%       2. Black model with digital smile correction.
%
%   The product is the original 2Y Assignment 6 product. Since the payoff
%   depends on one single equity observation, the early-redemption
%   probability can be computed from the one-dimensional risk-neutral
%   marginal distribution:
%
%       P(S_T < K).
%
%   In the corrected version, the digital probability is adjusted using the
%   local slope of the implied volatility smile.

    %% Read simulation objects

    simBlack = marketBlack.simulation;
    simCorrected = marketBlackCorrected.simulation;

    %% Differences

    probabilityDifference = ...
        simCorrected.probabilityBelowStrike ...
        - simBlack.probabilityBelowStrike;

    legBDifference = ...
        legBBlackCorrected.npv ...
        - legBBlack.npv;

    upfrontDifference = ...
        upfrontBlackCorrected ...
        - upfrontBlack;

    upfrontDifferenceBps = ...
        10000 * upfrontDifference;

    %% Header

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf(' ASSIGNMENT 6 - EXERCISE 1.b MODEL SELECTION REPORT\n');
    fprintf(' BLACK VS SMILE-CORRECTED BLACK\n');
    fprintf('============================================================\n\n');

    %% Product info

    fprintf('1. PRODUCT AND MODEL SETUP\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Product maturity                    : %d years\n', product.maturityYears);
    fprintf('Underlying strike                   : %.10f\n', product.underlying.strike);
    fprintf('Reset date                          : %s\n', datestr(product.partyB.resetDates(1)));
    fprintf('Payment date                        : %s\n', datestr(product.partyB.paymentDates(1)));
    fprintf('Final maturity date                 : %s\n', datestr(product.partyB.paymentDates(end)));
    fprintf('Coupon if below strike              : %.8f%%\n', ...
        100 * product.partyB.coupons.year1.rate);
    fprintf('Final coupon if no early redemption : %.8f%%\n', ...
        100 * product.partyB.coupons.final.rate);

    fprintf('\n');
    fprintf('Relevant probability                : P(S_T < K)\n');

    fprintf('\n');

    %% Market quantities

    fprintf('2. COMMON MARKET QUANTITIES\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Forward F(0,T)                     : %.10f\n', simBlack.forward);
    fprintf('Discount factor P(0,T)             : %.10f\n', simBlack.discountFactor);
    fprintf('Implied volatility at strike       : %.10f\n', simBlack.impliedVolatility);
    fprintf('Black d2                           : %.10f\n', simBlack.d2);

    fprintf('\n');

    %% Black

    fprintf('3. BLACK MODEL WITHOUT CORRECTION\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Model name                         : %s\n', string(simBlack.modelName));
    fprintf('P(S_T < K)                         : %.10f\n', ...
        simBlack.probabilityBelowStrike);
    fprintf('P(Early redemption)                : %.10f\n', ...
        simBlack.probabilityEarlyRedemption);
    fprintf('Leg A NPV                          : %.10f\n', legABlack.npv);
    fprintf('Leg B NPV                          : %.10f\n', legBBlack.npv);
    fprintf('Fair upfront X                     : %.10f\n', upfrontBlack);
    fprintf('Fair upfront X                     : %.8f%%\n', 100 * upfrontBlack);
    fprintf('MtM A after upfront                : %.12e\n', mtmABlack);

    fprintf('\n');

    %% Corrected Black

    fprintf('4. BLACK MODEL WITH SMILE CORRECTION\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Model name                         : %s\n', string(simCorrected.modelName));
    fprintf('Black P(S_T < K) before correction : %.10f\n', ...
        simCorrected.blackProbabilityBelowStrike);
    fprintf('Smile slope dSigma/dK              : %.10e\n', ...
        simCorrected.smileSlope);
    fprintf('Black76 vega                       : %.10f\n', ...
        simCorrected.vega);
    fprintf('Correction price                   : %.10e\n', ...
        simCorrected.correctionPrice);
    fprintf('Correction probability             : %.10e\n', ...
        simCorrected.correctionProbability);
    fprintf('Corrected P(S_T < K)               : %.10f\n', ...
        simCorrected.probabilityBelowStrike);
    fprintf('P(Early redemption)                : %.10f\n', ...
        simCorrected.probabilityEarlyRedemption);
    fprintf('Leg A NPV                          : %.10f\n', legABlackCorrected.npv);
    fprintf('Leg B NPV                          : %.10f\n', legBBlackCorrected.npv);
    fprintf('Fair upfront X                     : %.10f\n', upfrontBlackCorrected);
    fprintf('Fair upfront X                     : %.8f%%\n', 100 * upfrontBlackCorrected);
    fprintf('MtM A after upfront                : %.12e\n', mtmABlackCorrected);

    fprintf('\n');

    %% Comparison

    fprintf('5. COMPARISON\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Delta probability P(S_T < K)       : %.10e\n', probabilityDifference);
    fprintf('Delta Leg B NPV                    : %.10f\n', legBDifference);
    fprintf('Delta upfront                      : %.10f\n', upfrontDifference);
    fprintf('Delta upfront                      : %.8f%%\n', 100 * upfrontDifference);
    fprintf('Delta upfront                      : %.4f bps of notional\n', upfrontDifferenceBps);

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf(' END MODEL SELECTION REPORT\n');
    fprintf('============================================================\n\n');

end