function treePricer = buildTreePricer(TEnd, nStepsPerYear, lMax, dx)
%BUILDTREEPRICER Build a generic recombining trinomial tree pricer.
%
% INPUTS:
%   TEnd           - Total time horizon of the tree, in years.
%   nStepsPerYear  - Number of time steps per year.
%   lMax           - Maximum vertical level index.
%   dx             - Space step of the state variable.
%
% OUTPUT:
%   treePricer     - Struct containing the generic trinomial tree geometry.
%
% The level vector is ordered from bottom to top:
%
%       levelVector = [-lMax, ..., 0, ..., +lMax]'.
%
% Therefore, moving up in the tree corresponds to increasing the MATLAB
% array index, while moving down corresponds to decreasing the index.

    dt = 1 / nStepsPerYear;
    totalSteps = round(TEnd * nStepsPerYear);

    levelVector = (-lMax:lMax)';
    xVector = levelVector * dx;
    numNodes = length(xVector);

    treePricer = struct();

    treePricer.TEnd = TEnd;
    treePricer.nStepsPerYear = nStepsPerYear;

    treePricer.dt = dt;
    treePricer.totalSteps = totalSteps;

    treePricer.lMax = lMax;
    treePricer.dx = dx;

    treePricer.levelVector = levelVector;
    treePricer.xVector = xVector;
    treePricer.numNodes = numNodes;

end