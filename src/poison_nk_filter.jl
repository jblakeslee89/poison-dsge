using MacroModelling

# Extension of poison_nk_cee.jl with a Kalman-style perception filter.
# The Fed no longer responds to the raw signal (ygap + ν + attack); it
# responds to its filtered estimate gap_perceived, which is a convex
# combination of an AR(1) prior and the current signal.
#
#   K_gain ∈ [0,1]   weight on raw signal (1 = naive Fed, 0 = ignore signal)
#   ρ_p              persistence of the Fed's AR(1) prior on the gap
#
# The CEE frictions remain available via χ_p, h, ρ_i.

@model PoisonNK_Filter begin
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

    # Perception filter: convex combination of AR(1) prior and raw signal
    gap_perceived[0] = (1 - K_gain) * ρ_p * gap_perceived[-1] +
                       K_gain * (ygap[0] + ν[0] + attack[0])

    # Taylor rule — responds to filtered perception, not raw signal
    i[0] = ρ_i * i[-1] +
           (1 - ρ_i) * (rstar + πstar +
                        α * (π[0] - πstar) +
                        γ * gap_perceived[0])
end

@parameters PoisonNK_Filter begin
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

    # CEE frictions
    χ_p   = 0.5
    h     = 0.7
    ρ_i   = 0.7

    # Perception filter
    K_gain = 1.0      # 1.0 = naive Fed (recovers PoisonNK_CEE behavior)
    ρ_p    = 0.85     # AR(1) persistence of Fed's prior on gap
end
