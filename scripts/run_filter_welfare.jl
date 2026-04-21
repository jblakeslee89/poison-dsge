using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "poison_nk_filter.jl"))

using MacroModelling
using Plots
using Printf
using DataFrames
using CSV

println("=" ^ 76)
println("Kalman perception + welfare: how much can filtering defend against attack?")
println("=" ^ 76)

# Pre-compile
println("\nPre-compiling ...")
_ = get_irf(PoisonNK_Filter, periods = 1)
println("Done.\n")

# Welfare loss: L = var(π_ann) + λ·var(ygap), λ = 0.5
# Compute model-implied unconditional variances under (a) all shocks active
# and (b) attack shock muted (σ_att = 0).
λ = 0.5

# Using IRF energy as a proxy for variance contribution per shock
# (since each shock is unit-σ, sum of squared IRF gives variance contribution).
function shock_variance_contribution(model, shk::Symbol, var::Symbol;
                                      params, periods=80, scale=1.0)
    irf = get_irf(model, parameters = params, periods = periods)
    series = [irf(var, p, shk) * scale for p in 1:periods]
    return sum(series .^ 2)
end

function welfare_loss(model; params, attack_on::Bool, λ=0.5, periods=80)
    σ_att_val = attack_on ? 1.0 : 0.0
    full_params = vcat(params, [:σ_att => σ_att_val])

    var_pi   = sum(shock_variance_contribution(model, shk, :π;
                                                params = full_params,
                                                periods = periods,
                                                scale = 4.0)   # annualized pp
                   for shk in [:ε_rn, :ε_ν, :ε_att])
    var_ygap = sum(shock_variance_contribution(model, shk, :ygap;
                                                params = full_params,
                                                periods = periods)
                   for shk in [:ε_rn, :ε_ν, :ε_att])
    return (loss = var_pi + λ * var_ygap, var_pi = var_pi, var_ygap = var_ygap)
end

# Three regimes
regimes = [
    ("Naive (K=1.00)",       1.00),
    ("Filter (K=0.50)",      0.50),
    ("Heavy filter (K=0.20)", 0.20),
]

println("=" ^ 88)
println("Welfare loss under SW frictions (χ_p=0.5, h=0.7, ρ_i=0.7), 80-period horizon")
@printf("%-22s | %12s | %12s | %14s | %12s\n",
        "Regime", "L (no atk)", "L (atk on)", "Δ from atk", "Robust gain")
println("-" ^ 88)

results = DataFrame(regime=String[], K_gain=Float64[],
                    L_no_attack=Float64[], L_attack=Float64[],
                    Δ_attack=Float64[])

base_params = [:χ_p => 0.5, :h => 0.7, :ρ_i => 0.7, :ρ_p => 0.85]

L_naive_atk = nothing  # for robustness gain reference
for (name, k) in regimes
    params = vcat(base_params, [:K_gain => k])

    L_off = welfare_loss(PoisonNK_Filter, params=params, attack_on=false, λ=λ)
    L_on  = welfare_loss(PoisonNK_Filter, params=params, attack_on=true,  λ=λ)
    Δ     = L_on.loss - L_off.loss

    if k == 1.00
        global L_naive_atk = Δ
    end
    rg = isnothing(L_naive_atk) ? "—" : @sprintf("%+5.1f%%", 100 * (L_naive_atk - Δ) / L_naive_atk)

    @printf("%-22s | %12.4f | %12.4f | %+14.4f | %12s\n",
            name, L_off.loss, L_on.loss, Δ, rg)

    push!(results, (name, k, L_off.loss, L_on.loss, Δ))
end
println("=" ^ 88)

# Same comparison for attack-shock dynamics
println("\nAttack-shock impact + cumulative policy response by regime (bp):")
println("-" ^ 76)
@printf("%-22s | %10s | %14s\n", "Regime", "i₀ (bp)", "cum 8Q (bp)")
println("-" ^ 76)

irf_compare = DataFrame(regime=String[], K_gain=Float64[],
                        period=Int[], i_bp=Float64[], pi_pp_ann=Float64[])

