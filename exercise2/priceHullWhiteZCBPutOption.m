function putPrice = priceHullWhiteZCBPutOption(a, sigma, expiryTime, maturityTime, strike, ...
    discountExpiry, discountMaturity)
%PRICEHULLWHITEZCBPUTOPTION Price a European put option on a ZCB under Hull-White.
%
%   putPrice = PRICEHULLWHITEZCBPUTOPTION(a, sigma, expiryTime, maturityTime, ...
%       strike, discountExpiry, discountMaturity)
%
%   computes the time-zero price of a European put option written on a
%   zero-coupon bond under the one-factor Hull-White model.
%
%   The option payoff at expiry T is:
%
%       max(K - P(T,S), 0)
%
%   where:
%
%       T = expiryTime
%       S = maturityTime
%       K = strike
%
%   INPUTS:
%   -------
%   a
%       Hull-White mean-reversion parameter.
%
%   sigma
%       Hull-White volatility parameter.
%
%   expiryTime
%       Option expiry time T, in years.
%
%   maturityTime
%       Maturity time S of the underlying ZCB, in years.
%
%   strike
%       Strike K of the ZCB put option.
%
%   discountExpiry
%       Market discount factor P(0,T).
%
%   discountMaturity
%       Market discount factor P(0,S).
%
%   OUTPUT:
%   -------
%   putPrice
%       Time-zero price of the ZCB put option.
%
%   FORMULA:
%   --------
%   The Hull-White ZCB put price is:
%
%       Put = K P(0,T) N(-d2) - P(0,S) N(-d1)
%
%   with:
%
%       d1 = log(P(0,S) / (K P(0,T))) / sigmaP + 0.5 sigmaP
%       d2 = d1 - sigmaP
%
%   and:
%
%       sigmaP = sigma * B(T,S) * sqrt((1 - exp(-2aT)) / (2a))
%
%       B(T,S) = (1 - exp(-a(S - T))) / a
%
%   The implementation is vectorized and expands scalar inputs to the
%   common target size.

    %% Defensive formatting

    expiryTime = expiryTime(:);
    maturityTime = maturityTime(:);
    strike = strike(:);
    discountExpiry = discountExpiry(:);
    discountMaturity = discountMaturity(:);

    targetLength = max([ ...
        numel(expiryTime), ...
        numel(maturityTime), ...
        numel(strike), ...
        numel(discountExpiry), ...
        numel(discountMaturity) ...
    ]);

    if isscalar(expiryTime)
        expiryTime = expiryTime * ones(targetLength, 1);
    end

    if isscalar(maturityTime)
        maturityTime = maturityTime * ones(targetLength, 1);
    end

    if isscalar(strike)
        strike = strike * ones(targetLength, 1);
    end

    if isscalar(discountExpiry)
        discountExpiry = discountExpiry * ones(targetLength, 1);
    end

    if isscalar(discountMaturity)
        discountMaturity = discountMaturity * ones(targetLength, 1);
    end

    if numel(expiryTime) ~= targetLength || ...
            numel(maturityTime) ~= targetLength || ...
            numel(strike) ~= targetLength || ...
            numel(discountExpiry) ~= targetLength || ...
            numel(discountMaturity) ~= targetLength
        error("All non-scalar inputs must have compatible lengths.");
    end

    if any(maturityTime <= expiryTime)
        error("Each maturityTime must be strictly greater than expiryTime.");
    end

    %% Hull-White bond loading B(T,S)

    bondLoading = (1 - exp(-a .* (maturityTime - expiryTime))) ./ a;

    %% Hull-White bond option volatility sigmaP

    varianceTerm = (1 - exp(-2 .* a .* expiryTime)) ./ (2 .* a);

    bondVolatility = sigma .* bondLoading .* sqrt(varianceTerm);

    %% Price

    putPrice = zeros(targetLength, 1);

    smallVolatility = abs(bondVolatility) < 1e-14;

    putPrice(smallVolatility) = max( ...
        strike(smallVolatility) .* discountExpiry(smallVolatility) ...
        - discountMaturity(smallVolatility), ...
        0 ...
    );

    regular = ~smallVolatility;

    if any(regular)

        d1 = log( ...
            discountMaturity(regular) ./ ...
            (strike(regular) .* discountExpiry(regular)) ...
        ) ./ bondVolatility(regular) ...
        + 0.5 .* bondVolatility(regular);

        d2 = d1 - bondVolatility(regular);

        putPrice(regular) = ...
            strike(regular) .* discountExpiry(regular) .* normcdf(-d2) ...
            - discountMaturity(regular) .* normcdf(-d1);

    end

end