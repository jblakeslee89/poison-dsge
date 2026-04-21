using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "poison_nk_filter.jl"))

using MacroModelling
using Plots
using Printf
using DataFrames
using CSV

println("=" ^ 76)
println("Strategic attacker: optimize magnitude and persistence vs detection cost")
println("Compares naive Fed (K=1.0) vs filter Fed (K=0.025) under κ=0.15")
println("=" ^ 76)

_ = get_irf(PoisonNK_Filter, periods = 1)   # pre-compile

# Base calibration
base_params = [:κ => 0.15, :χ_p => 0.5, :h => 0.7, :ρ_i => 0.7, :ρ_p => 0.85]

# Attacker objective: push policy rate DOWN (negative cumulative response = attacker wins).
# Payoff(A, ρ) = −Σ i_t after attack shock, scaled by σ_att = A.
# Expected payoff accounting for detection: (1 − P_det(A, ρ)) · Payoff(A, ρ).
# Detection model: P_det = 1 − exp(−γ_d · A² · ρ).
# γ_d calibrated so the baseline attack (A=1, ρ=0.8) has P_det = 0.50:
#     0.50 = 1 − exp(−γ_d · 1 · 0.8)   →   γ_d = −ln(0.5)/0.8 ≈ 0.866
γ_d = -log(0.5) / 0.8

function cumulative_policy_response(model; params, periods=8)
    irf = get_irf(model, parameters = params, periods = periods)
    return sum(irf(:i, p, :ε_att) * 100 for p in 1:periods)  # bp
end

function attacker_payoff(model; A::Float64, ρ::Float64, K_gain::Float64, periods=8)
    # Ensure ρ and A are in valid ranges; Dynare-ish stability needs ρ < 1
    ρ_safe = clamp(ρ, 0.0, 0.99)
    A_safe = max(A, 1e-6)

    params = vcat(base_params, [:σ_att => A_safe, :ρ_att => ρ_safe, :K_gain => K_gain])
    cum_i = cumulative_policy_response(model, params=params, periods=periods)

    # Attacker wants rates DOWN, so raw payoff = -cum_i
    raw_payoff = -cum_i

    # Detection probability and expected payoff
    p_det = 1 - exp(-γ_d * A_safe^2 * ρ_safe)
    expected_payoff = (1 - p_det) * raw_payoff

    return (payoff = raw_payoff, p_det = p_det, expected = expected_payoff)
end

# Grid
A_grid   = 0.1:0.1:3.0      # 30 magnitudes
ρ_grid   = 0.0:0.05:0.95    # 20 persistences
regimes  = [("Naive Fed (K=1.00)", 1.000),
            ("Filter Fed (K=0.025)", 0.025)]

results = Dict{String, NamedTuple}()

for (regime_name, K_val) in regimes
    @printf("\nEvaluating attacker grid under %s ...\n", regime_name)

    raw    = zeros(length(A_grid), length(ρ_grid))
    p_det  = zeros(length(A_grid), length(ρ_grid))
    eu     = zeros(length(A_grid), length(ρ_grid))

    t_start = time()
    for (i, A) in enumerate(A_grid), (j, ρ) in enumerate(ρ_grid)
        r = attacker_payoff(PoisonNK_Filter, A=A, ρ=ρ, K_gain=K_val)
        raw[i, j]   = r.payoff
        p_det[i, j] = r.p_det
        eu[i, j]    = r.expected
    end
    @printf("  Done in %.1f seconds.\n", time() - t_start)

    # Find optimum
    idx      = argmax(eu)
    A_star   = A_grid[idx[1]]
    ρ_star   = ρ_grid[idx[2]]
    u_star   = eu[idx]
    raw_star = raw[idx]
    det_star = p_det[idx]

    @printf("  Optimal attack: A* = %.2f, ρ* = %.2f\n", A_star, ρ_star)
    @printf("    Raw payoff (|cum i|):     %.2f bp\n", raw_star)
    @printf("    Detection probability:    %.1f%%\n", 100*det_star)
    @printf("    Expected attacker utility: %.2f bp (undetected-adjusted)\n", u_star)

    results[regime_name] = (raw=raw, p_det=p_det, eu=eu,
                             A_star=A_star, ρ_star=ρ_star,
                             u_star=u_star, raw_star=raw_star, det_star=det_star,
                             K_gain=K_val)
end

# Comparison summary
println("\n" * "=" ^ 92)
println("Attacker's optimal choice under each defense regime")
println("=" ^ 92)
@printf("%-24s | %6s | %6s | %11s | %12s | %16s\n",
        "Regime", "A*", "ρ*", "raw |Δi| bp", "P(det)%", "E[attack util] bp")
println("-" ^ 92)

for (regime_name, _) in regimes
    r = results[regime_name]
    @printf("%-24s | %6.2f | %6.2f | %11.2f | %12.1f | %16.2f\n",
            regime_name, r.A_star, r.ρ_star, r.raw_star,
            100*r.det_star, r.u_star)
end
println("=" ^ 92)

u_naive  = results["Naive Fed (K=1.00)"].u_star
u_filter = results["Filter Fed (K=0.025)"].u_star
@printf("\nAttacker utility drop from filtering: %.2f → %.2f (%+.1f%%)\n",
        u_naive, u_filter, 100 * (u_filter - u_naive) / u_naive)

# Figures
println("\nGenerating figures ...")
gr()

function sym_clims(M)
    lim = maximum(abs.(M))
    return (-lim, lim)
end

plots_list = Any[]
for (regime_name, _) in regimes
    r = results[regime_name]
    p = heatmap(ρ_grid, A_grid, r.eu,
                title = "E[attacker utility], " * regime_name,
                xlabel = "ρ_att (persistence)",
                ylabel = "A (attack magnitude, σ)",
                clims = sym_clims(r.eu),
                c = cgrad(:RdBu),   # red = attacker does well
                colorbar_title = "bp")
    scatter!(p, [r.ρ_star], [r.A_star],
             markersize = 10, markershape = :star5,
             color = :yellow, markerstrokecolor = :black,
             markerstrokewidth = 1.5, label = "optimum")
    push!(plots_list, p)
end

fig = plot(plots_list..., layout = (1, 2), size = (1300, 500),
           plot_title = "Strategic attacker: optimal (A, ρ) by Fed defense regime",
           plot_titlefontsize = 12)

png_path = joinpath(@__DIR__, "..", "results", "strategic_attacker.png")
mkpath(dirname(png_path))
savefig(fig, png_path)
println("Figure saved to $png_path")

# Save raw data
df = DataFrame(regime=String[], K_gain=Float64[],
               A=Float64[], ρ_att=Float64[],
               raw_payoff_bp=Float64[], p_det=Float64[],
               expected_utility_bp=Float64[])
for (regime_name, K_val) in regimes
    r = results[regime_name]
    for (i, A) in enumerate(A_grid), (j, ρ) in enumerate(ρ_grid)
        push!(df, (regime_name, K_val, A, ρ, r.raw[i,j], r.p_det[i,j], r.eu[i,j]))
    end
end
CSV.write(joinpath(@__DIR__, "..", "results", "strategic_attacker_grid.csv"), df)

println("\nDone.")
