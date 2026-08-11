function resultsTable = printCalibrationReport(modelName, alphaValue, sigmaOpt, kappaOpt, etaOpt, objValue, ...
    strikes, logMoneyness, marketVols, modelVols, callMarket, callModel, idxPrint)
%PRINTCALIBRATIONREPORT Print option model calibration results.
%
%   resultsTable = PRINTCALIBRATIONREPORT(modelName, alphaValue, sigmaOpt,
%       kappaOpt, etaOpt, objValue, strikes, logMoneyness, marketVols,
%       modelVols, callMarket, callModel, idxPrint)
%
%   prints calibrated model parameters, the final objective value, and a
%   table comparing market and model quantities at each strike.
%
%   The function is model-agnostic and can be used, for example, for:
%
%       modelName = "NIG"
%       modelName = "VG"
%       modelName = "NTS"
%
%   INPUTS:
%   -------
%   modelName
%       Name of the calibrated model.
%
%   alphaValue
%       Model alpha parameter.
%
%       For NIG:
%           alphaValue = 1/2.
%
%       For VG:
%           alphaValue = 0.
%
%       For generic NTS:
%           alphaValue is the chosen NTS alpha.
%
%   sigmaOpt
%       Calibrated sigma.
%
%   kappaOpt
%       Calibrated kappa.
%
%   etaOpt
%       Calibrated eta.
%
%   objValue
%       Final calibration objective value.
%
%   strikes
%       Option strikes.
%
%   logMoneyness
%       Log-moneyness values:
%
%           x = log(F0 / K).
%
%   marketVols
%       Market implied volatilities.
%
%   modelVols
%       Model implied volatilities.
%
%   callMarket
%       Market call prices.
%
%   callModel
%       Model call prices.
%
%   idxPrint
%       Optional indices of rows to print.
%
%   OUTPUT:
%   -------
%   resultsTable
%       Table containing strikes, log-moneyness, market/model implied
%       volatilities, market/model call prices, and pricing errors.

    %% Defensive formatting

    modelName = string(modelName);

    strikes = strikes(:);
    logMoneyness = logMoneyness(:);
    marketVols = marketVols(:);
    modelVols = modelVols(:);
    callMarket = callMarket(:);
    callModel = callModel(:);

    if nargin < 13 || isempty(idxPrint)
        idxPrint = 1:numel(strikes);
    end

    if numel(strikes) ~= numel(logMoneyness) || ...
            numel(strikes) ~= numel(marketVols) || ...
            numel(strikes) ~= numel(modelVols) || ...
            numel(strikes) ~= numel(callMarket) || ...
            numel(strikes) ~= numel(callModel)
        error("All market/model vectors must have the same length.");
    end

    %% Errors

    absError = abs(callModel - callMarket);

    relAbsError = NaN(size(absError));

    validMarketPrices = abs(callMarket) > 1e-14;

    relAbsError(validMarketPrices) = ...
        absError(validMarketPrices) ./ abs(callMarket(validMarketPrices));

    ivAbsError = abs(modelVols - marketVols);

    %% Output table

    resultsTable = table( ...
        strikes, ...
        logMoneyness, ...
        marketVols, ...
        modelVols, ...
        ivAbsError, ...
        callMarket, ...
        callModel, ...
        absError, ...
        relAbsError, ...
        'VariableNames', { ...
            'Strike', ...
            'LogMoneyness', ...
            'MarketIV', ...
            'ModelIV', ...
            'AbsIVError', ...
            'CallMarket', ...
            'CallModel', ...
            'AbsPriceError', ...
            'RelAbsPriceError'});

    %% Print report

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf(' %s CALIBRATION REPORT\n', upper(modelName));
    fprintf('============================================================\n');

    fprintf('model    = %s\n', modelName);
    fprintf('alpha    = %.8f\n', alphaValue);
    fprintf('sigma*   = %.8f\n', sigmaOpt);
    fprintf('kappa*   = %.8f\n', kappaOpt);
    fprintf('eta*     = %.8f\n', etaOpt);
    fprintf('objValue = %.12e\n', objValue);

    fprintf('\nCalibration table:\n');
    disp(resultsTable(idxPrint, :));

    fprintf('------------------------------------------------------------\n');
    fprintf('max |CallModel - CallMarket|       = %.6e\n', max(absError));
    fprintf('mean |CallModel - CallMarket|      = %.6e\n', mean(absError));

    fprintf('max relative price error           = %.6e\n', max(relAbsError, [], 'omitnan'));
    fprintf('mean relative price error          = %.6e\n', mean(relAbsError, 'omitnan'));

    fprintf('max |ModelIV - MarketIV|           = %.6e\n', max(ivAbsError));
    fprintf('mean |ModelIV - MarketIV|          = %.6e\n', mean(ivAbsError));

    %% Admissibility check

    if abs(kappaOpt * sigmaOpt^2) > 1e-14

        etaBoundValue = (1 - alphaValue) / (kappaOpt * sigmaOpt^2);

        fprintf('eta admissibility bound            = %.6f\n', etaBoundValue);
        fprintf('eta / bound                        = %.6f\n', etaOpt / etaBoundValue);

        if etaOpt < etaBoundValue
            fprintf('eta admissibility check            = PASSED\n');
        else
            fprintf('eta admissibility check            = WARNING\n');
        end

    else

        fprintf('eta admissibility bound            = not available\n');
        fprintf('eta admissibility check            = not available\n');

    end

    fprintf('============================================================\n\n');

end