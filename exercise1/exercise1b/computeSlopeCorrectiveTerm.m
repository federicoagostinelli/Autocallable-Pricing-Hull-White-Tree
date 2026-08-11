function [forward, volAtm, slope] = computeSlopeCorrectiveTerm(mktData, dfMat, refDate, endDate)
% computeSlopeCorrectiveTerm Computes the derivative of implied volatility
% with respect to strike using cubic spline interpolation and a central
% difference approximation.
%
% INPUTS:
%   mktData   : Struct containing market data. It must include:
%               - mktData.cSelect.reference
%               - mktData.cSelect.dividends
%               - mktData.cSelect.strikes
%               - mktData.cSelect.surface
%   dfMat     : Discount factor from reference date to maturity date.
%   refDate   : Reference date.
%   endDate   : Maturity date.
%
% OUTPUTS:
%   forward   : Forward price used as ATM anchor.
%   volAtm    : Implied volatility at the ATM forward.
%   slope     : Numerical derivative dSigma/dK evaluated at the ATM forward.

% Extract market data
spot = mktData.cSelect.reference;
dividendYield = mktData.cSelect.dividends;
strikes = mktData.cSelect.strikes;
volSmile = mktData.cSelect.surface;

% Compute time to maturity
timeToMaturity = yearfrac(refDate, endDate, 3);

% Compute forward price
forward = spot * exp(-dividendYield * timeToMaturity) / dfMat;

% ATM strike
strikeAtm = forward;

% Finite difference step
epsilon = 1e-3;

% Interpolate volatility around the ATM strike
volAtm = interp1(strikes, volSmile, strikeAtm, 'spline');
volUp = interp1(strikes, volSmile, strikeAtm + epsilon, 'spline');
volDown = interp1(strikes, volSmile, strikeAtm - epsilon, 'spline');

% Central difference approximation
slope = (volUp - volDown) / (2 * epsilon);

end