function zcb = computeHullWhiteZCBFromState(xt, a, sigma, t, T, P0t, P0T)
%COMPUTEHULLWHITEZCBFROMSTATE Compute exact Hull-White ZCB B(t,T).
%
%   zcb = computeHullWhiteZCBFromState(xt, a, sigma, t, T, P0t, P0T)
%
%   computes the exact conditional zero-coupon bond value:
%
%       B(t,T,x_t)
%
%   under the one-factor Hull-White model:
%
%       r(t) = phi(t) + x(t),
%
%   where x(t) is the zero-mean OU process.
%
%   The formula is:
%
%       B(t,T)
%       =
%       P(0,T) / P(0,t)
%       *
%       exp {
%           - x_t * B_HW(t,T)
%           - 1/2 * I(t,T)
%       }
%
%   where:
%
%       B_HW(t,T) = (1 - exp(-a(T-t))) / a
%
%   and:
%
%       I(t,T)
%       =
%       integral_0^t
%       [
%           sigma(u,T)^2 - sigma(u,t)^2
%       ] du.
%
%   No stochastic-discount approximation is used.

    %% Defensive checks

    if T <= t
        error("Maturity T must be strictly greater than current time t.");
    end

    if P0t <= 0 || P0T <= 0
        error("P0t and P0T must be strictly positive discount factors.");
    end

    %% Market forward ZCB

    marketForwardZCB = P0T / P0t;

    %% Hull-White loading of x(t)

    tau = T - t;

    BHW = (1 - exp(-a * tau)) / a;

    %% Exact variance adjustment integral
    %
    % I(t,T)
    % =
    % sigma^2 / a^3 *
    % [
    %   2(1 - exp(-a t))(1 - exp(-a tau))
    %   - 1/2(1 - exp(-2a t))(1 - exp(-2a tau))
    % ]

    varianceIntegral = (sigma^2 / a^3) * ( ...
        2.0 * (1.0 - exp(-a * t)) * (1.0 - exp(-a * tau)) ...
        - 0.5 * (1.0 - exp(-2.0 * a * t)) * ...
                (1.0 - exp(-2.0 * a * tau)) ...
    );

    

    %% Conditional ZCB

    zcb = marketForwardZCB .* exp( ...
        -xt .* BHW ...
        -0.5 * varianceIntegral ...
    );

end