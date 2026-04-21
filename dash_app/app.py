"""Adversarial Nowcasting and Monetary Policy — interactive demo.

Reads pre-computed Julia DSGE results from ./data/dash_cache_*.csv (Docker)
or ../results/dash_cache_*.csv (local dev) and serves an interactive
exploration of attack-shock dynamics and defense-regime tradeoffs.

Companion code: github.com/jblakeslee89/poison-dsge
"""
from pathlib import Path

import dash
from dash import Dash, Input, Output, dcc, html, callback_context, no_update
import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

HERE = Path(__file__).resolve().parent
# Prefer local ./data/ (Docker layout); fall back to ../results/ (dev)
if (HERE / "data" / "dash_cache_irfs.csv").exists():
    CACHE_DIR = HERE / "data"
else:
    CACHE_DIR = HERE.parent / "results"

IRF_CSV = CACHE_DIR / "dash_cache_irfs.csv"
WELFARE_CSV = CACHE_DIR / "dash_cache_welfare.csv"

irfs = pd.read_csv(IRF_CSV)
welfare = pd.read_csv(WELFARE_CSV)

# Pre-index for fast slider callbacks
irfs_attack = irfs[irfs["shock"] == "ε_att"].set_index(["κ", "h", "K_gain", "variable"])
welfare_idx = welfare.set_index(["κ", "h", "K_gain"])

KAPPA_VALUES = sorted(welfare["κ"].unique())
H_VALUES = sorted(welfare["h"].unique())
K_VALUES = sorted(welfare["K_gain"].unique())

VAR_TITLES = {
    "i": "Policy rate response (bp)",
    "π": "Inflation (pp, annualized)",
    "ygap": "Output gap (pp)",
}
VARS_ORDER = ["i", "π", "ygap"]

# Presets: (label, κ, h, K_gain, narrative)
PRESETS = [
    ("memo_toy",
     "Memo (toy model, 2025)",
     0.06, 0.0, 1.0,
     "Original Spring 2025 calibration. Flat Phillips curve, no consumption habit, naive Fed. "
     "Produces the headline sign-flip — a +1σ attack looks like a ~2 bp cut on impact."),
    ("realistic",
     "Realistic (SW posterior)",
     0.15, 0.7, 0.1,
     "Empirical Phillips slope, Smets-Wouters habit, Fed filtering heavily. "
     "Sign-flip attenuates at impact; cumulative 8Q response remains deeply negative."),
    ("defended",
     "Defended (heavy filter)",
     0.15, 0.7, 0.0,
     "Realistic calibration with Fed ignoring the raw nowcast signal entirely. "
     "Welfare under attack falls sharply; welfare under normal conditions rises modestly."),
]

def _closest(val, options):
    return min(options, key=lambda x: abs(x - val))

app = Dash(__name__, title="Adversarial Nowcasting and Monetary Policy")
server = app.server   # for gunicorn

_INDEX_CSS = """
<!DOCTYPE html>
<html>
<head>
  {%metas%}
  <title>{%title%}</title>
  {%favicon%}
  {%css%}
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", system-ui, sans-serif;
           background-color: #fafafa; color: #1a1a1a; margin: 0; }
    .container { max-width: 1400px; margin: 0 auto; padding: 24px; }
    h1 { font-size: 24px; margin: 0 0 4px 0; font-weight: 600; }
    h2 { font-size: 16px; margin: 24px 0 8px 0; color: #444; font-weight: 600;
         text-transform: uppercase; letter-spacing: 0.04em; }
    .lead { color: #555; font-size: 14px; max-width: 820px; line-height: 1.5; }
    .card { background: white; border: 1px solid #e6e6e9; border-radius: 8px;
            padding: 16px; }
    .row { display: flex; gap: 16px; }
    .row > * { flex: 1; }
    @media (max-width: 860px) {
      .row { flex-direction: column; }
    }
    .preset-btn { padding: 8px 14px; background: #fff; border: 1px solid #d0d0d6;
                  border-radius: 6px; cursor: pointer; font-size: 13px;
                  font-weight: 500; color: #333; transition: all 0.12s;
                  margin-right: 8px; margin-bottom: 8px; }
    .preset-btn:hover { background: #eef; border-color: #889; }
    .preset-btn:active { background: #ddf; }
    .narrative { background: #f0f4fa; border-left: 3px solid #3b6ea8;
                 padding: 10px 14px; margin-top: 12px; font-size: 13.5px;
                 color: #23476e; border-radius: 0 4px 4px 0; line-height: 1.5; }
    .summary { background: #f5f5f7; border-radius: 6px; padding: 14px 18px;
               margin-top: 16px; font-size: 14px; line-height: 1.7; }
    .summary strong { color: #1a1a1a; }
    .slider-label { font-weight: 600; font-size: 13px; margin-bottom: 4px; }
    .slider-help { font-size: 11.5px; color: #777; margin-bottom: 8px;
                   font-style: italic; }
    footer { border-top: 1px solid #e6e6e9; margin-top: 40px; padding-top: 16px;
             color: #888; font-size: 12px; }
    footer a { color: #3b6ea8; text-decoration: none; }
  </style>
</head>
<body>
  {%app_entry%}
  <footer>
    {%config%}
    {%scripts%}
    {%renderer%}
  </footer>
</body>
</html>
"""
app.index_string = _INDEX_CSS


