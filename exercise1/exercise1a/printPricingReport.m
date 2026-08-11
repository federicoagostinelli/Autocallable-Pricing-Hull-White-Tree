function printPricingReport(market, product, upfront, mtmA, legA, legB)
%PRINTPRICINGREPORT Print Assignment 6 pricing and upfront report.
%
%   PRINTPRICINGREPORT(market, product, upfront, mtmA, legA, legB)
%
%   prints a compact report for the Assignment 6 swap valuation, always
%   from Party A's perspective.
%
%   The function supports:
%
%       1. Standard Assignment 6 product.
%       2. Modified 3Y product for Exercise 1.d, identified by:
%
%              product.productType == "ModifiedThreeYear"
%
%       3. Different pricing models:
%
%              NIG
%              VG
%              Black
%              BlackCorrected
%
%   Sign convention
%   ---------------
%   Party A:
%
%       - pays Leg A:
%             Euribor 3M + 1.30%
%
%       - receives Leg B:
%             structured equity-linked coupon leg
%
%       - receives upfront X from Party B at inception.
%
%   Therefore:
%
%       MtM_A = PV(received Leg B)
%             - PV(paid Leg A)
%             + upfront * principal
%
%   The fair upfront satisfies:
%
%       upfront = (LegA - LegB) / principal

    %% Detect product type

    isModifiedThreeYear = ...
        isfield(product, "productType") && ...
        string(product.productType) == "ModifiedThreeYear";

    %% Detect model name

    modelName = "Unknown";

    if isfield(market, 'simulation') && isfield(market.simulation, 'modelName')
        modelName = string(market.simulation.modelName);
    elseif isfield(market, 'nts') && isfield(market.nts, 'modelName')
        modelName = string(market.nts.modelName);
    elseif isfield(market, 'vg') && isfield(market.vg, 'modelName')
        modelName = string(market.vg.modelName);
    end

    fprintf('\n');
    fprintf('============================================================\n');

    if isModifiedThreeYear
        fprintf(' ASSIGNMENT 6 EXERCISE 1.d PRICING REPORT - PARTY A PERSPECTIVE\n');
    else
        fprintf(' ASSIGNMENT 6 PRICING REPORT - PARTY A PERSPECTIVE\n');
    end

    fprintf(' MODEL: %s\n', modelName);
    fprintf('============================================================\n\n');

    %% Sign convention

    fprintf('1. SIGN CONVENTION\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Party A pays                : Euribor 3M + %.8f%%\n', ...
        100 * product.partyA.spread);
    fprintf('Party A receives            : Structured equity-linked coupons\n');
    fprintf('Party A receives upfront    : X from Party B at inception\n');
    fprintf('Fair condition              : MtM_A = PV_B - PV_A + X * Principal = 0\n');
    fprintf('Fair upfront                : X = (PV_A - PV_B) / Principal\n');

    fprintf('\n');

    %% Product summary

    fprintf('2. PRODUCT SUMMARY\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Principal                   : %.2f %s\n', ...
        product.principal, product.currency);
    fprintf('Start date                  : %s\n', datestr(product.startDate));
    fprintf('End date                    : %s\n', datestr(product.endDate));
    fprintf('Maturity                    : %d years\n', product.maturityYears);

    if isModifiedThreeYear
        fprintf('Product type                : Modified 3Y product\n');
        fprintf('Exercise 1.d logic          : Year-1 payoff repeated in Year 2\n');
    else
        fprintf('Product type                : Standard 2Y Assignment 6 product\n');
    end

    fprintf('\n');

    %% Simulation summary

    fprintf('3. EARLY REDEMPTION SIMULATION\n');
    fprintf('------------------------------------------------------------\n');

    if isfield(market, 'simulation')

        if isfield(market.simulation, 'nSim')
            fprintf('Number of simulations        : %d\n', market.simulation.nSim);
        end

        if isModifiedThreeYear

            if isfield(market.simulation, 'probabilityBelowStrikeYear1')
                fprintf('P(S_1 < Strike)              : %.8f%%\n', ...
                    100 * market.simulation.probabilityBelowStrikeYear1);
            end

            if isfield(market.simulation, 'probabilityBelowStrikeYear2')
                fprintf('P(S_2 < Strike)              : %.8f%%\n', ...
                    100 * market.simulation.probabilityBelowStrikeYear2);
            end

            fprintf('P(ER year 1)                 : %.8f%%\n', ...
                100 * market.simulation.probabilityEarlyRedemptionYear1);

            fprintf('P(ER year 2)                 : %.8f%%\n', ...
                100 * market.simulation.probabilityEarlyRedemptionYear2);

            if isfield(market.simulation, 'probabilityEarlyRedemptionYear2ConditionalOnNoER1')
                fprintf('P(ER year 2 | no ER year 1)  : %.8f%%\n', ...
                    100 * market.simulation.probabilityEarlyRedemptionYear2ConditionalOnNoER1);
            end

            fprintf('P(Survival to final)         : %.8f%%\n', ...
                100 * market.simulation.probabilitySurvivalToFinal);

        else

            if isfield(market.simulation, 'probabilityBelowStrike')
                fprintf('P(S_reset < Strike)          : %.8f%%\n', ...
                    100 * market.simulation.probabilityBelowStrike);
            end

            if isfield(market.simulation, 'probabilityEarlyRedemption')
                fprintf('P(Early redemption)          : %.8f%%\n', ...
                    100 * market.simulation.probabilityEarlyRedemption);
            end

        end

    else
        fprintf('Simulation not found in market.simulation.\n');
    end

    fprintf('Observation date year 1      : %s\n', ...
        datestr(product.partyB.resetDates(1)));

    if isModifiedThreeYear && numel(product.partyB.resetDates) >= 2
        fprintf('Observation date year 2      : %s\n', ...
            datestr(product.partyB.resetDates(2)));
    end

    fprintf('First coupon payment date    : %s\n', ...
        datestr(product.partyB.paymentDates(1)));

    if isModifiedThreeYear && numel(product.partyB.paymentDates) >= 2
        fprintf('Second coupon payment date   : %s\n', ...
            datestr(product.partyB.paymentDates(2)));
    end

    fprintf('Final maturity date          : %s\n', ...
        datestr(product.partyB.paymentDates(end)));
    fprintf('Strike                       : %.8f\n', product.underlying.strike);

    fprintf('\n');

    %% Model summary

    fprintf('4. MODEL SUMMARY\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Pricing model                : %s\n', modelName);

    if isfield(market, 'nts') && ...
            (modelName == "NIG" || modelName == "NTS" || contains(modelName, "NIG"))

        fprintf('Model family                 : NTS / NIG\n');

        if isfield(market.nts, 'alpha')
            fprintf('Alpha used for simulation    : %.8f\n', market.nts.alpha);
        end

        if isfield(market.nts, 'calibrationDate')
            fprintf('Calibration date             : %s\n', ...
                datestr(market.nts.calibrationDate));
        end

        if isfield(market.nts, 'calibrationTime')
            fprintf('Calibration time ACT/365     : %.10f\n', ...
                market.nts.calibrationTime);
        end

        if isfield(market.nts, 'forward')
            fprintf('Forward                      : %.10f\n', market.nts.forward);
        end

        if isfield(market.nts, 'discountFactor')
            fprintf('Discount factor              : %.10f\n', market.nts.discountFactor);
        end

        if isfield(market.nts, 'sigmaOpt')
            fprintf('sigma                        : %.10f\n', market.nts.sigmaOpt);
        end

        if isfield(market.nts, 'kappaOpt')
            fprintf('kappa                        : %.10f\n', market.nts.kappaOpt);
        end

        if isfield(market.nts, 'etaOpt')
            fprintf('eta                          : %.10f\n', market.nts.etaOpt);
        end

        if isfield(market.nts, 'objValue')
            fprintf('objective value              : %.10e\n', market.nts.objValue);
        end

    elseif isfield(market, 'vg') && ...
            (modelName == "VG" || contains(modelName, "VG"))

        fprintf('Model family                 : Variance Gamma\n');

        if isfield(market.vg, 'alpha')
            fprintf('Alpha                        : %.8f\n', market.vg.alpha);
        end

        fprintf('Parameter source             : VG calibration\n');

        if isfield(market.vg, 'calibrationDate')
            fprintf('Calibration date             : %s\n', ...
                datestr(market.vg.calibrationDate));
        end

        if isfield(market.vg, 'calibrationTime')
            fprintf('Calibration time ACT/365     : %.10f\n', ...
                market.vg.calibrationTime);
        end

        if isfield(market.vg, 'forward')
            fprintf('Forward                      : %.10f\n', market.vg.forward);
        end

        if isfield(market.vg, 'discountFactor')
            fprintf('Discount factor              : %.10f\n', market.vg.discountFactor);
        end

        if isfield(market.vg, 'sigmaOpt')
            fprintf('sigma                        : %.10f\n', market.vg.sigmaOpt);
        end

        if isfield(market.vg, 'kappaOpt')
            fprintf('kappa                        : %.10f\n', market.vg.kappaOpt);
        end

        if isfield(market.vg, 'etaOpt')
            fprintf('eta                          : %.10f\n', market.vg.etaOpt);
        end

        if isfield(market.vg, 'objValue')
            fprintf('objective value              : %.10e\n', market.vg.objValue);
        end

    elseif modelName == "Black" || modelName == "BlackCorrected"

        fprintf('Model family                 : Black forward model\n');

        if isfield(market.simulation, 'resetDate')
            fprintf('Reset date                   : %s\n', ...
                datestr(market.simulation.resetDate));
        end

        if isfield(market.simulation, 'resetTime')
            fprintf('Reset time ACT/365           : %.10f\n', ...
                market.simulation.resetTime);
        end

        if isfield(market.simulation, 'forward')
            fprintf('Forward                      : %.10f\n', ...
                market.simulation.forward);
        end

        if isfield(market.simulation, 'discountFactor')
            fprintf('Discount factor              : %.10f\n', ...
                market.simulation.discountFactor);
        end

        if isfield(market.simulation, 'impliedVolatility')
            fprintf('Implied volatility at strike : %.10f\n', ...
                market.simulation.impliedVolatility);
        end

        if isfield(market.simulation, 'd2')
            fprintf('Black d2                     : %.10f\n', ...
                market.simulation.d2);
        end

        if isfield(market.simulation, 'blackProbabilityBelowStrike')
            fprintf('Black P(S_T < K)             : %.10f\n', ...
                market.simulation.blackProbabilityBelowStrike);
        end

        if modelName == "BlackCorrected"

            fprintf('Smile correction             : YES\n');

            if isfield(market.simulation, 'smileSlope')
                fprintf('Smile slope dSigma/dK        : %.10e\n', ...
                    market.simulation.smileSlope);
            end

            if isfield(market.simulation, 'vega')
                fprintf('Black76 vega                 : %.10f\n', ...
                    market.simulation.vega);
            end

            if isfield(market.simulation, 'correctionPrice')
                fprintf('Correction price             : %.10e\n', ...
                    market.simulation.correctionPrice);
            end

            if isfield(market.simulation, 'correctionProbability')
                fprintf('Correction probability       : %.10e\n', ...
                    market.simulation.correctionProbability);
            end

            if isfield(market.simulation, 'correctedProbabilityBelowStrike')
                fprintf('Corrected P(S_T < K)         : %.10f\n', ...
                    market.simulation.correctedProbabilityBelowStrike);
            end

        else

            fprintf('Smile correction             : NO\n');

        end

    else

        fprintf('Model details                : not available for this market struct.\n');

    end

    fprintf('\n');

    %% Leg A

    fprintf('5. LEG A - PAID BY PARTY A\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Leg type                    : Floating Euribor 3M + spread\n');
    fprintf('Payment frequency           : Quarterly\n');
    fprintf('Day count                   : ACT/360\n');
    fprintf('Spread                      : %.8f%%\n', ...
        100 * product.partyA.spread);
    fprintf('Payment discount factors    : Party A payment dates\n');
    fprintf('Reset dates                 : Not used for discounting cashflows\n');

    if isModifiedThreeYear

        fprintf('\n');
        fprintf('Scenario: Early cancellation at year 1\n');
        fprintf('  Cancellation/payment date  : %s\n', ...
            datestr(legA.earlyCancellationPaymentDateYear1));
        fprintf('  Party A coupons paid       : %d\n', ...
            legA.earlyCancellationPaymentIdxYear1);
        fprintf('  Floating component         : %.10f\n', ...
            legA.floatingLegAIfCancelledYear1);
        fprintf('  Spread component           : %.10f\n', ...
            legA.spreadLegAIfCancelledYear1);
        fprintf('  PV if cancelled year 1     : %.8f\n', ...
            legA.npvIfCancelledYear1);

        fprintf('\n');
        fprintf('Scenario: Early cancellation at year 2\n');
        fprintf('  Cancellation/payment date  : %s\n', ...
            datestr(legA.earlyCancellationPaymentDateYear2));
        fprintf('  Party A coupons paid       : %d\n', ...
            legA.earlyCancellationPaymentIdxYear2);
        fprintf('  Floating component         : %.10f\n', ...
            legA.floatingLegAIfCancelledYear2);
        fprintf('  Spread component           : %.10f\n', ...
            legA.spreadLegAIfCancelledYear2);
        fprintf('  PV if cancelled year 2     : %.8f\n', ...
            legA.npvIfCancelledYear2);

        fprintf('\n');
        fprintf('Scenario: Survival to final maturity\n');
        fprintf('  Final payment date         : %s\n', ...
            datestr(legA.finalPaymentDate));
        fprintf('  Party A coupons paid       : %d\n', ...
            legA.finalPaymentIdx);
        fprintf('  Floating component         : %.10f\n', ...
            legA.floatingLegAIfSurvivalToFinal);
        fprintf('  Spread component           : %.10f\n', ...
            legA.spreadLegAIfSurvivalToFinal);
        fprintf('  PV if survival             : %.8f\n', ...
            legA.npvIfSurvivalToFinal);

    else

        fprintf('\n');
        fprintf('Scenario: Early cancellation\n');
        fprintf('  Observation/reset date     : %s\n', ...
            datestr(legA.earlyRedemptionResetDate));
        fprintf('  Cancellation/payment date  : %s\n', ...
            datestr(legA.earlyCancellationPaymentDate));
        fprintf('  Party A coupons paid       : %d\n', ...
            legA.earlyCancellationPaymentIdx);
        fprintf('  Floating component         : %.10f\n', ...
            legA.floatingLegAIfEarlyCancelled);
        fprintf('  Spread component           : %.10f\n', ...
            legA.spreadLegAIfEarlyCancelled);
        fprintf('  PV if early cancelled      : %.8f\n', ...
            legA.npvIfEarlyCancelled);

        fprintf('\n');
        fprintf('Scenario: No early cancellation\n');
        fprintf('  Party A coupons paid       : %d\n', ...
            legA.finalPaymentIdx);
        fprintf('  Floating component         : %.10f\n', ...
            legA.floatingLegAIfNotCancelled);
        fprintf('  Spread component           : %.10f\n', ...
            legA.spreadLegAIfNotCancelled);
        fprintf('  PV if not cancelled        : %.8f\n', ...
            legA.npvIfNotCancelled);

    end

    fprintf('\n');
    fprintf('Probability-weighted PV Leg A: %.8f\n', legA.npv);

    fprintf('\n');

    %% Leg B

    fprintf('6. LEG B - RECEIVED BY PARTY A\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Leg type                    : Equity-linked annual coupon leg\n');
    fprintf('Payment frequency           : Annual\n');
    fprintf('Day count                   : 30/360\n');
    fprintf('Payment discount factors    : Party B payment dates\n');
    fprintf('Reset discount factors      : Used only for equity forward/calibration\n');

    fprintf('\n');
    fprintf('Coupon rule\n');
    fprintf('  Year 1 coupon              : %.8f%% if S_1 < %.8f\n', ...
        100 * product.partyB.coupons.year1.rate, product.underlying.strike);

    if isModifiedThreeYear
        fprintf('  Year 2 coupon              : %.8f%% if alive and S_2 < %.8f\n', ...
            100 * product.partyB.coupons.year1.rate, product.underlying.strike);
        fprintf('  Final coupon               : %.8f%% if no early redemption in years 1 and 2\n', ...
            100 * product.partyB.coupons.final.rate);
    else
        fprintf('  Year 1 coupon otherwise    : 0.00000000%%\n');
        fprintf('  Final coupon               : %.8f%% if no early redemption\n', ...
            100 * product.partyB.coupons.final.rate);
    end

    if isModifiedThreeYear

        fprintf('\n');
        fprintf('Scenario: Early redemption at year 1\n');
        fprintf('  First coupon payment date  : %s\n', ...
            datestr(legB.firstCouponPaymentDate));
        fprintf('  Coupon 1 unit PV           : %.10f\n', legB.coupon1LegB);
        fprintf('  PV if ER year 1            : %.8f\n', ...
            legB.npvIfEarlyRedeemedYear1);

        fprintf('\n');
        fprintf('Scenario: Early redemption at year 2\n');
        fprintf('  Second coupon payment date : %s\n', ...
            datestr(legB.secondCouponPaymentDate));
        fprintf('  Coupon 2 unit PV           : %.10f\n', legB.coupon2LegB);
        fprintf('  PV if ER year 2            : %.8f\n', ...
            legB.npvIfEarlyRedeemedYear2);

        fprintf('\n');
        fprintf('Scenario: Survival to final maturity\n');
        fprintf('  Final coupon payment date  : %s\n', ...
            datestr(legB.finalCouponPaymentDate));
        fprintf('  Coupon 3 unit PV           : %.10f\n', legB.coupon3LegB);
        fprintf('  PV if survival             : %.8f\n', ...
            legB.npvIfSurvivalToFinal);

        fprintf('\n');
        fprintf('Expected coupon 1 rate       : %.8f%%\n', ...
            100 * legB.expectedCoupon1Rate);
        fprintf('Expected coupon 2 rate       : %.8f%%\n', ...
            100 * legB.expectedCoupon2Rate);
        fprintf('Expected final coupon rate   : %.8f%%\n', ...
            100 * legB.expectedFinalCouponRate);

    else

        fprintf('\n');
        fprintf('Scenario: Early redemption\n');
        fprintf('  First coupon payment date  : %s\n', ...
            datestr(product.partyB.paymentDates(1)));
        fprintf('  Coupon 1 unit PV           : %.10f\n', legB.coupon1LegB);
        fprintf('  PV if early redeemed       : %.8f\n', ...
            legB.npvIfEarlyRedeemed);

        fprintf('\n');
        fprintf('Scenario: No early redemption\n');
        fprintf('  Final coupon payment date  : %s\n', ...
            datestr(product.partyB.paymentDates(2)));
        fprintf('  Coupon 2 unit PV           : %.10f\n', legB.coupon2LegB);
        fprintf('  PV if not redeemed         : %.8f\n', ...
            legB.npvIfNotRedeemed);

        fprintf('\n');
        fprintf('Expected coupon 1 rate       : %.8f%%\n', ...
            100 * legB.expectedCoupon1Rate);
        fprintf('Expected coupon 2 rate       : %.8f%%\n', ...
            100 * legB.expectedCoupon2Rate);

    end

    fprintf('Probability-weighted PV Leg B: %.8f\n', legB.npv);

    fprintf('\n');

    %% Upfront

    fprintf('7. FAIR UPFRONT\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('PV Leg A paid by Party A     : %.8f\n', legA.npv);
    fprintf('PV Leg B received by Party A : %.8f\n', legB.npv);
    fprintf('PV_A - PV_B                  : %.8f\n', legA.npv - legB.npv);
    fprintf('Fair upfront X               : %.10f\n', upfront);
    fprintf('Fair upfront X               : %.8f%%\n', 100 * upfront);
    fprintf('Upfront amount               : %.8f\n', upfront * product.principal);
    fprintf('MtM_A after upfront          : %.8e\n', mtmA);

    fprintf('\n');

    %% Consistency checks

    fprintf('8. CONSISTENCY CHECKS\n');
    fprintf('------------------------------------------------------------\n');

    if abs(mtmA) < 1e-6
        fprintf('MtM check                   : PASSED\n');
    else
        fprintf('MtM check                   : WARNING\n');
    end

    fprintf('Leg A discounting            : paymentDiscounts only\n');
    fprintf('Leg B discounting            : paymentDiscounts only\n');
    fprintf('Reset dates role             : observation/calibration only\n');

    if isfield(market, 'simulation')

        if isModifiedThreeYear

            if abs(legA.probabilityEarlyRedemptionYear1 ...
                    - market.simulation.probabilityEarlyRedemptionYear1) < 1e-14 && ...
               abs(legB.probabilityEarlyRedemptionYear1 ...
                    - market.simulation.probabilityEarlyRedemptionYear1) < 1e-14 && ...
               abs(legA.probabilityEarlyRedemptionYear2 ...
                    - market.simulation.probabilityEarlyRedemptionYear2) < 1e-14 && ...
               abs(legB.probabilityEarlyRedemptionYear2 ...
                    - market.simulation.probabilityEarlyRedemptionYear2) < 1e-14

                fprintf('Common ER probabilities      : PASSED\n');

            else

                fprintf('Common ER probabilities      : WARNING\n');

            end

        else

            if isfield(market.simulation, 'probabilityEarlyRedemption')
                if abs(legA.earlyRedemptionProbability ...
                        - market.simulation.probabilityEarlyRedemption) < 1e-14 && ...
                   abs(legB.earlyRedemptionProbability ...
                        - market.simulation.probabilityEarlyRedemption) < 1e-14
                    fprintf('Common p_ER usage            : PASSED\n');
                else
                    fprintf('Common p_ER usage            : WARNING\n');
                end
            end

        end

    end

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf(' END PRICING REPORT\n');
    fprintf('============================================================\n\n');

end