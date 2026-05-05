"""Chart factory for the Adversarial Nowcasting data story.

Reads pre-computed DSGE results from ../results/dash_cache_*.csv and returns
- editorial-styled Plotly figures, OR
- JSON-ready dicts for client-side scrolly morphing.

The story's right-side sticky chart is one Plotly div that gets re-rendered
in three states. We export those states as plain dicts the JS can hand
straight to Plotly.react().
"""
from pathlib import Path
import json

import pandas as pd
import plotly.graph_objects as go
import plotly.io as pio
from plotly.subplots import make_subplots

HERE = Path(__file__).resolve().parent
CACHE = HERE.parent / "results"

_irfs = pd.read_csv(CACHE / "dash_cache_irfs.csv")
_welfare = pd.read_csv(CACHE / "dash_cache_welfare.csv")

_irfs_attack = _irfs[_irfs["shock"] == "ε_att"].set_index(
    ["κ", "h", "K_gain", "variable"]
)
_welfare_idx = _welfare.set_index(["κ", "h", "K_gain"])

KAPPAS = sorted(_irfs["κ"].unique())
HS = sorted(_irfs["h"].unique())
KS = sorted(_irfs["K_gain"].unique())

# Editorial palette
NAVY = "#1f3a5f"
RED = "#c0392b"
SAND = "#d4a574"
INK = "#1a1a1a"
BG = "#fafaf7"
GRAY_LINE = "#dcdcdc"
GRAY_TEXT = "#666"


def _closest(val, options):
    return min(options, key=lambda x: abs(x - val))


def _series(kappa, h, K, var):
    kappa = _closest(kappa, KAPPAS)
    h = _closest(h, HS)
    K = _closest(K, KS)
    s = _irfs_attack.loc[(kappa, h, K, var)].sort_values("period")
    return s["period"].tolist(), s["value"].tolist()


def _editorial_layout(fig, height=720):
    fig.update_layout(
        height=height,
        paper_bgcolor=BG,
        plot_bgcolor=BG,
        font=dict(
            family="Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
            color=INK, size=13,
        ),
        margin=dict(l=70, r=40, t=70, b=60),
        hoverlabel=dict(bgcolor="white", font_size=12, font_family="sans-serif"),
        showlegend=False,
        transition=dict(duration=600, easing="cubic-in-out"),
    )
    fig.update_xaxes(
        showgrid=False, showline=True, linecolor=GRAY_LINE,
        ticks="outside", tickcolor=GRAY_LINE,
        tickfont=dict(size=11, color=GRAY_TEXT),
    )
    fig.update_yaxes(
        showgrid=True, gridcolor=GRAY_LINE, gridwidth=0.5,
        zeroline=True, zerolinecolor=GRAY_TEXT, zerolinewidth=1,
        showline=False, tickfont=dict(size=11, color=GRAY_TEXT),
    )
    return fig


