using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "poison_nk.jl"))

using MacroModelling
using Printf
using DataFrames
using CSV

println("=" ^ 60)
println("Poison-NK toy model — Julia port (MacroModelling.jl)")
println("Faithful port of poison_nk_ar1_attack.mod, Dynare 6.3")
println("=" ^ 60)

vars   = sort(get_variables(PoisonNK))
shocks = sort(get_shocks(PoisonNK))

println("\nVariables: ", vars)
println("Shocks:    ", shocks)

println("\nSteady state:")
ss = get_SS(PoisonNK)
println(ss)

println("\nComputing IRFs (16-quarter horizon, 1 s.d. shocks)...")
irf_data = get_irf(PoisonNK, periods = 16)

# Print summary: response of i (bp), π (annualized pp), ygap (pp)
# to each of the three shocks at horizons 0, 1, 2, 4, 8.
println("\n" * "=" ^ 60)
println("IRF Summary — 1 s.d. shocks")
println("=" ^ 60)

shock_syms = [:ε_rn, :ε_ν, :ε_att]
horizons   = [1, 2, 3, 5, 9]   # 1-indexed array; period 0 = index 1

for shk in shock_syms
    println("\nShock: $shk")
    println("  Period | i (bp)   | π (pp ann) | ygap (pp)  | attack (pp)")
    println("  -------|----------|------------|------------|------------")
    for h in horizons
        # Variables are in percent (πstar=0.5, rstar=0.125). To bp: ×100.
        # Annualized inflation: quarterly π × 4.
        i_resp    = irf_data(:i,      h, shk) * 100
        pi_resp   = irf_data(:π,      h, shk) * 4
        ygap_resp = irf_data(:ygap,   h, shk)
        att_resp  = irf_data(:attack, h, shk)
        @printf("  %6d | %+8.3f | %+10.4f | %+10.4f | %+10.4f\n",
                h-1, i_resp, pi_resp, ygap_resp, att_resp)
    end
end

# Save full IRFs to CSV for downstream comparison with Dynare reference
println("\nSaving IRFs to results/irf_julia.csv ...")
mkpath(joinpath(@__DIR__, "..", "results"))

records = DataFrame(period = Int[], variable = String[], shock = String[], value = Float64[])
for shk in shock_syms
    for var in [:attack, :i, :rn, :ygap, :ν, :π]
        for p in 1:16
            push!(records, (p-1, String(var), String(shk), irf_data(var, p, shk)))
        end
    end
end
csv_path = joinpath(@__DIR__, "..", "results", "irf_julia.csv")
CSV.write(csv_path, records)
println("Wrote $(nrow(records)) rows to $csv_path")

println("\nDone.")
