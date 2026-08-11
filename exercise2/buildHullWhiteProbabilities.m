function probabilities = buildHullWhiteProbabilities(treeHullWhite)
%BUILDHULLWHITEPROBABILITIES Compute Hull-White trinomial probabilities.
%
% INPUT:
%   treeHullWhite  - Hull-White tree struct.
%                    Required fields:
%                       lMax
%                       levelVector
%                       muHat
%
% OUTPUT:
%   probabilities  - Struct containing up, middle and down probabilities.
%
% The probabilities are ordered consistently with:
%
%       treeHullWhite.levelVector = [-lMax, ..., 0, ..., +lMax]'.
%
% Therefore:
%   index 1   corresponds to l = -lMax,
%   index end corresponds to l = +lMax.

    lMax = treeHullWhite.lMax;
    levelVector = treeHullWhite.levelVector;
    muHat = treeHullWhite.muHat;

    l = levelVector;

    %% Internal Nodes: Case A

    pu = 0.5 * (1/3 - l * muHat + (l * muHat).^2);
    pm = 2/3 - (l * muHat).^2;
    pd = 0.5 * (1/3 + l * muHat + (l * muHat).^2);

    %% Bottom Boundary Node: Case B, l = -lMax
    %
    % At the bottom boundary, the tree cannot move further down.
    % The branch is shifted upward.

    lBottom = -lMax;

    pu(1) = 0.5 * (1/3 + lBottom * muHat + (lBottom * muHat)^2);
    pm(1) = -1/3 - 2 * lBottom * muHat - (lBottom * muHat)^2;
    pd(1) = 0.5 * (7/3 + 3 * lBottom * muHat + (lBottom * muHat)^2);

    %% Top Boundary Node: Case C, l = +lMax
    %
    % At the top boundary, the tree cannot move further up.
    % The branch is shifted downward.

    lTop = lMax;

    pu(end) = 0.5 * (7/3 - 3 * lTop * muHat + (lTop * muHat)^2);
    pm(end) = -1/3 + 2 * lTop * muHat - (lTop * muHat)^2;
    pd(end) = 0.5 * (1/3 - lTop * muHat + (lTop * muHat)^2);

    %% Store Output

    probabilities = struct();

    probabilities.pu = pu;
    probabilities.pm = pm;
    probabilities.pd = pd;

end