function legB = priceLegBModifiedThreeYear(product, market)
%PRICELEGBMODIFIEDTHREEYEAR Price Party B leg of the modified 3Y product.
%
%   legB = PRICELEGBMODIFIEDTHREEYEAR(product, market)
%
%   prices the Party B coupon leg of the modified three-year contract.
%
%   Modified payoff
%   ---------------
%   Party B pays:
%
%       Year 1:
%           6% if S1 < strike.
%           If paid, the contract is cancelled at the first annual payment
%           date.
%
%       Year 2:
%           6% if S2 < strike, provided the contract was not cancelled in
%           year 1.
%           If paid, the contract is cancelled at the second annual payment
%           date.
%
%       Year 3:
%           2% if the contract survived the first two years.
%
%   Therefore:
%
%       ER1      = {S1 < strike}
%       ER2      = {S1 >= strike, S2 < strike}
%       Survival = {S1 >= strike, S2 >= strike}
%
%   No principal redemption is included.
%
%   Required simulation fields
%   --------------------------
%   The function reads:
%
%       market.simulation.probabilityEarlyRedemptionYear1
%       market.simulation.probabilityEarlyRedemptionYear2
%       market.simulation.probabilitySurvivalToFinal
%
%   INPUT
%   -----
%   product
%       Product struct created by initializeProduct and enriched by
%       prepareProductForPricing.
%
%   market
%       Market struct containing modified three-year simulation
%       probabilities.
%
%   OUTPUT
%   ------
%   legB
%       Struct containing the probability-weighted PV and scenario PVs.

    %% Input checks

    requiredFields = { ...
        'probabilityEarlyRedemptionYear1', ...
        'probabilityEarlyRedemptionYear2', ...
        'probabilitySurvivalToFinal'};

    if ~isfield(market, 'simulation')
        error('priceLegBModifiedThreeYear:MissingSimulation', ...
            'market.simulation is missing.');
    end

    for iField = 1:numel(requiredFields)
        fieldName = requiredFields{iField};

        if ~isfield(market.simulation, fieldName)
            error('priceLegBModifiedThreeYear:MissingSimulationField', ...
                'market.simulation.%s is missing.', fieldName);
        end
    end

    pER1 = market.simulation.probabilityEarlyRedemptionYear1;
    pER2 = market.simulation.probabilityEarlyRedemptionYear2;
    pSurvival = market.simulation.probabilitySurvivalToFinal;

    if any([pER1, pER2, pSurvival] < -1e-12) || ...
            any([pER1, pER2, pSurvival] > 1 + 1e-12)
        error('priceLegBModifiedThreeYear:InvalidProbabilities', ...
            'Scenario probabilities must be in [0,1].');
    end

    if abs(pER1 + pER2 + pSurvival - 1) > 1e-8
        error('priceLegBModifiedThreeYear:InvalidProbabilitySum', ...
            'Scenario probabilities must sum to one.');
    end

    if numel(product.partyB.paymentDiscounts) < 3 || ...
            numel(product.partyB.delta) < 3
        error('priceLegBModifiedThreeYear:InvalidPartyBSchedule', ...
            'Party B must contain at least three annual coupon periods.');
    end

    %% Scenario unit-notional discounted coupon contributions

    coupon1LegB = ...
        product.partyB.delta(1) ...
        * product.partyB.coupons.year1.rate ...
        * product.partyB.paymentDiscounts(1);

    coupon2LegB = ...
        product.partyB.delta(2) ...
        * product.partyB.coupons.year1.rate ...
        * product.partyB.paymentDiscounts(2);

    coupon3LegB = ...
        product.partyB.delta(3) ...
        * product.partyB.coupons.final.rate ...
        * product.partyB.paymentDiscounts(3);

    npvBIfEarlyRedeemedYear1 = product.principal * coupon1LegB;
    npvBIfEarlyRedeemedYear2 = product.principal * coupon2LegB;
    npvBIfSurvivalToFinal = product.principal * coupon3LegB;

    %% Recursive probability-weighted NPV
    %
    % Year-2 continuation value:
    %
    %   if ER2      -> coupon2
    %   if survival -> coupon3
    %
    % Year-1 value:
    %
    %   if ER1      -> coupon1
    %   if no ER1   -> continuation

    npvB = ...
        pER1 * npvBIfEarlyRedeemedYear1 ...
        + pER2 * npvBIfEarlyRedeemedYear2 ...
        + pSurvival * npvBIfSurvivalToFinal;

    %% Output

    legB = struct();

    legB.npv = npvB;

    legB.probabilityEarlyRedemptionYear1 = pER1;
    legB.probabilityEarlyRedemptionYear2 = pER2;
    legB.probabilitySurvivalToFinal = pSurvival;

    legB.npvIfEarlyRedeemedYear1 = npvBIfEarlyRedeemedYear1;
    legB.npvIfEarlyRedeemedYear2 = npvBIfEarlyRedeemedYear2;
    legB.npvIfSurvivalToFinal = npvBIfSurvivalToFinal;

    legB.coupon1LegB = coupon1LegB;
    legB.coupon2LegB = coupon2LegB;
    legB.coupon3LegB = coupon3LegB;

    legB.expectedCoupon1Rate = ...
        pER1 * product.partyB.coupons.year1.rate;

    legB.expectedCoupon2Rate = ...
        pER2 * product.partyB.coupons.year1.rate;

    legB.expectedFinalCouponRate = ...
        pSurvival * product.partyB.coupons.final.rate;

    legB.firstCouponPaymentDate = product.partyB.paymentDates(1);
    legB.secondCouponPaymentDate = product.partyB.paymentDates(2);
    legB.finalCouponPaymentDate = product.partyB.paymentDates(3);

    legB.firstResetDate = product.partyB.resetDates(1);
    legB.secondResetDate = product.partyB.resetDates(2);

end