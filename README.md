# Visualising Why SE = SD / √n

An interactive Shiny app that builds up the standard error formula step by
step, using simulation and live plots. Designed for non-mathematics students
encountering the standard error for the first time.

---

## Purpose

The formula SE = σ/√n is one of the most used — and least understood — results
in introductory statistics. This app breaks the derivation into five concrete,
visual steps, each on its own tab, so students can see *why* averaging reduces
variability and *why* the reduction follows a square-root curve rather than a
straight line.

---

## Controls (sidebar)

| Control | Description |
|---|---|
| **Population SD (σ)** | Sets the spread of the underlying Normal population (range 1–20) |
| **Sample size (n)** | Number of observations in each sample (range 1–100) |
| **Number of repeated samples** | How many samples are drawn to build the sampling distributions (500–5000) |
| **Resample** | Picks a new random seed — confirms patterns hold across different draws |

The **Theoretical predictions** panel updates live, showing Var(single obs),
Var(sum), SD(sum), Var(mean), and SE for the current σ and n.

---

## Tabs

### ① One observation
Shows the theoretical Normal(0, σ) population curve alongside a strip chart
of one random sample of size n. Establishes that individual observations vary
with spread σ.

### ② Sums get wobblier
Side-by-side histograms of individual observations (blue) and sums of n
observations (purple), on a shared horizontal scale. As n increases, the sum
histogram widens — each observation adds its own wobble, so variance
accumulates: Var(sum) = n × σ².

### ③ Dividing gives the mean
Histogram of k sample means with a smoothed density overlay (teal) and the
theoretical Normal(0, σ/√n) curve (orange dashed). Demonstrates that dividing
the sum by n shrinks variance by n² — not n — giving Var(mean) = σ²/n and
SE = σ/√n.

### ④ All together
All three distributions (single observations, sums, means) stacked vertically
on the same horizontal scale, with theoretical Normal overlays on each row.
Directly shows the full contrast in spread across the three quantities.

### ⑤ The √n rule
Plots the theoretical SE = σ/√n curve from n = 1 to 100, with simulated SE
values at key n values overlaid as dots. An orange diamond marks the current
slider position. Illustrates the diminishing-returns relationship: halving the
SE requires quadrupling n.

---

## Technical notes

- **Base R only** — no packages beyond `shiny` are required
- The population in Tab ① is the exact theoretical `dnorm` curve, not a
  simulated sample, so it does not shift when resampling
- Slider changes reuse the current random seed, keeping plots stable while
  students explore parameters; the **Resample** button generates a fresh seed
- All in-plot annotations use `grconvertX/Y("npc")` coordinates so they remain
  fixed in the panel corner regardless of data scale or resample

---

## Course context

Developed for BIOL 3P96 — Biostatistics, Brock University.
Built with R and Shiny (base R graphics only).