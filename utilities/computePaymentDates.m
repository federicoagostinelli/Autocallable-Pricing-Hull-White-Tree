function [paymentDates, details] = computePaymentDates( ...
    startDate, endDate, paymentsPerYear, convention)
%COMPUTEPAYMENTDATES Build the adjusted payment schedule of a contract.
%
%   [paymentDates, details] = computePaymentDates( ...
%       startDate, endDate, paymentsPerYear, convention)
%
%   returns the contractual payment dates between startDate and endDate,
%   adjusted according to the selected TARGET business-day convention.
%
%   Dates are generated from the unadjusted schedule:
%
%       startDate + k * tenorMonths,    k = 1, ..., numberOfRegularPeriods
%
%   where:
%
%       tenorMonths = 12 / paymentsPerYear
%
%   Each generated date is then adjusted by businessDateOffsetTarget.
%   The final maturity date is also adjusted with the same convention and
%   appended only if it is not already the last generated payment date.
%
%   INPUTS:
%       startDate
%           Contract start date. Scalar datetime.
%
%       endDate
%           Contract maturity date. Scalar datetime.
%
%       paymentsPerYear
%           Number of payments per year. For example, 4 means quarterly
%           payments.
%
%       convention
%           TARGET business-day convention. Supported values are:
%               'following'
%               'modifiedfollowing'
%
%   OUTPUTS:
%       paymentDates
%           Column vector of adjusted payment dates.
%
%       details
%           Struct with schedule information:
%               details.paymentsPerYear
%               details.tenorMonths
%               details.totalMonths
%               details.numberOfRegularPeriods
%               details.adjustedMaturityDate
%               details.includesStub

    tenorMonths = 12 / paymentsPerYear;

    totalMonths = split( ...
        between(startDate, endDate, 'Months'), ...
        'Months');

    numberOfRegularPeriods = floor(totalMonths / tenorMonths);

    paymentDates = NaT(numberOfRegularPeriods, 1);

    for periodIdx = 1:numberOfRegularPeriods

        monthOffset = periodIdx * tenorMonths;

        paymentDates(periodIdx) = businessDateOffsetTarget( ...
            startDate, ...
            0, ...
            monthOffset, ...
            0, ...
            convention);

    end

    adjustedMaturityDate = adjustTargetBusinessDay(endDate, convention);

    if isempty(paymentDates) || paymentDates(end) ~= adjustedMaturityDate
        paymentDates = [paymentDates; adjustedMaturityDate];
        includesStub = true;
    else
        includesStub = false;
    end

    details = struct();

    details.paymentsPerYear = paymentsPerYear;
    details.tenorMonths = tenorMonths;
    details.totalMonths = totalMonths;
    details.numberOfRegularPeriods = numberOfRegularPeriods;
    details.adjustedMaturityDate = adjustedMaturityDate;
    details.includesStub = includesStub;

end