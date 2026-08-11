function plotImpliedVolatilitySmile(mktData, detailsCorr, dfMat, refDate, endDate)
% plotImpliedVolatilitySmile Generates a plot of the 1-year implied
% volatility smile, highlighting the ATM forward and its tangent line.
%
% INPUTS:
%   mktData      : Struct containing market data. It must include
%                  mktData.cSelect.strikes, mktData.cSelect.surface,
%                  mktData.cSelect.reference, and mktData.cSelect.dividends.
%   detailsCorr  : Struct containing smile correction details, including
%                  the field slope.
%   dfMat        : Discount factor from reference date to maturity date.
%   refDate      : Reference date.
%   endDate      : Maturity date.

% Extract market data
strikes = mktData.cSelect.strikes;
volSmile = mktData.cSelect.surface;
spot = mktData.cSelect.reference;
dividendYield = mktData.cSelect.dividends;

% Initialize figure
figure('Name', 'Implied Volatility Smile', 'Color', 'w');

% Plot volatility smile in percentage terms
plot(strikes, volSmile * 100, '-o', ...
    'LineWidth', 1.5, ...
    'MarkerSize', 5, ...
    'Color', [0 0.4470 0.7410]);
hold on;

% Compute time to maturity
timeToMaturity = yearfrac(refDate, endDate, 3);

% Compute forward price
forward = spot * exp(-dividendYield * timeToMaturity) / dfMat;

% Identify ATM forward point
[~, idxForward] = min(abs(strikes - forward));
volForward = volSmile(idxForward);

plot(forward, volForward * 100, 'ro', ...
    'MarkerSize', 8, ...
    'MarkerFaceColor', 'r');

% Compute tangent line using local slope
slopePct = detailsCorr.slope * 100;
tangentLine = volForward * 100 + slopePct * (strikes - forward);

plot(strikes, tangentLine, '--k', 'LineWidth', 1.2);

% Chart formatting
grid on;
title('Market Implied Volatility Smile (1-Year Expiry)', ...
    'FontSize', 14, 'FontWeight', 'bold');
xlabel('Strike Price (EUR)', ...
    'FontSize', 12, 'FontWeight', 'bold');
ylabel('Implied Volatility (%)', ...
    'FontSize', 12, 'FontWeight', 'bold');
legend('Implied Volatility Curve', ...
       'ATM Forward Anchor', ...
       'Local Tangent', ...
       'Location', 'best', ...
       'FontSize', 11);

hold off;

end