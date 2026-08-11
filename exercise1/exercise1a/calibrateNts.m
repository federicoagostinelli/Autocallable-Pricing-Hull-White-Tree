function market = calibrateNts(market, product)
%CALIBRATENTS Calibrate the NTS/NIG model for Assignment 6.
%
%   market = CALIBRATENTS(market, product)
%
%   calibrates the NIG model to the EuroStoxx/Stoxx50 implied-volatility
%   smile stored in:
%
%       market.equity.strikes
%       market.equity.volSmile
%
%   and stores all calibration inputs and outputs in:
%
%       market.nts
%
%   Model convention
%   ----------------
%
%   The NIG model is implemented as the NTS model with:
%
%       alpha = 1/2
%
%   Calibration maturity
%   --------------------
%
%   The calibration maturity is the first Party B coupon reset date:
%
%       product.partyB.resetDates(1)
%
%   because the stochastic equity-linked coupon is:
%
%       Coupon_1 = 6% if Stoxx50(T_reset_1) < Strike, else 0%.
%
%   The final coupon is fixed at 2%, and therefore does not require equity
%   calibration at the final payment date.
%
%   INPUT
%   -----
%
%       market
%           Market struct created by initializeMarket. Required fields:
%
%               market.dateInfo.refDate
%               market.dates
%               market.discounts
%               market.equity.strikes
%               market.equity.volSmile
%               market.equity.spot
%               market.equity.dividendYield
%
%       product
%           Product struct created by initializeProduct and enriched by
%           prepareProductForPricing. Required fields:
%
%               product.partyB.resetDates
%               product.partyB.resetTimes
%               product.partyB.resetDiscounts
%
%   OUTPUT
%   ------
%
%       market
%           Same market struct enriched with:
%
%               market.nts.modelName
%               market.nts.alpha
%               market.nts.calibrationDate
%               market.nts.calibrationTime
%               market.nts.discountFactor
%               market.nts.forward
%               market.nts.penaltyValue
%               market.nts.params0
%               market.nts.optimOptions
%               market.nts.paramsOpt
%               market.nts.sigmaOpt
%               market.nts.kappaOpt
%               market.nts.etaOpt
%               market.nts.objValue
%               market.nts.strikes
%               market.nts.logMoneyness
%               market.nts.marketVols
%               market.nts.modelVols
%               market.nts.callMarket
%               market.nts.callModel
%               market.nts.absError
%               market.nts.resultsTable
%               market.nts.discountFactorCheck
%
%   Required helper functions:
%
%       getDiscountFactorByZeroRatesLinearInterp
%       runPricingFourier
%       objectiveNtsCalibration
%       printCalibrationReport
%       plotVolSmile

    %% NIG calibration setup

    market.nts = struct();

    % NIG is the NTS model with alpha = 1/2.
    market.nts.modelName = "NIG";
    market.nts.alpha = 1 / 2;

    %% Calibration date, time and discount factor

    market.nts.calibrationDate = product.partyB.resetDates(1);
    market.nts.calibrationTime = product.partyB.resetTimes(1);

    % Discount factor already prepared at product level.
    discountFactorFromProduct = double(product.partyB.resetDiscounts(1));

    % Same discount factor recomputed directly from the market curve.
    discountFactorFromCurve = getDiscountFactorByZeroRatesLinearInterp( ...
        market.dateInfo.refDate, ...
        market.nts.calibrationDate, ...
        market.dates, ...
        market.discounts);

    discountFactorFromCurve = double(discountFactorFromCurve);

    % Consistency check.
    discountFactorTolerance = 1e-12;

    discountFactorAbsDiff = abs( ...
        discountFactorFromProduct - discountFactorFromCurve);

    if discountFactorAbsDiff > discountFactorTolerance
        error('calibrateNts:DiscountFactorMismatch', ...
            ['Discount factor mismatch at calibration date %s.\n' ...
             'From product: %.16f\n' ...
             'From curve  : %.16f\n' ...
             'Abs diff    : %.3e\n' ...
             'Tolerance   : %.3e'], ...
            datestr(market.nts.calibrationDate), ...
            discountFactorFromProduct, ...
            discountFactorFromCurve, ...
            discountFactorAbsDiff, ...
            discountFactorTolerance);
    end

    market.nts.discountFactor = discountFactorFromProduct;

    market.nts.discountFactorCheck = struct();
    market.nts.discountFactorCheck.fromProduct = discountFactorFromProduct;
    market.nts.discountFactorCheck.fromCurve = discountFactorFromCurve;
    market.nts.discountFactorCheck.absDiff = discountFactorAbsDiff;
    market.nts.discountFactorCheck.tolerance = discountFactorTolerance;
    market.nts.discountFactorCheck.passed = true;

    %% Equity forward at calibration maturity

    market.nts.forward = market.equity.spot ...
        * exp(-market.equity.dividendYield * market.nts.calibrationTime) ...
        / market.nts.discountFactor;

    %% Calibration parameters

    market.nts.penaltyValue = 1e12;

    % p = [sigma; kappa; eta]
    market.nts.params0 = [0.20; 1.00; 0.10];

    market.nts.optimOptions = optimset( ...
        'Display', 'off', ...
        'TolX', 1e-6, ...
        'TolFun', 1e-6, ...
        'MaxFunEvals', 5000, ...
        'MaxIter', 5000);

    %% Calibration settings

    alpha = market.nts.alpha;
    penaltyValue = market.nts.penaltyValue;
    params0 = market.nts.params0(:);
    options = market.nts.optimOptions;

    %% Market data

    strikes = market.equity.strikes(:);
    marketVols = market.equity.volSmile(:);

    spot = market.equity.spot;

    if ~isscalar(spot) || ~isfinite(spot) || spot <= 0
        error('calibrateNts:InvalidSpot', ...
            'market.equity.spot must be a positive finite scalar.');
    end

    dividendYield = market.equity.dividendYield;

    forward = double(market.nts.forward);
    dfMat = double(market.nts.discountFactor);
    timeToMaturity = double(market.nts.calibrationTime);

    if ~isscalar(forward) || ~isfinite(forward) || forward <= 0
        error('calibrateNts:InvalidForward', ...
            'The calibration forward must be a positive finite scalar.');
    end

    if ~isscalar(dfMat) || ~isfinite(dfMat) || dfMat <= 0
        error('calibrateNts:InvalidDiscountFactor', ...
            'The calibration discount factor must be a positive finite scalar.');
    end

    if ~isscalar(timeToMaturity) || ~isfinite(timeToMaturity) || timeToMaturity <= 0
        error('calibrateNts:InvalidTimeToMaturity', ...
            'The calibration time to maturity must be a positive finite scalar.');
    end

    if numel(strikes) ~= numel(marketVols)
        error('calibrateNts:InvalidSmileDimensions', ...
            'market.equity.strikes and market.equity.volSmile must have the same number of elements.');
    end

    if any(strikes <= 0) || any(~isfinite(strikes))
        error('calibrateNts:InvalidStrikes', ...
            'All strikes must be positive and finite.');
    end

    if any(marketVols <= 0) || any(~isfinite(marketVols))
        error('calibrateNts:InvalidVols', ...
            'All market implied volatilities must be positive and finite.');
    end

    %% Log-moneyness

    logMoneyness = log(forward ./ strikes);

    %% Market call prices from Black formula

    sqrtT = sqrt(timeToMaturity);
    volSqrtT = marketVols .* sqrtT;

    d1 = (logMoneyness + 0.5 .* marketVols.^2 .* timeToMaturity) ./ volSqrtT;
    d2 = d1 - volSqrtT;

    callMarket = dfMat .* (forward .* normcdf(d1) - strikes .* normcdf(d2));

    %% NTS characteristic exponent

    charExpNts = @(u, sigma, kappa, eta) ...
        (timeToMaturity ./ kappa) .* ((1 - alpha) ./ alpha) .* ...
        (1 - (1 + (kappa ./ (2 * (1 - alpha))) .* sigma.^2 .* ...
        (u.^2 + 1i .* u .* (1 + 2 .* eta))).^alpha);

    %% Martingale correction

    martingaleCorrection = @(sigma, kappa, eta) ...
        -real(charExpNts(-1i, sigma, kappa, eta));

    %% NTS characteristic function

    charFuncNts = @(u, sigma, kappa, eta) ...
        exp(charExpNts(u, sigma, kappa, eta) + ...
        1i .* u .* martingaleCorrection(sigma, kappa, eta));

    %% Admissibility bound

    etaBound = @(sigma, kappa) ...
        (1 - alpha) ./ (kappa .* sigma.^2);

    %% Model prices as a function of p = [sigma, kappa, eta]

    modelCallPrices = @(p) runPricingFourier( ...
        @(u) charFuncNts(u, p(1), p(2), p(3)), ...
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

    charFuncNtsOpt = @(u) charFuncNts(u, sigmaOpt, kappaOpt, etaOpt);

    %% Model call prices

    callModel = runPricingFourier( ...
        charFuncNtsOpt, ...
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
        market.nts.modelName, ...
        market.nts.alpha, ...
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

    %% Plot volatility smile

    plotVolSmile( ...
        market.nts.modelName, ...
        logMoneyness, ...
        marketVols, ...
        modelVols, ...
        timeToMaturity);

    %% Store calibration outputs in market.nts

    market.nts.paramsOpt = paramsOpt;

    market.nts.sigmaOpt = sigmaOpt;
    market.nts.kappaOpt = kappaOpt;
    market.nts.etaOpt = etaOpt;
    market.nts.objValue = objValue;

    market.nts.strikes = strikes;
    market.nts.logMoneyness = logMoneyness;

    market.nts.marketVols = marketVols;
    market.nts.modelVols = modelVols;

    market.nts.callMarket = callMarket;
    market.nts.callModel = callModel;

    market.nts.absError = abs(callModel - callMarket);
    market.nts.resultsTable = resultsTable;

    market.nts.spot = spot;
    market.nts.dividendYield = dividendYield;
    market.nts.timeToMaturity = timeToMaturity;

end