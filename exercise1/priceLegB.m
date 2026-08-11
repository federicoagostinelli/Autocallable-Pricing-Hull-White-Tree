function legB = priceLegB(product, market)
%PRICELEGB Price Party B equity-linked coupon leg.
%
%   legB = PRICELEGB(product, market)
%
%   prices the Party B leg of the Assignment 6 hedging swap.
%
%   Party B pays:
%
%       - Year 1 coupon:
%             6% if Stoxx50 < Strike at the first coupon reset date,
%             otherwise 0%.
%
%       - Final coupon:
%             2%, paid only if the product has not been redeemed/cancelled
%             early.
%
%   Early redemption timing
%   -----------------------
%
%   The first coupon condition is observed at:
%
%       product.partyB.resetDates(1)
%
%   which is two TARGET business days before:
%
%       product.partyB.paymentDates(1)
%
%   If the condition is met at the reset date, the coupon is not paid at the
%   reset date. It is paid on the corresponding coupon payment date.
%
%   Therefore the first coupon is discounted using:
%
%       product.partyB.paymentDiscounts(1)
%
%   and not:
%
%       product.partyB.resetDiscounts(1)
%
%   Valuation
%   ---------
%
%   The early redemption probability is read from:
%
%       market.simulation.probabilityEarlyRedemption
%
%   In the base two-year product:
%
%       if early redemption occurs:
%
%           coupon 1 = 6%
%           coupon 2 = 0%
%
%       if early redemption does not occur:
%
%           coupon 1 = 0%
%           coupon 2 = 2%
%
%   Hence:
%
%       PV_B =
%           p_ER       * principal * delta_1 * coupon_1 * P(0,T_1)
%         + (1 - p_ER) * principal * delta_2 * coupon_2 * P(0,T_2)
%
%   where T_1 and T_2 are Party B payment dates.
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
%       legB
%           Struct containing the probability-weighted PV and scenario PVs.

    %% Input checks

    if ~isfield(market, 'simulation') || ...
            ~isfield(market.simulation, 'probabilityEarlyRedemption')
        error('priceLegB:MissingSimulation', ...
            ['market.simulation.probabilityEarlyRedemption is missing. ' ...
             'Run simulateEarlyRedemptionEvent in the main first.']);
    end

    if ~isscalar(market.simulation.probabilityEarlyRedemption) || ...
            ~isfinite(market.simulation.probabilityEarlyRedemption) || ...
            market.simulation.probabilityEarlyRedemption < 0 || ...
            market.simulation.probabilityEarlyRedemption > 1
        error('priceLegB:InvalidProbability', ...
            'market.simulation.probabilityEarlyRedemption must be a scalar in [0,1].');
    end

    if numel(product.partyB.paymentDiscounts) < 2 || ...
            numel(product.partyB.delta) < 2
        error('priceLegB:InvalidPartyBSchedule', ...
            'Party B must contain at least two annual coupon periods.');
    end

    %% Scenario unit-notional discounted coupon contributions

    coupon1LegB = ...
        product.partyB.delta(1) ...
        * product.partyB.coupons.year1.rate ...
        * product.partyB.paymentDiscounts(1);

    coupon2LegB = ...
        product.partyB.delta(2) ...
        * product.partyB.coupons.final.rate ...
        * product.partyB.paymentDiscounts(2);

    npvBIfEarlyRedeemed = product.principal * coupon1LegB;

    npvBIfNotRedeemed = product.principal * coupon2LegB;

    %% Probability-weighted NPV

    npvB = ...
        market.simulation.probabilityEarlyRedemption * npvBIfEarlyRedeemed ...
        + (1.0 - market.simulation.probabilityEarlyRedemption) ...
        * npvBIfNotRedeemed;

    %% Output

    legB = struct();

    legB.npv = npvB;
    legB.earlyRedemptionProbability = ...
        market.simulation.probabilityEarlyRedemption;

    legB.npvIfEarlyRedeemed = npvBIfEarlyRedeemed;
    legB.npvIfNotRedeemed = npvBIfNotRedeemed;

    legB.coupon1LegB = coupon1LegB;
    legB.coupon2LegB = coupon2LegB;

    legB.expectedCoupon1Rate = ...
        market.simulation.probabilityEarlyRedemption ...
        * product.partyB.coupons.year1.rate;

    legB.expectedCoupon2Rate = ...
        (1.0 - market.simulation.probabilityEarlyRedemption) ...
        * product.partyB.coupons.final.rate;

    legB.earlyRedemptionResetDate = product.partyB.resetDates(1);
    legB.firstCouponPaymentDate = product.partyB.paymentDates(1);
    legB.finalCouponPaymentDate = product.partyB.paymentDates(2);

end