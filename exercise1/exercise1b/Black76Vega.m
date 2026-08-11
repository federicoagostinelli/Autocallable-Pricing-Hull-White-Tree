function Vega = Black76Vega(F, K, B, sigma, T)
% BLACK76VEGA Computes only the Vega sensitivity of a European option
% using the Black (1976) model for forwards.
%
% INPUTS:
%   F:     The forward price of the underlying asset
%   K:     The strike price of the option
%   B:     The discount factor from maturity to today B(t0, t)
%   sigma: The annualized implied volatility
%   T:     The time to maturity in years (Act/365)
%
% OUTPUTS:
%   Vega:  The calculated Vega sensitivity

% Compute d1 for the Black 76 model
d1 = (log(F ./ K) + 0.5 * sigma.^2 .* T) ./ (sigma .* sqrt(T));

% Compute the PDF for d1
Nd1 = (1 / sqrt(2 * pi)) * exp(-0.5 * d1.^2);

% Calculate Vega
Vega = B .* F .* sqrt(T) .* Nd1;

end