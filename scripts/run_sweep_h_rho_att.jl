using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

include(joinpath(@__DIR__, "..", "src", "poison_nk_cee.jl"))

using MacroModelling
using Plots
using Printf
using DataFrames
using CSV

println("=" ^ 76)
println("2D parameter sweep: h × ρ_att (under SW posterior frictions)")
println("Holding χ_p = 0.5, ρ_i = 0.7. Varying habit and attack persistence.")
println("=" ^ 76)

# Grid
hs       = 0.0:0.05:0.95   # 20 points
rho_atts = 0.0:0.05:0.95   # 20 points

# Pre-compile
println("\nPre-compiling ...")
_ = get_irf(PoisonNK_CEE, periods = 1)
println("Done. Sweeping $(length(hs))×$(length(rho_atts)) = $(length(hs)*length(rho_atts)) grid points.\n")

i0_grid   = zeros(length(hs), length(rho_atts))   # impact response, bp
icum_grid = zeros(length(hs), length(rho_atts))   # cumulative Q0..Q7, bp

t_start = time()
for (i, h_val) in enumerate(hs), (j, ra_val) in enumerate(rho_atts)
    irf = get_irf(PoisonNK_CEE,
                  parameters = [:h => h_val, :ρ_att => ra_val,
                                :χ_p => 0.5, :ρ_i => 0.7],
                  periods = 16)
    series_bp = [irf(:i, p, :ε_att) * 100 for p in 1:8]
    i0_grid[i, j]   = series_bp[1]
    icum_grid[i, j] = sum(series_bp)
end
t_elapsed = time() - t_start
@printf("Sweep complete in %.1f seconds.\n", t_elapsed)

# Save raw grid as CSV
df = DataFrame(h=Float64[], rho_att=Float64[], i0_bp=Float64[], icum8_bp=Float64[])
for (i, h_val) in enumerate(hs), (j, ra_val) in enumerate(rho_atts)
    push!(df, (h_val, ra_val, i0_grid[i,j], icum_grid[i,j]))
end
csv_path = joinpath(@__DIR__, "..", "results", "sweep_h_rho_att.csv")
mkpath(dirname(csv_path))
CSV.write(csv_path, df)
println("Saved $(nrow(df)) rows to $csv_path")

# Plot heatmaps with zero contour
println("\nGenerating figure ...")
gr()

function sym_clims(M)
    lim = maximum(abs.(M))
    return (-lim, lim)
end

p1 = heatmap(rho_atts, hs, i0_grid,
             title = "Impact policy response i₀ (bp)",
             xlabel = "ρ_att (attack persistence)",
             ylabel = "h (consumption habit)",
             clims = sym_clims(i0_grid),
             c = cgrad(:RdBu, rev = true),
             colorbar_title = "bp",
             size = (600, 500))
contour!(p1, rho_atts, hs, i0_grid, levels = [0.0],
         color = :black, linewidth = 2, label = "")

p2 = heatmap(rho_atts, hs, icum_grid,
             title = "Cumulative 8Q response Σi₀..₇ (bp)",
             xlabel = "ρ_att (attack persistence)",
             ylabel = "h (consumption habit)",
             clims = sym_clims(icum_grid),
             c = cgrad(:RdBu, rev = true),
             colorbar_title = "bp",
             size = (600, 500))
contour!(p2, rho_atts, hs, icum_grid, levels = [0.0],
         color = :black, linewidth = 2, label = "")

fig = plot(p1, p2, layout = (1, 2), size = (1200, 500),
           plot_title = "Adversarial nowcast: sign-flip frontier under SW frictions",
           plot_titlefontsize = 12)

png_path = joinpath(@__DIR__, "..", "results", "sweep_h_rho_att.png")
savefig(fig, png_path)
println("Figure saved to $png_path")

# Summary stats
println("\n" * "=" ^ 76)
println("Summary")
println("=" ^ 76)
@printf("Impact response i₀:    range [%+7.2f, %+7.2f] bp\n",
        minimum(i0_grid), maximum(i0_grid))
@printf("Cumulative 8Q i₀..₇:   range [%+7.2f, %+7.2f] bp\n",
        minimum(icum_grid), maximum(icum_grid))

# Quick scan of where impact crosses zero
println("\nFraction of grid cells with i₀ < 0 (sign-flip survives at impact): ",
        @sprintf("%.1f%%", 100 * count(<(0), i0_grid) / length(i0_grid)))
println("Fraction of grid cells with cumulative < 0 (sign-flip survives in cum): ",
        @sprintf("%.1f%%", 100 * count(<(0), icum_grid) / length(icum_grid)))

# Slice: at ρ_att = 0.8 (the toy calibration), find h-threshold
j_ref = findfirst(==(0.80), collect(rho_atts))
if !isnothing(j_ref)
    println("\nAt ρ_att = 0.80 (toy calibration), impact response by h:")
    println("  h    | i₀ (bp)  | cum8 (bp)")
    println("  -----|----------|----------")
    for i in 1:length(hs)
        @printf("  %.2f | %+8.2f | %+8.2f\n", hs[i], i0_grid[i, j_ref], icum_grid[i, j_ref])
    end
end

println("\nDone.")
