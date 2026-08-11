function product = initializeProduct(market)
%INITIALIZEPRODUCT Initialize the Assignment 6 certificate / hedging swap.
%
%   product = INITIALIZEPRODUCT(market)
%
%   builds the contractual data of the Assignment 6 certificate and of the
%   corresponding hedging swap. The product start date is set equal to the
%   market reference date, consistently with the market initializer where
%   the difference between 15-Feb-2008 and 19-Feb-2008 is ignored.
%
%   This function stores only contractual inputs. Market-dependent pricing
%   quantities such as payment dates, reset dates, reset times, accrual
%   factors, discount factors and forward rates are added later by:
%
%       product = prepareProductForPricing(product, market);
%
%   Assignment 6 contractual summary
%   --------------------------------
%
%   Certificate / issue:
%
%       Principal Amount:
%           100 MIO EUR
%
%       Maturity:
%           2 years after the Start Date
%
%       Coupon:
%           Payable annually on a 30/360 basis
%
%       Year 1 coupon:
%           6% if Stoxx50 < Strike at Coupon Reset Date
%
%       Last Year coupon:
%           2%
%
%       Coupon Reset Dates:
%           2 business days prior to the respective Coupon Payment Date,
%           i.e. in arrears
%
%       Strike:
%           3200
%
%       Coupon Payment Dates:
%           Annually, subject to Following Business Day Convention
%
%       Early Redemption:
%           If, on a Coupon Reset Date, the coupon reset implies that the
%           Cumulative Coupon Accrual is equal to or above the Trigger Level,
%           the notes redeem early on the respective Coupon Payment Date at
%           100% of par.
%
%       Trigger Level:
%           6%
%
%   Hedging swap:
%
%       Party A pays:
%           Euribor 3M + 1.30%
%
%       Party A payment dates:
%           Quarterly, subject to Modified Following Business Day Convention
%
%       Party A daycount:
%           ACT/360
%
%       Party B pays at Start Date:
%           X%
%
%       Party B pays:
%           Same coupon structure as the certificate
%
%       Early cancellation:
%           If the early redemption condition is met, the swap is
%           automatically cancelled.
%
%   INPUT
%
%       market
%           Market struct created by initializeMarket.
%
%   OUTPUT
%
%       product
%           Product struct containing contractual data only.
%
%   DESIGN NOTE
%
%       This function contains product-specific quantities such as notional,
%       strike, coupons, trigger level, Party A spread and contractual
%       schedules. These quantities should not be stored in the market
%       initializer.

    product = struct();

    %% General contractual data

    product.principal = 100.0e6;
    product.currency = 'EUR';
    product.startDate = market.dateInfo.refDate;

    product.maturityYears = 2;
    product.endDate = product.startDate + calyears(product.maturityYears);

    %% General conventions

    product.blackDayCount = market.dateInfo.blackDayCount; % ACT/365

    %% Early redemption / cancellation rule

    product.earlyRedemption = struct();

    product.earlyRedemption.isActive = true;
    product.earlyRedemption.triggerLevel = 0.06;
    product.earlyRedemption.redemptionPrice = 1.00;

    %% Underlying

    product.underlying = struct();

    product.underlying.name = market.equity.name;
    product.underlying.strike = 3200;

    %% Party A contractual data

    product.partyA = struct();

    product.partyA.payer = 'Bank XX';
    product.partyA.receiver = 'I.B.';

    product.partyA.legType = 'floating';
    product.partyA.index = 'Euribor 3M';
    product.partyA.spread = 0.0130;

    product.partyA.paymentFrequencyMonths = 3;
    product.partyA.paymentsPerYear = 4;

    product.partyA.paymentAdjust = 'modifiedfollowing';
    product.partyA.dayCount = market.dateInfo.dayCount; % ACT/360

    %% Party B contractual data

    product.partyB = struct();

    product.partyB.payer = 'I.B.';
    product.partyB.receiver = 'Bank XX';

    product.partyB.paysUpfront = true;
    product.partyB.upfrontSymbol = 'X';

    product.partyB.legType = 'equityLinkedCoupon';

    product.partyB.paymentFrequencyMonths = 12;
    product.partyB.paymentsPerYear = 1;

    product.partyB.accrualAdjust = 'modifiedfollowing';
    product.partyB.paymentAdjust = 'following';
    product.partyB.dayCount = 6;

    % Reset in arrears: 2 business days prior to each coupon payment date.
    product.partyB.resetLagBusinessDays = 2;

    %% Party B coupon rules

    product.partyB.coupons = struct();

    % Year 1:
    %   6% if Stoxx50 < Strike at Coupon Reset Date.
    product.partyB.coupons.year1 = struct();
    product.partyB.coupons.year1.rate = 0.06;
    product.partyB.coupons.year1.conditionType = 'lessThanStrike';
    product.partyB.coupons.year1.conditionUnderlying = product.underlying.name;
    product.partyB.coupons.year1.strike = product.underlying.strike;

    % Last year:
    %   2%.
    product.partyB.coupons.final = struct();
    product.partyB.coupons.final.rate = 0.02;
    product.partyB.coupons.final.conditionType = 'fixed';

    %% Cumulative coupon accrual rule

    product.cumulativeCouponAccrual = struct();

    product.cumulativeCouponAccrual.definition = ...
        'Previously paid coupon percentage plus originally scheduled coupon reset, ignoring the trigger level clause.';

    product.cumulativeCouponAccrual.includePreviouslyPaidCoupons = true;
    product.cumulativeCouponAccrual.ignoreTriggerInScheduledCoupon = true;

end