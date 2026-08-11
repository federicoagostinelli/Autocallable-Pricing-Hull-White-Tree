function diagnostics = checkHullWhiteTreeProbabilitiesAndMoments(treeHullWhite, probabilities)
%CHECKHULLWHITETREEPROBABILITIESANDMOMENTS Check HW tree probabilities and OU moments.
%
%   diagnostics = CHECKHULLWHITETREEPROBABILITIESANDMOMENTS(treeHullWhite, probabilities)
%   checks:
%
%       1. transition probabilities sum to one;
%       2. transition probabilities are non-negative;
%       3. the propagated tree distribution reproduces the OU mean and
%          variance approximately.
%
%   INPUTS:
%   -------
%   treeHullWhite
%       Hull-White tree struct.
%
%       Required fields:
%           a
%           sigma
%           dt
%           lMax
%           xVector
%           totalSteps
%           numNodes
%
%   probabilities
%       Struct with fields:
%           pu
%           pm
%           pd
%
%   OUTPUT:
%   -------
%   diagnostics
%       Struct containing probability diagnostics and moment errors.

    %% Read tree quantities

    a = treeHullWhite.a;
    sigma = treeHullWhite.sigma;
    dt = treeHullWhite.dt;
    lMax = treeHullWhite.lMax;
    xVector = treeHullWhite.xVector(:);
    totalSteps = treeHullWhite.totalSteps;
    numNodes = treeHullWhite.numNodes;

    pu = probabilities.pu(:);
    pm = probabilities.pm(:);
    pd = probabilities.pd(:);

    %% Probability checks

    probSum = pu + pm + pd;

    diagnostics = struct();

    diagnostics.maxProbabilitySumError = max(abs(probSum - 1));
    diagnostics.minPu = min(pu);
    diagnostics.minPm = min(pm);
    diagnostics.minPd = min(pd);
    diagnostics.minProbability = min([pu; pm; pd]);

    %% Branch indexing
    %
    % levelVector = [-lMax, ..., 0, ..., +lMax]'
    %
    % Internal nodes:
    %   up   -> j + 1
    %   mid  -> j
    %   down -> j - 1

    idxUp = [(2:numNodes)'; numNodes];
    idxMid = (1:numNodes)';
    idxDown = [1; (1:numNodes-1)'];

    % Bottom boundary, Case B.
    idxUp(1) = 3;
    idxMid(1) = 2;
    idxDown(1) = 1;

    % Top boundary, Case C.
    idxUp(end) = numNodes;
    idxMid(end) = numNodes - 1;
    idxDown(end) = numNodes - 2;

    %% Forward propagation of node probabilities

    middleIndex = lMax + 1;

    nodeProb = zeros(numNodes, 1);
    nodeProb(middleIndex) = 1;

    timeGrid = (0:totalSteps)' * dt;

    meanTree = zeros(totalSteps + 1, 1);
    varTree = zeros(totalSteps + 1, 1);
    meanExact = zeros(totalSteps + 1, 1);
    varExact = zeros(totalSteps + 1, 1);

    meanTree(1) = sum(nodeProb .* xVector);
    varTree(1) = sum(nodeProb .* xVector.^2) - meanTree(1)^2;

    meanExact(1) = 0;
    varExact(1) = 0;

    for step = 1:totalSteps

        nextProb = zeros(numNodes, 1);

        for j = 1:numNodes
            nextProb(idxUp(j)) = nextProb(idxUp(j)) + nodeProb(j) * pu(j);
            nextProb(idxMid(j)) = nextProb(idxMid(j)) + nodeProb(j) * pm(j);
            nextProb(idxDown(j)) = nextProb(idxDown(j)) + nodeProb(j) * pd(j);
        end

        nodeProb = nextProb;

        t = timeGrid(step + 1);

        meanTree(step + 1) = sum(nodeProb .* xVector);
        varTree(step + 1) = sum(nodeProb .* xVector.^2) - meanTree(step + 1)^2;

        meanExact(step + 1) = 0;
        varExact(step + 1) = sigma^2 / (2 * a) * (1 - exp(-2 * a * t));

    end

    diagnostics.timeGrid = timeGrid;

    diagnostics.meanTree = meanTree;
    diagnostics.meanExact = meanExact;
    diagnostics.meanError = meanTree - meanExact;
    diagnostics.maxAbsMeanError = max(abs(diagnostics.meanError));

    diagnostics.varTree = varTree;
    diagnostics.varExact = varExact;
    diagnostics.varError = varTree - varExact;
    diagnostics.maxAbsVarianceError = max(abs(diagnostics.varError));

    diagnostics.finalProbabilityMass = sum(nodeProb);
    diagnostics.finalProbabilityMassError = abs(sum(nodeProb) - 1);

    %% Print summary

    fprintf("\n============================================================\n");
    fprintf(" Hull-White tree probability and moment diagnostics\n");
    fprintf("============================================================\n");
    fprintf("Max |pu + pm + pd - 1| : %.16e\n", diagnostics.maxProbabilitySumError);
    fprintf("Min probability         : %.16e\n", diagnostics.minProbability);
    fprintf("Final probability mass  : %.16e\n", diagnostics.finalProbabilityMass);
    fprintf("Max |mean error|        : %.16e\n", diagnostics.maxAbsMeanError);
    fprintf("Max |variance error|    : %.16e\n", diagnostics.maxAbsVarianceError);
    fprintf("============================================================\n\n");

end