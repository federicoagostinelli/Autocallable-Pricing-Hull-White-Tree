function [fhat, x, z] = computeIntegralFFT(f, M, x1, z1)
% computeIntegralFFT Compute discrete Fourier transform via FFT following
% the convention dx*dz = 2*pi/N.
%
%   [fhat, x, z] = computeIntegralFFT(f, M, x1, z1)
%
%   Inputs:
%       f  : function handle
%            Function f(x) to be sampled on the x-grid.
%       M  : integer
%            Power such that N = 2^M is the number of grid points.
%       x1 : scalar
%            Left endpoint of the x-grid.
%       z1 : scalar
%            Left endpoint of the z-grid.
%
%   Outputs:
%       fhat : vector
%              Approximation of the Fourier transform at points z_k.
%       x    : vector
%              x-grid (spatial grid).
%       z    : vector
%              z-grid (Fourier grid).
%
%   Notes:
%       - Uses the convention:
%         fhat(z_k) = dx * exp(-1i*x1*z_k) * FFT{ f_j * exp(-1i*z1*dx*(j-1)) }
%       - Grids:
%           x_j = x1 + (j-1)*dx
%           z_k = z1 + (k-1)*dz
%       - Constraint: dx * dz = 2*pi / N

    N  = 2^M;

    % discretization
    dx = (-x1 - x1) / N;         % = -2*x1 / N
    dz = 2*pi / (N * dx);

    % grids
    x = x1 + (0:N-1) * dx;
    z = z1 + (0:N-1) * dz;

    % samples
    fj = f(x);

    % phase correction (shift z1)
    phase = exp(-1i * z1 * dx * (0:N-1));

    % FFT
    fhat = dx .* exp(-1i * x1 .* z) .* fft(fj .* phase);
end