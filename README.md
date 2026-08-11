# Advanced Derivatives Pricing: Autocallables & Bermudan Swaptions

## Project Overview
This repository contains a sophisticated MATLAB-based quantitative framework dedicated to the pricing of complex, path-dependent derivatives. The project is divided into two core modules: a Monte Carlo pricing engine for Equity Autocallable Certificates under infinite-activity Lévy processes (NIG, VG), and a lattice-based numerical engine implementing a 1-factor Hull-White trinomial tree to price Bermudan Swaptions.

*Note: This was a collaborative academic project developed for the Financial Engineering course at Politecnico di Milano. I co-developed the mathematical architecture and numerical pricing engines alongside my team, ensuring rigorous validation against theoretical bounds and analytical benchmarks.*

## Core Modules & Technical Implementation

### Module 1: Autocallable Certificate & Model Risk Engine
We priced a multi-callable structured product, analyzing the severe model risk introduced by flat-volatility continuous diffusion models when valuing path-dependent digital payoffs.
* **Advanced Monte Carlo Simulation:** Implemented simulation engines for Normal Inverse Gaussian (NIG) and Variance Gamma (VG) models to correctly capture the heavy tails and jump dynamics of the equity market.
* **Digital Smile Correction:** Proved that uncorrected Black-76 models severely misprice the upfront of the derivative. Implemented a Vega-weighted smile correction (evaluating the local slope of the volatility surface) to perfectly align the Gaussian framework with advanced Lévy models for single-observation payoffs.
* **Path-Dependency (Marginal vs. Joint Distributions):** Extended the certificate to a 3-year multi-callable structure, mathematically demonstrating why continuous models fail to capture the correct transition density between observation nodes compared to jump-driven models.

### Module 2: Hull-White Trinomial Tree for Bermudan Swaptions
We built a lattice-based pricing engine from scratch to value a 10-year Bermudan Payer Swaption (non-call 2).
* **Trinomial Tree Construction:** Discretized the mean-reverting Ornstein-Uhlenbeck (OU) process using a daily-grid trinomial tree (365 steps/year).
* **Alternative Branching:** Implemented dynamic top/bottom boundary branching algorithms to strictly enforce martingale conditions and prevent negative transition probabilities.
* **Backward Induction:** Computed the Bermudan optionality by comparing the intrinsic swap value against the continuation value at each valid exercise node, utilizing exact closed-form Zero-Coupon Bond (ZCB) stochastic discounting.
* **Rigorous Benchmarking:** Validated the tree by perfectly repricing the initial yield curve (ZCB Benchmark) and matching Jamshidian's analytical decomposition for European Swaptions.

## Key Results
* **Smile Impact:** Demonstrated that ignoring the equity volatility skew causes a ~64 bps mispricing in the certificate's upfront compensation.
* **Bermudan Optionality (Early Exercise Premium):** Isolated the value of the Bermudan flexibility by establishing rigorous theoretical boundaries, proving the tree price falls perfectly between the Maximum European lower bound and the Cap portfolio upper bound[cite: 5].
* **Numerical Stability:** The Hull-White tree achieved machine-precision accuracy in probability mass conservation and relative errors tightly constrained around $10^{-7}$ for ZCB repricing.

## Tech Stack
* **Language:** MATLAB
* **Quantitative Methods:** Monte Carlo Simulation, Lévy Processes (NIG, VG), Model Risk Analysis, Digital Volatility Smile Correction, 1-Factor Hull-White (Extended Vasicek) Model, Trinomial Trees, Jamshidian's Decomposition, Backward Induction.
