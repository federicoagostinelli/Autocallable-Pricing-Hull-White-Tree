function [St, gammaTime] = simulateVg(market, nSim, rngSeed)
%SIMULATEVG Simulate terminal prices under the Variance Gamma model.
%
%   [St, gammaTime] = simulateVg(market, nSim, rngSeed) simulates nSim
%   terminal prices using the calibrated Variance Gamma parameters stored
%   in the market structure.
%
%   Inputs
%   ------
%   market
%       Market structure containing the Variance Gamma inputs in market.vg.
%       The required fields are:
%           market.vg.forward
%           market.vg.calibrationTime
%           market.vg.sigmaOpt
%           market.vg.kappaOpt
%           market.vg.etaOpt
%
%   nSim
%       Number of Monte Carlo simulations.
%
%   rngSeed
%       Optional random seed used to make the Monte Carlo simulation
%       reproducible.
%
%   Outputs
%   -------
%   St
%       Simulated terminal prices.
%
%   gammaTime
%       Simulated Gamma-distributed market times used as the VG subordinator.

    % Set the random seed for Monte Carlo reproducibility
    if nargin > 2 && ~isempty(rngSeed)
        rng(rngSeed);
    end

    forward = market.vg.forward;
    timeToReset = market.vg.calibrationTime;

    sigma = market.vg.sigmaOpt;
    kappa = market.vg.kappaOpt;
    eta = market.vg.etaOpt;

    % 1. Simulate the market time process, i.e. the Gamma subordinator
    % Under the VG representation, G_t follows a Gamma distribution:
    % G_t ~ Gamma(shape, scale)
    % shape = t / kappa
    % scale = kappa
    shapeParameter = timeToReset / kappa;
    scaleParameter = kappa;

    % Generate nSim random Gamma-distributed market times
    gammaTime = gamrnd(shapeParameter, scaleParameter, [nSim, 1]);

    % 2. Martingale correction for the Variance Gamma model
    % This term is obtained analytically by imposing E[exp(X_t)] = 1
    % It is consistent with charExpVg(-1i) used in calibrateVG
    martingaleCorrection = (timeToReset / kappa) * log(1 + kappa * eta * sigma^2);

    % 3. Generate the directional market shock using a standard Brownian motion
    g = randn(nSim, 1);

    % 4. Build the Normal Mean-Variance Mixture representation of the log-return
    logReturn = martingaleCorrection ...
        + sigma .* sqrt(gammaTime) .* g ...
        - (0.5 + eta) .* sigma.^2 .* gammaTime;

    % 5. Compute the terminal simulated prices
    St = forward .* exp(logReturn);

end