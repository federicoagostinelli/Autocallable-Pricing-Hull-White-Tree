function price = priceEuropeanPayerSwaptionHullWhiteAnalytic( ...
    treeHullWhite, expiryTime, TFixed, deltaFixed, K, B0Expiry, B0Payments)
%PRICEEUROPEANPAYERSWAPTIONHULLWHITEANALYTIC Price European payer swaption.
%
%   price = PRICEEUROPEANPAYERSWAPTIONHULLWHITEANALYTIC(
%       treeHullWhite, expiryTime, TFixed, deltaFixed, K, B0Expiry, B0Payments)
%
%   prices a European payer swaption under the one-factor Hull-White model
%   using Jamshidian decomposition.
%
%   INPUTS:
%   -------
%   treeHullWhite
%       Hull-White tree struct with fields:
%           a
%           sigma
%
%   expiryTime
%       European swaption expiry S in ACT/365 years.
%
%   TFixed
%       Fixed-leg payment times T_i after the expiry.
%
%   deltaFixed
%       Fixed-leg accrual factors.
%
%   K
%       Fixed swap rate.
%
%   B0Expiry
%       Market discount factor P(0,S).
%
%   B0Payments
%       Market discount factors P(0,T_i).
%
%   OUTPUT:
%   -------
%   price
%       Analytical Hull-White European payer swaption price.
%
%   PAYOFF:
%   -------
%   At expiry S:
%
%       max(1 - P(S,T_n) - K * sum_i delta_i P(S,T_i), 0)
%
%   This is decomposed into bond puts through Jamshidian.

    %% Defensive formatting

    TFixed = TFixed(:);
    deltaFixed = deltaFixed(:);
    B0Payments = B0Payments(:);

    if numel(TFixed) ~= numel(deltaFixed) || numel(TFixed) ~= numel(B0Payments)
        error("TFixed, deltaFixed and B0Payments must have the same length.");
    end

    remainingIndex = TFixed > expiryTime + 1e-12;

    TFixed = TFixed(remainingIndex);
    deltaFixed = deltaFixed(remainingIndex);
    B0Payments = B0Payments(remainingIndex);

    if isempty(TFixed)
        price = 0;
        return;
    end

    %% Cash-flow coefficients

    nPayments = numel(TFixed);

    cashflowCoefficients = K * deltaFixed;
    cashflowCoefficients(end) = cashflowCoefficients(end) + 1;

    %% Find xStar such that:
    %
    %   sum_i c_i P(S,T_i;xStar) = 1

    rootFunction = @(x) sum( ...
        cashflowCoefficients .* hullWhiteZCBAtExpiryState( ...
            x, treeHullWhite, expiryTime, TFixed, B0Expiry, B0Payments) ...
    ) - 1;

    xLower = -1;
    xUpper = 1;

    while rootFunction(xLower) < 0
        xLower = 2 * xLower;
    end

    while rootFunction(xUpper) > 0
        xUpper = 2 * xUpper;
    end

    xStar = fzero(rootFunction, [xLower, xUpper]);

    %% Jamshidian strikes

    bondStrikes = hullWhiteZCBAtExpiryState( ...
        xStar, ...
        treeHullWhite, ...
        expiryTime, ...
        TFixed, ...
        B0Expiry, ...
        B0Payments ...
    );

    %% Sum bond puts

    price = 0;

    for i = 1:nPayments

        bondPut = hullWhiteBondPutPrice( ...
            treeHullWhite, ...
            expiryTime, ...
            TFixed(i), ...
            bondStrikes(i), ...
            B0Expiry, ...
            B0Payments(i) ...
        );

        price = price + cashflowCoefficients(i) * bondPut;

    end

end


function zcb = hullWhiteZCBAtExpiryState(x, treeHullWhite, S, T, B0S, B0T)
%HULLWHITEZCBATEXPIRYSTATE Compute P(S,T;x_S) under Hull-White.

    a = treeHullWhite.a;
    sigma = treeHullWhite.sigma;

    T = T(:);
    B0T = B0T(:);

    BHW = (1 - exp(-a * (T - S))) / a;

    varianceIntegral = hullWhiteForwardZCBVarianceIntegral(a, sigma, S, T);

    zcb = (B0T ./ B0S) .* exp( ...
        -x .* BHW ...
        -0.5 .* varianceIntegral ...
    );

end


function varianceIntegral = hullWhiteForwardZCBVarianceIntegral(a, sigma, t, T)
%HULLWHITEFORWARDZCBVARIANCEINTEGRAL Compute exact ZCB convexity term.
%
%   Computes:
%
%       integral_0^t [sigma(u,T)^2 - sigma(u,t)^2] du
%
%   where:
%
%       sigma(u,T) = sigma/a * (1 - exp(-a(T-u))).

    tau = T - t;

    varianceIntegral = (sigma^2 / a^3) .* ( ...
        1.5 ...
        - 2 .* exp(-a .* tau) ...
        + 0.5 .* exp(-2 .* a .* tau) ...
        + 2 .* exp(-a .* T) ...
        - 2 .* exp(-a .* t) ...
        - 0.5 .* exp(-2 .* a .* T) ...
        + 0.5 .* exp(-2 .* a .* t) ...
    );

end


function putPrice = hullWhiteBondPutPrice(treeHullWhite, S, T, X, B0S, B0T)
%HULLWHITEBONDPUTPRICE Price a put option on a ZCB under Hull-White.
%
%   Payoff at S:
%
%       max(X - P(S,T), 0)

    a = treeHullWhite.a;
    sigma = treeHullWhite.sigma;

    sigmaP = (sigma / a) * (1 - exp(-a * (T - S))) * ...
        sqrt((1 - exp(-2 * a * S)) / (2 * a));

    if sigmaP < 1e-14
        putPrice = max(X * B0S - B0T, 0);
        return;
    end

    h = log(B0T / (X * B0S)) / sigmaP + 0.5 * sigmaP;

    putPrice = X * B0S * normcdf(sigmaP - h) ...
        - B0T * normcdf(-h);

end