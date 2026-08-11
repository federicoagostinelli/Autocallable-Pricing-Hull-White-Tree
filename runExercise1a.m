function results = runExercise1a(baseMarket, product, settings)
%RUNEXERCISE1A Price the base product under the NIG model.

    nSim = settings.nSim;
    rngSeed = settings.rngSeed;

    %% NIG calibration

    marketNIG = baseMarket;

    marketNIG = calibrateNts( ...
        marketNIG, ...
        product);

    marketNIG.nts.alpha = 1 / 2;
    marketNIG.nts.modelName = 'NIG';

    printInitializationReport( ...
        marketNIG, ...
        product);

    %% NIG simulation and pricing

    marketNIG.simulation = simulateEarlyRedemptionEvent( ...
        product, ...
        marketNIG, ...
        nSim, ...
        rngSeed);

    marketNIG.simulation.modelName = "NIG";

    [upfrontNIG, mtmA_NIG, legA_NIG, legB_NIG] = computeUpfront( ...
        marketNIG, ...
        product);

    printPricingReport( ...
        marketNIG, ...
        product, ...
        upfrontNIG, ...
        mtmA_NIG, ...
        legA_NIG, ...
        legB_NIG);

    %% Store results

    results = struct();

    results.marketNIG = marketNIG;
    results.upfrontNIG = upfrontNIG;
    results.mtmA_NIG = mtmA_NIG;
    results.legA_NIG = legA_NIG;
    results.legB_NIG = legB_NIG;

end