function printExercise2BoundsSummary(bounds)
%PRINTEXERCISE2BOUNDSSUMMARY Print Exercise 2.c bounds summary.

    fprintf('\n============================================================\n');
    fprintf(' EXERCISE 2.c - BERMUDAN SWAPTION BOUNDS SUMMARY\n');
    fprintf('============================================================\n');
    fprintf('Lower bound max European        : %.12f\n', bounds.lowerBound);
    fprintf('Tree Bermudan price             : %.12f\n', bounds.bermudanSwaptionPrice);
    fprintf('Upper bound cap                 : %.12f\n', bounds.upperBoundCap);
    fprintf('Upper bound Jamshidian sum Euro : %.12f\n', bounds.upperBoundJamshidian);
    fprintf('Tight upper bound               : %.12f\n', bounds.upperBoundTight);
    fprintf('============================================================\n');

end