def _scrolly_chart(kappa, h, K, *,
                   title, kicker,
                   show_taylor_ref=False,
                   shade_undershoot=False,
                   highlight_callout=None):
    """Three-panel IRF chart for the scrollytelling sticky pane.

    `show_taylor_ref`: draws a horizontal +50bp line on the policy-rate panel
                       labeled 'Textbook Taylor: +50 bp'.
    `shade_undershoot`: shades quarters 1-8 on the policy-rate panel.
    `highlight_callout`: text → annotation arrow at quarter 0 of policy rate.
    """
    fig = make_subplots(
        rows=3, cols=1, shared_xaxes=True,
        vertical_spacing=0.07,
        subplot_titles=["Policy rate (bp)", "Inflation (pp, annualized)", "Output gap (pp)"],
    )

    panels = [("i", NAVY, 1), ("π", "rgba(31,58,95,0.40)", 2), ("ygap", "rgba(31,58,95,0.40)", 3)]
    for var, color, row in panels:
        x, y = _series(kappa, h, K, var)
        fig.add_trace(
            go.Scatter(
                x=x, y=y, mode="lines",
                line=dict(color=color, width=3.5 if var == "i" else 2),
                hovertemplate=f"Q%{{x}}<br>%{{y:.2f}}<extra></extra>",
                showlegend=False,
            ),
            row=row, col=1,
        )
        fig.add_hline(y=0, line_color=GRAY_TEXT, line_width=0.8, row=row, col=1)

    # Optional: taylor reference line at +50bp on policy rate
    if show_taylor_ref:
        fig.add_hline(y=50, line_color=RED, line_width=1.4, line_dash="dash",
                      row=1, col=1,
                      annotation=dict(
                          text="<b>Textbook Taylor: +50 bp</b>",
                          font=dict(color=RED, size=11),
                          xanchor="left", x=10, yanchor="bottom",
                          showarrow=False,
                      ))

    # Optional: shade quarters 1-8 on policy rate panel
    if shade_undershoot:
        fig.add_vrect(x0=1, x1=8, fillcolor=RED, opacity=0.07, line_width=0,
                      row=1, col=1,
                      annotation=dict(
                          text="<b>The eight-quarter undershoot</b>",
                          font=dict(color=RED, size=11),
                          y=1, yanchor="top", xanchor="center", x=4.5,
                          showarrow=False,
                      ))

    # Optional: annotation callout near impact
    if highlight_callout:
        x0, y0 = _series(kappa, h, K, "i")
        impact = y0[0]
        fig.add_annotation(
            x=0, y=impact, text=f"<b>{highlight_callout}</b>",
            showarrow=True, arrowhead=2, arrowwidth=1.4, arrowcolor=RED,
            ax=70, ay=-50,
            font=dict(color=RED, size=11.5, family="Inter, sans-serif"),
            bgcolor="rgba(255,255,255,0.92)",
            bordercolor=RED, borderwidth=1, borderpad=6,
            row=1, col=1,
        )

    # Style subplot titles
    for ann in fig["layout"]["annotations"][:3]:
        ann["font"] = dict(size=12.5, color=GRAY_TEXT, family="Inter, sans-serif")
        ann["xanchor"] = "left"
        ann["x"] = 0

    fig.update_xaxes(title_text="Quarters after attack", row=3, col=1)
    fig = _editorial_layout(fig, height=720)

    if title:
        fig.update_layout(title=dict(
            text=f"<span style='font-size:11px;color:{GRAY_TEXT};letter-spacing:0.05em;text-transform:uppercase'>{kicker}</span><br>"
                 f"<span style='font-family:Source Serif Pro,serif;font-size:18px;color:{INK}'>{title}</span>",
            x=0.02, xanchor="left", y=0.98, yanchor="top",
        ))
    return fig


def scrolly_states_json():
    """Return the three scrolly-state Plotly specs as a JSON string.

    Keys: 'realistic', 'cumulative', 'defended'. Each value is
    {data: [...], layout: {...}, config: {...}}.
    """
    states = {
        "realistic": _scrolly_chart(
            0.15, 0.7, 1.0,
            kicker="State 1 of 3 — Naive Fed at SW posterior",
            title="A standardized attack hits a textbook-empirical Fed",
            show_taylor_ref=True,
            highlight_callout="Actual response:<br>+0.6 bp",
        ),
        "cumulative": _scrolly_chart(
            0.15, 0.7, 1.0,
            kicker="State 2 of 3 — Two years of policy drift",
            title="The cost lands over the eight quarters that follow",
            show_taylor_ref=True,
            shade_undershoot=True,
        ),
        "defended": _scrolly_chart(
            0.15, 0.7, 0.1,
            kicker="State 3 of 3 — Fed downweights the signal",
            title="Filter weight 0.1 collapses the attack response",
            show_taylor_ref=True,
        ),
    }

    out = {}
    for key, fig in states.items():
        spec = json.loads(pio.to_json(fig))
        spec["config"] = {"responsive": True, "displayModeBar": False}
        out[key] = spec
    return json.dumps(out)


def explorer_payload_json():
    """Embed the full IRF cache (pre-indexed) for client-side slider exploration."""
    grid = {
        "kappa": [float(x) for x in KAPPAS],
        "h":     [float(x) for x in HS],
        "K":     [float(x) for x in KS],
    }
    irf = {}
    for kappa in KAPPAS:
        for h in HS:
            for K in KS:
                key = f"{kappa:.2f}|{h:.1f}|{K:.1f}"
                try:
                    i_x = _irfs_attack.loc[(kappa, h, K, "i")].sort_values("period")["value"].tolist()
                    pi_x = _irfs_attack.loc[(kappa, h, K, "π")].sort_values("period")["value"].tolist()
                    yg_x = _irfs_attack.loc[(kappa, h, K, "ygap")].sort_values("period")["value"].tolist()
                    irf[key] = {"i": i_x, "pi": pi_x, "ygap": yg_x}
                except KeyError:
                    pass
    return json.dumps({"grid": grid, "irf": irf}, separators=(",", ":"))


