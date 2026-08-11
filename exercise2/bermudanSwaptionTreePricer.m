function price = bermudanSwaptionTreePricer(treeHullWhite, probabilities, Bermudan, ...
    TFixed, deltaFixed, B0Tree, B0Payments)
%BERMUDANSWAPTIONTREEPRICER Price a Bermudan payer swaption on a Hull-White tree.
%
%   price = bermudanSwaptionTreePricer(treeHullWhite, probabilities,
%       Bermudan, TFixed, deltaFixed, B0Tree, B0Payments)
%
%   prices a Bermudan payer swaption by backward induction on a
%   Hull-White trinomial tree.
%
%   Time convention
%   ---------------
%   The function distinguishes:
%
%       tModel
%           Time of the tree layer:
%
%               tModel = step * treeHullWhite.dt
%
%       tExercise
%           True contractual exercise time, obtained from:
%
%               Bermudan.exerciseTimes
%
%   Exercise is allowed only at tree layers associated with contractual
%   exercise times. If the contractual time is not exactly on the tree grid,
%   the function maps it to the nearest tree step and issues a warning.
%
%   For exact contractual exercise, use a tree grid such that:
%
%       Bermudan.exerciseTimes(i) / treeHullWhite.dt
%
%   is integer for every exercise date. With ACT/365 times, this is achieved
%   by using:
%
%       nStepsPerYear = 365.
%
%   Discounting convention
%   ----------------------
%   Continuation values use the model time grid and one-step stochastic
%   discounts between adjacent tree layers.
%
%   Immediate exercise values use the true contractual exercise time
%   tExercise and the contractual payment times TFixed.

    %% Read Hull-White tree quantities

    dt = treeHullWhite.dt;
    lMax = treeHullWhite.lMax;
    xVector = treeHullWhite.xVector;
    totalSteps = treeHullWhite.totalSteps;
    numNodes = treeHullWhite.numNodes;

    K = Bermudan.K;

    pu = probabilities.pu;
    pm = probabilities.pm;
    pd = probabilities.pd;

    %% Defensive checks

    if numel(B0Tree) < totalSteps + 1
        error("B0Tree must contain totalSteps + 1 discount factors.");
    end

    if numel(B0Payments) ~= numel(TFixed)
        error("B0Payments and TFixed must have the same length.");
    end

    if numel(deltaFixed) ~= numel(TFixed)
        error("deltaFixed and TFixed must have the same length.");
    end

    if numel(pu) ~= numNodes || numel(pm) ~= numNodes || numel(pd) ~= numNodes
        error("Probability vectors must have length treeHullWhite.numNodes.");
    end

    if ~isfield(Bermudan, "exerciseTimes")
        error("Bermudan.exerciseTimes is missing.");
    end

    %% Branch indexing
    %
    % levelVector = [-lMax, ..., 0, ..., +lMax]'.
    %
    % For internal nodes:
    %
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

    %% Exercise-step mapping: contractual times -> model steps

    exerciseTimes = Bermudan.exerciseTimes(:);

    exerciseStepsRaw = round(exerciseTimes ./ dt);
    exerciseTimesOnGrid = exerciseStepsRaw .* dt;
    exerciseGridErrors = abs(exerciseTimesOnGrid - exerciseTimes);

    if max(exerciseGridErrors) > 1e-10
        warning( ...
            "Some contractual exercise times are not exactly on the tree grid. Max error = %.12e.", ...
            max(exerciseGridErrors));
    end

    validExercise = ...
        exerciseStepsRaw >= 0 ...
        & exerciseStepsRaw < totalSteps;

    exerciseSteps = exerciseStepsRaw(validExercise);
    exerciseTimesValid = exerciseTimes(validExercise);
    exerciseTimesOnGridValid = exerciseTimesOnGrid(validExercise);

    if isempty(exerciseSteps)
        error("No valid exercise dates fall inside the tree horizon.");
    end

    isExerciseStep = false(totalSteps + 1, 1);

    exerciseTimeByStep = NaN(totalSteps + 1, 1);
    exerciseModelTimeByStep = NaN(totalSteps + 1, 1);

    for iExercise = 1:numel(exerciseSteps)

        stepIndex = exerciseSteps(iExercise) + 1;

        if isExerciseStep(stepIndex)
            warning( ...
                "Multiple contractual exercise times mapped to the same tree step %d.", ...
                exerciseSteps(iExercise));
        end

        isExerciseStep(stepIndex) = true;

        exerciseTimeByStep(stepIndex) = exerciseTimesValid(iExercise);
        exerciseModelTimeByStep(stepIndex) = exerciseTimesOnGridValid(iExercise);

    end

    %% Initialize terminal value

    V = zeros(numNodes, 1);

    %% Backward induction

    for step = (totalSteps - 1) : -1 : 0

        tModel = step * dt;

        %% Branch-specific stochastic discount factors
        %
        % These are one-step discounts between model tree layers:
        %
        %   tModel -> tModel + dt

        [DUp, DMid, DDown] = computeHullWhiteExactBranchDiscounts( ...
            xVector, ...
            xVector(idxUp), ...
            xVector(idxMid), ...
            xVector(idxDown), ...
            treeHullWhite, ...
            B0Tree, ...
            step);

        %% Continuation value on model grid

        VCont = ...
            pu .* DUp   .* V(idxUp) + ...
            pm .* DMid  .* V(idxMid) + ...
            pd .* DDown .* V(idxDown);

        %% Exercise decision at contractual time

        if isExerciseStep(step + 1)

            tExercise = exerciseTimeByStep(step + 1);
            tExerciseModel = exerciseModelTimeByStep(step + 1);

            if abs(tExercise - tModel) > 1e-10
                warning( ...
                    "Exercise contractual time %.12f differs from tree model time %.12f.", ...
                    tExercise, ...
                    tModel);
            end

            if abs(tExerciseModel - tModel) > 1e-12
                error("Internal exercise-step mapping inconsistency.");
            end

            remainingIndex = TFixed > tExercise + 1e-10;

            TRemaining = TFixed(remainingIndex);
            deltaRemaining = deltaFixed(remainingIndex);
            B0Remaining = B0Payments(remainingIndex);

            if isempty(TRemaining)

                intrinsicValue = zeros(numNodes, 1);

            else

                % P(0,tExercise). This is exactly B0Tree(step+1) only if
                % tExercise lies on the model grid.
                P0Exercise = B0Tree(step + 1);

                intrinsicValue = swapPricer( ...
                    xVector, ...
                    treeHullWhite, ...
                    tExercise, ...
                    TRemaining, ...
                    deltaRemaining, ...
                    K, ...
                    P0Exercise, ...
                    B0Remaining);

            end

            V = max(intrinsicValue, VCont);

        else

            V = VCont;

        end

    end

    %% Time-zero price
    %
    % Since levelVector = [-lMax, ..., 0, ..., +lMax]',
    % the zero OU state is at index lMax + 1.

    middleIndex = lMax + 1;

    price = V(middleIndex);

end