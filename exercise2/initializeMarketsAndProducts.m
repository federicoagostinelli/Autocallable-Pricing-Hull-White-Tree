function [baseMarket, productContract, product, settings] = initializeMarketsAndProducts()
%INITIALIZEMARKETSANDPRODUCTS Initialize common market data, products and settings.

    %% Common files

    curveFile = 'MktData_CurveBootstrap.xls';
    curveDateFormat = 'dd-mmm-yy';
    eurostoxxDataFile = "eurostoxx_Poli.mat";

    %% Simulation settings

    settings = struct();

    settings.nSim = 1e6;
    settings.rngSeed = 1;

    %% Hull-White settings for Exercise 2

    settings.hullWhite = struct();
    settings.hullWhite.a = 0.11;
    settings.hullWhite.sigma = 0.008;
    settings.hullWhite.nStepsPerYear = 365;

    %% Read and bootstrap the discount curve

    [curveDatesSet, curveRatesSet] = readExcelData( ...
        curveFile, ...
        curveDateFormat);

    [curveDates, curveDiscounts, curveZeroRates] = bootstrap( ...
        curveDatesSet, ...
        curveRatesSet);

    %% Base market initialization

    baseMarket = initializeMarket( ...
        curveDates, ...
        curveDiscounts, ...
        curveZeroRates, ...
        eurostoxxDataFile);

    %% Base 2Y product initialization

    productContract = initializeProduct( ...
        baseMarket);

    product = prepareProductForPricing( ...
        productContract, ...
        baseMarket);

end