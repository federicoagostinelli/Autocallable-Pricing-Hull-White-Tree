function [market, productContract] = extendMarketAndProductToThreeYears(market, productContract)
%EXTENDMARKETANDPRODUCTTOTHREEYEARS Extend Assignment 6 market/product to 3Y.
%
%   [market, productContract] =
%       EXTENDMARKETANDPRODUCTTOTHREEYEARS(market, productContract)
%
%   extends the original Assignment 6 setup from 2 years to 3 years, for
%   Exercise 1.d.
%
%   The function updates:
%
%       1. productContract
%          - maturityYears = 3
%          - endDate adjusted with Modified Following / market convention
%          - productType = "ModifiedThreeYear"
%          - Party B coupon structure:
%               year 1: 6%
%               year 2: 6% through the modified leg pricer
%               year 3: 2%
%
%       2. market.tenor
%          - quarterly Euribor 3M tenor grid extended to 3 years
%          - discount factors interpolated from the original market curve
%          - ACT/365 model times
%          - ACT/360 accrual factors
%          - forward rates
%          - forward zero-coupon bonds
%
%   INPUTS
%   ------
%   market
%       Market struct returned by initializeMarket.
%
%   productContract
%       Product contract struct returned by initializeProduct.
%
%   OUTPUTS
%   -------
%   market
%       Market struct with market.tenor extended to 3 years.
%
%   productContract
%       Product contract struct updated for the modified 3Y product.
%
%   IMPORTANT
%   ---------
%   Call this function before:
%
%       product = prepareProductForPricing(productContract, market);
%
%   because prepareProductForPricing needs market.tenor.dates long enough
%   to cover the full product maturity.

    %% Basic checks

    requiredMarketFields = ["dateInfo", "dates", "discounts", "tenor"];

    for iField = 1:numel(requiredMarketFields)
        fieldName = requiredMarketFields(iField);

        if ~isfield(market, fieldName)
            error("market.%s is missing.", fieldName);
        end
    end

    if ~isfield(market.dateInfo, "refDate")
        error("market.dateInfo.refDate is missing.");
    end

    if ~isfield(market.dateInfo, "paymentAdjust")
        market.dateInfo.paymentAdjust = 'modifiedfollowing';
    end

    if ~isfield(market.dateInfo, "dayCount")
        market.dateInfo.dayCount = 2; % ACT/360
    end

    if ~isfield(market.dateInfo, "blackDayCount")
        market.dateInfo.blackDayCount = 3; % ACT/365
    end

    if ~isfield(market.tenor, "tenorMonths")
        market.tenor.tenorMonths = 3;
    end

    if ~isfield(market.tenor, "paymentsPerYear")
        market.tenor.paymentsPerYear = 12 / market.tenor.tenorMonths;
    end

    %% Extend product contract to 3 years

    productContract.maturityYears = 3;

    productContract.endDate = businessDateOffsetTarget( ...
        market.dateInfo.refDate, ...
        productContract.maturityYears, ...
        0, ...
        0, ...
        market.dateInfo.paymentAdjust ...
    );

    % Exercise 1.d modified product flag.
    productContract.productType = "ModifiedThreeYear";

    % Point c / 1.d payoff structure:
    % Year 1: 6% if below strike.
    % Year 2: same 6% payoff if still alive.
    % Year 3: final 2% if still alive.
    productContract.partyB.coupons.year1.rate = 0.06;
    productContract.partyB.coupons.final.rate = 0.02;

    % If the 6% coupon is paid, early redemption is triggered.
    productContract.earlyRedemption.triggerLevel = 0.06;

    %% Extend market tenor grid to 3 years

    nYears = productContract.maturityYears;
    nPeriods = nYears * market.tenor.paymentsPerYear;

    market.tenor.dates = arrayfun( ...
        @(k) businessDateOffsetTarget( ...
            market.dateInfo.refDate, ...
            0, ...
            k * market.tenor.tenorMonths, ...
            0, ...
            market.dateInfo.paymentAdjust), ...
        0:nPeriods);

    market.tenor.discounts = arrayfun( ...
        @(d) getDiscountFactorByZeroRatesLinearInterp( ...
            market.dateInfo.refDate, ...
            d, ...
            market.dates, ...
            market.discounts), ...
        market.tenor.dates);

    market.tenor.times = yearfrac( ...
        market.dateInfo.refDate, ...
        market.tenor.dates, ...
        market.dateInfo.blackDayCount);

    market.tenor.dt = yearfrac( ...
        market.tenor.dates(1:end-1), ...
        market.tenor.dates(2:end), ...
        market.dateInfo.blackDayCount);

    market.tenor.delta = yearfrac( ...
        market.tenor.dates(1:end-1), ...
        market.tenor.dates(2:end), ...
        market.dateInfo.dayCount);

    market.tenor.resetTimes = yearfrac( ...
        market.dateInfo.refDate, ...
        market.tenor.dates(1:end-1), ...
        market.dateInfo.blackDayCount);

    market.tenor.forwardRates = ...
        (market.tenor.discounts(1:end-1) ./ market.tenor.discounts(2:end) - 1) ...
        ./ market.tenor.delta;

    market.tenor.forwardZCB = ...
        market.tenor.discounts(2:end) ./ market.tenor.discounts(1:end-1);

end