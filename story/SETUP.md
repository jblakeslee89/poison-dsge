# Story site setup — deploy runbook

The repo is at https://github.com/jblakeslee89/poison-dsge (private). The `main` branch holds source; the `gh-pages` branch holds rendered HTML, ready to serve.

## Important: GitHub Pages limitation on private repos

GitHub Pages does not work on private repos under a free GitHub plan. The push to `gh-pages` succeeded but enabling Pages returns HTTP 422 ("Your current plan does not support GitHub Pages for this repository").

Three options to get a live URL:

### Option 1: Make the repo public (simplest, free, immediate)

If there is no sensitive content (and there is not — this is a research project), this is the fastest path.

```bash
gh repo edit jblakeslee89/poison-dsge --visibility public --accept-visibility-change-consequences
gh api -X POST /repos/jblakeslee89/poison-dsge/pages -f 'source[branch]=gh-pages' -f 'source[path]=/'
```

Site is live in ~1 minute at **https://jblakeslee89.github.io/poison-dsge/**.

### Option 2: Cloudflare Pages (free, keeps repo private)

1. Sign in at dash.cloudflare.com (free account).
2. **Workers & Pages** → **Create application** → **Pages** → **Connect to Git**.
3. Authorize Cloudflare's GitHub app for the `poison-dsge` repo only.
4. Build settings:
    - Production branch: `main`
    - Build command: `pip install -r story/requirements.txt && curl -sL https://github.com/quarto-dev/quarto-cli/releases/download/v1.6.43/quarto-1.6.43-linux-amd64.tar.gz | tar -xz && ./quarto-1.6.43/bin/quarto render story`
    - Build output directory: `story/_site`
5. Deploy. Site is live at `https://poison-dsge.pages.dev` (or a custom domain you add later).

Cloudflare's free tier supports private GitHub repos, custom domains, and unlimited bandwidth.

### Option 3: GitHub Pro upgrade ($4/month)

Upgrades the personal account to support Pages on private repos. Run the same `gh api` commands as Option 1 once upgraded.

## Iterating locally

The story is fully renderable from your laptop without any of the above. To work on it:

```bash
cd "/Users/johnpb89/Claude Projects/Econ/poison-dsge/story"
QUARTO_PYTHON="$(pwd)/.venv/bin/python" ~/.local/bin/quarto preview
```

Opens a live-reload preview at http://localhost:4444. Edit `index.qmd` or `charts.py` and the page reloads automatically.

## Pushing updates

```bash
cd "/Users/johnpb89/Claude Projects/Econ/poison-dsge"
git add story/
git commit -m "Update story"
git push

# Then re-render and re-publish gh-pages:
cd story
QUARTO_PYTHON="$(pwd)/.venv/bin/python" ~/.local/bin/quarto render
cd /tmp && rm -rf poison-dsge-pages
git clone --depth 1 -b gh-pages https://github.com/jblakeslee89/poison-dsge.git poison-dsge-pages
rm -rf poison-dsge-pages/!(.git)  # clear old content
cp -R "/Users/johnpb89/Claude Projects/Econ/poison-dsge/story/_site/." poison-dsge-pages/
touch poison-dsge-pages/.nojekyll
cd poison-dsge-pages && git add -A && git commit -m "Update site" && git push origin gh-pages
```

(The GitHub Actions workflow at `.github/workflows/publish-story.yml` automates this once the repo is public or upgraded — but on free private it cannot push to a Pages-served branch since Pages itself is disabled.)

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
