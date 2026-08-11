function I = computeIntegralQuadrature(f)
% computeIntegralQuadrature Numerically evaluates a Fourier-type integral by adaptive quadrature.
%
%   I = computeIntegralQuadrature(psi)
%
%   Inputs:
%       f : function handle
%           Integrand to be evaluated. It must accept a real scalar or vector
%           of integration points and return the corresponding function values.
%
%   Outputs:
%       I   : numeric scalar
%           Numerical approximation of the integral of psi over the whole real line.
%
%   Notes:
%       - The integral is computed over (-Inf, +Inf) using MATLAB's QUADGK.
%       - Absolute and relative tolerances are set to 1e-10 and 1e-8.
%       - Intended for Lewis/Fourier pricing integrals defined on the real axis.
I = quadgk(f, -Inf, Inf, 'AbsTol', 1e-10, 'RelTol', 1e-8);
end