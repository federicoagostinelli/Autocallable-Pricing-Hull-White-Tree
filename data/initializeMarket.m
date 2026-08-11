function market = initializeMarket( ...
    curveDates, ...
    curveDiscounts, ...
    curveZeroRates, ...
    eurostoxxDataFile)
%INITIALIZEMARKET Initialize Assignment 6 IR + EuroStoxx market.
%
%   market = INITIALIZEMARKET(curveDates, curveDiscounts,
%   curveZeroRates, eurostoxxDataFile) returns a struct containing all
%   market data required for Assignment 6 certificate pricing.
%
%   This initializer is specific to Assignment 6.
%
%   Assignment 6 context
%   --------------------
%
%   The product is a certificate / structured bond linked to Stoxx50 /
%   EuroStoxx, with a hedging swap. The swap has:
%
%       Party A:
%           Pays Euribor 3M + 1.30%
%
%       Party A payment dates:
%           Quarterly, subject to Modified Following Business Day Convention
%
%       Party A daycount:
%           ACT/360
%
%       Party B:
%           Pays equity-linked coupons annually on a 30/360 basis.
%
%   Therefore, the interest-rate tenor grid in this market initializer is
%   quarterly and follows Party A, not Party B. Party B annual dates and
%   coupon rules must be initialized at product level.
%
%
%   INPUT
%   -----
%
%   curveDates
%       [1 x N] or [N x 1] vector of bootstrapped curve dates.
%
%       The first date is used as the market reference date t0.
%
%       Accepted formats:
%           - datetime vector;
%           - numeric datenum vector.
%
%   curveDiscounts
%       [1 x N] or [N x 1] vector of discount factors:
%
%           P(t0,T_i)
%
%       associated with curveDates.
%
%   curveZeroRates
%       [1 x N] or [N x 1] vector of continuously compounded zero rates
%       associated with curveDates.
%
%   eurostoxxDataFile
%       String or char containing the path to the MAT-file with EuroStoxx /
%       Stoxx50 market data.
%
%       If omitted or empty, the default file is:
%
%           "eurostoxx_Poli.mat"
%
%       The MAT-file is expected to contain:
%
%           cSelect.strikes
%               Vector of strikes used in the implied volatility smile.
%
%           cSelect.surface
%               Vector or matrix of implied volatilities associated with the
%               strikes. For Assignment 6 this is used as the EuroStoxx /
%               Stoxx50 implied volatility input.
%
%           cSelect.reference
%               Spot/reference level of the underlying.
%
%           cSelect.dividends
%               Dividend yield used for the equity forward dynamics.
%
%   OUTPUT
%   ------
%
%   market
%       Struct containing joint interest-rate and equity market data.
%
%       market.dates
%           Bootstrapped curve dates.
%
%       market.discounts
%           Bootstrapped discount factors P(t0,T_i).
%
%       market.zeroRates
%           Continuously compounded zero rates associated with market.dates.
%
%       market.dateInfo
%           Date and day-count conventions.
%
%           market.dateInfo.refDate
%               Market reference date t0. Equal to curveDates(1).
%
%           market.dateInfo.tradeDate
%               Trade date. Set equal to refDate.
%
%           market.dateInfo.paymentAdjust
%               Business-day adjustment convention for Party A quarterly
%               payment dates. Set to 'modifiedfollowing'.
%
%           market.dateInfo.dayCount
%               Party A / Euribor 3M accrual day-count convention.
%               MATLAB basis 2 = ACT/360.
%
%           market.dateInfo.blackDayCount
%               Day-count convention used for model times and equity
%               forward times. MATLAB basis 3 = ACT/365.
%
%       market.tenor
%           Quarterly Euribor 3M tenor grid used for Party A and IR
%           discounting/forward-rate quantities.
%
%           market.tenor.tenorMonths
%               Length of each Euribor tenor period in months.
%               Equal to 3.
%
%           market.tenor.paymentsPerYear
%               Number of Euribor periods per year.
%               Equal to 4.
%
%           market.tenor.dayCount
%               Day-count convention used for Euribor accrual factors.
%
%           market.tenor.blackDayCount
%               Day-count convention used for model times.
%
%           market.tenor.dates
%               Quarterly tenor dates:
%
%                   T_0,T_1,...,T_M
%
%               starting from market.dateInfo.refDate and extending to the
%               Assignment 6 certificate maturity.
%
%           market.tenor.discounts
%               Discount factors P(t0,T_i) interpolated on tenor dates.
%
%           market.tenor.times
%               ACT/365 times from refDate to each tenor date:
%
%                   times(i) = yearfrac(t0,T_i,blackDayCount)
%
%           market.tenor.dt
%               ACT/365 model time steps:
%
%                   dt(i) = yearfrac(T_i,T_{i+1},blackDayCount)
%
%           market.tenor.delta
%               ACT/360 Euribor accrual factors:
%
%                   delta(i) = yearfrac(T_i,T_{i+1},dayCount)
%
%           market.tenor.resetTimes
%               Reset times of the forward rates:
%
%                   resetTimes(i) = yearfrac(t0,T_i,blackDayCount)
%
%           market.tenor.forwardRates
%               Initial Euribor forward rates:
%
%                   L_i(t0) =
%                       (P(t0,T_i)/P(t0,T_{i+1}) - 1) / delta_i
%
%           market.tenor.forwardZCB
%               Initial forward zero-coupon bonds:
%
%                   B_i(t0) = P(t0,T_{i+1}) / P(t0,T_i)
%
%       market.equity
%           EuroStoxx / Stoxx50 market data.
%
%           market.equity.name
%               Name of the underlying.
%
%           market.equity.strikes
%               Implied volatility smile strikes.
%
%           market.equity.volSmile
%               Implied volatility smile values.
%
%           market.equity.spot
%               Spot/reference level of EuroStoxx/Stoxx50.
%
%           market.equity.dividendYield
%               Dividend yield used for forward dynamics.
%
%       market.modelAssumptions
%           Modeling assumptions.
%
%           market.modelAssumptions.interestRateEquityIndependent
%               Boolean flag. True for Assignment 6, where interest rates
%               and EuroStoxx dynamics are assumed independent.
%
%           market.modelAssumptions.interestRatesDeterministic
%               Boolean flag. True when the curve is used deterministically.
%
%   TENOR INDEXING CONVENTION
%   -------------------------
%
%   market.tenor.dates contains:
%
%       T_0,T_1,...,T_M
%
%   market.tenor.delta(i), market.tenor.dt(i),
%   market.tenor.forwardRates(i), market.tenor.forwardZCB(i), and
%   market.tenor.resetTimes(i) refer to the period:
%
%       [T_i,T_{i+1}]
%
%   in mathematical notation.
%
%   With MATLAB indexing:
%
%       period i corresponds to:
%
%           market.tenor.dates(i) -> market.tenor.dates(i+1)
%
%   IMPORTANT DESIGN NOTE
%   ---------------------
%
%   This function initializes market data only. It does not initialize the
%   annual Party B coupon schedule. That schedule belongs to the product
%   initializer because Party B dates depend on the payoff definition.
%
%   Required helper functions in the codebase:
%
%       businessDateOffsetTarget
%       getDiscountFactorByZeroRatesLinearInterp

    %% Optional inputs

    if nargin < 4 || isempty(eurostoxxDataFile)
        eurostoxxDataFile = "eurostoxx_Poli.mat";
    end

    %% Defensive input formatting

    if isnumeric(curveDates)
        curveDates = datetime(curveDates, 'ConvertFrom', 'datenum');
    end

    curveDates = curveDates(:).';
    curveDiscounts = curveDiscounts(:).';
    curveZeroRates = curveZeroRates(:).';

    if numel(curveDates) ~= numel(curveDiscounts) || ...
            numel(curveDates) ~= numel(curveZeroRates)
        error("curveDates, curveDiscounts and curveZeroRates must have the same length.");
    end

    %% Base market struct

    market = struct();

    market.dates = curveDates;
    market.discounts = curveDiscounts;
    market.zeroRates = curveZeroRates;

    %% Date information

    market.dateInfo = struct();

    market.dateInfo.refDate = curveDates(1);
    market.dateInfo.tradeDate = market.dateInfo.refDate;

    % Ignore the 15-Feb-2008 / 19-Feb-2008 difference:
    % the model tenor grid starts from refDate.
    market.dateInfo.paymentAdjust = 'modifiedfollowing';

    market.dateInfo.dayCount = 2;      % ACT/360
    market.dateInfo.blackDayCount = 3; % ACT/365

    %% Quarterly Euribor 3M tenor grid for Party A

    market.tenor = struct();

    market.tenor.tenorMonths = 3;
    market.tenor.paymentsPerYear = 12 / market.tenor.tenorMonths;

    market.tenor.dayCount = market.dateInfo.dayCount;
    market.tenor.blackDayCount = market.dateInfo.blackDayCount;

    % Assignment 6 certificate maturity is 2 years.
    nYears = 2;
    nPeriods = nYears * market.tenor.paymentsPerYear;

    market.tenor.dates = arrayfun( ...
        @(k) businessDateOffsetTarget( ...
            market.dateInfo.refDate, ...
            0, ...
            k * market.tenor.tenorMonths, ...
            0, ...
            market.dateInfo.paymentAdjust), ...
        0:nPeriods);

    market.tenor.discounts = arrayfun( ...
        @(d) getDiscountFactorByZeroRatesLinearInterp( ...
            market.dateInfo.refDate, ...
            d, ...
            market.dates, ...
            market.discounts), ...
        market.tenor.dates);

    market.tenor.times = yearfrac( ...
        market.dateInfo.refDate, ...
        market.tenor.dates, ...
        market.dateInfo.blackDayCount);

    market.tenor.dt = yearfrac( ...
        market.tenor.dates(1:end-1), ...
        market.tenor.dates(2:end), ...
        market.dateInfo.blackDayCount);

    market.tenor.delta = yearfrac( ...
        market.tenor.dates(1:end-1), ...
        market.tenor.dates(2:end), ...
        market.dateInfo.dayCount);

    market.tenor.resetTimes = yearfrac( ...
        market.dateInfo.refDate, ...
        market.tenor.dates(1:end-1), ...
        market.dateInfo.blackDayCount);

    market.tenor.forwardRates = ...
        (market.tenor.discounts(1:end-1) ./ market.tenor.discounts(2:end) - 1) ...
        ./ market.tenor.delta;

    market.tenor.forwardZCB = ...
        market.tenor.discounts(2:end) ./ market.tenor.discounts(1:end-1);

    %% EuroStoxx / Stoxx50 market data

    equityData = load(eurostoxxDataFile);

    if ~isfield(equityData, "cSelect")
        error("The EuroStoxx MAT-file must contain a structure named cSelect.");
    end

    requiredFields = ["strikes", "surface", "reference", "dividends"];

    for iField = 1:numel(requiredFields)
        fieldName = requiredFields(iField);

        if ~isfield(equityData.cSelect, fieldName)
            error("equityData.cSelect.%s is missing.", fieldName);
        end
    end

    market.equity = struct();

    market.equity.name = "EuroStoxx/Stoxx50";
    market.equity.strikes = double(equityData.cSelect.strikes(:));
    market.equity.volSmile = double(equityData.cSelect.surface(:));
    market.equity.spot = double(equityData.cSelect.reference);
    market.equity.dividendYield = double(equityData.cSelect.dividends);

    %% Model assumptions

    market.modelAssumptions = struct();

    market.modelAssumptions.interestRateEquityIndependent = true;
    market.modelAssumptions.interestRatesDeterministic = true;

end