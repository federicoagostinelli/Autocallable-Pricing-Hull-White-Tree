function legA = priceLegA(product, market)
%PRICELEGA Price Party A floating leg with early cancellation.
%
%   legA = PRICELEGA(product, market)
%
%   prices the Party A leg of the Assignment 6 hedging swap.
%
%   Party A pays:
%
%       Euribor 3M + spread
%
%   on a quarterly ACT/360 schedule.
%
%   Early redemption timing
%   -----------------------
%
%   The early redemption condition is observed at the first Party B coupon
%   reset date:
%
%       product.partyB.resetDates(1)
%
%   which is two TARGET business days before the first annual coupon payment
%   date.
%
%   However, the reset date is only the observation date. If the condition is
%   met, the actual coupon payment and swap cancellation occur on:
%
%       product.partyB.paymentDates(1)
%
%   Therefore, although the condition is observed before the fourth Party A
%   quarterly payment date, Party A still pays the fourth quarterly coupon.
%
%   In the early-cancellation scenario, Party A pays:
%
%       quarterly coupons 1, 2, 3, 4
%
%   and not only coupons 1, 2, 3.
%
%   Discounting convention
%   ----------------------
%
%   Cashflows are paid on payment dates, not on reset dates. Therefore the
%   present value of Party A uses:
%
%       product.partyA.paymentDiscounts
%
%   and not reset-date discount factors.
%
%   The reset date only determines whether early cancellation occurs.
%
%   Valuation
%   ---------
%
%   With deterministic single-curve rates, the Euribor component of a
%   floater starting at t0 and ending at T_k is telescopic:
%
%       FloatingPV(0,T_k) = 1 - P(0,T_k)
%
%   in unit-notional terms.
%
%   The spread component is:
%
%       SpreadPV(0,T_k) =
%           spread * sum_{i=1}^{k} delta_i P(0,T_i)
%
%   where T_i are Party A quarterly payment dates.
%
%   Since the swap can cancel after the first annual payment date:
%
%       PV_A =
%           p_ER       * PV_A(0,T_1)
%         + (1 - p_ER) * PV_A(0,T_2)
%
%   where p_ER is read from:
%
%       market.simulation.probabilityEarlyRedemption
%
%   INPUT
%
%       product
%           Product struct created by initializeProduct and enriched by
%           prepareProductForPricing.
%
%       market
%           Market struct containing:
%
%               market.simulation.probabilityEarlyRedemption
%
%           obtained once in the main by simulateEarlyRedemptionEvent.
%
%   OUTPUT
%
%       legA
%           Struct containing the probability-weighted PV and the two
%           deterministic scenario PVs.

    %% Input checks

    if ~isfield(market, 'simulation') || ...
            ~isfield(market.simulation, 'probabilityEarlyRedemption')
        error('priceLegA:MissingSimulation', ...
            ['market.simulation.probabilityEarlyRedemption is missing. ' ...
             'Run simulateEarlyRedemptionEvent in the main first.']);
    end

    if ~isscalar(market.simulation.probabilityEarlyRedemption) || ...
            ~isfinite(market.simulation.probabilityEarlyRedemption) || ...
            market.simulation.probabilityEarlyRedemption < 0 || ...
            market.simulation.probabilityEarlyRedemption > 1
        error('priceLegA:InvalidProbability', ...
            'market.simulation.probabilityEarlyRedemption must be a scalar in [0,1].');
    end

    paymentsPerPartyBPeriod = ...
        product.partyA.paymentsPerYear / product.partyB.paymentsPerYear;

    if mod(paymentsPerPartyBPeriod, 1) ~= 0
        error('priceLegA:InvalidFrequencyMapping', ...
            'Party B payment dates do not map exactly to Party A payment grid.');
    end

    earlyCancellationPaymentIdx = paymentsPerPartyBPeriod;

    if earlyCancellationPaymentIdx > numel(product.partyA.paymentDiscounts)
        error('priceLegA:InvalidEarlyCancellationIndex', ...
            'Early cancellation payment index exceeds available Party A payments.');
    end

    %% Scenario 1: early cancellation at first annual payment date

    floatingLegAIfEarlyCancelled = ...
        1.0 - product.partyA.paymentDiscounts(earlyCancellationPaymentIdx);

    spreadLegAIfEarlyCancelled = ...
        product.partyA.spread ...
        * sum( ...
            product.partyA.delta(1:earlyCancellationPaymentIdx) ...
            .* product.partyA.paymentDiscounts(1:earlyCancellationPaymentIdx) ...
        );

    npvAIfEarlyCancelled = product.principal * ...
        (floatingLegAIfEarlyCancelled + spreadLegAIfEarlyCancelled);

    %% Scenario 2: no early cancellation, full maturity

    floatingLegAIfNotCancelled = ...
        1.0 - product.partyA.paymentDiscounts(end);

    spreadLegAIfNotCancelled = ...
        product.partyA.spread ...
        * sum( ...
            product.partyA.delta(:) ...
            .* product.partyA.paymentDiscounts(:) ...
        );

    npvAIfNotCancelled = product.principal * ...
        (floatingLegAIfNotCancelled + spreadLegAIfNotCancelled);

    %% Probability-weighted NPV

    npvA = ...
        market.simulation.probabilityEarlyRedemption * npvAIfEarlyCancelled ...
        + (1.0 - market.simulation.probabilityEarlyRedemption) ...
        * npvAIfNotCancelled;

    %% Output

    legA = struct();

    legA.npv = npvA;
    legA.earlyRedemptionProbability = ...
        market.simulation.probabilityEarlyRedemption;

    legA.npvIfEarlyCancelled = npvAIfEarlyCancelled;
    legA.npvIfNotCancelled = npvAIfNotCancelled;

    legA.floatingLegAIfEarlyCancelled = floatingLegAIfEarlyCancelled;
    legA.spreadLegAIfEarlyCancelled = spreadLegAIfEarlyCancelled;

    legA.floatingLegAIfNotCancelled = floatingLegAIfNotCancelled;
    legA.spreadLegAIfNotCancelled = spreadLegAIfNotCancelled;

    legA.earlyRedemptionResetDate = product.partyB.resetDates(1);
    legA.earlyCancellationPaymentDate = product.partyB.paymentDates(1);

    legA.earlyCancellationPaymentIdx = earlyCancellationPaymentIdx;
    legA.finalPaymentIdx = numel(product.partyA.paymentDiscounts);

end