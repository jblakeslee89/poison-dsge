# Poison-DSGE: Adversarial Nowcasting and Monetary Policy

Julia port and extension of Blakeslee (2025), *Data Poisoning, Nowcasting, and Monetary Policy*. The original 3-equation NK-DSGE toy model was implemented in Dynare 6.3 for a Spring 2025 RAND macro course. This project rebuilds it in Julia (MacroModelling.jl), validates against the Dynare reference output, then extends it to a workhorse NK / Smets-Wouters-lite specification with a Kalman-filter perception block, strategic-attacker dynamics, Monte Carlo over policy regimes, and an interactive Plotly Dash front-end.

## Status

- [x] Project scaffold
- [x] Julia env (MacroModelling.jl, MAT.jl, Plots.jl)
- [ ] Port toy model (`src/poison_nk.jl`)
- [ ] Validate against Dynare IRFs (`test/`)
- [ ] Galí (2008) NK extension
- [ ] Kalman perception block
- [ ] Strategic attacker
- [ ] Monte Carlo grid
- [ ] Dash front-end

## Methodological commitment

The rebuilt model is **not** calibrated to reproduce the toy result (a +1pp attack flipping a 50bp hike into a 1-2bp cut via the expectations channel). Whatever the workhorse specification produces, that is the finding.

## Layout

```
src/                 Model definitions
scripts/             Runners (solve, plot, sweep)
test/                Regression tests vs. Dynare reference
data/dynare_reference/  Original .mod files and .mat IRF outputs
results/             Generated figures and tables (gitignored)
docs/                Methodology brief
```

## Reference

Original Dynare source: `data/dynare_reference/poison_nk_ar1_attack.mod`
