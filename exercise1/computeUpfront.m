function [upfront, mtmA, legA, legB] = computeUpfront(market, product)
%COMPUTEUPFRONT Compute the fair upfront from Party A's perspective.
%
%   [upfront, mtmA, legA, legB] = COMPUTEUPFRONT(market, product)
%
%   computes the fair upfront X paid by Party B to Party A at inception for
%   the Assignment 6 hedging swap.
%
%   Perspective and sign convention
%   -------------------------------
%
%   Everything is computed from Party A's perspective.
%
%   Party A:
%
%       - pays the floating leg:
%
%             Euribor 3M + 1.30%
%
%       - receives the Party B structured coupon leg;
%
%       - receives the upfront X from Party B at inception.
%
%   Therefore, from Party A's perspective:
%
%       MtM_A = PV(received structured leg)
%             - PV(paid floating leg)
%             + upfront * principal
%
%   The fair upfront is the value that makes the initial mark-to-market zero:
%
%       MtM_A = 0
%
%   hence:
%
%       upfront = [PV(paid floating leg) - PV(received structured leg)]
%                 / principal
%
%   i.e.
%
%       upfront = (legA.npv - legB.npv) / product.principal
%
%   where:
%
%       legA.npv
%           Present value of the floating leg paid by Party A.
%
%       legB.npv
%           Present value of the structured coupon leg received by Party A
%           from Party B.
%
%   Product dispatch
%   ----------------
%
%   Standard Assignment 6 product:
%
%       legA = priceLegA(product, market)
%       legB = priceLegB(product, market)
%
%   Modified 3Y product for Exercise 1.d:
%
%       product.productType = "ModifiedThreeYear"
%
%   In that case:
%
%       legA = priceLegAModifiedThreeYear(product, market)
%       legB = priceLegBModifiedThreeYear(product, market)
%
%   INPUT
%
%       market
%           Market struct initialized by initializeMarket, calibrated by
%           calibrateNts, and enriched with market.simulation.
%
%       product
%           Product struct initialized by initializeProduct and enriched by
%           prepareProductForPricing.
%
%   OUTPUT
%
%       upfront
%           Fair upfront rate X in decimal units, paid by Party B to Party A
%           at inception.
%
%       mtmA
%           Initial mark-to-market from Party A's perspective after setting
%           the fair upfront. This should be numerically close to zero.
%
%       legA
%           Output struct from the selected Party A leg pricer.
%
%       legB
%           Output struct from the selected Party B leg pricer.

    %% Price legs

    if isfield(product, "productType") && product.productType == "ModifiedThreeYear"

        legA = priceLegAModifiedThreeYear(product, market);
        legB = priceLegBModifiedThreeYear(product, market);

    else

        legA = priceLegA(product, market);
        legB = priceLegB(product, market);

    end

    %% Fair upfront from Party A's perspective

    upfront = ...
        (legA.npv - legB.npv) ...
        / product.principal;

    %% Check fair MtM from Party A's perspective

    mtmA = ...
        legB.npv ...
        - legA.npv ...
        + upfront * product.principal;

end