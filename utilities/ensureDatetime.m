function d = ensureDatetime(x)
%ENSUREDATETIME Convert supported date formats to datetime.
%
%   Numeric dates are assumed to be MATLAB datenums.

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