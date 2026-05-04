"""Chart factory for the data story.

Reads pre-computed DSGE results from ../results/dash_cache_*.csv and returns
Plotly figures sized and styled for editorial use (single-chart-on-the-page,
not a multi-panel dashboard).
"""
from pathlib import Path

import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

HERE = Path(__file__).resolve().parent
CACHE = HERE.parent / "results"

_irfs = pd.read_csv(CACHE / "dash_cache_irfs.csv")
_welfare = pd.read_csv(CACHE / "dash_cache_welfare.csv")

# Pre-index for fast slicing
_irfs_attack = _irfs[_irfs["shock"] == "ε_att"].set_index(
    ["κ", "h", "K_gain", "variable"]
)
_welfare_idx = _welfare.set_index(["κ", "h", "K_gain"])

# Editorial palette
NAVY = "#1f3a5f"
RED = "#c0392b"
SAND = "#d4a574"
GRAY_LINE = "#dcdcdc"
GRAY_TEXT = "#666"
INK = "#1a1a1a"
BG = "#fafaf7"

VAR_LABELS = {
    "i": "Policy rate (bp)",
    "π": "Inflation (pp, annualized)",
    "ygap": "Output gap (pp)",
}
VARS_ORDER = ["i", "π", "ygap"]


def _closest(val, options):
    return min(options, key=lambda x: abs(x - val))


def _editorial_layout(fig: go.Figure, height: int = 540) -> go.Figure:
    """Apply Reuters-style editorial styling to a figure."""
    fig.update_layout(
        height=height,
        paper_bgcolor=BG,
        plot_bgcolor=BG,
        font=dict(
            family="-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
            color=INK,
            size=13,
        ),
        margin=dict(l=60, r=30, t=60, b=50),
        hoverlabel=dict(bgcolor="white", font_size=12, font_family="sans-serif"),
        showlegend=False,
    )
    fig.update_xaxes(
        showgrid=False,
        showline=True,
        linecolor=GRAY_LINE,
        ticks="outside",
        tickcolor=GRAY_LINE,
        tickfont=dict(size=11, color=GRAY_TEXT),
    )
    fig.update_yaxes(
        showgrid=True,
        gridcolor=GRAY_LINE,
        gridwidth=0.5,
        zeroline=True,
        zerolinecolor=GRAY_TEXT,
        zerolinewidth=1,
        showline=False,
        tickfont=dict(size=11, color=GRAY_TEXT),
    )
    return fig


def irf_panel(kappa: float, h: float, K_gain: float,
              highlight: str | None = None,
              annotate_signflip: bool = False,
              title: str | None = None) -> go.Figure:
    """Three-panel IRF chart: policy rate, inflation, output gap.

    `highlight` can be 'i', 'π', or 'ygap' to dim non-highlighted panels.
    `annotate_signflip` adds a callout at quarter 0 if i flips sign vs the
    naive Taylor-rule prediction.
    """
    kappa = _closest(kappa, sorted(_irfs["κ"].unique()))
    h = _closest(h, sorted(_irfs["h"].unique()))
    K_gain = _closest(K_gain, sorted(_irfs["K_gain"].unique()))

    fig = make_subplots(
        rows=3, cols=1, shared_xaxes=True,
        vertical_spacing=0.06,
        subplot_titles=[VAR_LABELS[v] for v in VARS_ORDER],
    )

    for i, var in enumerate(VARS_ORDER, start=1):
        try:
            series = _irfs_attack.loc[(kappa, h, K_gain, var)].sort_values("period")
        except KeyError:
            continue
        is_highlighted = (highlight is None) or (highlight == var)
        color = NAVY if is_highlighted else "rgba(31,58,95,0.25)"
        line_w = 3 if is_highlighted else 1.5
        fig.add_trace(
            go.Scatter(
                x=series["period"], y=series["value"],
                mode="lines", line=dict(color=color, width=line_w),
                name=VAR_LABELS[var],
                hovertemplate=f"Q%{{x}}<br>{VAR_LABELS[var]}: %{{y:.2f}}<extra></extra>",
            ),
            row=i, col=1,
        )
        # Zero reference
        fig.add_hline(y=0, line_color=GRAY_TEXT, line_width=0.8, row=i, col=1)

    # Sign-flip annotation
    if annotate_signflip:
        try:
            i0 = _irfs_attack.loc[(kappa, h, K_gain, "i")].sort_values("period").iloc[0]["value"]
            if i0 < 0:
                fig.add_annotation(
                    x=0, y=i0,
                    text=f"<b>{i0:.1f} bp</b><br>The Fed cuts<br>instead of hiking",
                    showarrow=True, arrowhead=2, arrowwidth=1.5,
                    arrowcolor=RED, ax=80, ay=-50,
                    font=dict(color=RED, size=12, family="sans-serif"),
                    bgcolor="white", bordercolor=RED, borderwidth=1, borderpad=6,
                    row=1, col=1,
                )
        except KeyError:
            pass

    # Subplot title styling
    for ann in fig["layout"]["annotations"][:3]:
        ann["font"] = dict(size=12, color=GRAY_TEXT, family="sans-serif")
        ann["xanchor"] = "left"
        ann["x"] = 0

    fig.update_xaxes(title_text="Quarters after attack", row=3, col=1)

    fig = _editorial_layout(fig, height=560)
    if title:
        fig.update_layout(title=dict(
            text=title,
            font=dict(size=15, color=INK, family="serif"),
            x=0, xanchor="left", y=0.98,
        ))
    return fig


def welfare_bars(kappa: float, h: float, K_gain: float) -> go.Figure:
    """Welfare loss with vs without attack."""
    kappa = _closest(kappa, sorted(_welfare["κ"].unique()))
    h = _closest(h, sorted(_welfare["h"].unique()))
    K_gain = _closest(K_gain, sorted(_welfare["K_gain"].unique()))
    row = _welfare_idx.loc[(kappa, h, K_gain)]
    L_no = float(row["L_no_attack"])
    L_yes = float(row["L_attack"])
    fig = go.Figure()
    fig.add_trace(go.Bar(
        x=["Normal economy", "Under attack"],
        y=[L_no, L_yes],
        marker=dict(color=[NAVY, RED]),
        text=[f"{L_no:.2f}", f"{L_yes:.2f}"],
        textposition="outside",
        textfont=dict(size=14, color=INK),
        hovertemplate="%{x}: L = %{y:.3f}<extra></extra>",
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


def cumulative_5x_callout(kappa_realistic: float = 0.15,
                          h_realistic: float = 0.7,
                          k_naive: float = 1.0,
                          horizon: int = 8) -> dict:
    """Compute the 5x cumulative-loss number for the inline stat callout."""
    def cum_i(k_, h_, K_):
        try:
            s = _irfs_attack.loc[(k_, h_, K_, "i")].sort_values("period")
            return float(s.head(horizon)["value"].sum())
        except KeyError:
            return float("nan")
    toy = cum_i(0.06, 0.0, k_naive)
    realistic = cum_i(kappa_realistic, h_realistic, k_naive)
    return {
        "toy_cum": toy,
        "realistic_cum": realistic,
        "ratio": realistic / toy if toy else float("nan"),
        "horizon": horizon,
    }
