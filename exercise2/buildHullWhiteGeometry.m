function geometry = buildHullWhiteGeometry(a, sigma, nStepsPerYear)
%BUILDHULLWHITEGEOMETRY Compute Hull-White trinomial tree geometry.
%
% INPUTS:
%   a              - Hull-White mean-reversion parameter.
%   sigma          - Hull-White volatility parameter.
%   nStepsPerYear  - Number of time steps per year.
%
% OUTPUT:
%   geometry       - Struct containing Hull-White discretization quantities.

    dt = 1 / nStepsPerYear;

    muHat = 1 - exp(-a * dt);

    sigmaHat = sigma * sqrt( ...
        (1 - exp(-2 * a * dt)) / (2 * a) ...
    );

    dx = sqrt(3) * sigmaHat;

    lowerBound = (1 - sqrt(2/3)) / muHat;
    upperBound = sqrt(2/3) / muHat;

    lMax = floor(lowerBound) + 1;

    if lMax >= upperBound
        error(['Invalid Hull-White tree geometry: lMax does not satisfy ', ...
               '1 - sqrt(2/3) < lMax * muHat < sqrt(2/3).']);
    end

    geometry = struct();

    geometry.dt = dt;
    geometry.muHat = muHat;
    geometry.sigmaHat = sigmaHat;
    geometry.dx = dx;
    geometry.lMax = lMax;

    geometry.lowerBound = lowerBound;
    geometry.upperBound = upperBound;

end