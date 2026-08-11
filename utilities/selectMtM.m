function mtm = selectMtM(mtmCorrected, mtmUncorrected, useSmileCorrection)

    if useSmileCorrection
        mtm = mtmCorrected;
    else
        mtm = mtmUncorrected;
    end

end