def make_layout():
    slider_col = lambda id_, label, help_, values, default: html.Div([
        html.Div(label, className="slider-label"),
        html.Div(help_, className="slider-help"),
        dcc.Slider(id=id_, min=min(values), max=max(values), value=default,
                   marks={v: f"{v:.2f}" if v < 1 else f"{v:.1f}" for v in values},
                   step=None),
    ], style={"padding": "8px 12px"})

    preset_buttons = html.Div([
        html.Button(label, id={"type": "preset", "id": pid},
                    n_clicks=0, className="preset-btn")
        for pid, label, *_ in PRESETS
    ], style={"marginBottom": "4px"})

    return html.Div([
        html.H1("Adversarial Nowcasting and Monetary Policy"),
        html.Div(
            "Interactive companion to a New Keynesian DSGE study of data-poisoning "
            "attacks on the Fed's real-time nowcast inputs. Drag the sliders or pick "
            "a preset to see how model specification shapes the attack's impact on "
            "policy, inflation, and welfare.",
            className="lead",
        ),

        html.H2("Scenarios"),
        preset_buttons,
        html.Div(id="scenario-narrative", className="narrative"),

        html.H2("Parameters"),
        html.Div([
            slider_col("kappa-slider",
                       "κ — Phillips curve slope",
                       "Flat (0.06) = toy memo. Empirical ≈ 0.10–0.20.",
                       KAPPA_VALUES, 0.15),
            slider_col("h-slider",
                       "h — consumption habit",
                       "Toy = 0. Smets–Wouters posterior ≈ 0.70.",
                       H_VALUES, 0.7),
            slider_col("k-slider",
                       "K_gain — Fed's weight on raw nowcast signal",
                       "1.0 = naive Fed. 0 = ignore signal entirely.",
                       K_VALUES, 0.1),
        ], className="row card"),

        html.H2("Attack-shock response"),
        html.Div([
            html.Div(dcc.Graph(id="irf-graph", config={"displayModeBar": False}),
                     className="card", style={"flex": 2}),
            html.Div(dcc.Graph(id="welfare-graph", config={"displayModeBar": False}),
                     className="card"),
        ], className="row"),

        html.Div(id="summary-box", className="summary"),

        html.Div([
            "Method: New Keynesian DSGE with Smets–Wouters frictions and a Kalman-style "
            "perception block. Solved in Julia (MacroModelling.jl); pre-computed results "
            "served via Dash. ",
            html.A("Companion code & methodology brief", href="#", style={"color": "#3b6ea8"}),
            ". John Blakeslee, 2026.",
        ], style={"fontSize": "12px", "color": "#888", "marginTop": "24px",
                  "borderTop": "1px solid #e6e6e9", "paddingTop": "16px"}),
    ], className="container")


app.layout = make_layout()


# ---- Preset → slider sync ----
@app.callback(
    Output("kappa-slider", "value"),
    Output("h-slider", "value"),
    Output("k-slider", "value"),
    *[Input({"type": "preset", "id": pid}, "n_clicks") for pid, *_ in PRESETS],
    prevent_initial_call=True,
)
def apply_preset(*n_clicks_list):
    ctx = callback_context
    if not ctx.triggered:
        return no_update, no_update, no_update
    triggered_id = ctx.triggered[0]["prop_id"].rsplit(".", 1)[0]
    import json
    try:
        parsed = json.loads(triggered_id)
        pid = parsed.get("id")
    except (json.JSONDecodeError, ValueError):
        return no_update, no_update, no_update
    for preset_pid, _, κ, h, k, _ in PRESETS:
        if preset_pid == pid:
            return (_closest(κ, KAPPA_VALUES),
                    _closest(h, H_VALUES),
                    _closest(k, K_VALUES))
    return no_update, no_update, no_update


