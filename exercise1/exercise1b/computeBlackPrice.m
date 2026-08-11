function [blackPrice, details] = computeBlackPrice(dfMat, mktData, refDate, matDate)
% computeBlackPrice Computes the price of a digital call option
% under the pure Black model, without smile correction.
%
% INPUTS:
%   dfMat      : Discount factor at maturity.
%   mktData    : Struct containing market data. It must include:
%                - mktData.cSelect.reference
%                - mktData.cSelect.dividends
%                - mktData.cSelect.strikes
%                - mktData.cSelect.surface
%   refDate    : Valuation date.
%   matDate    : Maturity date.
%
% OUTPUTS:
%   blackPrice : Digital option price assuming unit payoff.
%   details    : Struct containing relevant intermediate quantities.

% Compute time to maturity
timeToMaturity = yearfrac(refDate, matDate, 3);

% Extract market data
spot = mktData.cSelect.reference;
dividendYield = mktData.cSelect.dividends;
strikes = mktData.cSelect.strikes;
volSmile = mktData.cSelect.surface;

% Compute forward price
forward = spot * exp(-dividendYield * timeToMaturity) / dfMat;

% ATM strike
strikeAtm = forward;

% Interpolate ATM volatility
sigmaAtm = interp1(strikes, volSmile, strikeAtm, 'spline');

% Compute d2 in the Black model
d2 = (log(forward / strikeAtm) - 0.5 * sigmaAtm^2 * timeToMaturity) ...
    / (sigmaAtm * sqrt(timeToMaturity));

% Compute digital option price
blackPrice = dfMat * normcdf(d2);

% Store report details
details = struct();
details.timeToMaturity = timeToMaturity;
details.forward = forward;
details.sigmaAtm = sigmaAtm;

end