# ============================================================
# Welfare comparison (used after the bigstat)
# ============================================================
def welfare_compare(kappa=0.15, h=0.7):
    kappa = _closest(kappa, sorted(_welfare["κ"].unique()))
    h = _closest(h, sorted(_welfare["h"].unique()))

    configs = [
        ("Naive Fed (K = 1.0)", 1.0),
        ("Light filter (K = 0.1)", 0.1),
        ("Defended Fed (K = 0.0)", 0.0),
    ]
    L_no, L_yes = [], []
    for _, K in configs:
        try:
            r = _welfare_idx.loc[(kappa, h, _closest(K, sorted(_welfare["K_gain"].unique())))]
            L_no.append(float(r["L_no_attack"]))
            L_yes.append(float(r["L_attack"]))
        except KeyError:
            L_no.append(0.0); L_yes.append(0.0)

    labels = [c[0] for c in configs]
    fig = go.Figure()
    fig.add_trace(go.Bar(
        name="Without attack",
        x=labels, y=L_no, marker=dict(color=NAVY),
        text=[f"{v:.2f}" for v in L_no],
        textposition="outside", textfont=dict(size=12, color=GRAY_TEXT),
    ))
    fig.add_trace(go.Bar(
        name="Under attack",
        x=labels, y=L_yes, marker=dict(color=RED),
        text=[f"{v:.2f}" for v in L_yes],
        textposition="outside", textfont=dict(size=12, color=INK),
    ))
    fig.update_layout(
        barmode="group",
        title=dict(
            text="<b>Welfare loss across filter regimes</b>",
            font=dict(size=15, color=INK, family="Source Serif Pro, serif"),
            x=0.02, xanchor="left", y=0.96,
        ),
        legend=dict(
            orientation="h", yanchor="bottom", y=1.05, xanchor="right", x=1,
            font=dict(size=11.5, color=GRAY_TEXT),
        ),
        showlegend=True,
    )
    fig = _editorial_layout(fig, height=480)
    fig.update_layout(showlegend=True)
    fig.update_yaxes(title_text="Loss L = var(π) + 0.5·var(ygap)")
    return fig


def welfare_ratios(kappa=0.15, h=0.7):
    """Welfare-loss ratio (attack/no-attack) at the realistic SW calibration."""
    def ratio_at(K_):
        try:
            r = _welfare_idx.loc[(_closest(kappa, sorted(_welfare["κ"].unique())),
                                  _closest(h, sorted(_welfare["h"].unique())),
                                  _closest(K_, sorted(_welfare["K_gain"].unique())))]
            return float(r["L_attack"] / r["L_no_attack"]) if r["L_no_attack"] > 0 else float("nan")
        except KeyError:
            return float("nan")
    return {
        "naive": ratio_at(1.0),
        "light_filter": ratio_at(0.1),
        "defended": ratio_at(0.0),
    }


# Backward compat
def cumulative_5x_callout(**_):
    """Compute the cumulative-bp diagnostic (kept for backwards compatibility)."""
    horizon = 8
    def cum_i(k_, h_, K_):
        try:
            s = _irfs_attack.loc[(k_, h_, K_, "i")].sort_values("period")
            return float(s.head(horizon)["value"].sum())
        except KeyError:
            return float("nan")
    toy = cum_i(0.06, 0.0, 1.0)
    realistic = cum_i(0.15, 0.7, 1.0)
    return {"toy_cum": toy, "realistic_cum": realistic,
            "ratio": realistic / toy if toy else float("nan"),
            "horizon": horizon}


# Old single-config helpers, still used by explore.qmd
def irf_panel(kappa, h, K_gain, **_):
    return _scrolly_chart(kappa, h, K_gain, kicker="", title="")


def welfare_bars(kappa, h, K_gain):
    kappa = _closest(kappa, sorted(_welfare["κ"].unique()))
    h = _closest(h, sorted(_welfare["h"].unique()))
    K_gain = _closest(K_gain, sorted(_welfare["K_gain"].unique()))
    row = _welfare_idx.loc[(kappa, h, K_gain)]
    L_no = float(row["L_no_attack"])
    L_yes = float(row["L_attack"])
    fig = go.Figure()
    fig.add_trace(go.Bar(
        x=["Normal economy", "Under attack"],
        y=[L_no, L_yes], marker=dict(color=[NAVY, RED]),
        text=[f"{L_no:.2f}", f"{L_yes:.2f}"],
        textposition="outside", textfont=dict(size=14, color=INK),
    ))
    fig.update_layout(
        title=dict(
            text=f"Welfare loss · κ={kappa}, h={h}, K={K_gain}",
            font=dict(size=14, color=GRAY_TEXT, family="sans-serif"),
            x=0, xanchor="left",
        ),
    )
    fig = _editorial_layout(fig, height=380)
    fig.update_yaxes(title_text="Loss (lower is better)")
    return fig
