using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "poison_nk_filter.jl"))

using MacroModelling
using DataFrames
using CSV
using Printf

println("=" ^ 76)
println("Pre-compute cache for Dash front-end")
println("Grid: κ × h × K_gain, 3 shocks × 3 variables × 16 quarters + welfare")
println("=" ^ 76)

_ = get_irf(PoisonNK_Filter, periods = 1)   # pre-compile

# Grid
κ_grid      = [0.06, 0.10, 0.15, 0.20]
h_grid      = [0.0, 0.3, 0.5, 0.7, 0.9]
K_grid      = collect(0.0:0.1:1.0)
shocks      = [:ε_rn, :ε_ν, :ε_att]
vars_track  = [:i, :π, :ygap]

# Fixed params (SW posterior)
base_params = [:χ_p => 0.5, :ρ_i => 0.7, :ρ_p => 0.85]

λ = 0.5

# Helpers
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

function run_grid()
    irf_rows     = DataFrame(κ=Float64[], h=Float64[], K_gain=Float64[],
                              shock=String[], variable=String[],
                              period=Int[], value=Float64[])
    welfare_rows = DataFrame(κ=Float64[], h=Float64[], K_gain=Float64[],
                              L_no_attack=Float64[], L_attack=Float64[])

    total = length(κ_grid) * length(h_grid) * length(K_grid)
    counter = 0
    t_start = time()

    for κ in κ_grid, h in h_grid, K in K_grid
        counter += 1
        params = vcat(base_params, [:κ => κ, :h => h, :K_gain => K])

        irf = get_irf(PoisonNK_Filter, parameters = params, periods = 16)
        for shk in shocks, var in vars_track, p in 1:16
            scale = (var == :i)    ? 100.0 :
                    (var == :π)    ? 4.0   :
                    1.0
            push!(irf_rows, (κ, h, K, String(shk), String(var), p-1,
                             irf(var, p, shk) * scale))
        end

        L_off = welfare_loss(PoisonNK_Filter, params=params, attack_on=false, λ=λ)
        L_on  = welfare_loss(PoisonNK_Filter, params=params, attack_on=true,  λ=λ)
        push!(welfare_rows, (κ, h, K, L_off, L_on))

        if counter % 20 == 0 || counter == total
            @printf("  [%4d / %d] elapsed %.1fs\n", counter, total, time() - t_start)
        end
    end

    return irf_rows, welfare_rows
end

irf_rows, welfare_rows = run_grid()

# Save
out_dir = joinpath(@__DIR__, "..", "results")
mkpath(out_dir)

irf_path     = joinpath(out_dir, "dash_cache_irfs.csv")
welfare_path = joinpath(out_dir, "dash_cache_welfare.csv")
CSV.write(irf_path, irf_rows)
CSV.write(welfare_path, welfare_rows)

println("\nIRF rows:     $(nrow(irf_rows))  →  $irf_path")
println("Welfare rows: $(nrow(welfare_rows))  →  $welfare_path")
@printf("Total time: %.1fs\n", time() - t_start)
println("Done.")
