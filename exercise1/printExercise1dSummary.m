function printExercise1dSummary(marketModified3Y, upfront3Y, mtmA_3Y, ...
    legA_3Y, legB_3Y, nSim)
%PRINTEXERCISE1DSUMMARY Print additional report for Exercise 1.d.

    fprintf('\n============================================================\n');
    fprintf(' EXERCISE 1.d - MODIFIED 3Y PRODUCT UNDER NIG\n');
    fprintf('============================================================\n');

    fprintf('Number of simulations                      : %.0f\n', nSim);

    fprintf('\nReset times\n');
    fprintf('Reset time year 1                          : %.10f\n', ...
        marketModified3Y.simulation.resetTime1);
    fprintf('Reset time year 2                          : %.10f\n', ...
        marketModified3Y.simulation.resetTime2);

    fprintf('\nForward levels\n');
    fprintf('Forward year 1                             : %.10f\n', ...
        marketModified3Y.simulation.forward1);
    fprintf('Forward year 2                             : %.10f\n', ...
        marketModified3Y.simulation.forward2);

    fprintf('\nEarly-redemption probabilities\n');
    fprintf('P(ER year 1)                               : %.10f\n', ...
        marketModified3Y.simulation.probabilityEarlyRedemptionYear1);
    fprintf('P(ER year 2)                               : %.10f\n', ...
        marketModified3Y.simulation.probabilityEarlyRedemptionYear2);
    fprintf('P(ER year 2 | no ER year 1)                : %.10f\n', ...
        marketModified3Y.simulation.probabilityEarlyRedemptionYear2ConditionalOnNoER1);
    fprintf('P(survival to final)                       : %.10f\n', ...
        marketModified3Y.simulation.probabilitySurvivalToFinal);

    fprintf('\nLeg values\n');
    fprintf('Leg A NPV                                  : %.10f\n', legA_3Y.npv);
    fprintf('Leg B NPV                                  : %.10f\n', legB_3Y.npv);

    fprintf('\nFair upfront X\n');
    fprintf('X as decimal                               : %.10f\n', upfront3Y);
    fprintf('X in percent                               : %.8f%%\n', 100 * upfront3Y);
    fprintf('MTM A after fair X                         : %.12e\n', mtmA_3Y);

    fprintf('============================================================\n');

end