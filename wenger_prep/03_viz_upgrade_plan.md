# Viz upgrade plan: from Dash app to Reuters-style data story

## What you have now

A clean, functional Dash app at `dash_app/app.py`. Three sliders (κ, h, K_gain), three preset buttons, a guided tour, IRF chart on the left, welfare bar chart on the right. Pre-computed cache loads instantly. Hosted-ready for HuggingFace Spaces via Docker. Methodology brief and companion primer in `docs/`.

It works. It is academically credible. But the layout reads as "professor demo": all controls visible at once, the user has to know what to do. There is no narrative arc. Reuters Graphics, NYT Upshot, Bloomberg, FT, Pew: they all use **scrollytelling**. Vertical scroll on the left side text column triggers state changes in a sticky chart on the right. The reader is led through the argument; they do not have to drive.

## Target reference points

Open these on a desktop and look at the structure, not the topic:

- Reuters Graphics: any recent piece at graphics.reuters.com
- NYT Upshot: any "How the Economy Works" or election forecast piece
- Pudding.cool: highly designed scrollytelling, similar tech stack
- FT Visual Storytelling: ft.com/visual-and-data-journalism

Common pattern:
1. **Big editorial headline** in serif type. Subhead in sans-serif.
2. **Hero chart** that animates in as the page loads. One chart, no controls visible.
3. **Scroll-driven narrative**: text on the left, chart on the right that updates with each section. Annotations (arrows, callouts, highlighted regions) appear at the right moment.
4. **One or two big-stat callouts** mid-story. "5x" or "$43B" in 80px type.
5. **A "play with it yourself" section** at the bottom, where the controls finally appear. This is where your current Dash app lives. By the time the reader gets here, they know what the sliders mean.
6. **"About this story" sidebar** with methodology, data sources, and a link to the academic version.

## Three options, ranked by effort and payoff

### Option A: Quarto site with Closeread (recommended for Wednesday)

**What it is.** Quarto is a scientific publishing system from Posit (RStudio). Closeread is a Quarto extension that does scrollytelling out of the box. You write Markdown with special blocks; it produces a static site that does sticky-chart scrollytelling.

**Why it fits.** You already have:
- A LaTeX methodology brief (`docs/methodology_brief.tex`)
- A companion primer (`docs/companion_primer.tex`)
- Pre-computed CSVs (`results/dash_cache_*.csv`)
- Working Plotly charts in the Dash app

Quarto natively renders Plotly, embeds LaTeX math, and publishes to GitHub Pages with one command. Closeread layers scrollytelling on top.

**Effort.** Two to three evenings. The bulk is rewriting the existing intro paragraphs as scrollytelling beats and choosing 6 to 8 chart states to step through.

**Stack.**
- Quarto (already installed if you have RStudio; otherwise `brew install quarto`)
- Closeread extension: `quarto add qmd-lab/closeread`
- Plotly Python (you already use this)
- Hosting: GitHub Pages (free) or Netlify

**Skeleton structure.**
1. Hero: headline + auto-playing IRF animation showing the sign-flip on the toy model.
2. Scrolly act 1 (5 beats): "The Pravda operation. 3.6 million articles. Why central banks are vulnerable."
3. Scrolly act 2 (8 beats): the model walkthrough. Each beat advances κ or h by one step, and the chart annotates what changed. End with the sign-flip moment.
4. Big-stat callout: "5x cumulative welfare loss under realistic frictions."
5. Scrolly act 3 (4 beats): the defense regime. Walk K_gain from 1.0 down to 0. Watch welfare collapse to baseline.
6. Crossover finding: "At empirical Phillips slope, defense pays off above ~25% perceived attack probability."
7. "Play with it yourself": embed the existing Dash app in an iframe.
8. Methodology sidebar: link to the LaTeX PDFs you already have.

### Option B: Observable Notebook (medium effort, slickest result)

**What it is.** Observable Plot is the modern d3 successor. Observable notebooks are interactive by default. There are excellent scrollytelling templates.

**Why it might fit.** If you want the most polished result and are willing to learn a small amount of JavaScript. Observable notebooks look more like Reuters than anything else for a single author.

**Why I am not leading with this.** You are not a JS developer. The learning curve is real for someone whose toolchain is Julia and Python. Two evenings becomes a week.

### Option C: Next.js + Scrollama + d3 (the Reuters stack itself)

**What it is.** What Reuters and NYT actually use. React framework, Scrollama library for scroll detection, d3 for charts.

**Why I am not recommending this for Wednesday.** Two-week project minimum. Worth it if this becomes a long-term portfolio piece or you decide to publish it as a stand-alone story. Not for a coffee meeting in five days.

## Concrete plan if you go with Quarto + Closeread

### Day 1 (3 hours)

1. Install Quarto and Closeread.
2. Create `dash_app/../story/` directory. Initialize a Quarto project.
3. Port the existing intro paragraphs from `dash_app/app.py` (lines 202-234) into the first Quarto page.
4. Render once, deploy to GitHub Pages, confirm the pipeline works.

