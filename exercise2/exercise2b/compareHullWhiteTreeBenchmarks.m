function comparison = compareHullWhiteTreeBenchmarks( ...
    treeHullWhite, probabilities, Bermudan, TFixed, deltaFixed, ...
    B0Tree, B0Payments, zcbMaturities, europeanExpiry)
%COMPAREHULLWHITETREEBENCHMARKS Compare HW tree prices with benchmarks.
%
%   comparison = COMPAREHULLWHITETREEBENCHMARKS(
%       treeHullWhite, probabilities, Bermudan,
%       TFixed, deltaFixed, B0Tree, B0Payments,
%       zcbMaturities, europeanExpiry)
%
%   performs two validation checks:
%
%       1. ZCB prices by backward induction vs market discount factors.
%
%       2. European payer swaption prices:
%              analytical Hull-White price
%              vs
%              tree price obtained by using BermudanSwaptionTreePricer
%              with one single exercise date.
%
%   INPUTS:
%   -------
%   treeHullWhite
%       Hull-White tree struct.
%
%   probabilities
%       Hull-White transition probabilities.
%
%   Bermudan
%       Original Bermudan contract struct.
%
%   TFixed
%       Fixed-leg payment times of the underlying swap.
%
%   deltaFixed
%       Fixed-leg accrual factors.
%
%   B0Tree
%       Market discount factors on the artificial tree grid.
%
%   B0Payments
%       Market discount factors on the underlying swap payment dates.
%
%   zcbMaturities
%       Vector of ZCB maturities to test.
%
%   europeanExpiry
%       Vector of European swaption expiries to test.
%
%       Each expiry generates a different European payer swaption with one
%       single exercise date. The underlying swap cash flows are selected as
%       the payments with:
%
%           TFixed > expiry.
%
%   OUTPUT:
%   -------
%   comparison
%       Struct with two tables:
%
%           comparison.zcb
%           comparison.europeanSwaption

    %% ================================================================
    %  1. ZCB checks
    % ================================================================

    zcbMaturities = zcbMaturities(:);
    nZCB = numel(zcbMaturities);

    zcbTreePrices = NaN(nZCB, 1);
    zcbMarketPrices = NaN(nZCB, 1);
    zcbAbsErrors = NaN(nZCB, 1);
    zcbRelErrors = NaN(nZCB, 1);
    zcbSteps = NaN(nZCB, 1);

    for iZCB = 1:nZCB

        maturity = zcbMaturities(iZCB);

        maturityStep = round(maturity / treeHullWhite.dt);
        maturityOnGrid = maturityStep * treeHullWhite.dt;

        if maturityStep < 0 || maturityStep > treeHullWhite.totalSteps
            warning("ZCB maturity %.8f is outside the tree horizon. Skipping.", maturity);
            continue;
        end

        if abs(maturityOnGrid - maturity) > 1e-10
            warning( ...
                "ZCB maturity %.8f is not exactly on the tree grid. Using nearest tree time %.8f.", ...
                maturity, ...
                maturityOnGrid ...
            );
        end

        zcbSteps(iZCB) = maturityStep;

        [zcbTreePrices(iZCB), zcbMarketPrices(iZCB), ...
            zcbAbsErrors(iZCB), zcbRelErrors(iZCB)] = ...
            priceZCBByHullWhiteTree( ...
                treeHullWhite, ...
                probabilities, ...
                B0Tree, ...
                maturityOnGrid ...
            );

    end

    comparison = struct();

    comparison.zcb = table( ...
        zcbMaturities, ...
        zcbSteps, ...
        zcbTreePrices, ...
        zcbMarketPrices, ...
        zcbAbsErrors, ...
        zcbRelErrors, ...
        'VariableNames', ...
        {'Maturity', 'MaturityStep', 'TreePrice', ...
         'MarketPrice', 'AbsError', 'RelError'} ...
    );

    %% ================================================================
    %  2. European swaption checks for multiple expiries
    % ================================================================

    europeanExpiries = europeanExpiry(:);
    nExpiries = numel(europeanExpiries);

    swaptionTreePrices = NaN(nExpiries, 1);
    swaptionAnalyticPrices = NaN(nExpiries, 1);
    swaptionAbsErrors = NaN(nExpiries, 1);
    swaptionRelErrors = NaN(nExpiries, 1);
    expirySteps = NaN(nExpiries, 1);
    expiryOnGridValues = NaN(nExpiries, 1);
    numRemainingPayments = zeros(nExpiries, 1);

    for iExpiry = 1:nExpiries

        expiry = europeanExpiries(iExpiry);

        %% Map expiry to tree step

        expiryStep = round(expiry / treeHullWhite.dt);
        expiryOnGrid = expiryStep * treeHullWhite.dt;

        if expiryStep < 0 || expiryStep > treeHullWhite.totalSteps
            warning("European expiry %.8f is outside the tree horizon. Skipping.", expiry);
            continue;
        end

        if abs(expiryOnGrid - expiry) > 1e-10
            warning( ...
                "European expiry %.8f is not exactly on the tree grid. Using nearest tree time %.8f.", ...
                expiry, ...
                expiryOnGrid ...
            );
        end

        expirySteps(iExpiry) = expiryStep;
        expiryOnGridValues(iExpiry) = expiryOnGrid;

        %% Check remaining swap payments

        remainingIndex = TFixed > expiryOnGrid + 1e-10;
        numRemainingPayments(iExpiry) = sum(remainingIndex);

        if numRemainingPayments(iExpiry) == 0
            warning("European expiry %.8f has no remaining swap payments. Skipping.", expiry);
            continue;
        end

        %% Allocate European option as Bermudan with one exercise date

        EuropeanOption = Bermudan;
        EuropeanOption.exerciseTimes = expiryOnGrid;
        EuropeanOption.nonCallYears = expiryOnGrid;

        %% Tree price using Bermudan pricer with one exercise date

        swaptionTreePrices(iExpiry) = bermudanSwaptionTreePricer( ...
            treeHullWhite, ...
            probabilities, ...
            EuropeanOption, ...
            TFixed, ...
            deltaFixed, ...
            B0Tree, ...
            B0Payments ...
        );

        %% Analytical Hull-White European swaption price

        B0Expiry = B0Tree(expiryStep + 1);

        swaptionAnalyticPrices(iExpiry) = priceEuropeanPayerSwaptionHullWhiteAnalytic( ...
            treeHullWhite, ...
            expiryOnGrid, ...
            TFixed, ...
            deltaFixed, ...
            Bermudan.K, ...
            B0Expiry, ...
            B0Payments ...
        );

        %% Errors

        swaptionAbsErrors(iExpiry) = abs(...
            swaptionTreePrices(iExpiry) - swaptionAnalyticPrices(iExpiry));

        if abs(swaptionAnalyticPrices(iExpiry)) > 1e-14
            swaptionRelErrors(iExpiry) = ...
                swaptionAbsErrors(iExpiry) / swaptionAnalyticPrices(iExpiry);
        else
            swaptionRelErrors(iExpiry) = NaN;
        end

    end

    comparison.europeanSwaption = table( ...
        europeanExpiries, ...
        expiryOnGridValues, ...
        expirySteps, ...
        numRemainingPayments, ...
        swaptionTreePrices, ...
        swaptionAnalyticPrices, ...
        swaptionAbsErrors, ...
        swaptionRelErrors, ...
        'VariableNames', ...
        {'Expiry', 'ExpiryOnGrid', 'ExpiryStep', 'NumRemainingPayments', ...
         'TreePrice', 'AnalyticPrice', 'AbsError', 'RelError'} ...
    );

    %% ================================================================
    %  3. Print summary
    % ================================================================

    fprintf("\n============================================================\n");
    fprintf(" Hull-White tree validation benchmarks\n");
    fprintf("============================================================\n");

    fprintf("\nZCB benchmark:\n");
    disp(comparison.zcb);

    fprintf("\nEuropean payer swaption benchmark:\n");
    disp(comparison.europeanSwaption);

    fprintf("============================================================\n\n");

end