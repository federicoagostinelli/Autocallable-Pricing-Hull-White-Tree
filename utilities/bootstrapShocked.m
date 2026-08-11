function [dates, discounts, zeroRates] = bootstrapShocked(datesSet, ratesSet, shock)
%BOOTSTRAPSHOCKED Bootstrap a shocked yield curve from Deposits, Futures and Swaps.
%
%   [dates, discounts, zeroRates] = BOOTSTRAPSHOCKED(datesSet, ratesSet, shock)
%   constructs discount factors and continuously compounded zero rates after
%   applying a shock to the input market quotes.
%
%   INPUT
%       datesSet
%           Struct with fields:
%               settlement : scalar settlement/reference date
%               depos      : deposit maturity dates
%               futures    : futures period dates, with columns:
%                            column 1 = start date
%                            column 2 = end date
%               swaps      : swap maturity dates
%
%       ratesSet
%           Struct with fields:
%               depos      : deposit bid/ask quotes or quote matrix
%               futures    : futures bid/ask quotes or quote matrix
%               swaps      : swap bid/ask quotes or quote matrix
%
%       shock
%           Either:
%
%               scalar numeric
%                   Parallel shock applied to every market quote.
%
%               timetable
%                   Pandas-Series-like shock object. Row times are the
%                   shocked pillar dates and the first variable contains
%                   shock values.
%
%                   Shocks are aligned by date to the bootstrap pillars:
%
%                       depos(1:3)
%                       futures(1:7) end dates
%                       swaps(2:end)
%
%                   Missing pillar dates receive zero shock.
%                   Shock dates not used by the bootstrap are ignored.
%
%           Shock must be in absolute rate units, e.g. 1 bp = 1e-4.
%
%   OUTPUT
%       dates
%           Bootstrapped curve dates.
%
%       discounts
%           Bootstrapped discount factors P(0,T).
%
%       zeroRates
%           Continuously compounded zero rates.

    if nargin < 3 || isempty(shock)
        shock = 0.0;
    end

    %% Normalize dates

    refDate      = ensureDatetime(datesSet.settlement);
    deposDates   = ensureDatetime(datesSet.depos);
    futuresDates = ensureDatetime(datesSet.futures);
    swapDates    = ensureDatetime(datesSet.swaps);

    if ~isscalar(refDate)
        error('datesSet.settlement must contain exactly one date.');
    end

    %% Select instruments used in bootstrap

    nDepos = 3;
    nFutures = 7;

    deposDatesUsed = deposDates(1:nDepos);
    futuresEndDatesUsed = futuresDates(1:nFutures, 2);
    swapDatesUsed = swapDates(2:end);

    shockPillars = [
        deposDatesUsed(:)
        futuresEndDatesUsed(:)
        swapDatesUsed(:)
    ];

    shockValues = getAlignedShockSeries(shock, shockPillars);

    shockDepos   = shockValues(1:nDepos);
    shockFutures = shockValues(nDepos + (1:nFutures));
    shockSwaps   = shockValues(nDepos + nFutures + (1:numel(swapDatesUsed)));

    %% Initialize curve

    dates = refDate;
    discounts = 1.0;

    %% 1. Deposits

    deposRatesUsed = mean(ratesSet.depos(1:nDepos, :), 2);
    deposRatesUsed = deposRatesUsed(:) + shockDepos(:);

    tauDepos = yearfrac(refDate, deposDatesUsed, 2); % ACT/360

    dfDepos = 1 ./ (1 + deposRatesUsed(:) .* tauDepos(:));

    dates = [dates; deposDatesUsed(:)];
    discounts = [discounts; dfDepos(:)];

    %% 2. Futures

    for i = 1:nFutures

        d_start = futuresDates(i, 1);
        d_end   = futuresDates(i, 2);

        r_fut = mean(ratesSet.futures(i, :)) + shockFutures(i);

        df_start = getDiscountFactorByZeroRatesLinearInterp( ...
            refDate, ...
            d_start, ...
            dates, ...
            discounts);

        tau = yearfrac(d_start, d_end, 2); % ACT/360

        df_end = df_start / (1 + r_fut * tau);

        dates = [dates; d_end];
        discounts = [discounts; df_end];

    end

    %% 3. Swaps

    for i = 2:length(swapDates)

        targetDate = swapDates(i);
        swapRate = mean(ratesSet.swaps(i, :)) + shockSwaps(i - 1);

        couponDates = buildAnnualTargetSchedule(refDate, targetDate);
        knownCouponDates = couponDates(1:end-1);

        if isempty(knownCouponDates)

            pv_fixed_known = 0.0;
            prev_date = refDate;

        else

            scheduleKnown = [refDate; knownCouponDates(:)];

            tauKnown = yearfrac( ...
                scheduleKnown(1:end-1), ...
                scheduleKnown(2:end), ...
                6); % 30E/360 European

            dfKnown = getDiscountFactorByZeroRatesLinearInterp( ...
                refDate, ...
                knownCouponDates(:), ...
                dates, ...
                discounts);

            pv_fixed_known = sum(tauKnown(:) .* dfKnown(:));
            prev_date = knownCouponDates(end);

        end

        tau_last = yearfrac(prev_date, targetDate, 6); % 30E/360 European

        df_final = (1 - swapRate * pv_fixed_known) / ...
                   (1 + swapRate * tau_last);

        dates = [dates; targetDate];
        discounts = [discounts; df_final];

    end

    %% Zero rates

    zeroRates = fromDiscountFactorsToZeroRates(dates(1), dates, discounts);

    if numel(zeroRates) == numel(discounts) - 1
        zeroRates = [zeroRates(1); zeroRates(:)];
    else
        zeroRates = zeroRates(:);
    end

