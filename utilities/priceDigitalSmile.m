function price = priceDigitalSmile(F0, K, strikes, sigma_mkt, T, B, digital_payoff)
% PRICEDIGITALSMILE Prices a cash-or-nothing digital call option
% accounting for the implied volatility smile.
%
% The digital is priced as the limit of a bull spread (call spread),
% using plain vanilla calls whose prices are consistent with the
% implied volatility smile sigma(K):
%
%   dc(K) = lim_{eps->0} [c(K,sigma(K)) - c(K+eps,sigma(K+eps))] / eps
%         = -d/dK * c[K, sigma(K)]
%
% Applying the chain rule (total derivative w.r.t. K):
%
%   dc_smile(K) = -d/dK * c[K, sigma(K)]
%               = [-dc/dK]_Black  -  [dsigma/dK] * [dc/dsigma]
%               = dc_Black(K)     -  [dsigma/dK] * Vega
%
% The term [dsigma/dK] is the slope of the implied vol smile,
% estimated numerically via central finite differences.
% The Vega of the Black call is:
%
%   Vega = B * F0 * n(d1) * sqrt(T)
%
% where n(.) is the standard normal PDF.
%
% -------------------------------------------------------------------------
% INPUTS:
%   F0             : forward price at t0 for maturity T         [scalar]
%   K              : strike price of the digital option         [scalar]
%   strikes        : vector of market strikes                   [Nx1 double]
%   sigma_mkt      : vector of market implied volatilities      [Nx1 double]
%                    (must correspond to strikes, same order)
%   T              : time to maturity in years (Act/365)        [scalar]
%   B              : discount factor B(t0, t)                   [scalar]
%   digital_payoff : cash payoff amount = Notional * coupon     [scalar]
%                    (e.g. 10e6 * 0.05 = 500,000 EUR)
%
% OUTPUTS:
%   price          : smile-adjusted price of the digital call   [scalar]
%                    option in EUR
%

sigma_K = interp1(strikes, sigma_mkt, K, 'spline');

d2 = (log(F0/K) - 0.5 * sigma_K^2 * T) / (sigma_K * sqrt(T));
dc_black = B * normcdf(d2);

%slope impact: dsigma/dK via central finite differences   
epsilon = 1;  % 1 index point perturbation
sigma_Kplus  = interp1(strikes, sigma_mkt, K + epsilon, 'spline');
sigma_Kminus = interp1(strikes, sigma_mkt, K - epsilon, 'spline');
dSigma_dK = (sigma_Kplus - sigma_Kminus) / (2 * epsilon);

%Vega of the black call   
d1 = (log(F0/K) + 0.5 * sigma_K^2 * T) / (sigma_K * sqrt(T));
vega = B * F0 * normpdf(d1) * sqrt(T);

   
dc_smile = dc_black - dSigma_dK * vega;

   
price = dc_smile * digital_payoff;

end