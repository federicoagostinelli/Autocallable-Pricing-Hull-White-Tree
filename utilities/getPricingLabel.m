function pricingLabel = getPricingLabel(useSmileCorrection)

    if useSmileCorrection
        pricingLabel = 'Smile-corrected digital';
    else
        pricingLabel = 'Uncorrected Black-76';
    end

end