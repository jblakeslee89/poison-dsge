# Story site: Adversarial Nowcasting

Quarto + Closeread scrollytelling site for the poison-dsge project.

## Local development

```bash
cd story
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt

# Render once to /tmp:
QUARTO_PYTHON=$(pwd)/.venv/bin/python quarto render

# Live preview:
QUARTO_PYTHON=$(pwd)/.venv/bin/python quarto preview
```

The site reads pre-computed DSGE results from `../results/dash_cache_*.csv` (the same cache the Dash app uses).

## Structure

| File | Purpose |
|------|---------|
| `_quarto.yml` | Site config, navbar, Closeread defaults |
| `index.qmd` | The data story (hero + scrollytelling + big-stat + method note) |
| `methodology.qmd` | High-level methodology summary, links to LaTeX brief |
| `explore.qmd` | Static charts of the three canonical scenarios + link to Dash app |
| `charts.py` | Plotly chart factory; reads `../results/dash_cache_*.csv` |
| `styles.scss` | Editorial typography, hero block, big-stat callout |
| `_extensions/` | Closeread extension (installed via `quarto add qmd-lab/closeread`) |

## Deploying to GitHub Pages

One-time setup (after the GitHub repository is created and `git remote add origin` points to it):

```bash
# From the story/ directory
QUARTO_PYTHON=$(pwd)/.venv/bin/python quarto publish gh-pages
```

This will:
1. Render the site
2. Create a `gh-pages` branch
3. Push the rendered `_site/` to it
4. Configure GitHub Pages to serve from `gh-pages`

After the first publish, the site will be live at `https://<username>.github.io/<repo>/`.

For subsequent deploys, just re-run `quarto publish gh-pages`.

## Notes

- The Closeread layout is `sidebar-left`: narrative text on the left, sticky chart on the right.
- The `freeze: auto` setting in `_quarto.yml` caches Python execution between renders. Force a re-execute by deleting `_freeze/`.
- The "5×" stat in the hero is computed live from the cache via `charts.cumulative_5x_callout()`.
