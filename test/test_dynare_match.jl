using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "poison_nk.jl"))

using MacroModelling
using MAT
using Printf

function run_comparison()
    # full_ar1.mat is the canonical Dynare reference: contains IRFs for all
    # three shocks (rn_shk, nu_shk, atk_shk). The other two .mat files in
    # the reference folder are missing the attack-shock IRFs.
    ref_path = joinpath(@__DIR__, "..", "data", "dynare_reference", "full_ar1.mat")
    ref      = matread(ref_path)
    dyn_irfs = ref["oo_"]["irfs"]

    println("Dynare reference: $(basename(ref_path))")
    println("  $(length(keys(dyn_irfs))) IRF series loaded\n")

    println("Computing Julia IRFs (MacroModelling.jl) ...")
    jul_irfs = get_irf(PoisonNK, periods = 16)

    # Variable / shock name maps
    ascii_var = Dict(:π => "pi", :ν => "nu", :ygap => "ygap",
                     :i => "i", :rn => "rn", :attack => "attack")
    ascii_shk = Dict(:ε_rn => "rn_shk", :ε_ν => "nu_shk", :ε_att => "atk_shk")

    println("\n" * "=" ^ 76)
    println("Julia vs. Dynare IRF comparison — max |Δ| over horizons 1..16")
    println("=" ^ 76)
    @printf("%-10s %-10s %14s %14s   %s\n",
            "variable", "shock", "max|Δ|", "max|val|", "result")
    println("-" ^ 76)

    tol      = 1e-8
    all_pass = true
    n_compared = 0

    for (jvar, dvar) in ascii_var, (jshk, dshk) in ascii_shk
        dyn_key = "$(dvar)_$(dshk)"
        haskey(dyn_irfs, dyn_key) || continue

        dyn_series = vec(dyn_irfs[dyn_key])
        horizon    = min(length(dyn_series), 16)
        jul_series = [jul_irfs(jvar, p, jshk) for p in 1:horizon]

        diff      = maximum(abs.(jul_series .- dyn_series[1:horizon]))
        scale     = maximum(abs.(dyn_series[1:horizon]))
        pass      = diff < tol
        all_pass &= pass
        n_compared += 1
        mark      = pass ? "PASS" : "FAIL"

        @printf("%-10s %-10s %14.3e %14.3e   %s\n",
                String(jvar), String(jshk), diff, scale, mark)
    end

    println("=" ^ 76)
    println("Compared $n_compared series. $(all_pass ? "ALL PASS" : "SOME FAIL")")
    println("Tolerance: $tol")

    return all_pass
end

run_comparison()
