function plotVolSmile(modelName, logMoneyness, marketVols, modelVols, timeToMaturity)
%PLOTVOLSMILE Plot market and calibrated model implied volatility smiles.
%
%   PLOTVOLSMILE(modelName, logMoneyness, marketVols, modelVols,
%       timeToMaturity)
%
%   creates a plot comparing market implied volatilities and model implied
%   volatilities from the calibrated model.
%
%   INPUTS:
%   -------
%   modelName
%       Name of the calibrated model, for example:
%
%           "NIG"
%           "VG"
%           "NTS"
%
%   logMoneyness
%       Log-moneyness values:
%
%           x = log(F0 / K).
%
%   marketVols
%       Market implied volatilities in decimal form.
%
%   modelVols
%       Model implied volatilities in decimal form.
%
%   timeToMaturity
%       Time to maturity in years.
%
%   OUTPUT:
%   -------
%   none. The function creates a figure.

    %% Defensive formatting

    modelName = string(modelName);

    logMoneyness = logMoneyness(:);
    marketVols = marketVols(:);
    modelVols = modelVols(:);

    if numel(logMoneyness) ~= numel(marketVols) || ...
            numel(logMoneyness) ~= numel(modelVols)
        error("logMoneyness, marketVols and modelVols must have the same length.");
    end

    %% Sort by log-moneyness

    [logMoneynessSorted, sortIdx] = sort(logMoneyness);

    marketVolsSorted = marketVols(sortIdx);
    modelVolsSorted = modelVols(sortIdx);

    %% Plot

    figure('Color', 'white', 'Position', [100, 100, 850, 500]);

    ax = gca;
    hold(ax, 'on');

    marketHandle = plot(ax, logMoneynessSorted, marketVolsSorted * 100, ...
        '-o', ...
        'Color', [0.2, 0.47, 0.72], ...
        'LineWidth', 2, ...
        'MarkerFaceColor', [0.2, 0.47, 0.72], ...
        'MarkerSize', 7, ...
        'DisplayName', 'Market IV');

    modelHandle = plot(ax, logMoneynessSorted, modelVolsSorted * 100, ...
        '--s', ...
        'Color', [0.85, 0.33, 0.10], ...
        'LineWidth', 2, ...
        'MarkerFaceColor', [0.85, 0.33, 0.10], ...
        'MarkerSize', 7, ...
        'DisplayName', sprintf('%s IV', modelName));

    xline(0, ':', ...
        'Color', [0.5, 0.5, 0.5], ...
        'LineWidth', 1.2, ...
        'Label', 'ATM', ...
        'LabelVerticalAlignment', 'bottom', ...
        'FontSize', 9);

    xlabel(ax, 'Log-Moneyness  log(F_0/K)', ...
        'FontSize', 12, ...
        'FontWeight', 'normal');

    ylabel(ax, 'Implied Volatility (%)', ...
        'FontSize', 12, ...
        'FontWeight', 'normal');

    title(ax, sprintf('%s Calibration Smile, T = %.4f', modelName, timeToMaturity), ...
        'FontSize', 14, ...
        'FontWeight', 'bold');

    ax.FontSize = 11;
    ax.Box = 'on';
    ax.GridAlpha = 0.25;
    ax.GridLineStyle = ':';
    ax.XMinorGrid = 'off';
    ax.YMinorGrid = 'off';
    ax.TickDir = 'out';

    grid(ax, 'on');

    legend([marketHandle, modelHandle], ...
        'Location', 'best', ...
        'FontSize', 11, ...
        'Box', 'on');

    allVols = [marketVolsSorted(:); modelVolsSorted(:)];

    xRange = range(logMoneynessSorted);
    yRange = range(allVols * 100);

    if xRange == 0
        xRange = 1;
    end

    if yRange == 0
        yRange = 1;
    end

    xPad = 0.05 * xRange;
    yPad = 0.05 * yRange;

    xlim([min(logMoneynessSorted) - xPad, max(logMoneynessSorted) + xPad]);
    ylim([min(allVols) * 100 - yPad, max(allVols) * 100 + yPad]);

    hold(ax, 'off');

end