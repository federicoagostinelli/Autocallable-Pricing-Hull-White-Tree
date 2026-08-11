function discountFactors = getDiscountFactorsAtModelTimes(market, modelTimes)
%GETDISCOUNTFACTORSATMODELTIMES Get market discount factors at ACT/365 model times.
%
%   discountFactors = GETDISCOUNTFACTORSATMODELTIMES(market, modelTimes)
%   converts ACT/365 model times into artificial dates and interpolates
%   market zero rates using getDiscountFactorByZeroRatesLinearInterp.

    refDate = ensureDatetime(market.dateInfo.refDate);
    curveDates = ensureDatetime(market.dates);
    curveDiscounts = market.discounts;

    modelTimes = modelTimes(:);

    modelDates = refDate + days(365 * modelTimes);

    discountFactors = getDiscountFactorByZeroRatesLinearInterp( ...
        refDate, ...
        modelDates, ...
        curveDates, ...
        curveDiscounts ...
    );

end