function simulation = simulateEarlyRedemptionVG(product, market, nSim, rngSeed)
%SIMULATEEARLYREDEMPTIONEVENT Simulate Assignment 6 early redemption event.
%
%   simulation = SIMULATEEARLYREDEMPTIONEVENT(product, market, nSim, rngSeed)
%
%   simulates EuroStoxx/Stoxx50 at the first coupon reset date and determines
%   whether early redemption / cancellation occurs.
%
%   For Assignment 6 base product:
%
%       coupon1 = 6% if S(T_reset_1) < strike, else 0%.
%
%   Since the trigger level is 6%, early redemption occurs exactly when:
%
%       S(T_reset_1) < strike.
%
%   INPUT
%
%       product
%           Product struct enriched by prepareProductForPricing.
%
%       market
%           Market struct enriched by calibrateNts.
%
%       nSim
%           Number of Monte Carlo simulations. Default: 1e6.
%
%       rngSeed
%           Optional random seed.
%
%   OUTPUT
%
%       simulation
%           Struct containing:
%
%               St
%               belowStrike
%               coupon1Rate
%               earlyRedeemed
%               probabilityBelowStrike
%               probabilityEarlyRedemption

    if nargin < 3 || isempty(nSim)
        nSim = 1e6;
    end

    if nargin < 4
        rngSeed = [];
    end

    St = simulateVg(market, nSim, rngSeed);

    belowStrike = St < product.underlying.strike;

    coupon1Rate = product.partyB.coupons.year1.rate .* belowStrike;

    earlyRedeemed = coupon1Rate >= product.earlyRedemption.triggerLevel;

    simulation = struct();

    simulation.nSim = nSim;
    simulation.St = St;
    simulation.belowStrike = belowStrike;
    simulation.coupon1Rate = coupon1Rate;
    simulation.earlyRedeemed = earlyRedeemed;

    simulation.probabilityBelowStrike = mean(belowStrike);
    simulation.probabilityEarlyRedemption = mean(earlyRedeemed);

end