using MacroModelling

# CEE / Smets-Wouters extension of poison_nk.jl.
# Three frictions toggleable via parameters; all default to 0 so that
# the model collapses to the toy NK exactly.
#
#   χ_p  ∈ [0,1)  price indexation (Galí-Gertler 1999 hybrid Phillips)
#   h    ∈ [0,1)  consumption habit (backward-looking IS)
#   ρ_i  ∈ [0,1)  interest rate smoothing (partial-adjustment Taylor)
#
# Calibration follows Smets-Wouters (2007) posterior means when frictions
# are turned on: χ_p ≈ 0.5, h ≈ 0.7, ρ_i ≈ 0.7.

@model PoisonNK_CEE begin
    # Hybrid Phillips curve
    π[0] = (β / (1 + β*χ_p)) * π[1] +
           (χ_p / (1 + β*χ_p)) * π[-1] +
           κ * ygap[0]

    # IS curve with consumption habit
    ygap[0] = (h / (1 + h)) * ygap[-1] +
              (1 / (1 + h)) * ygap[1] -
              ((1 - h) / (1 + h)) * φ * (i[0] - π[1] - rn[0])

    # AR(1) processes
    rn[0]     = ρ_r   * rn[-1]     + σ_rn  * ε_rn[x]
    ν[0]      = ρ_ν   * ν[-1]      + σ_ν   * ε_ν[x]
    attack[0] = ρ_att * attack[-1] + σ_att * ε_att[x]

    # Taylor rule with partial adjustment
    i[0] = ρ_i * i[-1] +
           (1 - ρ_i) * (rstar + πstar +
                        α * (π[0] - πstar) +
                        γ * (ygap[0] + ν[0] + attack[0]))
end

@parameters PoisonNK_CEE begin
    β     = 0.99
    κ     = 0.06
    φ     = 1.0
    α     = 1.5
    γ     = 0.5
    rstar = 0.5 / 4
    πstar = 2.0 / 4
    ρ_r   = 0.8
    ρ_ν   = 0.6
    ρ_att = 0.8
    σ_rn  = 0.4
    σ_ν   = 0.3
    σ_att = 1.0

    # Frictions (default off — recovers toy)
    χ_p   = 0.0
    h     = 0.0
    ρ_i   = 0.0
end
