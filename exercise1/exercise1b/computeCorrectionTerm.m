function [correctionTerm, details] = computeCorrectionTerm(mktData, dfMat, refDate, matDate)
% computeCorrectionTerm Computes the smile adjustment term for a digital
% option using implied volatility slope and Black vega.
%
% INPUTS:
%   mktData         : Struct containing market data.
%   dfMat           : Discount factor at maturity.
%   refDate         : Valuation date.
%   matDate         : Maturity date.
%
% OUTPUTS:
%   correctionTerm  : Smile correction term.
%   details         : Struct containing relevant intermediate quantities.

% Compute time to maturity
timeToMaturity = yearfrac(refDate, matDate, 3);

% Compute forward, ATM volatility, and local slope
[forward, sigmaAtm, slope] = computeSlopeCorrectiveTerm(mktData, dfMat, refDate, matDate);

% Compute Black vega at ATM forward
vega = Black76Vega(forward, forward, dfMat, sigmaAtm, timeToMaturity);

% Compute correction term
correctionTerm = slope * vega;

% Store report details
details = struct();
details.slope = slope;
details.vega = vega;

end