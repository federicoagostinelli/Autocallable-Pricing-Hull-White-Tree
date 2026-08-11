function market = calibrateVG(market, product)
%CALIBRATEVG Calibrate the Variance Gamma model for Assignment 6.
%
%   market = CALIBRATEVG(market, product)
%
%   calibrates the Variance Gamma model to the EuroStoxx/Stoxx50 implied
%   volatility smile stored in:
%
%       market.equity.strikes
%       market.equity.volSmile
%
%   and stores all calibration inputs and outputs in:
%
%       market.vg
%
%   The VG model is obtained as the NTS special case with:
%
%       alpha = 0
%
%   The function is designed to be compatible with the generic:
%
%       printCalibrationReport
%       plotVolSmile

    %% Variance Gamma calibration setup

    market.vg = struct();

    market.vg.modelName = "VG";
    market.vg.alpha = 0;

    %% Calibration date, time and discount factor

    market.vg.calibrationDate = product.partyB.resetDates(1);
    market.vg.calibrationTime = product.partyB.resetTimes(1);

    discountFactorFromProduct = double(product.partyB.resetDiscounts(1));

    discountFactorFromCurve = getDiscountFactorByZeroRatesLinearInterp( ...
        market.dateInfo.refDate, ...
        market.vg.calibrationDate, ...
        market.dates, ...
        market.discounts);

    discountFactorFromCurve = double(discountFactorFromCurve);

    discountFactorTolerance = 1e-12;

    discountFactorAbsDiff = abs( ...
        discountFactorFromProduct - discountFactorFromCurve);

    if discountFactorAbsDiff > discountFactorTolerance
        error('calibrateVG:DiscountFactorMismatch', ...
            ['Discount factor mismatch at calibration date %s.\n' ...
             'From product: %.16f\n' ...
             'From curve  : %.16f\n' ...
             'Abs diff    : %.3e\n' ...
             'Tolerance   : %.3e'], ...
            datestr(market.vg.calibrationDate), ...
            discountFactorFromProduct, ...
            discountFactorFromCurve, ...
            discountFactorAbsDiff, ...
            discountFactorTolerance);
    end

    market.vg.discountFactor = discountFactorFromProduct;

    market.vg.discountFactorCheck = struct();
    market.vg.discountFactorCheck.fromProduct = discountFactorFromProduct;
    market.vg.discountFactorCheck.fromCurve = discountFactorFromCurve;
    market.vg.discountFactorCheck.absDiff = discountFactorAbsDiff;
    market.vg.discountFactorCheck.tolerance = discountFactorTolerance;
    market.vg.discountFactorCheck.passed = true;

    %% Equity forward at calibration maturity

    market.vg.forward = market.equity.spot ...
        * exp(-market.equity.dividendYield * market.vg.calibrationTime) ...
        / market.vg.discountFactor;

    %% Calibration parameters

    market.vg.penaltyValue = 1e12;

    % p = [sigma; kappa; eta]
    market.vg.params0 = [0.20; 1.00; 0.10];

    market.vg.optimOptions = optimset( ...
        'Display', 'off', ...
        'TolX', 1e-6, ...
        'TolFun', 1e-6, ...
        'MaxFunEvals', 5000, ...
        'MaxIter', 5000);

    %% Calibration settings

    alpha = market.vg.alpha;
    penaltyValue = market.vg.penaltyValue;
    params0 = market.vg.params0(:);
    options = market.vg.optimOptions;

    %% Market data

    strikes = market.equity.strikes(:);
    marketVols = market.equity.volSmile(:);
    spot = market.equity.spot;

    if ~isscalar(spot) || ~isfinite(spot) || spot <= 0
        error('calibrateVG:InvalidSpot', ...
            'market.equity.spot must be a positive finite scalar.');
    end

    dividendYield = market.equity.dividendYield;
    forward = double(market.vg.forward);
    dfMat = double(market.vg.discountFactor);
    timeToMaturity = double(market.vg.calibrationTime);

    if ~isscalar(forward) || ~isfinite(forward) || forward <= 0
        error('calibrateVG:InvalidForward', ...
            'The calibration forward must be a positive finite scalar.');
    end

    if ~isscalar(dfMat) || ~isfinite(dfMat) || dfMat <= 0
        error('calibrateVG:InvalidDiscountFactor', ...
            'The calibration discount factor must be a positive finite scalar.');
    end

    if ~isscalar(timeToMaturity) || ~isfinite(timeToMaturity) || timeToMaturity <= 0
        error('calibrateVG:InvalidTimeToMaturity', ...
            'The calibration time to maturity must be a positive finite scalar.');
    end

    if numel(strikes) ~= numel(marketVols)
        error('calibrateVG:InvalidSmileDimensions', ...
            'market.equity.strikes and market.equity.volSmile must have the same number of elements.');
    end

    %% Log-moneyness

    logMoneyness = log(forward ./ strikes);

    %% Market call prices from Black formula

    sqrtT = sqrt(timeToMaturity);

    volSqrtT = marketVols .* sqrtT;

    d1 = (logMoneyness + 0.5 .* marketVols.^2 .* timeToMaturity) ./ volSqrtT;
    d2 = d1 - volSqrtT;

    callMarket = dfMat .* (forward .* normcdf(d1) - strikes .* normcdf(d2));

    %% VG characteristic exponent

    charExpVg = @(u, sigma, kappa, eta) ...
        -(timeToMaturity ./ kappa) .* log( ...
            1 + (kappa ./ 2) .* sigma.^2 .* ...
            (u.^2 + 1i .* (1 + 2 .* eta) .* u));

    %% Martingale correction

    martingaleCorrection = @(sigma, kappa, eta) ...
        -real(charExpVg(-1i, sigma, kappa, eta));

    %% VG characteristic function

    charFuncVg = @(u, sigma, kappa, eta) ...
        exp( ...
            charExpVg(u, sigma, kappa, eta) ...
            + 1i .* u .* martingaleCorrection(sigma, kappa, eta));

    %% Admissibility bound

    etaBound = @(sigma, kappa) ...
        1 ./ (kappa .* sigma.^2);

    %% Model prices as a function of p = [sigma, kappa, eta]

    modelCallPrices = @(p) runPricingFourier( ...
        @(u) charFuncVg(u, p(1), p(2), p(3)), ...
        logMoneyness, ...
        dfMat, ...
        forward);

    %% Objective function

    objective = @(p) objectiveNtsCalibration( ...
        p, ...
        modelCallPrices, ...
        callMarket, ...
        etaBound, ...
        penaltyValue);

    %% Calibration

    [paramsOpt, objValue] = fminsearch(objective, params0, options);

    sigmaOpt = paramsOpt(1);
    kappaOpt = paramsOpt(2);
    etaOpt = paramsOpt(3);

    %% Calibrated characteristic function

    charFuncVgOpt = @(u) charFuncVg(u, sigmaOpt, kappaOpt, etaOpt);

    %% Model call prices

    callModel = runPricingFourier( ...
        charFuncVgOpt, ...
        logMoneyness, ...
        dfMat, ...
        forward);

    callModel = callModel(:);

    undiscountedCallModel = callModel ./ dfMat;

    %% Model implied volatilities

    modelVols = arrayfun(@(strike, price) ...
        blsimpv(forward, strike, 0, timeToMaturity, price), ...
        strikes, ...
        undiscountedCallModel);

    modelVols = modelVols(:);

    %% Calibration report table

    idxPrint = unique([ ...
        1, ...
        round(numel(strikes) / 2), ...
        numel(strikes)]);

    resultsTable = printCalibrationReport( ...
        "VG", ...
        alpha, ...
        sigmaOpt, ...
        kappaOpt, ...
        etaOpt, ...
        objValue, ...
        strikes, ...
        logMoneyness, ...
        marketVols, ...
        modelVols, ...
        callMarket, ...
        callModel, ...
        idxPrint);

    %% Plot

    plotVolSmile( ...
        "VG", ...
        logMoneyness, ...
        marketVols, ...
        modelVols, ...
        timeToMaturity);

    %% Store calibration outputs in market.vg

    market.vg.paramsOpt = paramsOpt;

    market.vg.sigmaOpt = sigmaOpt;
    market.vg.kappaOpt = kappaOpt;
    market.vg.etaOpt = etaOpt;
    market.vg.objValue = objValue;

    market.vg.strikes = strikes;
    market.vg.logMoneyness = logMoneyness;

    market.vg.marketVols = marketVols;
    market.vg.modelVols = modelVols;

    market.vg.callMarket = callMarket;
    market.vg.callModel = callModel;

    market.vg.absError = abs(callModel - callMarket);

    market.vg.resultsTable = resultsTable;

    market.vg.spot = spot;
    market.vg.dividendYield = dividendYield;
    market.vg.timeToMaturity = timeToMaturity;

end