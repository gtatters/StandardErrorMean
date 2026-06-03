# Visualising Why SE = SD / sqrt(n)
# A step-by-step interactive demonstration
# Base R only — no additional libraries required

#shinylive::export(appdir = "../CentralLimitMean/", destdir = "docs")
#httpuv::runStaticServer("docs/", port = 8008)

# library(shiny)

# =============================================================================
# Colour palette — matches the existing CLT app style
# COL_POP    : population / single observations (blue)
# COL_SUM    : sums of n observations (purple) — new to this app
# COL_MEAN   : sample means / sampling distribution (teal)
# COL_THEORY : theoretical overlay curves (orange)
# =============================================================================
COL_POP    <- "#195190"
COL_SUM    <- "#8B3A8B"
COL_MEAN   <- "#009499"
COL_THEORY <- "#E07B39"

# =============================================================================
# UI
# =============================================================================
ui <- fluidPage(
  
  titlePanel(
    "Visualising Why SE = SD / \u221an",
    windowTitle = "Why SE = SD/sqrt(n)"
  ),
  
  sidebarLayout(
    
    # -------------------------------------------------------------------------
    # Sidebar: all controls
    # -------------------------------------------------------------------------
    sidebarPanel(
      
      wellPanel(
        # sigma, n, k sliders — changing these re-uses the current seed so
        # the random pattern stays stable while students adjust parameters.
        sliderInput("sigma",
                    "Population SD (\u03c3):",
                    min = 1, max = 20, value = 10, step = 1),
        sliderInput("n",
                    "Sample size (n):",
                    min = 1, max = 100, value = 10, step = 1),
        sliderInput("k",
                    "Number of repeated samples:",
                    min = 500, max = 5000, value = 2000, step = 500),
        br(),
        # Resample button — clicking this picks a new random seed so students
        # can verify the patterns are not an artifact of one lucky draw.
        # No icon= argument, for consistency with other apps in the series.
        actionButton("resample", "Resample",
                     width = "100%",
                     class = "btn-primary")
      ),
      
      # Live theoretical predictions panel —
      # updates whenever sigma or n sliders change.
      # The Var(mean) row shows the full cancellation n*sigma^2 / n^2 = sigma^2/n
      # so students can follow the algebra step by step.
      wellPanel(
        p(strong("Theoretical predictions:")),
        uiOutput("theory_box")
      ),
      
      helpText("Glenn Tattersall, PhD"),
      helpText("For use in BIOL 3P96 - Biostatistics")
    ),
    
    # -------------------------------------------------------------------------
    # Main panel: five tabs, one per conceptual step
    # -------------------------------------------------------------------------
    mainPanel(
      tabsetPanel(
        type = "tabs",
        
        # --- Tab 1: raw scatter of individual observations -------------------
        tabPanel(
          title = "\u2460 One observation",
          br(),
          div(
            p("Each observation drawn at random from the population can land
               anywhere in the distribution. The population standard deviation
               \u03c3 measures how spread out those individual values are.
               Below, the left panel shows the full population density curve;
               the right panel shows one random sample of n points as a strip
               chart, so you can see the scatter directly."),
            align = "justify"
          ),
          br(),
          plotOutput("plot_step1", height = "420px"),
          br(),
          div(textOutput("text_step1"), align = "justify")
        ),
        
        # --- Tab 2: histograms comparing single obs vs sums ------------------
        tabPanel(
          title = "\u2461 Sums get wobblier",
          br(),
          div(
            p("When we add n independent observations together to form a sum,
               each observation contributes its own wobble to the total.
               Because the observations are independent, those wobbles
               accumulate: the variance of the sum grows in proportion to n,
               so the SD of the sum is \u03c3\u221an — wider than a single observation.
               The two histograms below share the same horizontal scale so
               you can directly compare how much wider the purple sum
               distribution is relative to the blue single-observation
               distribution."),
            align = "justify"
          ),
          br(),
          plotOutput("plot_step2", height = "420px"),
          br(),
          div(textOutput("text_step2"), align = "justify")
        ),
        
        # --- Tab 3: histogram of sample means with CLT overlay ---------------
        tabPanel(
          title = "\u2462 Dividing gives the mean",
          br(),
          div(
            p("To compute a sample mean we divide the sum by n. Dividing a
               random variable by a constant n shrinks its variance by n\u00b2
               (not just n), because variance scales with the square of any
               multiplier. So the variance of the mean is \u03c3\u00b2/n, and the
               standard deviation of the mean — the standard error — is
               \u03c3/\u221an. The orange dashed curve is that theoretical prediction;
               watch how closely it matches the teal histogram of simulated
               sample means."),
            align = "justify"
          ),
          br(),
          plotOutput("plot_step3", height = "420px"),
          br(),
          div(textOutput("text_step3"), align = "justify")
        ),
        
        # --- Tab 4: all three distributions stacked on a shared x-axis ------
        tabPanel(
          title = "\u2463 All together",
          br(),
          div(
            p("Here all three distributions are stacked on the same
               horizontal scale so you can compare their widths directly.
               Single observations (blue) show the baseline spread.
               Sums of n observations (purple) are even more spread out.
               Sample means of n observations (teal) are the most tightly
               clustered — squeezed in by the \u03c3/\u221an factor.
               The orange dashed curve on each panel shows the theoretical
               normal prediction."),
            align = "justify"
          ),
          br(),
          plotOutput("plot_step4", height = "520px"),
          br(),
          div(textOutput("text_step4"), align = "justify")
        ),
        
        # --- Tab 5: SE vs n curve showing diminishing returns ----------------
        tabPanel(
          title = "\u2464 The \u221an rule",
          br(),
          div(
            p("The SE shrinks as n grows, but it follows a square-root curve
               rather than a straight line. Doubling n does not halve the SE;
               you need to quadruple n to halve it. The orange curve shows
               the theoretical SE = \u03c3/\u221an relationship. The teal dots are
               the observed SD of sample means from simulations at several
               values of n — they should sit right on the curve. The
               highlighted orange diamond marks the current n slider value."),
            align = "justify"
          ),
          br(),
          plotOutput("plot_step5", height = "420px"),
          br(),
          div(textOutput("text_step5"), align = "justify")
        )
      ) # end tabsetPanel
    )   # end mainPanel
  )     # end sidebarLayout
)       # end fluidPage

# =============================================================================
# Server
# =============================================================================
server <- function(input, output, session) {
  
  # ---------------------------------------------------------------------------
  # Seed management
  #
  # rv$seed starts from a time-based value when the app launches.
  # Clicking "Resample" replaces it with a new random integer, which
  # invalidates all downstream reactives and triggers fresh draws.
  # Changing a slider does NOT change rv$seed, so the random pattern
  # stays stable while students explore sigma / n / k.
  # ---------------------------------------------------------------------------
  rv <- reactiveValues(seed = as.integer(Sys.time()))
  
  observeEvent(input$resample, {
    rv$seed <- sample.int(1e6, 1)
  })
  
  # ---------------------------------------------------------------------------
  # Core data reactive: population + sample matrix
  #
  # Depends on rv$seed, sigma, n, and k.
  # Returns a named list:
  #   $pop   : 100 000-value Normal(0, sigma) reference population
  #   $mat   : n x k matrix — n rows = obs within one sample, k cols = samples
  #   $sums  : length-k vector — column sums of mat (one sum per sample)
  #   $means : length-k vector — column means of mat (one mean per sample)
  #   $indiv : k individual observations drawn from pop (for Step 1 & 2)
  # ---------------------------------------------------------------------------
  simdata <- reactive({
    
    seed  <- rv$seed
    sigma <- input$sigma
    n     <- input$n
    k     <- input$k
    
    # Population: large enough to treat as the true distribution.
    # seed+0 is reserved for the population so it stays fixed across
    # slider changes (only Resample changes it).
    set.seed(seed)
    pop <- rnorm(1e5, mean = 0, sd = sigma)
    
    # Sample matrix: n rows x k columns.
    # seed+1 keeps the matrix stable for a given seed while sliders change.
    set.seed(seed + 1)
    mat <- matrix(
      sample(pop, n * k, replace = TRUE),
      nrow = n, ncol = k
    )
    
    # k individual observations for the Step 1 strip chart and Step 2
    # side-by-side comparison. seed+2 keeps these stable too.
    set.seed(seed + 2)
    indiv <- sample(pop, k)
    
    list(
      pop   = pop,
      mat   = mat,
      sums  = colSums(mat),
      means = colMeans(mat),
      indiv = indiv
    )
  })
  
  # ---------------------------------------------------------------------------
  # Theory box (sidebar)
  #
  # Displays the step-by-step variance derivation for current sigma and n.
  # The Var(mean) row explicitly shows the cancellation:
  #   Var(mean) = n*sigma^2 / n^2 = sigma^2 / n
  # so students can see why dividing by n shrinks variance by n^2, not n.
  # Uses HTML() so Unicode superscripts and the sqrt symbol render correctly.
  # ---------------------------------------------------------------------------
  output$theory_box <- renderUI({
    
    sig <- input$sigma
    n   <- input$n
    
    tagList(
      p(HTML(paste0("<b>\u03c3</b> = ", sig))),
      p(HTML(paste0("<b>n</b> = ", n))),
      p(HTML(paste0("Var(single obs) = \u03c3\u00b2 = ", sig^2))),
      p(HTML(paste0("Var(sum of n)   = n\u00d7\u03c3\u00b2 = ", n * sig^2))),
      p(HTML(paste0("SD(sum of n)    = \u03c3\u221an = ",
                    round(sig * sqrt(n), 2)))),
      # Var(mean) = Var(sum/n) = Var(sum)/n^2 = n*sigma^2 / n^2 = sigma^2/n
      # The intermediate form n*sigma^2/n^2 is shown so the n^2 cancellation
      # is explicit, then simplified to sigma^2/n with its numeric value.
      p(HTML(paste0("Var(mean) = n\u03c3\u00b2/n\u00b2 = \u03c3\u00b2/n = ",
                    round(sig^2 / n, 3)))),
      p(HTML(paste0("<b>SE = \u03c3/\u221an = ",
                    round(sig / sqrt(n), 3), "</b>")))
    )
  })
  
  # ---------------------------------------------------------------------------
  # STEP 1 PLOT
  #
  # Left panel : density curve of the full population (100 000 values)
  # Right panel: strip chart of one fresh sample of size n
  #
  # Both panels share x limits of +/-4sigma so the population spread and
  # individual sample scatter are directly comparable side by side.
  # The teal vertical line on the right panel marks the sample mean;
  # the grey dashed line on both panels marks the true mean (0).
  #
  # Annotations use grconvertX/Y(0.05, 0.90, "npc") on both panels so
  # the text is always pinned to the upper-left corner of each panel,
  # regardless of data scale or sample draw — never obscured by points.
  # ---------------------------------------------------------------------------
  output$plot_step1 <- renderPlot({
    
    d   <- simdata()
    sig <- input$sigma
    n   <- input$n
    
    # Draw one fresh sample of size n for the strip chart.
    # seed+10 keeps this sample distinct from the mat/indiv seeds above.
    set.seed(rv$seed + 10)
    samp <- sample(d$pop, n)
    
    xr <- c(-4 * sig, 4 * sig)   # shared x range across both panels
    
    op <- par(mfrow = c(1, 2), mar = c(4, 3, 3, 1))
    on.exit(par(op))
    
    # AFTER
    # --- Left: theoretical Normal(0, sigma) density — exact curve, not sampled ---
    # Using dnorm directly means this panel never shifts on resample,
    # reinforcing that the population is a fixed, known distribution.
    x_seq <- seq(xr[1], xr[2], length.out = 500)
    y_seq <- dnorm(x_seq, mean = 0, sd = sig)
    plot(x_seq, y_seq,
         type = "l", col = COL_POP, lwd = 2,
         main = "Population distribution (theoretical)",
         xlab = "Value", ylab = "Density",
         xlim = xr, ylim = c(0, max(y_seq) * 1.1),
         cex.main = 1.3, cex.axis = 1.1, cex.lab = 1.1)
    polygon(c(x_seq, rev(x_seq)), c(y_seq, rep(0, length(y_seq))),
            col = adjustcolor(COL_POP, 0.25), border = NA)
    abline(v = 0, lty = 2, col = "grey50")   # true mean = 0
    # grconvertX/Y pins the label to the upper-left corner of this panel
    text(grconvertX(0.05, "npc"), grconvertY(0.90, "npc"),
         labels = paste0("\u03c3 = ", sig),
         col = COL_POP, cex = 1.2, adj = 0)
    
    # --- Right: strip chart of the one sample ---
    stripchart(samp,
               method = "jitter", jitter = 0.3,
               pch = 16,
               col = adjustcolor(COL_POP, 0.6),
               xlim = xr,
               main = paste0("One random sample  (n = ", n, ")"),
               xlab = "Value", ylab = "",
               cex = 1.2, cex.main = 1.3, cex.axis = 1.1, cex.lab = 1.1)
    abline(v = 0,          lty = 2, col = "grey50")          # true mean
    abline(v = mean(samp), lty = 1, col = COL_MEAN, lwd = 2) # sample mean
    # grconvertX/Y pins the label to the upper-left corner of this panel,
    # above the jittered points regardless of where they fall
    text(grconvertX(0.05, "npc"), grconvertY(0.90, "npc"),
         labels = paste0("sample mean = ", round(mean(samp), 2),
                         "\nsample SD  = ", round(sd(samp), 2)),
         col = "black", cex = 1.0, adj = 0)
  })
  
  # Explanatory text rendered below the Step 1 plot
  output$text_step1 <- renderText({
    sig <- input$sigma
    paste0(
      "Each individual observation is drawn from a population with SD = \u03c3 = ", sig, ". ",
      "A randomly chosen value will typically land within about \u00b1", sig,
      " of the true mean, but sometimes much further away. ",
      "This raw scatter is what we track through the next steps as we build up to the sample mean."
    )
  })
  
  # ---------------------------------------------------------------------------
  # STEP 2 PLOT
  #
  # Left panel : histogram of k individual observations  (blue)
  # Right panel: histogram of k sums, each = sum of one n-row sample  (purple)
  #
  # Both histograms share the same x limits (set by whichever distribution
  # is widest) so the difference in spread is directly readable as bar width.
  # Observed SDs and theoretical values are annotated in the upper-left
  # of each panel using grconvertX/Y so they stay in a fixed corner
  # regardless of the data range.
  # ---------------------------------------------------------------------------
  output$plot_step2 <- renderPlot({
    
    d   <- simdata()
    sig <- input$sigma
    n   <- input$n
    
    indiv <- d$indiv   # k single observations (from simdata)
    sv    <- d$sums    # k sums, each = colSum of one sample column
    
    # Shared x limits — driven by whichever is wider (usually the sums)
    max_extent <- max(abs(c(indiv, sv))) * 1.15
    xr <- c(-max_extent, max_extent)
    
    sd_indiv      <- round(sd(indiv), 2)
    sd_sum_obs    <- round(sd(sv),    2)
    sd_sum_theory <- round(sig * sqrt(n), 2)
    
    op <- par(mfrow = c(1, 2), mar = c(4, 3, 3, 1))
    on.exit(par(op))
    
    # --- Left: single observations ---
    hist(indiv,
         breaks = 40, freq = FALSE,
         col    = adjustcolor(COL_POP, 0.6), border = COL_POP,
         main   = "Single observations",
         xlab   = "Value", ylab = "Density",
         xlim   = xr,
         cex.main = 1.3, cex.axis = 1.1, cex.lab = 1.1)
    abline(v = 0, lty = 2, col = "grey50")
    # grconvertX/Y places text at a fixed fraction of the panel area
    # regardless of the data scale — avoids text falling off the plot
    text(grconvertX(0.05, "npc"), grconvertY(0.90, "npc"),
         labels = paste0("Observed SD = ", sd_indiv,
                         "\nTheory: \u03c3 = ", sig),
         col = COL_POP, cex = 1.05, adj = 0)
    
    # --- Right: sums of n observations ---
    hist(sv,
         breaks = 40, freq = FALSE,
         col    = adjustcolor(COL_SUM, 0.6), border = "white",
         main   = paste0("Sums of ", n, " observations"),
         xlab   = paste0("Sum of ", n, " values"), ylab = "Density",
         xlim   = xr,
         cex.main = 1.3, cex.axis = 1.1, cex.lab = 1.1)
    abline(v = 0, lty = 2, col = "grey50")
    text(grconvertX(0.05, "npc"), grconvertY(0.90, "npc"),
         labels = paste0("Observed SD = ", sd_sum_obs,
                         "\nTheory: \u03c3\u221an = ", sd_sum_theory),
         col = COL_SUM, cex = 1.05, adj = 0)
  })
  
  # Explanatory text rendered below the Step 2 plot
  output$text_step2 <- renderText({
    sig <- input$sigma
    n   <- input$n
    paste0(
      "A single observation has SD = \u03c3 = ", sig, ". ",
      "Adding ", n, " independent observations together means their wobbles accumulate: ",
      "Var(sum) = n \u00d7 \u03c3\u00b2 = ", n, " \u00d7 ", sig^2, " = ", n * sig^2, ", ",
      "so SD(sum) = \u03c3\u221an = ", round(sig * sqrt(n), 2), ". ",
      "The sum histogram should be visibly wider than the single-observation histogram — ",
      "try increasing n to exaggerate the difference."
    )
  })
  
  # ---------------------------------------------------------------------------
  # STEP 3 PLOT
  #
  # Single histogram of the k sample means (teal bars).
  # Two curves are overlaid:
  #   (1) smoothed kernel density of the simulated means — teal solid line
  #   (2) theoretical Normal(mean=0, sd=sigma/sqrt(n)) — orange dashed line
  #
  # x limits are set to +/-4 SE so both curves are fully visible even when
  # SE is very small (large n).
  #
  # The annotation uses grconvertX/Y so it is pinned to the upper-left corner
  # of the panel regardless of data scale or resample — it no longer jumps.
  # ---------------------------------------------------------------------------
  output$plot_step3 <- renderPlot({
    
    d   <- simdata()
    sig <- input$sigma
    n   <- input$n
    mv  <- d$means
    
    se_theory <- sig / sqrt(n)
    sd_obs    <- round(sd(mv), 3)
    
    dens  <- density(mv)
    xr    <- c(-4 * se_theory, 4 * se_theory)
    x_seq <- seq(xr[1], xr[2], length.out = 300)
    
    hist(mv,
         breaks = 40, freq = FALSE,
         col    = adjustcolor(COL_MEAN, 0.6), border = "white",
         main   = paste0("Sample means  (n = ", n, ")"),
         xlab   = "Sample mean", ylab = "Density",
         xlim   = xr,
         cex.main = 1.3, cex.axis = 1.1, cex.lab = 1.1)
    
    lines(dens, col = COL_MEAN, lwd = 2)   # smoothed observed density
    
    # Theoretical Normal curve: mean=0 (population mean), sd=sigma/sqrt(n)
    lines(x_seq,
          dnorm(x_seq, mean = 0, sd = se_theory),
          col = COL_THEORY, lwd = 2.5, lty = 2)
    
    abline(v = 0, lty = 2, col = "grey50")   # true population mean
    
    legend("topright",
           legend = c("Observed density",
                      paste0("Theory: Normal(0, \u03c3/\u221an = ",
                             round(se_theory, 2), ")")),
           col = c(COL_MEAN, COL_THEORY),
           lwd = c(2, 2.5), lty = c(1, 2),
           bty = "n", cex = 1.0)
    
    # Upper-left annotation pinned by grconvertX/Y — stays fixed on resample
    text(grconvertX(0.05, "npc"), grconvertY(0.90, "npc"),
         labels = paste0("Observed SE = ", sd_obs,
                         "\nTheory: \u03c3/\u221an = ", round(se_theory, 3)),
         col = "black", cex = 1.05, adj = 0)
  })
  
  # Explanatory text rendered below the Step 3 plot
  output$text_step3 <- renderText({
    sig <- input$sigma
    n   <- input$n
    paste0(
      "Dividing the sum by n to get the mean shrinks variance by n\u00b2 ",
      "(because variance scales with the square of any constant multiplier). ",
      "So: Var(mean) = n\u03c3\u00b2 / n\u00b2 = \u03c3\u00b2/n = ",
      sig^2, "/", n, " = ", round(sig^2 / n, 3), ". ",
      "Taking the square root gives SE = \u03c3/\u221an = ",
      sig, "/\u221a", n, " = ", round(sig / sqrt(n), 3), ". ",
      "The orange dashed curve is that theoretical prediction — check how closely ",
      "it tracks the teal histogram."
    )
  })
  
  # ---------------------------------------------------------------------------
  # STEP 4 PLOT
  #
  # Three histograms stacked vertically (mfrow = c(3,1)), all sharing the
  # same x limits.  The shared range is driven by the widest distribution
  # (the sums), so the narrowing from row 1 to row 3 is immediately visible.
  #
  # Row 1: single observations (blue)  — SD = sigma
  # Row 2: sums of n obs (purple)      — SD = sigma * sqrt(n)
  # Row 3: means of n obs (teal)       — SD = sigma / sqrt(n)
  #
  # Each row includes:
  #   - a smoothed density line (same colour as bars)
  #   - a theoretical Normal overlay (orange dashed)
  #   - annotation pinned to the upper-left via grconvertX/Y — does not jump
  #   - a grey dashed line at x = 0 (true mean; expected sum = 0)
  #
  # Font sizes: cex.main/axis/lab all set to 1.3/1.2/1.2 for iPad legibility.
  # plot_row() is a local helper defined inside renderPlot so it has direct
  # access to xr and COL_THEORY without needing extra arguments.
  # ---------------------------------------------------------------------------
  output$plot_step4 <- renderPlot({
    
    d   <- simdata()
    sig <- input$sigma
    n   <- input$n
    
    indiv <- d$indiv
    sv    <- d$sums
    mv    <- d$means
    
    # Shared x limits — driven by the sums (always the widest)
    max_extent <- max(abs(c(indiv, sv, mv))) * 1.1
    xr <- c(-max_extent, max_extent)
    
    op <- par(mfrow = c(3, 1), mar = c(3, 4, 3, 1), oma = c(1, 0, 2.5, 0))
    on.exit(par(op))
    
    # Internal helper: draws one histogram row with density + theory overlay.
    # Arguments:
    #   vals      : vector of simulated values to histogram
    #   col       : fill colour for bars and density line
    #   main_txt  : panel title string
    #   xlab_txt  : x-axis label string
    #   theory_sd : SD for the Normal(0, theory_sd) theoretical overlay
    #   ann_col   : colour for the upper-left annotation text
    plot_row <- function(vals, col, main_txt, xlab_txt, theory_sd, ann_col) {
      dens <- density(vals)
      hist(vals,
           breaks   = 50, freq = FALSE,
           col      = adjustcolor(col, 0.55), border = "white",
           main     = main_txt, xlab = xlab_txt, ylab = "Density",
           xlim     = xr,
           cex.main = 1.3, cex.axis = 1.2, cex.lab  = 1.2)
      lines(dens, col = col, lwd = 2)
      abline(v = 0, lty = 2, col = "grey60")   # true mean (= 0 for all three)
      
      # Theoretical Normal overlay centred on 0
      x_seq <- seq(xr[1], xr[2], length.out = 300)
      lines(x_seq,
            dnorm(x_seq, mean = 0, sd = theory_sd),
            col = COL_THEORY, lwd = 2, lty = 2)
      
      # Upper-left annotation pinned by grconvertX/Y — stays fixed on resample
      text(grconvertX(0.05, "npc"), grconvertY(0.88, "npc"),
           labels = paste0("SD = ", round(sd(vals), 2),
                           "  (theory: ", round(theory_sd, 2), ")"),
           col = ann_col, cex = 1.4, adj = 0)
    }
    
    plot_row(indiv, COL_POP,
             main_txt  = "Single observations",
             xlab_txt  = "Value",
             theory_sd = sig,
             ann_col   = COL_POP)
    
    plot_row(sv, COL_SUM,
             main_txt  = paste0("Sums of ", n, " observations"),
             xlab_txt  = paste0("Sum of ", n, " values"),
             theory_sd = sig * sqrt(n),
             ann_col   = COL_SUM)
    
    plot_row(mv, COL_MEAN,
             main_txt  = paste0("Means of ", n, " observations  \u2192  SE = \u03c3/\u221an"),
             xlab_txt  = "Sample mean",
             theory_sd = sig / sqrt(n),
             ann_col   = COL_MEAN)
    
    mtext("All three distributions on the same scale",
          outer = TRUE, cex = 1.15, font = 2, line = 1)
  })
  
  # Explanatory text rendered below the Step 4 plot
  output$text_step4 <- renderText({
    sig <- input$sigma
    n   <- input$n
    paste0(
      "Comparing all three on a shared scale shows the full picture: ",
      "a single observation has SD = ", sig, "; ",
      "the sum of ", n, " observations has SD = \u03c3\u221an = ", round(sig * sqrt(n), 2), "; ",
      "and the mean of ", n, " observations has SE = \u03c3/\u221an = ", round(sig / sqrt(n), 2), ". ",
      "The mean is narrower than a single observation, but not by as much as you might expect — ",
      "it takes quadrupling n just to halve the SE."
    )
  })
  
  # ---------------------------------------------------------------------------
  # STEP 5 PLOT
  #
  # Builds the theoretical SE = sigma/sqrt(n) curve for n = 1 to 100, then
  # overlays simulated dots at n = 1, 2, 4, 5, 10, 20, 25, 50, 100.
  # Each dot is the SD of 3000 sample means simulated at that n value.
  #
  # Seed strategy for the dots:
  #   Each n_dots value gets its own sub-seed = rv$seed + ni, so:
  #     - clicking Resample changes all dots (rv$seed changes)
  #     - moving the sigma slider changes their spread but not their pattern
  #     - moving the n slider only moves the orange diamond, not the dots
  #
  # The orange diamond marks the current n slider position on the curve.
  # Its label is offset upward by 0.10*sig (previously 0.03*sig) so it
  # clears the orange theory curve rather than sitting on top of it.
  # ---------------------------------------------------------------------------
  output$plot_step5 <- renderPlot({
    
    sig    <- input$sigma
    n_curr <- input$n
    seed   <- rv$seed
    
    # Theoretical curve across n = 1 to 100
    n_seq    <- seq(1, 100, by = 1)
    se_curve <- sig / sqrt(n_seq)
    
    # Simulated dots: 3000 samples at each of these n values.
    # sapply loops over n_dots; each iteration uses seed+ni so each dot
    # has its own reproducible stream independent of the others.
    n_dots <- c(1, 2, 4, 5, 10, 20, 25, 50, 100)
    obs_se <- sapply(n_dots, function(ni) {
      set.seed(seed + ni)
      mat <- matrix(rnorm(ni * 3000, mean = 0, sd = sig), nrow = ni)
      sd(colMeans(mat))
    })
    
    # Build the plot
    plot(n_seq, se_curve,
         type = "l", lwd = 2.5, col = COL_THEORY,
         main = "Standard Error vs Sample Size",
         xlab = "Sample size (n)",
         ylab = paste0("Standard Error  (\u03c3 = ", sig, ")"),
         ylim = c(0, sig * 1.1),
         cex.main = 1.3, cex.axis = 1.1, cex.lab = 1.1)
    
    grid(col = "grey88", lty = 1)   # light grid helps students read off values
    
    # Teal dots: simulated SEs at the fixed n_dots values
    points(n_dots, obs_se, pch = 19, col = COL_MEAN, cex = 1.6)
    
    # Orange diamond: position of the current n slider on the theoretical curve
    se_curr <- sig / sqrt(n_curr)
    points(n_curr, se_curr, pch = 18, col = "#E07B39", cex = 2.8)
    
    # Drop-lines from the diamond to both axes
    segments(n_curr, 0,       n_curr, se_curr, lty = 2, col = "#E07B39", lwd = 1.5)
    segments(0,      se_curr, n_curr, se_curr, lty = 2, col = "#E07B39", lwd = 1.5)
    
    # Label offset upward by 0.10*sig so it clears the orange theory curve.
    # Previously 0.03*sig, which placed the text on top of the line.
    text(n_curr + 2, se_curr + 0.10 * sig,
         labels = paste0("n = ", n_curr, "\nSE = ", round(se_curr, 2)),
         col = "#E07B39", cex = 1.05, adj = 0)
    
    legend("topright",
           legend = c(paste0("Theory: \u03c3/\u221an"),
                      "Simulated SE",
                      "Current n"),
           col = c(COL_THEORY, COL_MEAN, "#E07B39"),
           pch = c(NA,  19,  18),
           lwd = c(2.5, NA,  NA),
           lty = c(1,   NA,  NA),
           bty = "n", cex = 1.0)
  })
  
  # Explanatory text rendered below the Step 5 plot
  output$text_step5 <- renderText({
    sig    <- input$sigma
    n_curr <- input$n
    n_4x   <- n_curr * 4
    paste0(
      "With \u03c3 = ", sig, " and n = ", n_curr,
      ", the SE = \u03c3/\u221an = ", round(sig / sqrt(n_curr), 2), ". ",
      "To cut the SE in half you would need to quadruple the sample size to n = ", n_4x,
      " (giving SE = ", round(sig / sqrt(n_4x), 2), "). ",
      "This diminishing return is the practical lesson of the \u221an rule: ",
      "collecting more data always helps, but each successive halving of uncertainty ",
      "costs four times as many observations."
    )
  })
  
} # end server

# =============================================================================
# Launch
# =============================================================================
shinyApp(ui = ui, server = server)