### Day 2 (4 hours)

1. Write 8-10 scrollytelling beats. Each beat is one paragraph + one chart state. Sketch on paper first.
2. Convert the existing Plotly figures from the Dash app into standalone Python functions that take parameters and return Plotly figures. Save as `story/charts.py`.
3. Build the scrollytelling sequence in the Closeread syntax.

### Day 3 (3 hours)

1. Add the big-stat callouts. The "5x" finding deserves a 100-pixel font moment.
2. Add chart annotations: arrows, vertical reference lines, shaded regions for "the sign-flip window."
3. Embed the existing Dash app in an iframe at the bottom for the "play with it yourself" section. Or rebuild a stripped-down version with Observable inputs if Dash embedding is awkward.
4. Editorial polish. Serif headline font (Tiempos Headline if you have it, else Source Serif Pro or Crimson Text). Sans-serif body (Inter or Source Sans). Lots of whitespace. Margin notes for citations.

### Day 4 (2 hours)

1. Mobile test. Reuters stories are read on phones. Use Chrome DevTools device mode.
2. Read it cold. Cut anything that does not earn its place.
3. Send to a non-economist friend, watch them scroll. Anywhere they pause, fix.
4. Final deploy. Custom domain if you want (`poison-dsge.johnblakeslee.com`). Otherwise GitHub Pages default URL is fine.

## Editorial principles (the parts that distinguish data journalism from academic figures)

1. **One chart, one idea.** Reuters never asks the reader to interpret two trends in one frame. Your IRF chart currently shows three variables; that is fine because they tell one story (Fed response, inflation, output gap moving together). But if a single beat is supposed to make one point, kill the other two lines for that beat.

2. **Annotate everything.** Default Plotly charts say "policy rate response (bp)". Reuters charts say "The Fed cut rates by 2bp on impact, not the 50bp the textbook predicted." The annotation is the headline; the chart is the evidence.

3. **Headlines, not titles.** "Adversarial Nowcasting and Monetary Policy" is a paper title. The data story headline is something like "If you can fool the Fed's machine learning, you can move tens of billions of dollars. We modeled how."

4. **Big numbers, big.** When the reader hits the "5x" finding, it should be unmissable. 80 to 100 pixel display type, lots of whitespace around it.

5. **Show the data, then the model.** Your current intro talks about the model first. Reuders flip this. Show real Pravda screenshot or the Federal Reserve's nowcasting pipeline diagram first. Anchor in reality. Then introduce the model.

6. **Cut waste mercilessly.** The intro on the current Dash app is three substantial paragraphs (~280 words) before the user sees a chart. Reuters would cut it to one tight paragraph with a hero chart underneath. The detailed framing moves into the scrollytelling beats where it can be paced.

## Integration with the paper

Two integration moves worth making.

**1. Inline the methodology sidebar.** The methodology brief PDF is 292 KB and 30+ pages. No reader will click it. Instead, pull the three or four most important figures out and inline them in collapsible "details" disclosures next to the main story. The brief becomes the canonical academic version; the inline figures show the reader what the rigor looks like without forcing them to read it.

**2. The companion primer is a reading-track for non-economists.** Keep it as a downloadable PDF, but also break it into the margin annotations of the data story. When a beat in the scrollytelling mentions "habit formation", a small sidebar explains what that is in two sentences, with a "more in the primer" link.

This way the data story is the entry point. The brief and the primer are the layers underneath. A senior economist who wants the technical version sees one click away. A policy reader who just wants the takeaway never has to leave the story.

## What to actually show Wenger Wednesday

If the Quarto site is up by Tuesday night: open it on your laptop, scroll through the first two acts (about 90 seconds), then jump to the "play with it yourself" section. Hand her the laptop. Let her drag the K_gain slider. The big "5x" callout in the middle is the moment her face should change.

If the Quarto site is not done by Tuesday night: do not show her the current Dash app first. Instead, walk her through the methodology brief PDF on key findings (the sign-flip plot, the welfare-vs-K_gain plot, the crossover plot). Then say "this is the academic version. I am rebuilding the public version as a Reuters-style data story; happy to send you the link when it is up."

The second option is fine. The first option is better. The current Dash app, shown to a non-DSGE economist with no scrollytelling context, is easy to misread as just sliders-and-graphs.

## Hosting

GitHub Pages, free, custom domain optional, deploys on push from a `gh-pages` branch. `quarto publish gh-pages` does it in one command.

If you want a domain: `poison-dsge.johnblakeslee.com` or similar. Buy on Cloudflare (cheapest), point CNAME at `<your-github-username>.github.io`. Five minutes to set up.

## What I can help with next

If you want to proceed with the Quarto plan, the next step is for me to scaffold the project: directory structure, sample Closeread page, port the first chart, deploy the empty shell to GitHub Pages so we know the pipeline works. That is roughly the Day 1 plan above. I can do it as a single contiguous task. Just say "scaffold the Quarto site."
