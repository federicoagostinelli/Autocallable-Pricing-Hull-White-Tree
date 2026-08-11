function printInitializationReport(market, product)
%PRINTINITIALIZATIONREPORT Print Assignment 6 market/product/NTS-NIG report.
%
%   PRINTINITIALIZATIONREPORT(market, product)
%
%   prints a compact report after:
%
%       - market initialization;
%       - product initialization;
%       - preparation for pricing;
%       - NTS/NIG calibration.
%
%   The function assumes that calibration results are stored in:
%
%       market.nts
%
%   and that product schedules have already been prepared by:
%
%       product = prepareProductForPricing(product, market);

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf(' ASSIGNMENT 6 REPORT\n');
    fprintf('============================================================\n\n');

    %% Market

    fprintf('1. MARKET\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Reference date              : %s\n', datestr(market.dateInfo.refDate));
    fprintf('Trade date                  : %s\n', datestr(market.dateInfo.tradeDate));
    fprintf('Curve points                : %d\n', numel(market.dates));
    fprintf('First curve date            : %s\n', datestr(market.dates(1)));
    fprintf('Last curve date             : %s\n', datestr(market.dates(end)));
    fprintf('First discount factor       : %.10f\n', market.discounts(1));
    fprintf('Last discount factor        : %.10f\n', market.discounts(end));
    fprintf('IR payment adjustment       : %s\n', market.dateInfo.paymentAdjust);
    fprintf('IR day count                : ACT/360, basis %d\n', market.dateInfo.dayCount);
    fprintf('Model time day count        : ACT/365, basis %d\n', market.dateInfo.blackDayCount);

    if isfield(market, 'modelAssumptions')
        if isfield(market.modelAssumptions, 'interestRateEquityIndependent')
            fprintf('IR / equity independent     : %d\n', ...
                market.modelAssumptions.interestRateEquityIndependent);
        end

        if isfield(market.modelAssumptions, 'interestRatesDeterministic')
            fprintf('Deterministic IR            : %d\n', ...
                market.modelAssumptions.interestRatesDeterministic);
        end
    end

    fprintf('\n');

    %% Tenor

    fprintf('2. EURIBOR 3M TENOR GRID\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Tenor months                : %d\n', market.tenor.tenorMonths);
    fprintf('Payments per year           : %d\n', market.tenor.paymentsPerYear);
    fprintf('Number of tenor dates       : %d\n', numel(market.tenor.dates));
    fprintf('Number of periods           : %d\n', numel(market.tenor.delta));
    fprintf('First tenor date            : %s\n', datestr(market.tenor.dates(1)));
    fprintf('Last tenor date             : %s\n', datestr(market.tenor.dates(end)));
    fprintf('First forward Euribor 3M    : %.8f%%\n', ...
        100 * market.tenor.forwardRates(1));
    fprintf('Last forward Euribor 3M     : %.8f%%\n', ...
        100 * market.tenor.forwardRates(end));

    fprintf('\n');

    %% Equity

    fprintf('3. EUROSTOXX / STOXX50 MARKET\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Underlying                  : %s\n', market.equity.name);
    fprintf('Spot/reference              : %.8f\n', market.equity.spot);
    fprintf('Dividend yield              : %.8f%%\n', ...
        100 * market.equity.dividendYield);
    fprintf('Number of strikes           : %d\n', numel(market.equity.strikes));
    fprintf('Min strike                  : %.8f\n', min(market.equity.strikes));
    fprintf('Max strike                  : %.8f\n', max(market.equity.strikes));
    fprintf('Min market vol              : %.8f%%\n', ...
        100 * min(market.equity.volSmile(:)));
    fprintf('Max market vol              : %.8f%%\n', ...
        100 * max(market.equity.volSmile(:)));

    fprintf('\n');

    %% Product

    fprintf('4. PRODUCT\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Principal                   : %.2f\n', product.principal);
    fprintf('Currency                    : %s\n', product.currency);
    fprintf('Start date                  : %s\n', datestr(product.startDate));
    fprintf('End date                    : %s\n', datestr(product.endDate));
    fprintf('Maturity years              : %d\n', product.maturityYears);

    fprintf('\n');

    %% Party A

    fprintf('5. PARTY A - FLOATING LEG\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Payer                       : %s\n', product.partyA.payer);
    fprintf('Receiver                    : %s\n', product.partyA.receiver);
    fprintf('Index                       : %s\n', product.partyA.index);
    fprintf('Spread                      : %.8f%%\n', ...
        100 * product.partyA.spread);
    fprintf('Payment frequency           : quarterly\n');
    fprintf('Payment adjustment          : %s\n', product.partyA.paymentAdjust);
    fprintf('Day count                   : ACT/360, basis %d\n', ...
        product.partyA.dayCount);

    if isfield(product.partyA, 'paymentDates')
        fprintf('Number of payments          : %d\n', ...
            numel(product.partyA.paymentDates));
        fprintf('First payment date          : %s\n', ...
            datestr(product.partyA.paymentDates(1)));
        fprintf('Last payment date           : %s\n', ...
            datestr(product.partyA.paymentDates(end)));
    end

    fprintf('\n');

    %% Party B

    fprintf('6. PARTY B - EQUITY-LINKED LEG\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('Payer                       : %s\n', product.partyB.payer);
    fprintf('Receiver                    : %s\n', product.partyB.receiver);
    fprintf('Pays upfront                : %d\n', product.partyB.paysUpfront);
    fprintf('Upfront symbol              : %s\n', product.partyB.upfrontSymbol);
    fprintf('Payment frequency           : annual\n');
    fprintf('Accrual adjustment          : %s\n', product.partyB.accrualAdjust);
    fprintf('Payment adjustment          : %s\n', product.partyB.paymentAdjust);
    fprintf('Day count                   : 30/360, basis %d\n', product.partyB.dayCount);
    fprintf('Reset lag                   : %d TARGET business days\n', ...
        product.partyB.resetLagBusinessDays);
    fprintf('Underlying                  : %s\n', product.underlying.name);
    fprintf('Strike                      : %.8f\n', product.underlying.strike);

    fprintf('Year 1 coupon               : %.8f%% if Stoxx50 < Strike\n', ...
        100 * product.partyB.coupons.year1.rate);
    fprintf('Year 1 coupon otherwise     : 0.00000000%%\n');
    fprintf('Final coupon                : %.8f%% fixed\n', ...
        100 * product.partyB.coupons.final.rate);

    fprintf('Early redemption active     : %d\n', ...
        product.earlyRedemption.isActive);
    fprintf('Trigger level               : %.8f%%\n', ...
        100 * product.earlyRedemption.triggerLevel);
    fprintf('Redemption price            : %.8f%% of par\n', ...
        100 * product.earlyRedemption.redemptionPrice);

    if isfield(product.partyB, 'paymentDates')
        fprintf('Number of coupons           : %d\n', ...
            numel(product.partyB.paymentDates));

        for iCoupon = 1:numel(product.partyB.paymentDates)
            fprintf('  Coupon %d start date       : %s\n', ...
                iCoupon, datestr(product.partyB.periodStartDates(iCoupon)));
            fprintf('  Coupon %d reset date       : %s\n', ...
                iCoupon, datestr(product.partyB.resetDates(iCoupon)));
            fprintf('  Coupon %d payment date     : %s\n', ...
                iCoupon, datestr(product.partyB.paymentDates(iCoupon)));
            fprintf('  Coupon %d accrual delta    : %.10f\n', ...
                iCoupon, product.partyB.delta(iCoupon));
            fprintf('  Coupon %d payment DF       : %.10f\n', ...
                iCoupon, product.partyB.paymentDiscounts(iCoupon));

            if isfield(product.partyB, 'resetDiscounts')
                fprintf('  Coupon %d reset DF         : %.10f\n', ...
                    iCoupon, product.partyB.resetDiscounts(iCoupon));
            end
        end
    end

    fprintf('\n');

    %% NTS / NIG calibration

    fprintf('7. NTS / NIG CALIBRATION\n');
    fprintf('------------------------------------------------------------\n');

    if ~isfield(market, 'nts')
        fprintf('No NTS calibration found in market.nts.\n');
        fprintf('============================================================\n\n');
        return;
    end

    %fprintf('Model                       : %s\n', market.nts.modelName);
    fprintf('alpha                       : %.8f\n', market.nts.alpha);
    fprintf('Calibration date            : %s\n', ...
        datestr(market.nts.calibrationDate));
    fprintf('Calibration time ACT/365    : %.10f\n', ...
        market.nts.calibrationTime);
    fprintf('Discount factor             : %.10f\n', ...
        market.nts.discountFactor);
    fprintf('Forward                     : %.10f\n', ...
        market.nts.forward);

    if isfield(market.nts, 'discountFactorCheck')
        fprintf('DF check product/curve diff : %.3e\n', ...
            market.nts.discountFactorCheck.absDiff);
        fprintf('DF check tolerance          : %.3e\n', ...
            market.nts.discountFactorCheck.tolerance);
        fprintf('DF check passed             : %d\n', ...
            market.nts.discountFactorCheck.passed);
    end

    fprintf('Initial sigma               : %.10f\n', market.nts.params0(1));
    fprintf('Initial kappa               : %.10f\n', market.nts.params0(2));
    fprintf('Initial eta                 : %.10f\n', market.nts.params0(3));

    fprintf('sigma                       : %.10f\n', market.nts.sigmaOpt);
    fprintf('kappa                       : %.10f\n', market.nts.kappaOpt);
    fprintf('eta                         : %.10f\n', market.nts.etaOpt);
    fprintf('objective value             : %.10e\n', market.nts.objValue);

    fprintf('Number of calibrated strikes: %d\n', numel(market.nts.strikes));

    if isfield(market.nts, 'absError')
        fprintf('Mean abs price error        : %.10e\n', ...
            mean(market.nts.absError));
        fprintf('Max abs price error         : %.10e\n', ...
            max(market.nts.absError));
    end

    if isfield(market.nts, 'marketVols') && isfield(market.nts, 'modelVols')
        volErrors = market.nts.modelVols(:) - market.nts.marketVols(:);

        fprintf('Mean vol error              : %.10e\n', mean(volErrors));
        fprintf('Max abs vol error           : %.10e\n', max(abs(volErrors)));
    end

    fprintf('\n');

    %% Smile check

    if isfield(market.nts, 'strikes') && ...
            isfield(market.nts, 'marketVols') && ...
            isfield(market.nts, 'modelVols')

        fprintf('8. VOL SMILE CHECK\n');
        fprintf('------------------------------------------------------------\n');
        fprintf('%12s %14s %14s %14s\n', ...
            'Strike', 'MarketVol', 'ModelVol', 'Error');

        idxPrint = unique([ ...
            1, ...
            round(numel(market.nts.strikes) / 2), ...
            numel(market.nts.strikes)]);

        for i = idxPrint
            fprintf('%12.4f %13.8f%% %13.8f%% %13.8f%%\n', ...
                market.nts.strikes(i), ...
                100 * market.nts.marketVols(i), ...
                100 * market.nts.modelVols(i), ...
                100 * (market.nts.modelVols(i) - market.nts.marketVols(i)));
        end

        fprintf('\n');
    end

    fprintf('============================================================\n');
    fprintf(' END REPORT\n');
    fprintf('============================================================\n\n');

end