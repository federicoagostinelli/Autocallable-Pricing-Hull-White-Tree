function legA = priceLegAModifiedThreeYear(product, market)
%PRICELEGAMODIFIEDTHREEYEAR Price Party A leg of the modified 3Y product.
%
%   legA = PRICELEGAMODIFIEDTHREEYEAR(product, market)
%
%   prices the Party A floating leg of the modified three-year contract.
%
%   Party A pays:
%
%       Euribor 3M + spread
%
%   on a quarterly ACT/360 schedule.
%
%   Cancellation logic
%   ------------------
%   If early redemption occurs at year 1, Party A pays all quarterly
%   coupons up to the first annual payment date.
%
%   If early redemption occurs at year 2, Party A pays all quarterly
%   coupons up to the second annual payment date.
%
%   If no early redemption occurs, Party A pays all quarterly coupons up to
%   final maturity.
%
%   Required simulation fields
%   --------------------------
%   The function reads:
%
%       market.simulation.probabilityEarlyRedemptionYear1
%       market.simulation.probabilityEarlyRedemptionYear2
%       market.simulation.probabilitySurvivalToFinal
%
%   INPUT
%   -----
%   product
%       Product struct created by initializeProduct and enriched by
%       prepareProductForPricing.
%
%   market
%       Market struct containing modified three-year simulation
%       probabilities.
%
%   OUTPUT
%   ------
%   legA
%       Struct containing the probability-weighted PV and the deterministic
%       scenario PVs.

    %% Input checks

    requiredFields = { ...
        'probabilityEarlyRedemptionYear1', ...
        'probabilityEarlyRedemptionYear2', ...
        'probabilitySurvivalToFinal'};

    if ~isfield(market, 'simulation')
        error('priceLegAModifiedThreeYear:MissingSimulation', ...
            'market.simulation is missing.');
    end

    for iField = 1:numel(requiredFields)
        fieldName = requiredFields{iField};

        if ~isfield(market.simulation, fieldName)
            error('priceLegAModifiedThreeYear:MissingSimulationField', ...
                'market.simulation.%s is missing.', fieldName);
        end
    end

    pER1 = market.simulation.probabilityEarlyRedemptionYear1;
    pER2 = market.simulation.probabilityEarlyRedemptionYear2;
    pSurvival = market.simulation.probabilitySurvivalToFinal;

    if any([pER1, pER2, pSurvival] < -1e-12) || ...
            any([pER1, pER2, pSurvival] > 1 + 1e-12)
        error('priceLegAModifiedThreeYear:InvalidProbabilities', ...
            'Scenario probabilities must be in [0,1].');
    end

    if abs(pER1 + pER2 + pSurvival - 1) > 1e-8
        error('priceLegAModifiedThreeYear:InvalidProbabilitySum', ...
            'Scenario probabilities must sum to one.');
    end

    paymentsPerPartyBPeriod = ...
        product.partyA.paymentsPerYear / product.partyB.paymentsPerYear;

    if mod(paymentsPerPartyBPeriod, 1) ~= 0
        error('priceLegAModifiedThreeYear:InvalidFrequencyMapping', ...
            'Party B payment dates do not map exactly to Party A payment grid.');
    end

    idxYear1End = paymentsPerPartyBPeriod;
    idxYear2End = 2 * paymentsPerPartyBPeriod;
    idxFinalEnd = numel(product.partyA.paymentDiscounts);

    if idxYear2End > idxFinalEnd
        error('priceLegAModifiedThreeYear:InvalidEarlyCancellationIndex', ...
            'Second early cancellation index exceeds available Party A payments.');
    end

    %% Scenario 1: cancellation at first annual payment date

    floatingLegAIfCancelledYear1 = ...
        1.0 - product.partyA.paymentDiscounts(idxYear1End);

    spreadLegAIfCancelledYear1 = ...
        product.partyA.spread ...
        * sum( ...
            product.partyA.delta(1:idxYear1End) ...
            .* product.partyA.paymentDiscounts(1:idxYear1End) ...
        );

    npvAIfCancelledYear1 = product.principal * ...
        (floatingLegAIfCancelledYear1 + spreadLegAIfCancelledYear1);

    %% Scenario 2: cancellation at second annual payment date

    floatingLegAIfCancelledYear2 = ...
        1.0 - product.partyA.paymentDiscounts(idxYear2End);

    spreadLegAIfCancelledYear2 = ...
        product.partyA.spread ...
        * sum( ...
            product.partyA.delta(1:idxYear2End) ...
            .* product.partyA.paymentDiscounts(1:idxYear2End) ...
        );

    npvAIfCancelledYear2 = product.principal * ...
        (floatingLegAIfCancelledYear2 + spreadLegAIfCancelledYear2);

    %% Scenario 3: no cancellation, full maturity

    floatingLegAIfSurvivalToFinal = ...
        1.0 - product.partyA.paymentDiscounts(idxFinalEnd);

    spreadLegAIfSurvivalToFinal = ...
        product.partyA.spread ...
        * sum( ...
            product.partyA.delta(1:idxFinalEnd) ...
            .* product.partyA.paymentDiscounts(1:idxFinalEnd) ...
        );

    npvAIfSurvivalToFinal = product.principal * ...
        (floatingLegAIfSurvivalToFinal + spreadLegAIfSurvivalToFinal);

    %% Recursive probability-weighted NPV
    %
    % If ER1 occurs, stop after year 1.
    % Otherwise, continue to year 2.
    % If ER2 occurs, stop after year 2.
    % Otherwise, continue to final maturity.

    npvA = ...
        pER1 * npvAIfCancelledYear1 ...
        + pER2 * npvAIfCancelledYear2 ...
        + pSurvival * npvAIfSurvivalToFinal;

    %% Output

    legA = struct();

    legA.npv = npvA;

    legA.probabilityEarlyRedemptionYear1 = pER1;
    legA.probabilityEarlyRedemptionYear2 = pER2;
    legA.probabilitySurvivalToFinal = pSurvival;

    legA.npvIfCancelledYear1 = npvAIfCancelledYear1;
    legA.npvIfCancelledYear2 = npvAIfCancelledYear2;
    legA.npvIfSurvivalToFinal = npvAIfSurvivalToFinal;

    legA.floatingLegAIfCancelledYear1 = floatingLegAIfCancelledYear1;
    legA.spreadLegAIfCancelledYear1 = spreadLegAIfCancelledYear1;

    legA.floatingLegAIfCancelledYear2 = floatingLegAIfCancelledYear2;
    legA.spreadLegAIfCancelledYear2 = spreadLegAIfCancelledYear2;

    legA.floatingLegAIfSurvivalToFinal = floatingLegAIfSurvivalToFinal;
    legA.spreadLegAIfSurvivalToFinal = spreadLegAIfSurvivalToFinal;

    legA.earlyCancellationPaymentIdxYear1 = idxYear1End;
    legA.earlyCancellationPaymentIdxYear2 = idxYear2End;
    legA.finalPaymentIdx = idxFinalEnd;

    legA.earlyCancellationPaymentDateYear1 = product.partyB.paymentDates(1);
    legA.earlyCancellationPaymentDateYear2 = product.partyB.paymentDates(2);
    legA.finalPaymentDate = product.partyB.paymentDates(3);

end