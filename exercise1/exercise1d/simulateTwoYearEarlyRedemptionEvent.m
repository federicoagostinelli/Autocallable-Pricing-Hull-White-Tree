function simulation = simulateTwoYearEarlyRedemptionEvent(product, market, nSim, rngSeed)
%SIMULATETWOYEAREARLYREDEMPTIONEVENT Simulate early redemption at year 1 and year 2.
%
%   simulation = SIMULATETWOYEAREARLYREDEMPTIONEVENT(product, market, nSim, rngSeed)
%
%   simulates the modified 3-year product with two possible early-redemption
%   dates.
%
%   The function reuses simulateEarlyRedemptionEvent:
%
%       1. first to simulate S1 at the first reset date;
%       2. then to simulate an independent NIG increment from year 1 to year 2.
%
%   Events:
%
%       ER1      = {S1 < strike}
%       ER2      = {S1 >= strike, S2 < strike}
%       Survival = {S1 >= strike, S2 >= strike}
%
%   INPUTS:
%   -------
%   product
%       Product struct enriched by prepareProductForPricing.
%
%   market
%       Market struct enriched by calibrateNts.
%
%   nSim
%       Number of Monte Carlo simulations. Default: 1e6.
%
%   rngSeed
%       Optional random seed.
%
%   OUTPUT:
%   -------
%   simulation
%       Struct containing simulated S1, S2, yearly early-redemption events
%       and the corresponding probabilities.

    %% Optional inputs

    if nargin < 3 || isempty(nSim)
        nSim = 1e6;
    end

    if nargin < 4
        rngSeed = [];
    end

    %% Basic checks

    if numel(product.partyB.resetDates) < 2
        error("The product must contain at least two Party B reset dates.");
    end

    %% Reset dates and times

    refDate = market.dateInfo.refDate;
    blackDayCount = market.dateInfo.blackDayCount;

    resetDate1 = product.partyB.resetDates(1);
    resetDate2 = product.partyB.resetDates(2);

    resetTime1 = yearfrac(refDate, resetDate1, blackDayCount);
    resetTime2 = yearfrac(refDate, resetDate2, blackDayCount);

    if resetTime2 <= resetTime1
        error("The second reset time must be greater than the first reset time.");
    end

    %% Forward levels at year 1 and year 2

    discount1 = getDiscountFactorByZeroRatesLinearInterp( ...
        refDate, ...
        resetDate1, ...
        market.dates, ...
        market.discounts);

    discount2 = getDiscountFactorByZeroRatesLinearInterp( ...
        refDate, ...
        resetDate2, ...
        market.dates, ...
        market.discounts);

    forward1 = market.equity.spot ...
        * exp(-market.equity.dividendYield * resetTime1) ...
        / discount1;

    forward2 = market.equity.spot ...
        * exp(-market.equity.dividendYield * resetTime2) ...
        / discount2;

    %% Simulate S1 using the existing one-year early-redemption function

    marketYear1 = market;

    marketYear1.nts.forward = forward1;
    marketYear1.nts.calibrationTime = resetTime1;
    marketYear1.nts.calibrationDate = resetDate1;

    simulationYear1 = simulateEarlyRedemptionEvent( ...
        product, ...
        marketYear1, ...
        nSim, ...
        rngSeed);

    S1 = simulationYear1.St;

    %% Simulate independent increment from T1 to T2
    %
    % simulateEarlyRedemptionEvent internally calls simulateNig.
    %
    % If we set marketIncrement.nts.forward = 1, the simulated St is:
    %
    %       incrementFactor12 = exp(X_{T2} - X_{T1})
    %
    % Then:
    %
    %       S2 = F(0,T2) * (S1 / F(0,T1)) * incrementFactor12

    marketIncrement = market;

    marketIncrement.nts.forward = 1.0;
    marketIncrement.nts.calibrationTime = resetTime2 - resetTime1;
    marketIncrement.nts.calibrationDate = resetDate2;

    if isempty(rngSeed)
        incrementSeed = [];
    else
        incrementSeed = rngSeed + 1;
    end

    simulationIncrement = simulateEarlyRedemptionEvent( ...
        product, ...
        marketIncrement, ...
        nSim, ...
        incrementSeed);

    incrementFactor12 = simulationIncrement.St;

    S2 = forward2 .* (S1 ./ forward1) .* incrementFactor12;

    %% Early-redemption events

    belowStrike1 = S1 < product.underlying.strike;
    belowStrike2 = S2 < product.underlying.strike;

    coupon1Rate = product.partyB.coupons.year1.rate .* belowStrike1;
    coupon2Rate = product.partyB.coupons.year1.rate .* belowStrike2;

    earlyRedeemedYear1 = coupon1Rate >= product.earlyRedemption.triggerLevel;

    aliveAfterYear1 = ~earlyRedeemedYear1;

    earlyRedeemedYear2 = aliveAfterYear1 ...
        & (coupon2Rate >= product.earlyRedemption.triggerLevel);

    survivalToFinal = aliveAfterYear1 & ~earlyRedeemedYear2;

    %% Output

    simulation = struct();

    simulation.nSim = nSim;

    simulation.resetDate1 = resetDate1;
    simulation.resetDate2 = resetDate2;

    simulation.resetTime1 = resetTime1;
    simulation.resetTime2 = resetTime2;

    simulation.forward1 = forward1;
    simulation.forward2 = forward2;

    simulation.S1 = S1;
    simulation.S2 = S2;

    simulation.incrementFactor12 = incrementFactor12;

    simulation.belowStrike1 = belowStrike1;
    simulation.belowStrike2 = belowStrike2;

    simulation.coupon1Rate = coupon1Rate;
    simulation.coupon2Rate = coupon2Rate;

    simulation.earlyRedeemedYear1 = earlyRedeemedYear1;
    simulation.aliveAfterYear1 = aliveAfterYear1;

    simulation.earlyRedeemedYear2 = earlyRedeemedYear2;
    simulation.survivalToFinal = survivalToFinal;

    simulation.probabilityBelowStrikeYear1 = mean(belowStrike1);
    simulation.probabilityBelowStrikeYear2 = mean(belowStrike2);

    simulation.probabilityEarlyRedemptionYear1 = mean(earlyRedeemedYear1);
    simulation.probabilityEarlyRedemptionYear2 = mean(earlyRedeemedYear2);
    simulation.probabilitySurvivalToFinal = mean(survivalToFinal);

    if 1 - simulation.probabilityEarlyRedemptionYear1 > 0
        simulation.probabilityEarlyRedemptionYear2ConditionalOnNoER1 = ...
            simulation.probabilityEarlyRedemptionYear2 ...
            / (1 - simulation.probabilityEarlyRedemptionYear1);
    else
        simulation.probabilityEarlyRedemptionYear2ConditionalOnNoER1 = NaN;
    end

    % Compatibility fields with the original one-date simulation.
    simulation.St = S1;
    simulation.belowStrike = belowStrike1;
    simulation.coupon1RateOriginal = coupon1Rate;
    simulation.earlyRedeemed = earlyRedeemedYear1;
    simulation.probabilityBelowStrike = simulation.probabilityBelowStrikeYear1;
    simulation.probabilityEarlyRedemption = simulation.probabilityEarlyRedemptionYear1;

end