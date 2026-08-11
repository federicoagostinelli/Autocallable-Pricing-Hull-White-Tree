function objValue = objectiveNtsCalibration(p, modelCallPrices, callPricesMkt, boundEta, penaltyValue)
% objectiveNtsCalibration Computes calibration loss for NTS model.

sigma = p(1);
kappa = p(2);
eta = p(3);

% Enforce basic positivity
if sigma <= 0 || kappa <= 0
    objValue = penaltyValue;
    return
end

% Admissibility condition
if eta < -boundEta(sigma, kappa)
    objValue = penaltyValue;
    return
end

% Compute model prices
callPricesModel = modelCallPrices(p);

% Squared error
pricingError = callPricesModel - callPricesMkt;
objValue = sum(pricingError .^ 2);

end