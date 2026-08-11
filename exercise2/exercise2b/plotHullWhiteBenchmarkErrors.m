function plotHullWhiteBenchmarkErrors(comparison)
%PLOTHULLWHITEBENCHMARKERRORS Plot ZCB and European swaption pricing errors.
%
%   plotHullWhiteBenchmarkErrors(comparison) plots:
%
%       1. ZCB tree-vs-market pricing errors.
%       2. European swaption tree-vs-analytic pricing errors.
%
%   INPUT:
%   ------
%   comparison
%       Output struct returned by compareHullWhiteTreeBenchmarks.
%
%       Required fields:
%
%           comparison.zcb
%               Table with variables:
%                   Maturity
%                   TreePrice
%                   MarketPrice
%                   AbsError
%                   RelError
%
%           comparison.europeanSwaption
%               Either:
%                   - struct with fields expiry, treePrice, analyticPrice,
%                     absError, relError;
%                   - struct array with the same fields;
%                   - table with variables Expiry, TreePrice, AnalyticPrice,
%                     AbsError, RelError.

    %% ================================================================
    %  1. ZCB errors
    % ================================================================

    if ~isfield(comparison, "zcb")
        error("comparison.zcb is missing.");
    end

    zcbTable = comparison.zcb;

    figure;

    plot(zcbTable.Maturity, zcbTable.AbsError, '-o', 'LineWidth', 1.5);
    grid on;

    xlabel("ZCB maturity");
    ylabel("Tree price - market price");
    title("Hull-White Tree Validation: ZCB Absolute Error");

    figure;

    plot(zcbTable.Maturity, zcbTable.RelError, '-o', 'LineWidth', 1.5);
    grid on;

    xlabel("ZCB maturity");
    ylabel("Relative error");
    title("Hull-White Tree Validation: ZCB Relative Error");

    %% ================================================================
    %  2. European swaption errors
    % ================================================================

    if ~isfield(comparison, "europeanSwaption")
        warning("comparison.europeanSwaption is missing. Only ZCB plots were produced.");
        return;
    end

    euro = comparison.europeanSwaption;

    if istable(euro)

        expiry = euro.Expiry;
        absError = euro.AbsError;
        relError = euro.RelError;

    elseif isstruct(euro) && numel(euro) > 1

        expiry = arrayfun(@(s) s.expiry, euro).';
        absError = arrayfun(@(s) s.absError, euro).';
        relError = arrayfun(@(s) s.relError, euro).';

    elseif isstruct(euro)

        expiry = euro.expiry;
        absError = euro.absError;
        relError = euro.relError;

    else

        error("Unsupported format for comparison.europeanSwaption.");

    end

    figure;

    plot(expiry, absError, '-o', 'LineWidth', 1.5);
    grid on;

    xlabel("European swaption expiry");
    ylabel("Tree price - analytic price");
    title("Hull-White Tree Validation: European Swaption Absolute Error");

    figure;

    plot(expiry, relError, '-o', 'LineWidth', 1.5);
    grid on;

    xlabel("European swaption expiry");
    ylabel("Relative error");
    title("Hull-White Tree Validation: European Swaption Relative Error");

end