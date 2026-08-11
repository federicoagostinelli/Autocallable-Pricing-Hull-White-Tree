function [dates, discounts, zeroRates] = bootstrap(datesSet, ratesSet)
% BOOTSTRAP Constructs a yield curve from Deposits, Futures, and Swaps
% using Depos, Futures, and Swaps quotes.

    %% --- Normalize all dates to datetime ---
    refDate      = ensureDatetime(datesSet.settlement);
    deposDates   = ensureDatetime(datesSet.depos);
    futuresDates = ensureDatetime(datesSet.futures);
    swapDates    = ensureDatetime(datesSet.swaps);

    if ~isscalar(refDate)
        error('datesSet.settlement must contain exactly one date.');
    end

    %% --- Initialize curve ---
    dates = refDate;
    discounts = 1.0;

    %% --- 1. DEPOS ---
    nDepos = 3;

    deposDatesUsed = deposDates(1:nDepos);
    deposRatesUsed = mean(ratesSet.depos(1:nDepos, :), 2);

    tauDepos = yearfrac(refDate, deposDatesUsed, 2); % ACT/360
    dfDepos = 1 ./ (1 + deposRatesUsed(:) .* tauDepos(:));

    dates = [dates; deposDatesUsed(:)];
    discounts = [discounts; dfDepos(:)];

    %% --- 2. FUTURES ---
    nFutures = 7;

    for i = 1:nFutures
        d_start = futuresDates(i, 1);
        d_end   = futuresDates(i, 2);
        r_fut   = mean(ratesSet.futures(i, :));

        df_start = getDiscountFactorByZeroRatesLinearInterp( ...
            refDate, d_start, dates, discounts);

        tau = yearfrac(d_start, d_end, 2); % ACT/360
        df_end = df_start / (1 + r_fut * tau);

        dates = [dates; d_end];
        discounts = [discounts; df_end];
    end

    %% --- 3. SWAPS: one loop over maturities, no inner loop ---
    for i = 2:length(swapDates)
        targetDate = swapDates(i);
        swapRate = mean(ratesSet.swaps(i, :));

        couponDates = buildAnnualTargetSchedule(refDate, targetDate);
        knownCouponDates = couponDates(1:end-1);

        if isempty(knownCouponDates)
            pv_fixed_known = 0;
            prev_date = refDate;
        else
            scheduleKnown = [refDate; knownCouponDates(:)];

            tauKnown = yearfrac( ...
                scheduleKnown(1:end-1), ...
                scheduleKnown(2:end), ...
                6); % 30E/360 European

            dfKnown = getDiscountFactorByZeroRatesLinearInterp( ...
                refDate, knownCouponDates(:), dates, discounts);

            pv_fixed_known = sum(tauKnown(:) .* dfKnown(:));
            prev_date = knownCouponDates(end);
        end

        tau_last = yearfrac(prev_date, targetDate, 6);

        df_final = (1 - swapRate * pv_fixed_known) / ...
                   (1 + swapRate * tau_last);

        dates = [dates; targetDate];
        discounts = [discounts; df_final];
    end

    %% --- Zero rates ---
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