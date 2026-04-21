using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "poison_nk_filter.jl"))

using MacroModelling
using Plots
using Printf
using DataFrames
using CSV

println("=" ^ 76)
println("Filter robustness: K_gain → 0 and ρ_p sensitivity")
println("At empirical κ = 0.15, SW-posterior frictions")
println("=" ^ 76)

_ = get_irf(PoisonNK_Filter, periods = 1)   # pre-compile

λ = 0.5
ks          = 0.00:0.025:1.00              # extended floor, finer grid
rho_p_vals  = [0.50, 0.70, 0.85, 0.95]
base_params = [:κ => 0.15, :χ_p => 0.5, :h => 0.7, :ρ_i => 0.7]

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

results    = Dict{Float64, NamedTuple}()
summary_df = DataFrame(ρ_p=Float64[], K_opt=Float64[], L_at_Kopt=Float64[],
                       L_at_K1=Float64[], L_no_attack_at_Kopt=Float64[],
                       L_no_attack_at_K1=Float64[], crossover_p=Float64[])

for ρ_p in rho_p_vals
    @printf("\nSolving ρ_p = %.2f ...\n", ρ_p)
    L_off = Float64[]
    L_on  = Float64[]
    for K in ks
        params = vcat(base_params, [:K_gain => K, :ρ_p => ρ_p])
        push!(L_off, welfare_loss(PoisonNK_Filter, params=params, attack_on=false, λ=λ))
        push!(L_on,  welfare_loss(PoisonNK_Filter, params=params, attack_on=true,  λ=λ))
    end
    results[ρ_p] = (L_off=L_off, L_on=L_on)

    idx_naive = findfirst(==(1.0), collect(ks))
    idx_best  = argmin(L_on)
    K_opt     = ks[idx_best]

    A = L_on[idx_naive]
    C = L_off[idx_naive]
    B = L_on[idx_best]
    D = L_off[idx_best]
    p_star = (D - C) / ((A - B) + (D - C))

    @printf("  K_opt = %.3f    L_on(K_opt) = %.3f    L_no(K_opt) = %.3f\n",
            K_opt, B, D)
    @printf("  K=1.0:           L_on = %.3f              L_no = %.3f\n", A, C)
    @printf("  crossover p*     = %.2f%%\n", 100 * p_star)

    push!(summary_df, (ρ_p, K_opt, B, A, D, C, p_star))
end

# Figure: 4 curves on one plot, with zoom inset on K ∈ [0, 0.3]
println("\nGenerating figure ...")
gr()

p1 = plot(xlabel="K_gain (Fed's weight on raw signal)",
          ylabel="Welfare loss L under attack",
          title="Welfare under attack vs filtering intensity",
          legend=:topleft)

colors_rp = [:steelblue, :darkgreen, :firebrick, :purple]
for (idx, ρ_p) in enumerate(rho_p_vals)
    r = results[ρ_p]
    plot!(p1, ks, r.L_on, label=@sprintf("ρ_p = %.2f", ρ_p),
          linewidth=2, color=colors_rp[idx], marker=:circle, markersize=3)
    idx_best = argmin(r.L_on)
    scatter!(p1, [ks[idx_best]], [r.L_on[idx_best]],
             color=colors_rp[idx], markersize=8, markershape=:star5,
             label="")
end

p2 = plot(xlabel="K_gain",
          ylabel="Welfare loss L (no attack)",
          title="Welfare under normal conditions",
          legend=:none)

for (idx, ρ_p) in enumerate(rho_p_vals)
    r = results[ρ_p]
    plot!(p2, ks, r.L_off,
          linewidth=2, color=colors_rp[idx], marker=:circle, markersize=3)
end

fig = plot(p1, p2, layout=(1,2), size=(1200, 480),
           plot_title=@sprintf("Robustness: K_gain floor and ρ_p sensitivity (κ=0.15)"),
           plot_titlefontsize=12)

png_path = joinpath(@__DIR__, "..", "results", "filter_robustness.png")
mkpath(dirname(png_path))
savefig(fig, png_path)
println("Figure saved to $png_path")

println("\n" * "=" ^ 88)
println("Summary")
println("=" ^ 88)
@printf("%-8s | %-8s | %-12s | %-14s | %-13s\n",
        "ρ_p", "K_opt", "L(K_opt|atk)", "L(K=1|atk)", "crossover p*")
println("-" ^ 88)
for row in eachrow(summary_df)
    @printf("%-8.2f | %-8.3f | %-12.3f | %-14.3f | %12.2f%%\n",
            row.ρ_p, row.K_opt, row.L_at_Kopt, row.L_at_K1,
            100 * row.crossover_p)
end
println("=" ^ 88)

CSV.write(joinpath(@__DIR__, "..", "results", "filter_robustness_summary.csv"), summary_df)

sweep_df = DataFrame(ρ_p=Float64[], K_gain=Float64[],
                     L_no_attack=Float64[], L_attack=Float64[])
for ρ_p in rho_p_vals, (i, K) in enumerate(ks)
    r = results[ρ_p]
    push!(sweep_df, (ρ_p, K, r.L_off[i], r.L_on[i]))
end
CSV.write(joinpath(@__DIR__, "..", "results", "filter_robustness_sweep.csv"), sweep_df)

println("\nDone.")
