function treeHullWhite = buildHullWhiteTree(treePricer, geometry, a, sigma)
%BUILDHULLWHITETREE Add Hull-White parameters to a generic tree pricer.
%
% INPUTS:
%   treePricer     - Generic trinomial tree pricer.
%   geometry       - Hull-White geometry struct.
%   a              - Hull-White mean-reversion parameter.
%   sigma          - Hull-White volatility parameter.
%
% OUTPUT:
%   treeHullWhite  - Struct containing generic tree data and Hull-White data.

    treeHullWhite = treePricer;

    treeHullWhite.model = 'HullWhite';

    treeHullWhite.a = a;
    treeHullWhite.sigma = sigma;

    treeHullWhite.muHat = geometry.muHat;
    treeHullWhite.sigmaHat = geometry.sigmaHat;

    treeHullWhite.lowerBound = geometry.lowerBound;
    treeHullWhite.upperBound = geometry.upperBound;

end