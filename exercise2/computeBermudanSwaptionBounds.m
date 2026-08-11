function bounds = computeBermudanSwaptionBounds( ...
    market, treeHullWhite, Bermudan, TFixed, deltaFixed, ...
    B0Tree, B0Payments, bermudanSwaptionPrice)
%COMPUTEBERMUDANSWAPTIONBOUNDS Compute bounds for a Bermudan payer swaption.
%
%   bounds = COMPUTEBERMUDANSWAPTIONBOUNDS(
%       market, treeHullWhite, Bermudan, TFixed, deltaFixed,
%       B0Tree, B0Payments, bermudanSwaptionPrice)
%
%   computes:
%
%       1. Lower bound:
%
%              max_i European payer swaption(expiry_i)
%
%       2. Upper bound by cap:
%
%              sum of caplets on the underlying swap periods,
%              starting from the first exercise date.
%
%       3. Upper bound by Jamshidian:
%
%              sum_i European payer swaption(expiry_i)
%
%          where each European swaption is priced analytically with the
%          Hull-White / Jamshidian formula.
%
%   The tighter upper bound is:
%
%       upperBoundTight = min(upperBoundCap, upperBoundJamshidian)

    %% Read basic quantities

    a = treeHullWhite.a;
    sigma = treeHullWhite.sigma;
    dt = treeHullWhite.dt;
    totalSteps = treeHullWhite.totalSteps;

    K = Bermudan.K;

    TFixed = TFixed(:);
    deltaFixed = deltaFixed(:);
    B0Payments = B0Payments(:);

    if numel(TFixed) ~= numel(deltaFixed) || numel(TFixed) ~= numel(B0Payments)
        error("TFixed, deltaFixed and B0Payments must have the same length.");
    end

    exerciseTimes = Bermudan.exerciseTimes(:);

    %% ================================================================
    %  1. European swaptions on all Bermudan exercise dates
    % ================================================================
    %
    % These prices are used both for:
    %
    %   lower bound = max European;
    %   Jamshidian upper bound = sum Europeans.

    nExercise = numel(exerciseTimes);

    europeanTreeTimes = NaN(nExercise, 1);
    europeanSteps = NaN(nExercise, 1);
    europeanPrices = NaN(nExercise, 1);
    numRemainingPayments = zeros(nExercise, 1);

    for iExercise = 1:nExercise

        expiry = exerciseTimes(iExercise);

        expiryStep = round(expiry / dt);
        expiryOnGrid = expiryStep * dt;

        if expiryStep < 0 || expiryStep > totalSteps
            warning("Exercise time %.8f is outside the tree horizon. Skipping.", expiry);
            continue;
        end

        if abs(expiryOnGrid - expiry) > 1e-10
            warning( ...
                "Exercise time %.8f is not exactly on the tree grid. Using nearest tree time %.8f.", ...
                expiry, ...
                expiryOnGrid ...
            );
        end

        remainingIndex = TFixed > expiryOnGrid + 1e-10;
        numRemainingPayments(iExercise) = sum(remainingIndex);

        if numRemainingPayments(iExercise) == 0
            warning("Exercise time %.8f has no remaining payments. Skipping.", expiryOnGrid);
            continue;
        end

        B0Expiry = B0Tree(expiryStep + 1);

        europeanPrices(iExercise) = priceEuropeanPayerSwaptionHullWhiteAnalytic( ...
            treeHullWhite, ...
            expiryOnGrid, ...
            TFixed, ...
            deltaFixed, ...
            K, ...
            B0Expiry, ...
            B0Payments ...
        );

        europeanTreeTimes(iExercise) = expiryOnGrid;
        europeanSteps(iExercise) = expiryStep;

    end

    if all(isnan(europeanPrices))
        error("No valid European swaption candidate could be priced.");
    end

    europeanSwaptionTable = table( ...
        exerciseTimes, ...
        europeanTreeTimes, ...
        europeanSteps, ...
        numRemainingPayments, ...
        europeanPrices, ...
        'VariableNames', ...
        {'ExerciseTime', 'ExerciseTimeOnGrid', 'ExerciseStep', ...
         'NumRemainingPayments', 'EuropeanPrice'} ...
    );

    %% ================================================================
    %  2. Lower bound: maximum European payer swaption
    % ================================================================

    [lowerBound, bestIndex] = max(europeanPrices, [], 'omitnan');

    bestEuropeanExpiry = europeanTreeTimes(bestIndex);

    %% ================================================================
    %  3. Jamshidian upper bound: sum of European swaptions
    % ================================================================
    %
    % Since:
    %
    %   max_i payoff_i <= sum_i payoff_i
    %
    % the Bermudan value is bounded above by the sum of the European
    % swaptions exercisable on each Bermudan exercise date.
    %
    % Each European swaption has already been priced with the analytical
    % Hull-White / Jamshidian formula.

    upperBoundJamshidian = sum(europeanPrices, 'omitnan');

    %% ================================================================
    %  4. Cap upper bound
    % ================================================================
    %
    % The cap upper bound starts from the first valid Bermudan exercise
    % date, not from the best European expiry.
    %
    % Caplet on [T_{i-1}, T_i]:
    %
    %   delta_i * max(L_i - K, 0)
    %
    % is equivalent to:
    %
    %   (1 + delta_i K) * PutZCB(T_{i-1}, T_i, X_i)
    %
    % with:
    %
    %   X_i = 1 / (1 + delta_i K)

    validExerciseTimesOnGrid = europeanTreeTimes(~isnan(europeanTreeTimes));

    if isempty(validExerciseTimesOnGrid)
        error("No valid exercise time available to build the cap upper bound.");
    end

    firstCapStart = min(validExerciseTimesOnGrid);

    capletIndex = TFixed > firstCapStart + 1e-10;

    TCapEnd = TFixed(capletIndex);
    deltaCap = deltaFixed(capletIndex);
    B0CapEnd = B0Payments(capletIndex);

    if isempty(TCapEnd)

        upperBoundCap = NaN;
        capletTable = table();

    else

        TCapStart = [firstCapStart; TCapEnd(1:end-1)];

        %% Market discount factors P(0,TCapStart)

        refDate = ensureDatetime(market.dateInfo.refDate);
        curveDates = ensureDatetime(market.dates);
        curveDiscounts = market.discounts;

        capStartDates = refDate + days(365 * TCapStart);

        B0CapStart = getDiscountFactorByZeroRatesLinearInterp( ...
            refDate, ...
            capStartDates, ...
            curveDates, ...
            curveDiscounts ...
        );

        B0CapStart = B0CapStart(:);

        %% Caplet strikes as ZCB put strikes

        capletZCBStrikes = 1 ./ (1 + deltaCap .* K);

        %% ZCB puts under Hull-White

        capletZCBPuts = priceHullWhiteZCBPutOption( ...
            a, ...
            sigma, ...
            TCapStart, ...
            TCapEnd, ...
            capletZCBStrikes, ...
            B0CapStart, ...
            B0CapEnd ...
        );

        %% Caplet prices and cap upper bound

        capletPrices = (1 + deltaCap .* K) .* capletZCBPuts;

        upperBoundCap = sum(capletPrices);

        capletTable = table( ...
            TCapStart, ...
            TCapEnd, ...
            deltaCap, ...
            capletZCBStrikes, ...
            B0CapStart, ...
            B0CapEnd, ...
            capletZCBPuts, ...
            capletPrices, ...
            'VariableNames', ...
            {'StartTime', 'EndTime', 'Delta', 'ZCBStrike', ...
             'B0Start', 'B0End', 'ZCBPutPrice', 'CapletPrice'} ...
        );

    end

    %% ================================================================
    %  5. Tighter upper bound
    % ================================================================

    upperCandidates = [upperBoundCap; upperBoundJamshidian];

    upperBoundTight = min(upperCandidates, [], 'omitnan');

    %% ================================================================
    %  6. Store output
    % ================================================================

    bounds = struct();

    bounds.lowerBound = lowerBound;
    bounds.lowerBoundBestExpiry = bestEuropeanExpiry;

    bounds.europeanSwaptionTable = europeanSwaptionTable;

    % Backward compatibility with old field name.
    bounds.lowerBoundTable = europeanSwaptionTable;

    bounds.upperBoundCap = upperBoundCap;
    bounds.upperBoundCapStart = firstCapStart;
    bounds.capletTable = capletTable;

    bounds.upperBoundJamshidian = upperBoundJamshidian;

    bounds.upperBoundTight = upperBoundTight;

    % Backward compatibility with old field name.
    bounds.upperBound = upperBoundTight;

    bounds.bermudanSwaptionPrice = bermudanSwaptionPrice;

    bounds.check = struct();

    bounds.check.lowerMinusTree = ...
        lowerBound - bermudanSwaptionPrice;

    bounds.check.treeMinusUpperCap = ...
        bermudanSwaptionPrice - upperBoundCap;

    bounds.check.treeMinusUpperJamshidian = ...
        bermudanSwaptionPrice - upperBoundJamshidian;

    bounds.check.treeMinusUpperTight = ...
        bermudanSwaptionPrice - upperBoundTight;

    %% ================================================================
    %  7. Print summary
    % ================================================================

    fprintf("\n============================================================\n");
    fprintf(" Bermudan swaption bounds check\n");
    fprintf("============================================================\n");

    fprintf("\nEuropean swaption candidates priced by Jamshidian:\n");
    disp(europeanSwaptionTable);

    fprintf("\nLower bound\n");
    fprintf("Best European expiry             : %.8f\n", bestEuropeanExpiry);
    fprintf("Lower bound max European          : %.12f\n", lowerBound);

    fprintf("\nUpper bounds\n");
    fprintf("Cap upper bound start             : %.8f\n", firstCapStart);
    fprintf("Upper bound cap                   : %.12f\n", upperBoundCap);
    fprintf("Upper bound Jamshidian sum Euro   : %.12f\n", upperBoundJamshidian);
    fprintf("Upper bound tight min             : %.12f\n", upperBoundTight);

    fprintf("\nTree price\n");
    fprintf("Tree Bermudan price               : %.12f\n", bermudanSwaptionPrice);

    fprintf("\nChecks\n");
    fprintf("Lower bound - tree price          : %.12e\n", ...
        bounds.check.lowerMinusTree);
    fprintf("Tree price - upper bound cap      : %.12e\n", ...
        bounds.check.treeMinusUpperCap);
    fprintf("Tree price - upper bound Jamsh.   : %.12e\n", ...
        bounds.check.treeMinusUpperJamshidian);
    fprintf("Tree price - upper bound tight    : %.12e\n", ...
        bounds.check.treeMinusUpperTight);

    if bounds.check.lowerMinusTree > 1e-8
        warning("Lower bound is above the Bermudan tree price.");
    end

    if bounds.check.treeMinusUpperCap > 1e-8
        warning("Bermudan tree price is above the cap upper bound.");
    end

    if bounds.check.treeMinusUpperJamshidian > 1e-8
        warning("Bermudan tree price is above the Jamshidian upper bound.");
    end

    if bounds.check.treeMinusUpperTight > 1e-8
        warning("Bermudan tree price is above the tight upper bound.");
    end

    fprintf("============================================================\n\n");

end