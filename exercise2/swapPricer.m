function intrinsicValue = swapPricer(xt, treeHullWhite, tExercise, ...
    TFixedRemaining, deltaFixedRemaining, K, P0Exercise, B0FixedRemaining)
%SWAPPRICER Compute intrinsic value of a payer swap on a Hull-White tree.
%
%   intrinsicValue = swapPricer(xt, treeHullWhite, tExercise,
%       TFixedRemaining, deltaFixedRemaining, K, P0Exercise,
%       B0FixedRemaining)
%
%   computes the intrinsic value of entering the remaining payer swap at
%   exercise time tExercise and OU state xt.
%
%   The payer swap value is:
%
%       PV_float - PV_fixed
%
%   where:
%
%       PV_float = 1 - B(t,T_N)
%
%       PV_fixed = K * sum_j delta_j * B(t,T_j)
%
%   Therefore:
%
%       intrinsicValue = max(PV_float - PV_fixed, 0)
%
%   INPUTS:
%   -------
%   xt
%       Vector of OU states x(tExercise).
%
%   treeHullWhite
%       Hull-White tree struct with fields:
%
%           a
%           sigma
%
%   tExercise
%       True contractual exercise time.
%
%   TFixedRemaining
%       Remaining fixed-leg payment times strictly after tExercise.
%
%   deltaFixedRemaining
%       Fixed-leg accrual factors associated with TFixedRemaining.
%
%   K
%       Fixed strike rate of the payer swap.
%
%   P0Exercise
%       Market discount factor P(0,tExercise).
%
%   B0FixedRemaining
%       Market discount factors P(0,T_j) for each remaining payment date.
%
%   OUTPUT:
%   -------
%   intrinsicValue
%       Intrinsic value of the payer swaption at each OU state.

    %% Defensive formatting

    xt = xt(:);

    TFixedRemaining = TFixedRemaining(:);
    deltaFixedRemaining = deltaFixedRemaining(:);
    B0FixedRemaining = B0FixedRemaining(:);

    if numel(TFixedRemaining) ~= numel(deltaFixedRemaining) || ...
            numel(TFixedRemaining) ~= numel(B0FixedRemaining)
        error("TFixedRemaining, deltaFixedRemaining and B0FixedRemaining must have the same length.");
    end

    if isempty(TFixedRemaining)
        intrinsicValue = zeros(size(xt));
        return;
    end

    %% Read Hull-White parameters

    a = treeHullWhite.a;
    sigma = treeHullWhite.sigma;

    %% Compute stochastic ZCBs B(tExercise,T_j)

    numNodes = numel(xt);
    numPayments = numel(TFixedRemaining);

    BtT = zeros(numNodes, numPayments);

    for j = 1:numPayments

        BtT(:, j) = computeHullWhiteZCBFromState( ...
            xt, ...
            a, ...
            sigma, ...
            tExercise, ...
            TFixedRemaining(j), ...
            P0Exercise, ...
            B0FixedRemaining(j));

    end

    %% Floating leg

    BtTEnd = BtT(:, end);

    pvFloating = 1.0 - BtTEnd;

    %% Fixed leg

    pvFixed = K .* sum( ...
        BtT .* deltaFixedRemaining.', ...
        2);

    %% Payer swap intrinsic value

    swapNPV = pvFloating - pvFixed;

    intrinsicValue = max(swapNPV, 0.0);

end