end


function couponDates = buildAnnualTargetSchedule(refDate, targetDate)
% Same schedule logic as the original code, but without growing the array
% inside a while loop.

    maxYears = year(targetDate) - year(refDate) + 2;
    kGrid = (1:maxYears).';

    adjustedDates = arrayfun(@(k) ...
        businessDateOffsetTarget(refDate, k, 0, 0, 'following'), ...
        kGrid);

    couponDates = adjustedDates(adjustedDates <= targetDate);

    if isempty(couponDates) || couponDates(end) < targetDate
        couponDates = [couponDates(:); targetDate];
    else
        couponDates = couponDates(:);
        couponDates(end) = targetDate;
    end
end


function d = ensureDatetime(x)
% Convert supported date formats to datetime.
% Assumes numeric values are MATLAB datenums.

    if isa(x, 'datetime')
        d = x;
    elseif isnumeric(x)
        d = datetime(x, 'ConvertFrom', 'datenum');
    elseif iscellstr(x) || isstring(x) || ischar(x)
        d = datetime(x);
    else
        error('Unsupported date format: %s', class(x));
    end
end

function shockValues = getAlignedShockSeries(shock, targetDates)
%GETALIGNEDSHOCKSERIES Align a scalar or timetable shock to target dates.
%
%   shockValues = GETALIGNEDSHOCKSERIES(shock, targetDates) returns shocks
%   aligned with targetDates.
%
%   INPUT
%       shock
%           Either:
%
%               scalar numeric
%                   Parallel shock applied to all target dates.
%
%               timetable
%                   Timetable with dates as row times and one variable
%                   containing shock values.
%
%       targetDates
%           Dates to which shock values must be aligned.
%
%   OUTPUT
%       shockValues
%           Column vector of shocks aligned with targetDates.
%
%   Missing target dates receive zero shock.
%   Shock dates not appearing in targetDates are ignored.

    targetDates = ensureDatetime(targetDates);
    targetDates = targetDates(:);

    if isnumeric(shock) && isscalar(shock)
        shockValues = shock * ones(size(targetDates));
        return
    end

    if ~istimetable(shock)
        error('shock must be either a scalar numeric value or a timetable.');
    end

    shockDates = ensureDatetime(shock.Properties.RowTimes);
    shockVals = shock{:, 1};

    shockDates = shockDates(:);
    shockVals = shockVals(:);

    shockValues = zeros(size(targetDates));

    [isFound, loc] = ismember(targetDates, shockDates);

    shockValues(isFound) = shockVals(loc(isFound));

    missingTargetDates = targetDates(~isFound);

    if ~isempty(missingTargetDates)
        warning('%d bootstrap pillar dates have no shock. Missing shocks set to zero.', ...
            numel(missingTargetDates));
    end

    unusedShockDates = shockDates(~ismember(shockDates, targetDates));

    if ~isempty(unusedShockDates)
        warning('%d shock dates are not bootstrap pillars and were ignored.', ...
            numel(unusedShockDates));
    end

end