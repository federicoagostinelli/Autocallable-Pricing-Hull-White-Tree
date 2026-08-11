function zcb = computeHullWhiteOneStepZCB(xt, treeHullWhite, B0Tree, step)
%COMPUTEHULLWHITEONESTEPZCB Compute exact one-step Hull-White ZCB.
%
%   zcb = computeHullWhiteOneStepZCB(xt, treeHullWhite, B0Tree, step)
%
%   computes:
%
%       B(t_i,t_{i+1},x_i)
%
%   using the exact Hull-White ZCB formula.

    %% Read parameters

    a = treeHullWhite.a;
    sigma = treeHullWhite.sigma;
    dt = treeHullWhite.dt;

    %% Tree times

    t = step * dt;
    T = t + dt;

    %% Market discount factors

    if step + 2 > numel(B0Tree)
        error("B0Tree does not contain enough discount factors for this step.");
    end

    P0t = B0Tree(step + 1);
    P0T = B0Tree(step + 2);

    %% Exact one-step ZCB

    zcb = computeHullWhiteZCBFromState( ...
        xt, ...
        a, ...
        sigma, ...
        t, ...
        T, ...
        P0t, ...
        P0T ...
    );

end