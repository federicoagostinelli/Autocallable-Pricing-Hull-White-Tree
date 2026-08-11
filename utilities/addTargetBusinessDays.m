function outDates = addTargetBusinessDays(inDates, nBusinessDays)
%ADDTARGETBUSINESSDAYS Add TARGET business days to datetime dates.
%
%   outDates = ADDTARGETBUSINESSDAYS(inDates, nBusinessDays)
%
%   shifts each input date by a given number of TARGET business days.
%
%   INPUT
%   -----
%
%   inDates
%       Scalar, row vector, column vector or matrix of datetime dates.
%
%   nBusinessDays
%       Integer scalar or numeric array with the same size as inDates.
%
%       If nBusinessDays > 0, dates are moved forward.
%
%       If nBusinessDays < 0, dates are moved backward.
%
%       If nBusinessDays = 0, dates are returned unchanged.
%
%       The input date itself is not counted. For example, if inDate is a
%       Monday and nBusinessDays = -2, the output is the previous Thursday,
%       unless Friday or Thursday is a TARGET holiday.
%
%   OUTPUT
%   ------
%
%   outDates
%       Datetime array with the same size as inDates.
%
%   TARGET business-day calendar
%   ----------------------------
%
%   TARGET business days exclude:
%
%       - Saturdays;
%       - Sundays;
%       - January 1;
%       - Good Friday;
%       - Easter Monday;
%       - May 1;
%       - December 25;
%       - December 26.
%
%   EXAMPLES
%   --------
%
%       resetDates = addTargetBusinessDays(paymentDates, -2);
%
%       nextDates = addTargetBusinessDays(today, 5);
%
%   Notes
%   -----
%
%   This function counts actual TARGET business days. It is therefore
%   different from applying a calendar-day offset and then adjusting with a
%   business-day convention.

    %% Input checks

    if ~isa(inDates, 'datetime')
        error('inDates must be a datetime scalar or datetime array.');
    end

    if ~isnumeric(nBusinessDays)
        error('nBusinessDays must be numeric.');
    end

    if ~isscalar(nBusinessDays) && ~isequal(size(nBusinessDays), size(inDates))
        error('nBusinessDays must be scalar or have the same size as inDates.');
    end

    if any(mod(nBusinessDays(:), 1) ~= 0)
        error('nBusinessDays must contain integer values only.');
    end

    %% Broadcast scalar nBusinessDays if needed

    if isscalar(nBusinessDays)
        nBusinessDays = repmat(nBusinessDays, size(inDates));
    end

    %% Vectorized application over the input array

    outDates = arrayfun( ...
        @(d, n) addTargetBusinessDaysScalar(d, n), ...
        inDates, ...
        nBusinessDays);

end


function outDate = addTargetBusinessDaysScalar(inDate, nBusinessDays)
%ADDTARGETBUSINESSDAYSSCALAR Scalar implementation.

    if nBusinessDays == 0
        outDate = inDate;
        return;
    end

    step = sign(nBusinessDays);
    remainingDays = abs(nBusinessDays);

    outDate = inDate;

    while remainingDays > 0
        outDate = outDate + caldays(step);

        if isTargetBusinessDayScalar(outDate)
            remainingDays = remainingDays - 1;
        end
    end

end


function tf = isTargetBusinessDayScalar(d)
%ISTARGETBUSINESSDAYSCALAR Return true if d is a TARGET business day.

    wd = weekday(d); % 1 = Sunday, 7 = Saturday

    if wd == 1 || wd == 7
        tf = false;
        return;
    end

    holidays = targetHolidaysScalar(year(d));

    tf = ~ismember(datetime(year(d), month(d), day(d)), holidays);

end


function holidays = targetHolidaysScalar(y)
%TARGETHOLIDAYSSCALAR Return standard TARGET holidays for year y.

    easter = easterSundayScalar(y);

    holidays = [
        datetime(y, 1, 1)
        easter - caldays(2)   % Good Friday
        easter + caldays(1)   % Easter Monday
        datetime(y, 5, 1)
        datetime(y, 12, 25)
        datetime(y, 12, 26)
    ];

end


function easter = easterSundayScalar(y)
%EASTERSUNDAYSCALAR Compute Easter Sunday using the Meeus algorithm.

    a = mod(y, 19);
    b = floor(y / 100);
    c = mod(y, 100);
    d = floor(b / 4);
    e = mod(b, 4);
    f = floor((b + 8) / 25);
    g = floor((b - f + 1) / 3);
    h = mod(19 * a + b - d - g + 15, 30);
    i = floor(c / 4);
    k = mod(c, 4);
    l = mod(32 + 2 * e + 2 * i - h - k, 7);
    m = floor((a + 11 * h + 22 * l) / 451);

    monthEaster = floor((h + l - 7 * m + 114) / 31);
    dayEaster = mod(h + l - 7 * m + 114, 31) + 1;

    easter = datetime(y, monthEaster, dayEaster);

end