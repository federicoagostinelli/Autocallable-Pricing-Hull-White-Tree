function Bermudan = initializeExercise2Bermudan(marketIR)
%INITIALIZEEXERCISE2BERMUDAN Initialize the 10Y Bermudan payer swaption.

    %% Contract dates

    refDate = ensureDatetime(datetime(2008, 2, 15));

    Bermudan = struct();

    Bermudan.startDate = refDate;
    Bermudan.endDate = ensureDatetime(datetime(2018, 2, 19));

    Bermudan.maturity = yearfrac( ...
        Bermudan.startDate, ...
        Bermudan.endDate, ...
        marketIR.dateInfo.blackDayCount);

    Bermudan.K = 0.05;

    Bermudan.nonCallYears = 2;
    Bermudan.fixedPaymentsPerYear = 1;

    Bermudan.paymentAdjust = 'modifiedfollowing';
    Bermudan.fixedDayCount = 6; % 30/360

    %% Exercise schedule

    exerciseYears = Bermudan.nonCallYears : 1 : 9;

    exerciseDates = arrayfun( ...
        @(y) businessDateOffsetTarget( ...
            Bermudan.startDate, ...
            y, ...
            0, ...
            0, ...
            Bermudan.paymentAdjust), ...
        exerciseYears);

    Bermudan.exerciseDates = ensureDatetime(exerciseDates(:));

    Bermudan.exerciseTimes = yearfrac( ...
        marketIR.dateInfo.refDate, ...
        Bermudan.exerciseDates, ...
        marketIR.dateInfo.blackDayCount);

end