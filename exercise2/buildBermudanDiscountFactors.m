function [B0Tree, treeDates, treeTimes, B0Payments, paymentDates, paymentTimes, deltaPayments] = ...
    buildBermudanDiscountFactors(market, treeHullWhite, Bermudan)
%BUILDBERMUDANDISCOUNTFACTORS Build tree-grid and Bermudan payment discount factors.
%
%   [B0Tree, treeDates, treeTimes, B0Payments, paymentDates, paymentTimes, deltaPayments] = ...
%       BUILDBERMUDANDISCOUNTFACTORS(market, treeHullWhite, Bermudan)
%
%   computes the two families of discount factors needed to price a
%   Bermudan swaption on a Hull-White trinomial tree.
%
%   INPUTS:
%   -------
%   market
%       Market struct containing the bootstrapped discount curve.
%
%       Required fields:
%           market.dateInfo.refDate
%           market.dates
%           market.discounts
%
%       Optional fields:
%           market.dateInfo.paymentAdjust
%           market.dateInfo.blackDayCount
%           market.dateInfo.dayCount
%
%   treeHullWhite
%       Hull-White tree struct.
%
%       Required fields:
%           treeHullWhite.dt
%           treeHullWhite.totalSteps
%
%       The tree defines the artificial numerical grid used for backward
%       induction.
%
%   Bermudan
%       Bermudan swaption / underlying swap struct.
%
%       Required fields:
%           Bermudan.maturity
%
%       Optional fields:
%           Bermudan.startDate
%           Bermudan.endDate
%           Bermudan.paymentDates
%           Bermudan.periodStartDates
%           Bermudan.numPaymentPerYear
%           Bermudan.num_payment_a_year
%           Bermudan.paymentAdjust
%           Bermudan.fixedDayCount
%
%   OUTPUTS:
%   --------
%   B0Tree
%       Market discount factors P(0,t_i) on the artificial tree grid.
%       These are used in the backward induction to compute one-step
%       stochastic ZCBs B(t_i,t_{i+1}).
%
%   treeDates
%       Artificial ACT/365 model dates associated with the tree grid.
%       These are not contractual dates and are not business-day adjusted.
%
%   treeTimes
%       Tree model times:
%
%           0, dt, 2dt, ..., totalSteps * dt
%
%   B0Payments
%       Market discount factors P(0,T_j) on the Bermudan underlying swap
%       payment dates.
%
%   paymentDates
%       Contractual payment dates of the underlying swap, business-day
%       adjusted.
%
%   paymentTimes
%       ACT/365 times from refDate to paymentDates.
%
%   deltaPayments
%       Fixed-leg accrual factors between period start dates and payment
%       dates.
%
%   DESIGN NOTE:
%   ------------
%   B0Tree is aligned with the Hull-White tree.
%   B0Payments is aligned with the Bermudan underlying swap schedule.
%
%   Do not use market.tenor.dates for the Bermudan underlying swap unless
%   the Bermudan product explicitly uses that tenor schedule.

    %% ================================================================
    %  1. Market curve data
    % ================================================================

    refDate = ensureDatetime(market.dateInfo.refDate);
    curveDates = ensureDatetime(market.dates);
    curveDiscounts = market.discounts;

    if isfield(market.dateInfo, "blackDayCount")
        blackDayCount = market.dateInfo.blackDayCount;
    else
        blackDayCount = 3; % ACT/365
    end

    if isfield(Bermudan, "fixedDayCount")
        fixedDayCount = Bermudan.fixedDayCount;
    elseif isfield(market.dateInfo, "dayCount")
        fixedDayCount = market.dateInfo.dayCount;
    else
        fixedDayCount = 6; % fallback
    end

    if isfield(Bermudan, "paymentAdjust")
        paymentAdjust = Bermudan.paymentAdjust;
    elseif isfield(market.dateInfo, "paymentAdjust")
        paymentAdjust = market.dateInfo.paymentAdjust;
    else
        paymentAdjust = 'modifiedfollowing';
    end

    %% ================================================================
    %  2. Tree-grid discount factors
    % ================================================================
    %
    % Tree dates are artificial model dates.
    % They are not payment dates and are not business-day adjusted.

    dt = treeHullWhite.dt;
    totalSteps = treeHullWhite.totalSteps;

    treeStepIndex = (0:totalSteps)';
    treeTimes = treeStepIndex * dt;

    treeDates = refDate + days(365 * treeTimes);

    B0Tree = getDiscountFactorByZeroRatesLinearInterp( ...
        refDate, ...
        treeDates, ...
        curveDates, ...
        curveDiscounts ...
    );

    %% ================================================================
    %  3. Bermudan underlying swap payment dates
    % ================================================================
    %
    % Payment dates are contractual dates of the Bermudan underlying swap.
    % They must come from the Bermudan product definition

    if isfield(Bermudan, "paymentDates")

        paymentDates = ensureDatetime(Bermudan.paymentDates(:));

    else

        if isfield(Bermudan, "startDate")
            startDate = ensureDatetime(Bermudan.startDate);
        else
            startDate = refDate;
        end

        if isfield(Bermudan, "endDate")
            endDate = ensureDatetime(Bermudan.endDate);
        else
            endDate = businessDateOffsetTarget( ...
                startDate, ...
                Bermudan.maturity, ...
                0, ...
                0, ...
                paymentAdjust ...
            );
        end

        if isfield(Bermudan, "numPaymentPerYear")
            numPaymentPerYear = Bermudan.numPaymentPerYear;
        else
            numPaymentPerYear = 1;
        end

        [paymentDates, ~] = computePaymentDates( ...
            startDate, ...
            endDate, ...
            numPaymentPerYear, ...
            paymentAdjust ...
        );

        paymentDates = ensureDatetime(paymentDates(:));

    end

    %% ================================================================
    %  4. Payment times, accrual factors and payment-date discounts
    % ================================================================

    paymentTimes = yearfrac( ...
        refDate, ...
        paymentDates, ...
        blackDayCount ...
    );

    if isfield(Bermudan, "periodStartDates")

        periodStartDates = ensureDatetime(Bermudan.periodStartDates(:));

    else

        if isfield(Bermudan, "startDate")
            swapStartDate = ensureDatetime(Bermudan.startDate);
        else
            swapStartDate = refDate;
        end

        periodStartDates = [swapStartDate; paymentDates(1:end-1)];

    end

    deltaPayments = yearfrac( ...
        periodStartDates, ...
        paymentDates, ...
        fixedDayCount ...
    );

    B0Payments = getDiscountFactorByZeroRatesLinearInterp( ...
        refDate, ...
        paymentDates, ...
        curveDates, ...
        curveDiscounts ...
    );

end