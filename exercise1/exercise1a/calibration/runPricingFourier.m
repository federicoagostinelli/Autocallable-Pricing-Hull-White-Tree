function price = runPricingFourier(f, x, B, F0, M, x1, z1)
% runPricingFourier Compute European call prices with the Lewis formula.
%
%   price = runPricingFourier(f, x, B, F0)
%   price = runPricingFourier(f, x, B, F0, M, x1, z1)
%
%   Inputs:
%       f  : function handle
%            Characteristic function.
%       x  : scalar or vector
%            Log-moneyness values, with x = log(F0 / K).
%       B  : scalar
%            Discount factor B(t0,t).
%       F0 : scalar
%            Forward at time t0.
%       M  : integer, optional
%            Power such that N = 2^M is the number of FFT grid points.
%       x1 : scalar, optional
%            First point of the integration grid used in the FFT routine.
%       z1 : scalar, optional
%            First point of the output grid used in the FFT routine.
%
%   Output:
%       price : scalar or vector
%               European call price(s).
%
%   Notes:
%       - If only f, x, B, and F0 are provided, the integral is computed by
%         adaptive quadrature.
%       - If M, x1, and z1 are also provided, the integral is computed by FFT.
%       - The implemented formula is
%         c(x)/(B*F0) = 1 - exp(-x/2) * I(x),
%         where
%         I(x) = integral_R exp(-1i*xi*x) * f(-xi - 1i/2)
%                / (2*pi*(xi^2 + 1/4)) dxi.
%       - The convention is x = log(F0/K), so K = F0 * exp(-x).

    g = @(xi) f(-xi - 1i/2) ./ (2*pi .* (xi.^2 + 1/4));

    if nargin == 4
        I = arrayfun(@(xval) computeIntegralQuadrature( ...
            @(xi) exp(-1i .* xi .* xval) .* g(xi)), x);
        price = real(B .* F0 .* (1 - exp(-x./2) .* I));
        return
    end

    if nargin ~= 7
        error('runPricingFourier requires either 4 inputs or 7 inputs.');
    end

    [Ifft, ~, z] = computeIntegralFFT(g, M, x1, z1);
    I = interp1(z, Ifft, x, 'linear');

    price = real(B .* F0 .* (1 - exp(-x./2) .* I));
end