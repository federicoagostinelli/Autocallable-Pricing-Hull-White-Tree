function St = simulateNig(market, nSim, rngSeed)
%SIMULATENIG Simulate EuroStoxx/Stoxx50 at the first coupon reset date.
%
%   St = SIMULATENIG(market)
%   St = SIMULATENIG(market, nSim)
%   St = SIMULATENIG(market, nSim, rngSeed)
%
%   simulates the terminal EuroStoxx/Stoxx50 level at the first Party B
%   coupon reset date under the calibrated NIG model stored in:
%
%       market.nts
%
%   The simulated date is:
%
%       market.nts.calibrationDate
%
%   and the simulation time is:
%
%       market.nts.calibrationTime
%
%   where:
%
%       market.nts.calibrationTime =
%           yearfrac(market.dateInfo.refDate,
%                    product.partyB.resetDates(1),
%                    market.dateInfo.blackDayCount)
%
%   In the current setup:
%
%       market.dateInfo.blackDayCount = 3
%
%   i.e. ACT/365.
%
%   The simulated terminal value is:
%
%       S_T = F(0,T) * exp(X_T)
%
%   where:
%
%       F(0,T) = market.nts.forward
%
%   and X_T is a martingale-corrected NIG log-return, so that:
%
%       E[exp(X_T)] = 1
%
%   and therefore:
%
%       E[S_T] = F(0,T)
%
%   INPUT
%
%       market
%           Market struct after:
%
%               market = calibrateNts(market, product);
%
%           Required fields:
%
%               market.nts.alpha
%               market.nts.forward
%               market.nts.calibrationTime
%               market.nts.sigmaOpt
%               market.nts.kappaOpt
%               market.nts.etaOpt
%
%       nSim
%           Number of Monte Carlo simulations.
%           Default: 1e6.
%
%       rngSeed
%           Optional random seed.
%
%   OUTPUT
%
%       terminalUnderlying
%           [nSim x 1] simulated EuroStoxx/Stoxx50 levels at the first
%           coupon reset date.

    %% Optional inputs

    if nargin < 2 || isempty(nSim)
        nSim = 1e6;
    end

    if nargin >= 3 && ~isempty(rngSeed)
        rng(rngSeed);
    end

    nSim = double(nSim);

    if ~isscalar(nSim) || ~isfinite(nSim) || nSim <= 0 || mod(nSim, 1) ~= 0
        error('simulateNig:InvalidNSim', ...
            'nSim must be a positive integer scalar.');
    end

    %% Check calibration

    if ~isfield(market, 'nts')
        error('simulateNig:MissingNtsCalibration', ...
            'market.nts is missing. Run calibrateNts first.');
    end

    requiredFields = [
        "alpha"
        "forward"
        "calibrationTime"
        "sigmaOpt"
        "kappaOpt"
        "etaOpt"
    ];

    for iField = 1:numel(requiredFields)
        fieldName = requiredFields(iField);

        if ~isfield(market.nts, fieldName)
            error('simulateNig:MissingNtsField', ...
                'market.nts.%s is missing. Run calibrateNts first.', ...
                fieldName);
        end
    end

    if abs(market.nts.alpha - 0.5) > 1e-12
        error('simulateNig:OnlyNigSupported', ...
            'simulateNig supports NIG only, i.e. market.nts.alpha = 1/2.');
    end

    %% Read NIG inputs

    forward = market.nts.forward;
    timeToReset = market.nts.calibrationTime;

    sigma = market.nts.sigmaOpt;
    kappa = market.nts.kappaOpt;
    eta = market.nts.etaOpt;

    %% Input checks

    if ~isscalar(forward) || ~isfinite(forward) || forward <= 0
        error('simulateNig:InvalidForward', ...
            'market.nts.forward must be a positive finite scalar.');
    end

    if ~isscalar(timeToReset) || ~isfinite(timeToReset) || timeToReset <= 0
        error('simulateNig:InvalidTimeToReset', ...
            'market.nts.calibrationTime must be a positive finite scalar.');
    end

    if ~isscalar(sigma) || ~isfinite(sigma) || sigma <= 0
        error('simulateNig:InvalidSigma', ...
            'market.nts.sigmaOpt must be a positive finite scalar.');
    end

    if ~isscalar(kappa) || ~isfinite(kappa) || kappa <= 0
        error('simulateNig:InvalidKappa', ...
            'market.nts.kappaOpt must be a positive finite scalar.');
    end

    if ~isscalar(eta) || ~isfinite(eta)
        error('simulateNig:InvalidEta', ...
            'market.nts.etaOpt must be a finite scalar.');
    end

    %% Simulate inverse Gaussian subordinator

    meanIg = timeToReset;
    shapeIg = timeToReset^2 / kappa;

    gaussianForIg = randn(nSim, 1);
    squaredGaussian = gaussianForIg.^2;

    igCandidate = meanIg ...
        + (meanIg^2 .* squaredGaussian) ./ (2 * shapeIg) ...
        - (meanIg ./ (2 * shapeIg)) .* ...
        sqrt(4 * meanIg * shapeIg .* squaredGaussian ...
        + meanIg^2 .* squaredGaussian.^2);

    uniformRandom = rand(nSim, 1);

    inverseGaussianTime = igCandidate;

    useReciprocalBranch = uniformRandom > meanIg ./ (meanIg + igCandidate);

    inverseGaussianTime(useReciprocalBranch) = ...
        meanIg^2 ./ igCandidate(useReciprocalBranch);

    % Martingale correction

    martingaleCorrection = -real( ...
        (timeToReset ./ kappa) .* ...
        (1 - sqrt(1 + kappa .* sigma.^2 .* (2 .* eta))) );

    % Simulate NIG log-return

    g = randn(nSim, 1);

    logReturn = martingaleCorrection ...
        + sigma .* sqrt(inverseGaussianTime) .* g ...
        - (0.5 + eta) .* sigma.^2 .* inverseGaussianTime;

    % Terminal underlying level
    St = forward .* exp(logReturn);

end