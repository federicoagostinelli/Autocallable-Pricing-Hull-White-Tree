function [zcbTreePrice, zcbMarketPrice, absError, relError] = ...
    priceZCBByHullWhiteTree(treeHullWhite, probabilities, B0Tree, maturityTime)
%PRICEZCBBYHULLWHITETREE Price a ZCB by Hull-White tree backward induction.
%
%   [zcbTreePrice, zcbMarketPrice, absError, relError] =
%       PRICEZCBBYHULLWHITETREE(treeHullWhite, probabilities, B0Tree, maturityTime)
%
%   prices a zero-coupon bond paying 1 at maturityTime using backward
%   induction on the Hull-White tree.
%
%   INPUTS:
%   -------
%   treeHullWhite
%       Hull-White tree struct.
%
%   probabilities
%       Struct with fields pu, pm, pd.
%
%   B0Tree
%       Market discount factors on the artificial tree grid.
%
%   maturityTime
%       ZCB maturity in ACT/365 model years.
%
%   OUTPUTS:
%   --------
%   zcbTreePrice
%       ZCB price obtained by backward induction.
%
%   zcbMarketPrice
%       Market discount factor on the tree grid at maturityTime.
%
%   absError
%       zcbTreePrice - zcbMarketPrice.
%
%   relError
%       absError / zcbMarketPrice.

    %% Read tree quantities

    dt = treeHullWhite.dt;
    lMax = treeHullWhite.lMax;
    xVector = treeHullWhite.xVector(:);
    numNodes = treeHullWhite.numNodes;

    pu = probabilities.pu(:);
    pm = probabilities.pm(:);
    pd = probabilities.pd(:);

    %% Maturity step

    maturityStep = round(maturityTime / dt);

    if maturityStep < 0 || maturityStep > treeHullWhite.totalSteps
        error("maturityTime is outside the tree horizon.");
    end

    if abs(maturityStep * dt - maturityTime) > 1e-10
        warning("maturityTime is not exactly on the tree grid. Rounded to nearest step.");
    end

    if numel(B0Tree) < maturityStep + 1
        error("B0Tree does not contain enough discount factors.");
    end

    %% Branch indexing

    idxUp = [(2:numNodes)'; numNodes];
    idxMid = (1:numNodes)';
    idxDown = [1; (1:numNodes-1)'];

    idxUp(1) = 3;
    idxMid(1) = 2;
    idxDown(1) = 1;

    idxUp(end) = numNodes;
    idxMid(end) = numNodes - 1;
    idxDown(end) = numNodes - 2;

    %% Terminal payoff

    V = ones(numNodes, 1);

    %% Backward induction

    for step = (maturityStep - 1):-1:0

        [DUp, DMid, DDown] = computeHullWhiteExactBranchDiscounts( ...
            xVector, ...
            xVector(idxUp), ...
            xVector(idxMid), ...
            xVector(idxDown), ...
            treeHullWhite, ...
            B0Tree, ...
            step ...
        );

        V = ...
            pu .* DUp   .* V(idxUp) + ...
            pm .* DMid  .* V(idxMid) + ...
            pd .* DDown .* V(idxDown);

    end

    %% Time-zero value

    middleIndex = lMax + 1;

    zcbTreePrice = V(middleIndex);
    zcbMarketPrice = B0Tree(maturityStep + 1);

    absError = abs(zcbTreePrice - zcbMarketPrice);
    relError = absError / zcbMarketPrice;

end