function simulation = simulateEarlyRedemptionEventBlack(product, market, pricingMode)
%SIMULATEEARLYREDEMPTIONEVENTBLACK Compute early-redemption probability with Black.
%
%   simulation = SIMULATEEARLYREDEMPTIONEVENTBLACK(product, market)
%   computes the early-redemption probability of the base Assignment 6
%   product using a Black forward model.
%
%   simulation = SIMULATEEARLYREDEMPTIONEVENTBLACK(product, market, pricingMode)
%   allows selecting:
%
%       pricingMode = "Black"
%           Pure Black digital probability.
%
%       pricingMode = "BlackCorrected"
%           Black digital probability corrected using the slope of the
%           implied volatility smile.
%
%   The early-redemption event is:
%
%       S(T_reset) < Strike.
%
%   Therefore the relevant payoff is a digital put.
%
%   INPUTS
%   ------
%   product
%       Product struct enriched by prepareProductForPricing.
%
%   market
%       Market struct containing equity smile data and the discount curve.
%
%   pricingMode
%       Optional string:
%           "Black"
%           "BlackCorrected"
%
%   OUTPUT
%   ------
%   simulation
%       Struct compatible with priceLegA, priceLegB and computeUpfront.

    %% Optional input

    if nargin < 3 || isempty(pricingMode)
        pricingMode = "Black";
    end

    pricingMode = string(pricingMode);

    %% Reset date and reset time

    refDate = market.dateInfo.refDate;

    resetDate = product.partyB.resetDates(1);

    resetTime = yearfrac( ...
        refDate, ...
        resetDate, ...
        market.dateInfo.blackDayCount ...
    );

    %% Discount factor and equity forward

    discountFactor = getDiscountFactorByZeroRatesLinearInterp( ...
        refDate, ...
        resetDate, ...
        market.dates, ...
        market.discounts ...
    );

    spot = market.equity.spot;
    dividendYield = market.equity.dividendYield;

    forward = spot ...
        * exp(-dividendYield * resetTime) ...
        / discountFactor;

    %% Implied volatility at strike

    strike = product.underlying.strike;

    strikes = market.equity.strikes(:);
    volSmile = market.equity.volSmile(:);

    impliedVolatility = interp1( ...
        strikes, ...
        volSmile, ...
        strike, ...
        'spline', ...
        'extrap' ...
    );

    %% Pure Black digital put probability

    d2 = ( ...
        log(forward / strike) ...
        - 0.5 * impliedVolatility^2 * resetTime ...
    ) / (impliedVolatility * sqrt(resetTime));

    blackProbabilityBelowStrike = normcdf(-d2);

    %% Smile correction

    smileSlope = NaN;
    vega = NaN;
    correctionPrice = 0.0;
    correctionProbability = 0.0;

    if pricingMode == "BlackCorrected"

        epsilon = 1e-3;

        volUp = interp1( ...
            strikes, ...
            volSmile, ...
            strike + epsilon, ...
            'spline', ...
            'extrap' ...
        );

        volDown = interp1( ...
            strikes, ...
            volSmile, ...
            strike - epsilon, ...
            'spline', ...
            'extrap' ...
        );

        smileSlope = (volUp - volDown) / (2 * epsilon);

        vega = Black76Vega( ...
            forward, ...
            strike, ...
            discountFactor, ...
            impliedVolatility, ...
            resetTime ...
        );

        % Digital put correction:
        %
        %   DigitalPut_corrected =
        %       DigitalPut_Black + Vega * dSigma/dK

        correctionPrice = vega * smileSlope;

        correctionProbability = correctionPrice / discountFactor;

    elseif pricingMode ~= "Black"

        error("pricingMode must be either 'Black' or 'BlackCorrected'.");

    end

    correctedProbabilityBelowStrike = ...
        blackProbabilityBelowStrike + correctionProbability;

    correctedProbabilityBelowStrike = min( ...
        max(correctedProbabilityBelowStrike, 0.0), ...
        1.0 ...
    );

    %% Early redemption probability

    probabilityBelowStrike = correctedProbabilityBelowStrike;

    probabilityEarlyRedemption = probabilityBelowStrike;

    expectedCoupon1Rate = ...
        product.partyB.coupons.year1.rate ...
        * probabilityBelowStrike;

    %% Output compatible with original pipeline

    simulation = struct();

    simulation.modelName = pricingMode;
    simulation.nSim = 0;

    simulation.resetDate = resetDate;
    simulation.resetTime = resetTime;

    simulation.forward = forward;
    simulation.discountFactor = discountFactor;

    simulation.strike = strike;
    simulation.impliedVolatility = impliedVolatility;

    simulation.d2 = d2;

    simulation.blackProbabilityBelowStrike = blackProbabilityBelowStrike;
    simulation.correctionPrice = correctionPrice;
    simulation.correctionProbability = correctionProbability;
    simulation.correctedProbabilityBelowStrike = correctedProbabilityBelowStrike;

    simulation.smileSlope = smileSlope;
    simulation.vega = vega;

    simulation.probabilityBelowStrike = probabilityBelowStrike;
    simulation.probabilityEarlyRedemption = probabilityEarlyRedemption;

    simulation.expectedCoupon1Rate = expectedCoupon1Rate;

    %% Compatibility fields with Monte Carlo simulation

    simulation.St = [];
    simulation.belowStrike = [];
    simulation.coupon1Rate = [];
    simulation.earlyRedeemed = [];

end