# ---- Main view update ----
@app.callback(
    Output("irf-graph", "figure"),
    Output("welfare-graph", "figure"),
    Output("summary-box", "children"),
    Output("scenario-narrative", "children"),
    Input("kappa-slider", "value"),
    Input("h-slider", "value"),
    Input("k-slider", "value"),
)
def update_views(kappa, h, k):
    # Snap to nearest grid value (defensive, since slider is discrete anyway)
    kappa = _closest(kappa, KAPPA_VALUES)
    h = _closest(h, H_VALUES)
    k = _closest(k, K_VALUES)

    # IRFs
    irf_fig = make_subplots(rows=3, cols=1, shared_xaxes=True,
                            subplot_titles=[VAR_TITLES[v] for v in VARS_ORDER],
                            vertical_spacing=0.10)
    colors = {"i": "#b22222", "π": "#3b6ea8", "ygap": "#226a3e"}
    for row_idx, var in enumerate(VARS_ORDER, start=1):
        rows = irfs_attack.loc[(kappa, h, k, var)].sort_values("period")
        irf_fig.add_trace(
            go.Scatter(x=rows["period"], y=rows["value"],
                       mode="lines+markers",
                       line=dict(color=colors[var], width=2.5),
                       marker=dict(size=6),
                       showlegend=False),
            row=row_idx, col=1,
        )
        irf_fig.add_hline(y=0, line=dict(color="#aaa", width=1, dash="dash"),
                          row=row_idx, col=1)
    irf_fig.update_layout(
        title=dict(text="Response to +1σ attack shock (16 quarters)",
                   font=dict(size=14)),
        height=440, margin=dict(l=50, r=20, t=60, b=40),
        paper_bgcolor="white", plot_bgcolor="#fafafa",
    )
    irf_fig.update_xaxes(title_text="Quarter", row=3, col=1)

    # Welfare bars
    row_current = welfare_idx.loc[(kappa, h, k)]
    L_off = float(row_current["L_no_attack"])
    L_on = float(row_current["L_attack"])
    row_naive = welfare_idx.loc[(kappa, h, 1.0)]
    L_off_naive = float(row_naive["L_no_attack"])
    L_on_naive = float(row_naive["L_attack"])

    welfare_fig = go.Figure()
    welfare_fig.add_trace(go.Bar(
        x=["No attack", "Attack active"],
        y=[L_off, L_on],
        marker_color=["#3b6ea8", "#b22222"],
        text=[f"{L_off:.2f}", f"{L_on:.2f}"],
        textposition="outside",
        textfont=dict(size=12),
        showlegend=False,
    ))
    welfare_fig.update_layout(
        title=dict(text="Welfare loss at current settings", font=dict(size=14)),
        yaxis_title="L = var(π) + 0.5·var(ygap)",
        height=440, margin=dict(l=50, r=20, t=60, b=40),
        paper_bgcolor="white", plot_bgcolor="#fafafa",
    )

    # Crossover threshold vs naive Fed
    numer = L_off - L_off_naive
    denom = (L_on_naive - L_on) + (L_off - L_off_naive)
    if k == 1.0:
        crossover_text = "— (this is the naive regime)"
    elif denom <= 1e-9:
        crossover_text = "crossover degenerate — current filter dominated by naive"
    else:
        p_star = numer / denom
        if 0 <= p_star <= 1:
            crossover_text = (f"current filter preferred to naive if perceived attack "
                              f"probability exceeds p* = {p_star * 100:.1f}%")
        elif p_star < 0:
            crossover_text = "current filter strictly dominates naive"
        else:
            crossover_text = "current filter dominated by naive"

    # Impact + cumulative metrics
    i_rows = irfs_attack.loc[(kappa, h, k, "i")].sort_values("period")
    i0_bp = float(i_rows.iloc[0]["value"])
    i_cum8_bp = float(i_rows.iloc[:8]["value"].sum())

    summary = [
        html.Strong("Impact (Q0): "),
        f"{i0_bp:+.2f} bp policy rate.  ",
        html.Strong("8Q cumulative: "),
        f"{i_cum8_bp:+.2f} bp.  ",
        html.Br(),
        html.Strong("Welfare under attack: "),
        f"{L_on:.3f}  (naive benchmark at same κ, h: {L_on_naive:.3f}, "
        f"Δ = {L_on - L_on_naive:+.3f}).",
        html.Br(),
        html.Strong("Crossover: "),
        crossover_text,
    ]

    # Narrative for active preset, if any matches current settings
    narrative = "Drag the sliders or click a preset above."
    for pid, label, pκ, ph, pk, desc in PRESETS:
        if (abs(kappa - pκ) < 1e-6 and abs(h - ph) < 1e-6 and
                abs(k - pk) < 1e-6):
            narrative = html.Div([
                html.Strong(f"{label}. "), desc
            ])
            break

    return irf_fig, welfare_fig, summary, narrative


if __name__ == "__main__":
    app.run(debug=False, host="127.0.0.1", port=8050)
