using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "poison_nk_filter.jl"))

using MacroModelling
using Plots
using Printf
using DataFrames
using CSV

println("=" ^ 76)
println("κ sensitivity: does the Phillips slope change the filter-regime tradeoff?")
println("=" ^ 76)

_ = get_irf(PoisonNK_Filter, periods = 1)   # pre-compile

λ = 0.5
kappa_values = [0.06, 0.10, 0.15, 0.20]
ks           = 0.05:0.05:1.0
base_params  = [:χ_p => 0.5, :h => 0.7, :ρ_i => 0.7, :ρ_p => 0.85]

function shock_variance_contribution(model, shk, var; params, periods=80, scale=1.0)
    irf = get_irf(model, parameters = params, periods = periods)
    series = [irf(var, p, shk) * scale for p in 1:periods]
    return sum(series .^ 2)
end

function welfare_loss(model; params, attack_on::Bool, λ=0.5, periods=80)
    σ_att_val = attack_on ? 1.0 : 0.0
    full_params = vcat(params, [:σ_att => σ_att_val])
    var_pi = sum(shock_variance_contribution(model, shk, :π;
                    params=full_params, periods=periods, scale=4.0)
                 for shk in [:ε_rn, :ε_ν, :ε_att])
    var_ygap = sum(shock_variance_contribution(model, shk, :ygap;
                    params=full_params, periods=periods)
                   for shk in [:ε_rn, :ε_ν, :ε_att])
    return var_pi + λ * var_ygap
end

# For each κ, sweep K_gain
results = Dict{Float64, NamedTuple}()
sweep_df = DataFrame(κ=Float64[], K_gain=Float64[],
                     L_no_attack=Float64[], L_attack=Float64[])

for κ in kappa_values
    @printf("\nSolving κ = %.2f ...\n", κ)
    L_off = Float64[]
    L_on  = Float64[]
    for K in ks
        params = vcat(base_params, [:κ => κ, :K_gain => K])
        push!(L_off, welfare_loss(PoisonNK_Filter, params=params, attack_on=false, λ=λ))
        push!(L_on,  welfare_loss(PoisonNK_Filter, params=params, attack_on=true,  λ=λ))
        push!(sweep_df, (κ, K, L_off[end], L_on[end]))
    end
    results[κ] = (L_off=L_off, L_on=L_on)

    # Anchor at K=1.0 (naive); compute crossover probability for each alternative K
    idx_naive = findfirst(==(1.0), collect(ks))
    A = L_on[idx_naive]   # L_attack under naive
    C = L_off[idx_naive]  # L_no_attack under naive

    # Find K_gain that minimizes L_attack
    idx_best = argmin(L_on)
    B = L_on[idx_best]
    D = L_off[idx_best]
    K_opt = ks[idx_best]

    # Crossover probability: p* such that naive and best-K give same E[L]
    p_star = (D - C) / ((A - B) + (D - C))

    @printf("  Naive (K=1.00):   L_no=%.3f  L_on=%.3f\n", C, A)
    @printf("  Optimal K=%.2f:   L_no=%.3f  L_on=%.3f\n", K_opt, D, B)
    @printf("  Crossover p*:     %.2f%%\n", 100 * p_star)
end

# Plot: 4 panels, one per κ
println("\nGenerating figure ...")
gr()

plots = []
for (i, κ) in enumerate(kappa_values)
    r = results[κ]

    # Crossover reference
    idx_naive = findfirst(==(1.0), collect(ks))
    idx_best  = argmin(r.L_on)
    K_opt     = ks[idx_best]

    p = plot(ks, r.L_off, label="No attack",
             xlabel="K_gain",
             ylabel=i == 1 ? "Welfare loss L" : "",
             title=@sprintf("κ = %.2f", κ),
             linewidth=2, color=:steelblue, marker=:circle, markersize=3,
             legend=(i==1 ? :topright : :none))
    plot!(p, ks, r.L_on, label="Attack active",
          linewidth=2, color=:firebrick, marker=:square, markersize=3)
    vline!(p, [ks[idx_best]], color=:darkgreen, linestyle=:dot,
           label=(i==1 ? @sprintf("optimal K=%.2f", K_opt) : ""))

    push!(plots, p)
end

fig = plot(plots..., layout=(1, 4), size=(1600, 420),
           plot_title="κ sensitivity: filter tradeoff across Phillips-curve slopes",
           plot_titlefontsize=12)

png_path = joinpath(@__DIR__, "..", "results", "kappa_sensitivity.png")
mkpath(dirname(png_path))
savefig(fig, png_path)
println("Figure saved to $png_path")

# Summary table
println("\n" * "=" ^ 92)
println("Crossover thresholds by κ")
println("=" ^ 92)
@printf("%-10s | %-12s | %-12s | %-12s | %-12s | %-14s\n",
        "κ", "L_on naive", "L_off naive", "L_on opt", "K_opt", "Crossover p*")
println("-" ^ 92)

summary_df = DataFrame(κ=Float64[], L_on_naive=Float64[], L_off_naive=Float64[],
                       L_on_opt=Float64[], K_opt=Float64[], p_crossover=Float64[])

for κ in kappa_values
    r = results[κ]
    idx_naive = findfirst(==(1.0), collect(ks))
    idx_best  = argmin(r.L_on)
    A = r.L_on[idx_naive]
    C = r.L_off[idx_naive]
    B = r.L_on[idx_best]
    D = r.L_off[idx_best]
    K_opt = ks[idx_best]
    p_star = (D - C) / ((A - B) + (D - C))

    @printf("%-10.2f | %-12.4f | %-12.4f | %-12.4f | %-12.2f | %+13.2f%%\n",
            κ, A, C, B, K_opt, 100 * p_star)
    push!(summary_df, (κ, A, C, B, K_opt, p_star))
end
println("=" ^ 92)

CSV.write(joinpath(@__DIR__, "..", "results", "kappa_sensitivity_summary.csv"), summary_df)
CSV.write(joinpath(@__DIR__, "..", "results", "kappa_sensitivity_sweep.csv"), sweep_df)

println("\nDone.")
