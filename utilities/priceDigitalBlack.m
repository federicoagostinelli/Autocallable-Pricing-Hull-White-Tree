function price = priceDigitalBlack(F0, K, sigma, T, discount, digital_payoff)
% PRICEDIGITALBLACK Prices a cash-or-nothing digital call option
% using the Black (1976) model.
%
% INPUTS:
%   F0             : forward price at t0 for maturity T         [scalar]
%   K              : strike price of the digital option         [scalar]
%   sigma          : implied volatility (flat, ATM)             [scalar]
%   T              : time to maturity in years (Act/365)        [scalar]
%   B              : discount factor B(t0, t)                   [scalar]
%   digital_payoff : cash payoff amount = Notional * coupon     [scalar]
%                   
%
% OUTPUTS:
%   price          : price of the digital call option in EUR    [scalar]
%

  
d2 = (log(F0/K) - 0.5 * sigma^2 * T) / (sigma * sqrt(T));

dc = discount * normcdf(d2);

price = dc * digital_payoff;

end