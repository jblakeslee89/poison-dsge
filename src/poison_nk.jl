using MacroModelling

# Faithful port of poison_nk_ar1_attack.mod (Dynare 6.3).
# Variables, equations, and calibration match the source one-for-one.
# This is the toy model from Blakeslee (2025), used as the regression
# baseline before any extensions.

@model PoisonNK begin
    # New Keynesian Phillips curve
    π[0] = β * π[1] + κ * ygap[0]

    # IS curve (consumption Euler with output gap)
    ygap[0] = ygap[1] - φ * (i[0] - π[1] - rn[0])

    # Natural rate AR(1)
    rn[0] = ρ_r * rn[-1] + σ_rn * ε_rn[x]

    # Measurement noise AR(1)
    ν[0] = ρ_ν * ν[-1] + σ_ν * ε_ν[x]

    # Data poisoning attack AR(1)
    attack[0] = ρ_att * attack[-1] + σ_att * ε_att[x]

    # Taylor rule on perceived gap (true + noise + attack)
    i[0] = rstar + πstar +
           α * (π[0] - πstar) +
           γ * (ygap[0] + ν[0] + attack[0])
end

@parameters PoisonNK begin
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
end
