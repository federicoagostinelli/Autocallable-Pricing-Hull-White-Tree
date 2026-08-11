function [DUp, DMid, DDown] = computeHullWhiteExactBranchDiscounts( ...
    xCurrent, xUp, xMid, xDown, treeHullWhite, B0Tree, step)
%COMPUTEHULLWHITEBRANCHDISCOUNTSFROMSLIDE Compute branch-specific HW discounts.
%
%   [DUp, DMid, DDown] =
%       COMPUTEHULLWHITEBRANCHDISCOUNTSFROMSLIDE(
%           xCurrent, xUp, xMid, xDown, treeHullWhite, B0Tree, step)
%
%   computes branch-specific stochastic discount factors between two
%   consecutive tree dates t_i and t_{i+1} using the formula:
%
%       D(t_i,t_{i+1}) / B(t_i,t_{i+1})
%       =
%       exp {
%           - 1/2 * (sigmaStar)^2
%           - sigmaStar * gStar
%       }.
%
%   INPUTS:
%   -------
%   xCurrent
%       OU state values at time t_i.
%
%   xUp, xMid, xDown
%       OU state values reached at time t_{i+1} by the up, middle and down
%       branches.
%
%   treeHullWhite
%       Hull-White tree struct.
%
%       Required fields:
%           a
%           sigma
%           dt
%
%   B0Tree
%       Market discount factors on the artificial tree grid.
%
%       Required convention:
%           B0Tree(step + 1) = P(0,t_i)
%           B0Tree(step + 2) = P(0,t_{i+1})
%
%   step
%       Current tree step using zero-based indexing.
%
%   OUTPUTS:
%   --------
%   DUp, DMid, DDown
%       Branch-specific stochastic discount factors.
%
%   METHOD:
%   -------
%   First, the exact one-step ZCB B(t_i,t_{i+1},x_i) is computed.
%
%   Then, for each branch, the Gaussian shock is recovered from the forward
%   OU discretization:
%
%       x_{i+1} = exp(-a dt) x_i + sigmaHat * g
%
%   equivalently:
%
%       g = (x_{i+1} - exp(-a dt) x_i) / sigmaHat.
%
%   The stochastic discount is then computed as:
%
%       D = B(t_i,t_{i+1}) *
%           exp(-0.5 * sigmaStar^2 - sigmaStar * g).
%

    %% Read Hull-White parameters

    a = treeHullWhite.a;
    sigma = treeHullWhite.sigma;
    dt = treeHullWhite.dt;

    %% Exact one-step ZCB B(t_i,t_{i+1},x_i)

    Btdt = computeHullWhiteOneStepZCB( ...
        xCurrent, ...
        treeHullWhite, ...
        B0Tree, ...
        step ...
    );

    %% OU one-step volatility sigmaHat

    sigmaHat = sigma * sqrt( ...
        (1 - exp(-2 * a * dt)) / (2 * a) ...
    );

    %% Discount volatility sigmaStar

    sigmaStarSquared = (sigma^2 / a^2) * ( ...
        dt ...
        - 2 * (1 - exp(-a * dt)) / a ...
        + (1 - exp(-2 * a * dt)) / (2 * a) ...
    );

    sigmaStar = sqrt(sigmaStarSquared);

    %% Recover branch Gaussian shocks

    expMinusAdt = exp(-a * dt);

    gUp = (xUp - expMinusAdt .* xCurrent) ./ sigmaHat;
    gMid = (xMid - expMinusAdt .* xCurrent) ./ sigmaHat;
    gDown = (xDown - expMinusAdt .* xCurrent) ./ sigmaHat;

    %% Stochastic discount ratios 
    ratioUp = exp( ...
        -0.5 * sigmaStarSquared ...
        -sigmaStar .* gUp ...
    );

    ratioMid = exp( ...
        -0.5 * sigmaStarSquared ...
        -sigmaStar .* gMid ...
    );

    ratioDown = exp( ...
        -0.5 * sigmaStarSquared ...
        -sigmaStar .* gDown ...
    );

    %% Branch-specific stochastic discount factors

    DUp = Btdt .* ratioUp;
    DMid = Btdt .* ratioMid;
    DDown = Btdt .* ratioDown;

end