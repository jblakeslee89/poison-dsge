# Story site setup — GitHub flow

This is the deployment runbook. Follow it once the GitHub repository exists.

## 1. Create the GitHub repo

```bash
# On github.com: create a public repo called `poison-dsge` under your account.
# Do NOT initialize with README/license/.gitignore (the local repo already has commits).

cd "/Users/johnpb89/Claude Projects/Econ/poison-dsge"
git remote add origin https://github.com/jblakeslee89/poison-dsge.git
git branch -M main
git push -u origin main
```

## 2. Enable GitHub Pages

1. On github.com, go to your repo → **Settings** → **Pages**.
2. Under "Build and deployment" → **Source**, choose **Deploy from a branch**.
3. Under "Branch", select `gh-pages` (it will not exist yet — that's fine; it gets created on first deploy).
4. Save.

## 3. First-time deploy (option A: from your laptop)

The simplest path. Run this once, after you've pushed to GitHub:

```bash
cd "/Users/johnpb89/Claude Projects/Econ/poison-dsge/story"
QUARTO_PYTHON="$(pwd)/.venv/bin/python" ~/.local/bin/quarto publish gh-pages
```

Quarto will:
- Render the site locally
- Create the `gh-pages` branch
- Push the rendered HTML to it
- Configure GitHub Pages metadata

The first time you run this, Quarto asks for confirmation and your GitHub credentials (it uses `gh auth` if you have GitHub CLI, or git's credential helper otherwise).

After first publish, the site is live at:

**https://jblakeslee89.github.io/poison-dsge/**

(Replace `jblakeslee89` if your GitHub username differs.)

## 4. Subsequent deploys (option B: automatic via GitHub Actions)

The repo includes `.github/workflows/publish-story.yml`. Once enabled:

1. Any push to `main` that touches `story/**` or `results/dash_cache_*.csv` triggers a build.
2. The workflow installs Quarto and Python, renders the site, and pushes to `gh-pages`.
3. GitHub Pages serves the new version within ~1 minute.

To enable: on github.com, go to **Settings** → **Actions** → **General** → ensure "Allow all actions and reusable workflows" is selected. Push to `main` and watch the **Actions** tab.

## 5. Iterating locally

```bash
cd story
QUARTO_PYTHON="$(pwd)/.venv/bin/python" ~/.local/bin/quarto preview
```

Opens a live-reload preview at http://localhost:4444. Edit `index.qmd` or `charts.py` and the page reloads automatically.

## 6. Custom domain (optional)

If you want `poison-dsge.johnblakeslee.com` instead of the github.io URL:

1. Buy/configure DNS at Cloudflare or your registrar of choice.
2. Add a `CNAME` record pointing `poison-dsge.johnblakeslee.com` → `jblakeslee89.github.io`.
3. In `story/CNAME` (create the file), put the bare domain on one line: `poison-dsge.johnblakeslee.com`.
4. On github.com → repo → Settings → Pages → Custom domain → enter the domain → Save.
5. Tick "Enforce HTTPS" once the cert provisions (usually <10 minutes).

## What's in the deployed site

| Page | URL path | Content |
|------|---------|---------|
| Story | `/` | Hero, lede, scrollytelling (3 acts), big-stat callout, methodology note |
| Methodology | `/methodology.html` | Model summary, calibration grid, validation note |
| Try it yourself | `/explore.html` | Static charts of the three canonical scenarios |

## Known issue: the "5×" claim

The dash app's tour text and the project memory file describe the cumulative undershoot under realistic frictions as "~5× the toy memo's cumulative distortion." The current `results/dash_cache_*.csv` does not support this. Across cumulative windows of 4, 8, 12, and 16 quarters, the realistic-to-toy ratio is consistently 1.4× to 1.7×.

The story site uses the verifiable number ("74 bp / about 1.7×"). Before showing this to Wenger, decide whether:

(a) Re-run the precompute with a different parameterization that produces 5× (if there was a calibration drift between the original memo and the current cache);
(b) Update the dash app's tour text and the memo to match the current 1.7× finding;
(c) Reframe the headline finding around a different ratio that *is* 5× (e.g., welfare-cost ratio under a specific filter regime, peak deviation, variance ratio).

The 1.7× cumulative finding is still a meaningful and publishable result. The frame "the attack is worse, not better; it is just displaced in time" survives.
