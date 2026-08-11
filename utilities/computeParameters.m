function [S, K, C] = computeParameters(startDate, paymentDates, rules)

% Get raw unrounded year fractions
T_years = yearfrac(startDate, paymentDates, 3);
num_periods = length(paymentDates);

S = zeros(num_periods, 1);
K = zeros(num_periods, 1);
C = zeros(num_periods, 1);

for i = 1:size(rules, 1)
    start_yr = rules(i, 1);
    end_yr   = rules(i, 2);
    spread   = rules(i, 3);
    strike   = rules(i, 4);
    cap      = rules(i, 5);

    % SHIFT BOUNDARIES BY +0.1 YEARS TO ABSORB WEEKEND OR HOLIDAY ADJUSTMENTS
    idx = (T_years > (start_yr + 0.1)) & (T_years <= (end_yr + 0.1));

    idx(1) = false; % Protect first fixed coupon

    S(idx) = spread;
    K(idx) = strike;
    C(idx) = cap;
end
end