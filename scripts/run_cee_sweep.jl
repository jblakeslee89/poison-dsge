using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "poison_nk_cee.jl"))

using MacroModelling
using Printf
using DataFrames
using CSV

println("=" ^ 76)
println("CEE-friction sweep — does the +1pp attack sign-flip survive?")
println("=" ^ 76)

# Five scenarios. Friction values follow Smets-Wouters (2007) when on.
scenarios = [
    ("Toy (no frictions)",       [:χ_p => 0.0, :h => 0.0, :ρ_i => 0.0]),
    ("+ Indexation (χ_p=0.5)",   [:χ_p => 0.5, :h => 0.0, :ρ_i => 0.0]),
    ("+ Habit (h=0.7)",          [:χ_p => 0.0, :h => 0.7, :ρ_i => 0.0]),
    ("+ Smoothing (ρ_i=0.7)",    [:χ_p => 0.0, :h => 0.0, :ρ_i => 0.7]),
    ("All three (SW posterior)", [:χ_p => 0.5, :h => 0.7, :ρ_i => 0.7]),
]

# Pre-compile by solving once at default parameters
println("\nPre-compiling model ...")
_ = get_irf(PoisonNK_CEE, periods = 1)
println("Done.\n")

# Header
println("=" ^ 88)
@printf("%-32s | %14s | %14s | %14s\n",
        "Scenario", "i₀ (bp)", "π₀ (pp ann)", "ygap₀ (pp)")
println("-" ^ 88)

# Storage for the full IRF dump
all_irfs = DataFrame(scenario=String[], period=Int[], variable=String[], shock=String[], value=Float64[])

for (name, params) in scenarios
    irf = get_irf(PoisonNK_CEE, parameters = params, periods = 16)

    # Impact response (period 1 in 1-indexed array = period 0 in event time)
    i_imp    = irf(:i,     1, :ε_att) * 100   # bp
    pi_imp   = irf(:π,     1, :ε_att) * 4     # pp annualized
    ygap_imp = irf(:ygap,  1, :ε_att)         # pp

    @printf("%-32s | %+14.3f | %+14.4f | %+14.4f\n",
            name, i_imp, pi_imp, ygap_imp)

    for shk in [:ε_rn, :ε_ν, :ε_att],
        var in [:attack, :i, :rn, :ygap, :ν, :π],
        p   in 1:16
        push!(all_irfs, (name, p-1, String(var), String(shk), irf(var, p, shk)))
    end
end

println("=" ^ 88)

# Multi-period view of the attack shock for the final scenario
println("\nAttack-shock IRF (period 0..7) by scenario, policy rate (bp):")
println("-" ^ 88)
@printf("%-32s | %s\n", "Scenario",
        join([@sprintf("Q%d", q) for q in 0:7], "    "))
println("-" ^ 88)
for (name, params) in scenarios
    irf = get_irf(PoisonNK_CEE, parameters = params, periods = 16)
    series = [@sprintf("%+6.2f", irf(:i, p, :ε_att) * 100) for p in 1:8]
    @printf("%-32s | %s\n", name, join(series, "  "))
end
println("-" ^ 88)

# Same for inflation
println("\nAttack-shock IRF (period 0..7) by scenario, inflation (pp annualized):")
println("-" ^ 88)
@printf("%-32s | %s\n", "Scenario",
        join([@sprintf("Q%d", q) for q in 0:7], "    "))
println("-" ^ 88)
for (name, params) in scenarios
    irf = get_irf(PoisonNK_CEE, parameters = params, periods = 16)
    series = [@sprintf("%+6.2f", irf(:π, p, :ε_att) * 4) for p in 1:8]
    @printf("%-32s | %s\n", name, join(series, "  "))
end
println("-" ^ 88)

# Save full IRF panel
out_path = joinpath(@__DIR__, "..", "results", "irf_cee_sweep.csv")
mkpath(dirname(out_path))
CSV.write(out_path, all_irfs)
println("\nFull IRF panel ($(nrow(all_irfs)) rows) → $out_path")
println("\nDone.")