for (name, k) in regimes
    params = vcat(base_params, [:K_gain => k])
    irf = get_irf(PoisonNK_Filter, parameters = params, periods = 16)
    i_series = [irf(:i, p, :ε_att) * 100 for p in 1:8]
    @printf("%-22s | %+10.3f | %+14.3f\n", name, i_series[1], sum(i_series))

    for p in 1:16
        push!(irf_compare, (name, k, p-1,
                            irf(:i, p, :ε_att) * 100,
                            irf(:π, p, :ε_att) * 4))
    end
end
println("-" ^ 76)

# Now sweep K_gain finely for the welfare-vs-K_gain plot
println("\nFine sweep of K_gain (welfare vs filtering) ...")
ks = 0.05:0.05:1.0
welfare_off = Float64[]
welfare_on  = Float64[]
for k in ks
    params = vcat(base_params, [:K_gain => k])
    push!(welfare_off, welfare_loss(PoisonNK_Filter, params=params, attack_on=false, λ=λ).loss)
    push!(welfare_on,  welfare_loss(PoisonNK_Filter, params=params, attack_on=true,  λ=λ).loss)
end

# Plots
println("\nGenerating figure ...")
gr()

p1 = plot(ks, welfare_off, label="No attack",
          xlabel="K_gain (Fed's weight on raw signal)",
          ylabel="Welfare loss L = var(π) + 0.5·var(ygap)",
          title="Welfare vs filtering intensity",
          linewidth=2, color=:steelblue, marker=:circle)
plot!(p1, ks, welfare_on, label="Attack active",
      linewidth=2, color=:firebrick, marker=:square)
vline!(p1, [1.0], color=:gray, linestyle=:dash, label="naive (K=1)")

# Find K_gain that minimizes welfare loss under attack
best_k_idx = argmin(welfare_on)
vline!(p1, [ks[best_k_idx]], color=:darkgreen, linestyle=:dot,
       label = @sprintf("optimal K=%.2f", ks[best_k_idx]))

# Panel 2: attack-shock IRF for the three named regimes
p2 = plot(xlabel="Quarters after attack",
          ylabel="Policy rate response (bp)",
          title="Attack-shock IRF by regime",
          legend=:bottomright)
colors = [:firebrick, :steelblue, :darkgreen]
for (idx, (name, k)) in enumerate(regimes)
    sub = irf_compare[(irf_compare.regime .== name), :]
    plot!(p2, sub.period, sub.i_bp, label=name,
          linewidth=2, color=colors[idx], marker=:circle, markersize=4)
end
hline!(p2, [0], color=:black, linestyle=:dash, label="")

fig = plot(p1, p2, layout=(1,2), size=(1200, 480),
           plot_title="Filter regime tradeoff: defense vs responsiveness",
           plot_titlefontsize=12)

png_path = joinpath(@__DIR__, "..", "results", "filter_welfare.png")
mkpath(dirname(png_path))
savefig(fig, png_path)
println("Figure saved to $png_path")

# Save numeric results
csv_results = joinpath(@__DIR__, "..", "results", "filter_welfare_summary.csv")
CSV.write(csv_results, results)

csv_irf = joinpath(@__DIR__, "..", "results", "filter_welfare_irf.csv")
CSV.write(csv_irf, irf_compare)

csv_sweep = joinpath(@__DIR__, "..", "results", "filter_welfare_sweep.csv")
CSV.write(csv_sweep, DataFrame(K_gain=collect(ks), L_no_attack=welfare_off, L_attack=welfare_on))

println("\nFiles:")
println("  $png_path")
println("  $csv_results")
println("  $csv_irf")
println("  $csv_sweep")

# Summary
@printf("\nOptimal K_gain (minimizes L under attack): %.2f\n", ks[best_k_idx])
@printf("Welfare loss at K=1.00 (naive):             %.4f\n", welfare_on[end])
@printf("Welfare loss at K=%.2f (optimal):           %.4f\n",
        ks[best_k_idx], welfare_on[best_k_idx])
@printf("Robustness gain from filtering:             %+5.1f%%\n",
        100 * (welfare_on[end] - welfare_on[best_k_idx]) / welfare_on[end])

println("\nDone.")
