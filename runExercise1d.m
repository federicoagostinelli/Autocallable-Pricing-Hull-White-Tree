function results = runExercise1d(baseMarket, productContract, results1a, settings)
%RUNEXERCISE1D Price the modified 3Y product under the same NIG parameters.

    nSim = settings.nSim;
    rngSeed = settings.rngSeed;

    %% Extend product and market to 3 years

    marketModified3Y = baseMarket;

    productContract3Y = productContract;

    [marketModified3Y, productContract3Y] = extendMarketAndProductToThreeYears( ...
        marketModified3Y, ...
        productContract3Y);

    product3Y = prepareProductForPricing( ...
        productContract3Y, ...
        marketModified3Y);

    %% Reuse NIG parameters calibrated in Exercise 1.a

    marketModified3Y.nts = results1a.marketNIG.nts;
    marketModified3Y.nts.alpha = 1 / 2;
    marketModified3Y.nts.modelName = 'NIG';

    %% Simulate and price

    marketModified3Y.simulation = simulateTwoYearEarlyRedemptionEvent( ...
        product3Y, ...
        marketModified3Y, ...
        nSim, ...
        rngSeed);

    marketModified3Y.simulation.modelName = "NIG";

    [upfront3Y, mtmA_3Y, legA_3Y, legB_3Y] = computeUpfront( ...
        marketModified3Y, ...
        product3Y);

    printPricingReport( ...
        marketModified3Y, ...
        product3Y, ...
        upfront3Y, ...
        mtmA_3Y, ...
        legA_3Y, ...
        legB_3Y);

    

    %% Store results

    results = struct();

    results.market = marketModified3Y;
    results.product = product3Y;
    results.upfront = upfront3Y;
    results.mtmA = mtmA_3Y;
    results.legA = legA_3Y;
    results.legB = legB_3Y;

end