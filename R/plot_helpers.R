# Shared plotting helpers for publication figures (HMSC + GIFT).

filter_study_samples <- function(sample_metadata, genome_counts_filt = NULL) {
  meta <- sample_metadata %>%
    dplyr::filter(sample != "EHI01340")

  if (is.null(genome_counts_filt)) {
    return(meta)
  }

  valid_samples <- meta$sample
  counts <- genome_counts_filt %>%
    dplyr::select(genome, tidyselect::any_of(valid_samples))

  list(metadata = meta, genome_counts = counts)
}

validate_hmsc_posterior_import <- function(m, importFromHPC, expected_samples = NULL, model_label = "HMSC model") {
  n_sp_fit <- ncol(importFromHPC[[1]][[1]]$Beta)
  n_sp_unfit <- length(m$spNames)
  n_samples_unfit <- nrow(m$XData)

  if (n_sp_unfit != n_sp_fit) {
    stop(
      model_label, ": unfitted model (", n_sp_unfit,
      " genomes) does not match fitted posterior (", n_sp_fit,
      " genomes). Re-run the matching setup chapter and HPC fit.", call. = FALSE
    )
  }

  if (!is.null(expected_samples) && n_samples_unfit != expected_samples) {
    stop(
      model_label, ": unfitted model has ", n_samples_unfit,
      " samples but expected ", expected_samples,
      ". Re-run the matching setup chapter and HPC fit.", call. = FALSE
    )
  }

  invisible(TRUE)
}

environment_plot_settings <- function() {
  list(
    limits = c(
      "1000198 - Mixed forest",
      "1000221 - Temperate woodland",
      "1000218 - Xeric shrubland",
      "1000215 - Temperate shrubland",
      "1000245 - Cropland"
    ),
    labels_short = c("MF", "TW", "XS", "TS", "C"),
    labels_long = c(
      "1000198 - Mixed forest" = "Mixed forest (MF)",
      "1000221 - Temperate woodland" = "Temperate woodland (TW)",
      "1000218 - Xeric shrubland" = "Xeric shrubland (XS)",
      "1000215 - Temperate shrubland" = "Temperate shrubland (TS)",
      "1000245 - Cropland" = "Cropland (C)"
    ),
    colors = c(
      "#f56042", "#429ef5", "#42f58d", "#b142f5", "#FFA500"
    )
  )
}

environment_short_label_map <- function(env_settings = environment_plot_settings()) {
  stats::setNames(env_settings$labels_short, env_settings$limits)
}

environment_color_values <- function(env_settings = environment_plot_settings(),
                                     levels = NULL) {
  vals <- stats::setNames(env_settings$colors, env_settings$limits)
  if (is.null(levels)) {
    return(vals)
  }
  vals[levels]
}

phylum_stacked_environment_order <- function(sample_metadata,
                                             env_settings = environment_plot_settings()) {
  priority <- c(
    "1000221 - Temperate woodland",
    "1000245 - Cropland"
  )
  counts <- sample_metadata %>%
    dplyr::mutate(broad_environment = as.character(.data$broad_environment)) %>%
    dplyr::count(.data$broad_environment, name = "n")
  others <- counts %>%
    dplyr::filter(!.data$broad_environment %in% priority) %>%
    dplyr::arrange(dplyr::desc(.data$n), .data$broad_environment) %>%
    dplyr::pull(.data$broad_environment)
  c(priority, others)
}

alpha_metric_labels <- c(
  richness = "Richness (Hill q0)",
  neutral = "Neutral diversity (Hill q1)",
  phylogenetic = "Phylogenetic diversity (Hill q1)",
  functional = "Functional diversity (Hill q1)"
)

beta_metric_labels <- c(
  beta_q0n = "Richness turnover (Hill q0)",
  beta_q1n = "Neutral turnover (Hill q1)",
  beta_q1p = "Phylogenetic turnover (Hill q1)",
  beta_q1f = "Functional turnover (Hill q1)"
)

get_beta_estimate <- function(fit_model, model_obj, covariate_name) {
  getPostEstimate(hM = fit_model, parName = "Beta")$mean %>%
    as.data.frame() %>%
    mutate(variable = model_obj$covNames) %>%
    filter(variable == covariate_name) %>%
    pivot_longer(!variable, names_to = "genome", values_to = "mean") %>%
    dplyr::select(genome, mean)
}

get_beta_support <- function(fit_model, model_obj, covariate_name) {
  getPostEstimate(hM = fit_model, parName = "Beta")$support %>%
    as.data.frame() %>%
    mutate(variable = model_obj$covNames) %>%
    filter(variable == covariate_name) %>%
    pivot_longer(!variable, names_to = "genome", values_to = "support") %>%
    dplyr::select(genome, support)
}

get_beta_ci <- function(fit_model, model_obj, covariate_name, quantiles = c(0.1, 0.9)) {
  beta_q <- getPostEstimate(hM = fit_model, parName = "Beta", q = quantiles)$q
  idx_cov <- which(model_obj$covNames == covariate_name)
  n_genomes <- length(model_obj$spNames)

  purrr::map_dfr(seq_len(n_genomes), ~ {
    tibble(
      genome = model_obj$spNames[.x],
      q10 = beta_q[1, idx_cov, .x],
      q90 = beta_q[2, idx_cov, .x]
    )
  })
}

get_beta_complete <- function(fit_model, model_obj, covariate_name, genome_metadata = NULL,
                              quantiles = c(0.1, 0.9)) {
  if (is.null(genome_metadata)) {
    genome_metadata <- get("genome_metadata", envir = parent.frame(), inherits = TRUE)
  }
  estimate <- get_beta_estimate(fit_model, model_obj, covariate_name)
  ci <- get_beta_ci(fit_model, model_obj, covariate_name, quantiles)

  ci %>%
    right_join(estimate, by = "genome") %>%
    left_join(genome_metadata, by = "genome")
}

calculate_functional_differences <- function(elements_response, variable_name) {
  var_sym <- rlang::sym(variable_name)

  elements_response %>%
    filter(!!var_sym != "Neutral") %>%
    mutate(!!var_sym := droplevels(!!var_sym)) %>%
    group_by(GIFT) %>%
    summarise(
      n_pos = sum(!!var_sym == "Positive"),
      n_neg = sum(!!var_sym == "Negative"),
      mean_pos = mean(value[!!var_sym == "Positive"], na.rm = TRUE),
      mean_neg = mean(value[!!var_sym == "Negative"], na.rm = TRUE),
      diff = mean_pos - mean_neg,
      sd_pos = stats::sd(value[!!var_sym == "Positive"], na.rm = TRUE),
      sd_neg = stats::sd(value[!!var_sym == "Negative"], na.rm = TRUE),
      p = if (
        n_pos > 1 && n_neg > 1 &&
          stats::sd(value[!!var_sym == "Positive"], na.rm = TRUE) > 0 &&
          stats::sd(value[!!var_sym == "Negative"], na.rm = TRUE) > 0
      ) {
        stats::t.test(value ~ !!var_sym, var.equal = FALSE)$p.value
      } else {
        NA_real_
      },
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      se_diff = sqrt(.data$sd_pos^2 / .data$n_pos + .data$sd_neg^2 / .data$n_neg),
      df_welch = (.data$sd_pos^2 / .data$n_pos + .data$sd_neg^2 / .data$n_neg)^2 /
        ((.data$sd_pos^2 / .data$n_pos)^2 / pmax(.data$n_pos - 1, 1) +
           (.data$sd_neg^2 / .data$n_neg)^2 / pmax(.data$n_neg - 1, 1)),
      t_crit = stats::qt(0.975, pmax(.data$df_welch, 1)),
      ci_low = .data$diff - .data$t_crit * .data$se_diff,
      ci_high = .data$diff + .data$t_crit * .data$se_diff
    ) %>%
    mutate(p_adj = p.adjust(p, method = "BH")) %>%
    arrange(p_adj)
}

#' Mean genome-level HMSC beta per GIFT element (for interaction spotlight).
#'
#' Contrasts genomes that carry each GIFT element; tests whether mean beta != 0.
#' Use this for interaction instead of \code{calculate_functional_differences()},
#' because interaction-positive genomes largely overlap devil-negative genomes and
#' abundance contrasts mirror main-effect contrasts (see \code{audit_hmsc_spotlight_contrasts()}).
calculate_functional_beta_by_gift <- function(ci_data,
                                             elements_response,
                                             min_genomes = 10,
                                             presence_threshold = 0,
                                             beta_col = "mean") {
  genome_beta <- ci_data %>%
    dplyr::select(genome, beta = dplyr::all_of(beta_col))

  result <- elements_response %>%
    dplyr::filter(.data$value > presence_threshold) %>%
    dplyr::inner_join(genome_beta, by = "genome") %>%
    dplyr::group_by(.data$GIFT) %>%
    dplyr::summarise(
      n_genomes = dplyr::n(),
      n_pos = dplyr::n(),
      n_neg = dplyr::n(),
      diff = mean(.data$beta, na.rm = TRUE),
      sd_beta = stats::sd(.data$beta, na.rm = TRUE),
      p = if (
        dplyr::n() >= min_genomes &&
          is.finite(stats::sd(.data$beta, na.rm = TRUE)) &&
          stats::sd(.data$beta, na.rm = TRUE) > 0
      ) {
        stats::t.test(.data$beta, mu = 0)$p.value
      } else {
        NA_real_
      },
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      se_diff = .data$sd_beta / sqrt(.data$n_genomes),
      t_crit = stats::qt(0.975, pmax(.data$n_genomes - 1, 1)),
      ci_low = .data$diff - .data$t_crit * .data$se_diff,
      ci_high = .data$diff + .data$t_crit * .data$se_diff,
      p_adj = stats::p.adjust(.data$p, method = "BH")
    ) %>%
    dplyr::arrange(.data$p_adj)

  attr(result, "comparison_note") <- paste0(
    "Mean HMSC beta across genomes carrying each GIFT element (n >= ",
    min_genomes, ")"
  )
  result
}

#' Check whether interaction abundance contrasts mirror devil main-effect contrasts.
audit_hmsc_spotlight_contrasts <- function(post_table,
                                           functional_diff_devil,
                                           functional_diff_interaction,
                                           fc_threshold = 0.2,
                                           fdr_threshold = 0.05) {
  interaction_col <- "devil:temperature"
  pt <- post_table %>%
    tibble::rownames_to_column("genome")

  devil_int_crosstab <- table(pt$devil, pt[[interaction_col]])

  sig_devil <- functional_diff_devil %>%
    dplyr::filter(
      !is.na(.data$p_adj),
      .data$p_adj < fdr_threshold,
      abs(.data$diff) >= fc_threshold
    )
  sig_int <- functional_diff_interaction %>%
    dplyr::filter(
      !is.na(.data$p_adj),
      .data$p_adj < fdr_threshold,
      abs(.data$diff) >= fc_threshold
    )

  overlap <- sig_devil %>%
    dplyr::inner_join(
      sig_int %>% dplyr::select(GIFT, diff_int = diff),
      by = "GIFT"
    )

  mirror_cor <- if (nrow(overlap) >= 3) {
    stats::cor(overlap$diff, overlap$diff_int, use = "pairwise.complete.obs")
  } else {
    NA_real_
  }

  devil_pos_int_pos <- sum(
    pt$devil == "Positive" & pt[[interaction_col]] == "Positive",
    na.rm = TRUE
  )

  list(
    devil_int_crosstab = devil_int_crosstab,
    devil_pos_and_interaction_pos = devil_pos_int_pos,
    n_sig_devil = nrow(sig_devil),
    n_sig_interaction = nrow(sig_int),
    n_sig_both = nrow(overlap),
    diff_correlation = mirror_cor,
    mean_diff_ratio = if (nrow(overlap) > 0) {
      mean(overlap$diff_int / overlap$diff, na.rm = TRUE)
    } else {
      NA_real_
    },
    mirror_warning = !is.na(mirror_cor) &&
      mirror_cor < -0.8 &&
      devil_pos_int_pos == 0
  )
}

create_volcano_plot <- function(functional_differences,
                                variable_label,
                                gift_colors,
                                fc_threshold = 0.2,
                                fdr_threshold = 0.05,
                                x_lab = "Mean difference (Positive − Negative)",
                                highlight_thresholds = FALSE,
                                show_legend = TRUE,
                                volcano_metric = c("abundance_diff", "interaction_beta"),
                                subtitle = NULL,
                                theme_fn = theme_publication) {
  volcano_metric <- match.arg(volcano_metric)
  is_interaction_beta <- identical(volcano_metric, "interaction_beta")
  fc_label <- if (is_interaction_beta) "\u03b2" else "diff"
  default_interaction_subtitle <- paste(
    "Mean HMSC interaction \u03b2 across genomes carrying each GIFT element",
    "(distinct from abundance contrasts in panels A\u2013C)"
  )
  plot_data <- functional_differences %>%
    mutate(func = substr(GIFT, 1, 3)) %>%
    mutate(
      p_adj_plot = ifelse(is.na(p_adj) | p_adj == 0, .Machine$double.xmin, p_adj),
      neglog10_fdr = -log10(p_adj_plot),
      hit = !is.na(p_adj) & p_adj < fdr_threshold & abs(diff) >= fc_threshold
    ) %>%
    mutate(func = ifelse(hit, func, "NS")) %>%
    filter(neglog10_fdr < 20)

  func_levels <- sort(unique(plot_data$func))
  palette_df <- tibble(func = func_levels) %>%
    left_join(
      gift_colors %>% dplyr::select(func = Code_function, Color),
      by = "func"
    ) %>%
    mutate(
      Color = case_when(
        func == "NS" & is.na(Color) ~ "grey70",
        is.na(Color) ~ "#999999",
        TRUE ~ Color
      )
    )

  color_values <- setNames(palette_df$Color, palette_df$func)
  n_hits <- sum(plot_data$hit, na.rm = TRUE)
  fdr_line <- -log10(fdr_threshold)
  y_top <- 15
  x_left <- -0.6
  x_right <- 0.6

  p <- plot_data %>%
    ggplot2::ggplot(ggplot2::aes(x = diff, y = neglog10_fdr, color = func)) +
    ggplot2::geom_point(alpha = if (highlight_thresholds) 0.75 else 0.8, size = if (highlight_thresholds) 1.8 else 2) +
    ggplot2::ylim(0, y_top) +
    ggplot2::xlim(x_left, x_right) +
    ggrepel::geom_text_repel(
      data = subset(plot_data, hit),
      ggplot2::aes(label = GIFT),
      size = if (highlight_thresholds) 2.6 else 3,
      max.overlaps = 20,
      box.padding = 0.3,
      min.segment.length = 0
    ) +
    ggplot2::scale_color_manual(values = color_values) +
    ggplot2::labs(
      title = variable_label,
      x = x_lab,
      y = expression(-log[10]("FDR (BH)")),
      color = "Group",
      subtitle = if (!is.null(subtitle)) {
        subtitle
      } else if (highlight_thresholds && is_interaction_beta) {
        default_interaction_subtitle
      } else if (highlight_thresholds) {
        NULL
      } else {
        paste0("Thresholds: |", fc_label, "| \u2265 ", fc_threshold, ", FDR < ", fdr_threshold)
      }
    )

  if (highlight_thresholds) {
    p <- p +
      ggplot2::annotate(
        "rect",
        xmin = fc_threshold, xmax = x_right, ymin = fdr_line, ymax = y_top,
        fill = "#1B7837", alpha = 0.07
      ) +
      ggplot2::annotate(
        "rect",
        xmin = x_left, xmax = -fc_threshold, ymin = fdr_line, ymax = y_top,
        fill = "#D73027", alpha = 0.07
      ) +
      ggplot2::geom_vline(
        xintercept = c(-fc_threshold, fc_threshold),
        linetype = "dashed",
        colour = "grey35",
        linewidth = 0.45
      ) +
      ggplot2::geom_hline(
        yintercept = fdr_line,
        linetype = "dashed",
        colour = "grey35",
        linewidth = 0.45
      ) +
      ggplot2::annotate(
        "text",
        x = fc_threshold + 0.02,
        y = y_top - 0.6,
        hjust = 0,
        size = 2.8,
        colour = "grey25",
        label = paste0("|", fc_label, "| \u2265 ", fc_threshold)
      ) +
      ggplot2::annotate(
        "text",
        x = x_left + 0.02,
        y = fdr_line + 0.45,
        hjust = 0,
        size = 2.8,
        colour = "grey25",
        label = paste0("FDR < ", fdr_threshold)
      ) +
      ggplot2::annotate(
        "label",
        x = x_right - 0.02,
        y = 0.55,
        hjust = 1,
        size = 2.8,
        fill = "white",
        alpha = 0.85,
        colour = "grey20",
        label = if (is_interaction_beta) {
          paste0(n_hits, " significant (mean \u03b2 \u2260 0)")
        } else {
          paste0(n_hits, " significant GIFT elements")
        }
      )
  } else {
    p <- p +
      ggplot2::geom_vline(xintercept = c(-fc_threshold, fc_threshold), linetype = "dashed") +
      ggplot2::geom_hline(yintercept = fdr_line, linetype = "dashed")
  }

  p <- p + theme_fn() +
    ggplot2::theme(
      legend.position = if (isTRUE(show_legend)) "right" else "none"
    )

  if (is_interaction_beta) {
    p <- p +
      ggplot2::theme(
        plot.subtitle = ggplot2::element_text(
          size = rel(0.82),
          face = "italic",
          colour = "#2166AC",
          lineheight = 0.95,
          margin = ggplot2::margin(b = 4)
        ),
        panel.border = ggplot2::element_rect(
          colour = "#2166AC",
          fill = NA,
          linewidth = 0.75
        ),
        plot.title = ggplot2::element_text(colour = "#2166AC")
      )
  }

  p
}

prepare_functional_significance_data <- function(functional_differences,
                                                 gift_colors,
                                                 fc_threshold = 0.2,
                                                 fdr_threshold = 0.05,
                                                 truncate_func_label = 28L) {
  functional_differences %>%
    dplyr::mutate(
      func = substr(.data$GIFT, 1, 3),
      hit = !is.na(.data$p_adj) &
        .data$p_adj < fdr_threshold &
        abs(.data$diff) >= fc_threshold,
      direction = dplyr::case_when(
        .data$hit & .data$diff > 0 ~ "Positive association",
        .data$hit & .data$diff < 0 ~ "Negative association",
        TRUE ~ "Not significant"
      )
    ) %>%
    dplyr::left_join(
      gift_colors %>%
        dplyr::transmute(
          func = .data$Code_function,
          func_label = .data$Function,
          color = .data$Color
        ),
      by = "func"
    ) %>%
    dplyr::mutate(
      color = dplyr::if_else(is.na(.data$color), "grey70", .data$color),
      func_label_short = dplyr::if_else(
        is.na(.data$func_label) | .data$func_label == "",
        .data$func,
        .data$func_label
      ),
      func_label_short = if (!is.null(truncate_func_label) && is.finite(truncate_func_label)) {
        stringr::str_trunc(.data$func_label_short, truncate_func_label, "right")
      } else {
        .data$func_label_short
      },
      gift_label = paste0(.data$GIFT, " - ", .data$func_label_short)
    )
}

gift_func_color_map <- function(func_levels, gift_colors) {
  func_palette <- gift_colors %>%
    dplyr::filter(.data$Code_function %in% func_levels) %>%
    dplyr::transmute(func = .data$Code_function, color = .data$Color)
  func_color_map <- stats::setNames(func_palette$color, func_palette$func)
  missing_funcs <- setdiff(func_levels, names(func_color_map))
  if (length(missing_funcs) > 0) {
    func_color_map <- c(
      func_color_map,
      stats::setNames(rep("grey70", length(missing_funcs)), missing_funcs)
    )
  }
  func_color_map
}

add_functional_difference_intervals <- function(functional_differences) {
  if ("ci_low" %in% names(functional_differences) &&
      "ci_high" %in% names(functional_differences) &&
      !all(is.na(functional_differences$ci_low))) {
    return(functional_differences)
  }

  if (all(c("sd_pos", "sd_neg", "n_pos", "n_neg", "diff") %in% names(functional_differences))) {
    return(
      functional_differences %>%
        dplyr::mutate(
          se_diff = sqrt(.data$sd_pos^2 / .data$n_pos + .data$sd_neg^2 / .data$n_neg),
          df_welch = (.data$sd_pos^2 / .data$n_pos + .data$sd_neg^2 / .data$n_neg)^2 /
            ((.data$sd_pos^2 / .data$n_pos)^2 / pmax(.data$n_pos - 1, 1) +
               (.data$sd_neg^2 / .data$n_neg)^2 / pmax(.data$n_neg - 1, 1)),
          t_crit = stats::qt(0.975, pmax(.data$df_welch, 1)),
          ci_low = .data$diff - .data$t_crit * .data$se_diff,
          ci_high = .data$diff + .data$t_crit * .data$se_diff
        )
    )
  }

  functional_differences %>%
    dplyr::mutate(
      se_diff = dplyr::if_else(
        !is.na(.data$p) & .data$p > 0,
        abs(.data$diff) / stats::qnorm(1 - .data$p / 2),
        pmax(abs(.data$diff) * 0.2, 0.05)
      ),
      ci_low = .data$diff - stats::qnorm(0.975) * .data$se_diff,
      ci_high = .data$diff + stats::qnorm(0.975) * .data$se_diff
    )
}

prepare_functional_trait_forest_data <- function(functional_differences,
                                                 gift_colors,
                                                 fc_threshold = 0.2,
                                                 fdr_threshold = 0.05,
                                                 truncate_func_label = 28L) {
  functional_differences %>%
    add_functional_difference_intervals() %>%
    prepare_functional_significance_data(
      gift_colors = gift_colors,
      fc_threshold = fc_threshold,
      fdr_threshold = fdr_threshold,
      truncate_func_label = truncate_func_label
    ) %>%
    dplyr::mutate(
      coefficient = .data$diff,
      trait_label = .data$gift_label
    )
}

create_functional_trait_forest_plot <- function(functional_differences,
                                                gift_colors,
                                                variable_label = NULL,
                                                fc_threshold = 0.2,
                                                fdr_threshold = 0.05,
                                                negative_label = "Negative HMSC association",
                                                positive_label = "Positive HMSC association",
                                                x_lab = "Mean abundance difference (95% CI)",
                                                spotlight_cols = spotlight_palettes(),
                                                theme_fn = theme_publication) {
  plot_data <- prepare_functional_trait_forest_data(
    functional_differences,
    gift_colors,
    fc_threshold = fc_threshold,
    fdr_threshold = fdr_threshold
  )

  hits <- plot_data %>%
    dplyr::filter(.data$hit) %>%
    dplyr::arrange(.data$coefficient)

  n_hits <- nrow(hits)
  if (n_hits == 0) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate(
          "text",
          x = 0,
          y = 0,
          label = "No GIFT elements pass significance thresholds",
          size = 3.5,
          colour = "grey40"
        ) +
        ggplot2::theme_void()
    )
  }

  n_pos <- sum(hits$direction == "Positive association")
  n_neg <- sum(hits$direction == "Negative association")
  comparison_n <- hits %>%
    dplyr::slice(1) %>%
    dplyr::select("n_pos", "n_neg")

  comparison_note <- attr(functional_differences, "comparison_note")
  if (is.null(comparison_note)) {
    comparison_note <- paste0(
      "Compared genomes: ", comparison_n$n_pos, " positive vs ",
      comparison_n$n_neg, " negative"
    )
  }

  hits <- hits %>%
    dplyr::mutate(
      trait_label = factor(
        .data$trait_label,
        levels = .data$trait_label[order(.data$coefficient)]
      ),
      label_colour = dplyr::case_when(
        .data$direction == "Positive association" ~ spotlight_cols$congruent,
        .data$direction == "Negative association" ~ spotlight_cols$discordant,
        TRUE ~ "grey40"
      )
    )

  func_levels <- sort(unique(hits$func))
  func_color_map <- gift_func_color_map(func_levels, gift_colors)

  x_range <- range(
    c(hits$coefficient, hits$ci_low, hits$ci_high, -fc_threshold, fc_threshold),
    na.rm = TRUE
  )
  x_pad <- max(0.05, diff(x_range) * 0.12)
  x_left <- x_range[1] - x_pad
  x_right <- x_range[2] + x_pad

  title_text <- if (is.null(variable_label)) {
    "Significant functional traits"
  } else {
    paste0(variable_label, ": significant functional traits")
  }

  direction_summary <- if (n_pos > 0 && n_neg > 0) {
    paste0(
      n_hits, " traits (", n_pos, " enriched with positive genomes, ",
      n_neg, " with negative genomes)"
    )
  } else if (n_pos > 0) {
    paste0(n_hits, " traits enriched in genomes with positive HMSC association")
  } else {
    paste0(n_hits, " traits enriched in genomes with negative HMSC association")
  }

  p <- hits %>%
    ggplot2::ggplot(ggplot2::aes(y = .data$trait_label)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey45", linewidth = 0.45) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        xmin = .data$ci_low,
        xmax = .data$ci_high,
        colour = .data$func
      ),
      orientation = "y",
      width = 0.24,
      linewidth = 0.5,
      alpha = 0.9
    ) +
    ggplot2::geom_point(
      ggplot2::aes(
        x = .data$coefficient,
        fill = .data$func
      ),
      shape = 21,
      colour = "white",
      size = 2.8,
      stroke = 0.35
    ) +
    ggplot2::scale_fill_manual(values = func_color_map, name = "GIFT function") +
    ggplot2::scale_colour_manual(values = func_color_map, guide = "none") +
    ggplot2::scale_y_discrete(expand = ggplot2::expansion(mult = c(0.04, 0.08))) +
    ggplot2::coord_cartesian(xlim = c(x_left, x_right), clip = "off") +
    ggplot2::labs(
      title = title_text,
      subtitle = paste0(
        direction_summary,
        "\nThresholds: |difference| >= ", fc_threshold, ", FDR < ", fdr_threshold,
        "  |  ", comparison_note
      ),
      x = x_lab,
      y = NULL,
      caption = "Fill = GIFT function. Error bars = 95% CI."
    ) +
    theme_fn() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(size = 8, colour = "grey20"),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(colour = "grey93", linewidth = 0.25),
      plot.subtitle = ggplot2::element_text(size = 8, colour = "grey30", lineheight = 0.95),
      plot.caption = ggplot2::element_text(size = 7, colour = "grey35", hjust = 0),
      plot.margin = ggplot2::margin(10, 10, 8, 8),
      legend.position = "bottom",
      legend.box = "horizontal"
    ) +
    ggplot2::guides(fill = ggplot2::guide_legend(nrow = 2, byrow = TRUE, override.aes = list(size = 3)))

  p
}

#' Official #ShowYourStripes palette (8 blues + 8 reds from ColorBrewer 9-class single hue).
#' @seealso https://showyourstripes.info
show_your_stripes_colors <- function() {
  c(
    "#08306B", "#08519C", "#2171B5", "#4292C6",
    "#6BAED6", "#9ECAE1", "#C6DBEF", "#DEEBF7",
    "#FEE0D2", "#FCBBA1", "#FC9272", "#FB6A4A",
    "#EF3B2C", "#CB181D", "#A50F15", "#67000D"
  )
}

functional_climate_palette <- function(n = 256) {
  stripes <- show_your_stripes_colors()
  blues <- stripes[1:8]
  reds <- stripes[9:16]
  n_side <- floor((n - 1) / 2)
  c(
    grDevices::colorRampPalette(blues)(n_side),
    "#FFFFFF",
    grDevices::colorRampPalette(reds)(n_side)
  )
}

climate_stripe_endpoint_colors <- function() {
  stripes <- show_your_stripes_colors()
  list(
    negative = stripes[[1]],
    neutral = "#FFFFFF",
    positive = stripes[[16]]
  )
}

gift_major_function_group <- function(gift_codes) {
  func_major <- substr(gift_codes, 1, 1)
  dplyr::case_when(
    func_major == "D" ~ "Degradation",
    func_major == "B" ~ "Biosynthesis",
    func_major == "S" ~ "Structure",
    TRUE ~ "Other"
  )
}

gift_major_function_group_levels <- function() {
  c("Degradation", "Biosynthesis", "Structure", "Other")
}

gift_major_function_group_descriptions <- function() {
  c(
    Degradation = "Breakdown of lipids, sugars, proteins, and xenobiotics.",
    Biosynthesis = "Synthesis of amino acids, vitamins, SCFAs, and antibiotics.",
    Structure = "Cell envelope, appendages, and sporulation traits."
  )
}

create_gift_function_grouped_legend_plot <- function(gift_colors,
                                                     base_size = 9) {
  descriptions <- gift_major_function_group_descriptions()
  group_levels <- gift_major_function_group_levels()[1:3]
  group_layout <- tibble::tibble(
    func_group = factor(group_levels, levels = group_levels),
    group_x = c(0, 2.9, 5.6),
    n_col = c(5L, 5L, 3L),
    title_x = c(1.1, 3.95, 6.35),
    col_step = 0.55
  )

  items <- gift_colors %>%
    dplyr::transmute(
      code = .data$Code_function,
      label = .data$Code_function,
      color = .data$Color,
      func_group = factor(
        gift_major_function_group(.data$Code_function),
        levels = group_levels
      )
    ) %>%
    dplyr::arrange(.data$func_group, .data$code) %>%
    dplyr::group_by(.data$func_group) %>%
    dplyr::mutate(
      idx = dplyr::row_number(),
      n_col = group_layout$n_col[match(as.character(.data$func_group), group_layout$func_group)],
      col_step = group_layout$col_step[match(as.character(.data$func_group), group_layout$func_group)],
      legend_col = (.data$idx - 1L) %% .data$n_col,
      legend_row = (.data$idx - 1L) %/% .data$n_col,
      group_x = group_layout$group_x[match(as.character(.data$func_group), group_layout$func_group)],
      x = .data$group_x + .data$legend_col * .data$col_step,
      y = -(.data$legend_row + 0.5)
    ) %>%
    dplyr::ungroup()

  title_df <- group_layout %>%
    dplyr::mutate(
      y = 0.95,
      label = as.character(.data$func_group)
    )

  desc_df <- group_layout %>%
    dplyr::mutate(
      y = 0.45,
      label = vapply(
        as.character(.data$func_group),
        function(grp) {
          paste(stringr::str_wrap(descriptions[[grp]], width = 30), collapse = "\n")
        },
        character(1)
      )
    )

  y_min <- min(items$y) - 0.55
  y_max <- 1.35

  ggplot2::ggplot(items) +
    ggplot2::geom_rect(
      ggplot2::aes(
        xmin = .data$x,
        xmax = .data$x + 0.24,
        ymin = .data$y - 0.3,
        ymax = .data$y + 0.3,
        fill = .data$color
      ),
      colour = NA
    ) +
    ggplot2::geom_text(
      ggplot2::aes(x = .data$x + 0.28, y = .data$y, label = .data$label),
      hjust = 0,
      size = publication_legend_geom_text_mm(base_size * 0.36),
      colour = "grey15"
    ) +
    ggplot2::geom_text(
      data = title_df,
      ggplot2::aes(x = .data$title_x, y = .data$y, label = .data$label),
      inherit.aes = FALSE,
      fontface = "bold",
      size = publication_legend_geom_text_mm(base_size * 0.42),
      hjust = 0.5
    ) +
    ggplot2::geom_text(
      data = desc_df,
      ggplot2::aes(x = .data$title_x, y = .data$y, label = .data$label),
      inherit.aes = FALSE,
      size = publication_legend_geom_text_mm(base_size * 0.32),
      hjust = 0.5,
      colour = "grey35",
      lineheight = 0.95
    ) +
    ggplot2::annotate(
      "text",
      x = 3.6,
      y = y_min + 0.15,
      label = "Grey points: non-significant GIFT elements (NS)",
      size = publication_legend_geom_text_mm(base_size * 0.32),
      colour = "grey40",
      hjust = 0.5
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::scale_x_continuous(limits = c(-0.15, 7.8), expand = c(0, 0)) +
    ggplot2::scale_y_continuous(limits = c(y_min, y_max), expand = c(0, 0)) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.margin = ggplot2::margin(2, 8, 2, 8)
    )
}

compose_hmsc_volcano_composite <- function(panel_plots,
                                           gift_colors,
                                           ncol = 2L,
                                           legend_height_rel = 1.05,
                                           caption = NULL) {
  if (!requireNamespace("patchwork", quietly = TRUE)) {
    stop("Package 'patchwork' is required for HMSC volcano composites.", call. = FALSE)
  }

  if (is.null(caption) && length(panel_plots) >= 4L) {
    caption <- paste(
      "Panels A\u2013C: mean GIFT abundance difference between HMSC-positive and HMSC-negative genomes.",
      "Panel D: mean genome-level HMSC interaction \u03b2 per GIFT element (one-sample test vs 0)."
    )
  }

  panel_block <- patchwork::wrap_plots(panel_plots, ncol = ncol) +
    patchwork::plot_annotation(
      tag_levels = "A",
      caption = caption,
      theme = ggplot2::theme(
        plot.tag = ggplot2::element_text(face = "bold", size = 14),
        plot.tag.position = "topleft",
        plot.caption = ggplot2::element_text(
          size = 8,
          colour = "grey30",
          hjust = 0,
          lineheight = 1.05,
          margin = ggplot2::margin(t = 6)
        ),
        plot.caption.position = "plot"
      )
    ) &
    ggplot2::theme(legend.position = "none")

  legend_plot <- create_gift_function_grouped_legend_plot(gift_colors)

  panel_block / legend_plot +
    patchwork::plot_layout(heights = c(4, legend_height_rel))
}

hmsc_volcano_composite_dims_mm <- function(width_mm = publication_figure_defaults()$width_mm,
                                           height_mm = publication_figure_defaults()$height_mm,
                                           ncol = 2L,
                                           legend_extra_mm = 68) {
  list(
    width_mm = width_mm * ncol,
    height_mm = height_mm * 2 + legend_extra_mm
  )
}

add_gift_major_function_group <- function(data) {
  data %>%
    dplyr::mutate(
      func_major = substr(.data$GIFT, 1, 1),
      func_group = gift_major_function_group(.data$GIFT),
      func_group = factor(.data$func_group, levels = gift_major_function_group_levels())
    )
}

add_climate_stripe_fields <- function(data) {
  data %>%
    dplyr::mutate(
      p_adj_plot = dplyr::if_else(
        is.na(.data$p_adj) | .data$p_adj == 0,
        .Machine$double.xmin,
        .data$p_adj
      ),
      neglog10_fdr = -log10(.data$p_adj_plot),
      stripe_value = .data$coefficient,
      stripe_fill = .data$neglog10_fdr * sign(.data$coefficient)
    )
}

prepare_functional_predictor_comparison <- function(functional_diff_list,
                                                    predictor_labels = NULL,
                                                    gift_colors,
                                                    fc_threshold = 0.2,
                                                    fdr_threshold = 0.05,
                                                    trait_set = c("per_panel", "union"),
                                                    truncate_func_label = 28L) {
  trait_set <- match.arg(trait_set)
  if (is.null(predictor_labels)) {
    predictor_labels <- names(functional_diff_list)
  }
  if (is.null(predictor_labels) || any(predictor_labels == "")) {
    predictor_labels <- paste0("Predictor ", seq_along(functional_diff_list))
  }
  if (length(predictor_labels) != length(functional_diff_list)) {
    stop("predictor_labels must match functional_diff_list length", call. = FALSE)
  }

  fc_thresholds <- rep(fc_threshold, length(functional_diff_list))
  if (length(fc_threshold) > 1) {
    if (length(fc_threshold) != length(functional_diff_list)) {
      stop("fc_threshold must be length 1 or match functional_diff_list", call. = FALSE)
    }
    fc_thresholds <- fc_threshold
  }

  panel_data <- purrr::map2_dfr(
    functional_diff_list,
    seq_along(functional_diff_list),
    function(df, idx) {
      prepare_functional_trait_forest_data(
        df,
        gift_colors,
        fc_threshold = fc_thresholds[[idx]],
        fdr_threshold = fdr_threshold,
        truncate_func_label = truncate_func_label
      ) %>%
        dplyr::mutate(
          predictor_id = predictor_labels[[idx]],
          predictor_label = predictor_labels[[idx]]
        )
    }
  )

  if (nrow(panel_data) == 0L || !any(panel_data$hit)) {
    return(panel_data[0, ])
  }

  panel_data <- panel_data %>%
    dplyr::mutate(
      predictor_label = factor(.data$predictor_label, levels = predictor_labels)
    )

  if (identical(trait_set, "per_panel")) {
    return(
      panel_data %>%
        dplyr::filter(.data$hit) %>%
        add_gift_major_function_group() %>%
        add_climate_stripe_fields() %>%
        dplyr::group_by(.data$predictor_label) %>%
        dplyr::arrange(.data$func_group, .data$coefficient) %>%
        dplyr::mutate(
          trait_label = factor(
            .data$trait_label,
            levels = unique(.data$trait_label)
          )
        ) %>%
        dplyr::ungroup()
    )
  }

  sig_traits <- panel_data %>%
    dplyr::filter(.data$hit) %>%
    dplyr::pull(.data$GIFT) %>%
    unique()

  trait_order <- panel_data %>%
    dplyr::filter(.data$hit) %>%
    dplyr::group_by(.data$GIFT) %>%
    dplyr::summarise(
      max_abs = max(abs(.data$coefficient), na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::arrange(.data$max_abs) %>%
    dplyr::pull(.data$GIFT)

  trait_labels <- panel_data %>%
    dplyr::filter(.data$GIFT %in% trait_order) %>%
    dplyr::distinct(.data$GIFT, .data$trait_label) %>%
    dplyr::arrange(match(.data$GIFT, trait_order)) %>%
    dplyr::pull(.data$trait_label)

  panel_data %>%
    dplyr::filter(.data$GIFT %in% trait_order) %>%
    add_climate_stripe_fields() %>%
    dplyr::mutate(
      trait_label = factor(.data$trait_label, levels = trait_labels),
      stripe_value = dplyr::if_else(.data$hit, .data$coefficient, NA_real_),
      stripe_fill = dplyr::if_else(.data$hit, .data$stripe_fill, NA_real_)
    )
}

create_functional_climate_stripe_panel <- function(panel_data,
                                                   panel_label,
                                                   fill_limits = NULL,
                                                   negative_label = "Negative association",
                                                   positive_label = "Positive association",
                                                   x_lab = "Mean abundance difference",
                                                   fill_lab = expression(-log[10](FDR)),
                                                   show_non_sig = TRUE,
                                                   group_by_function = FALSE,
                                                   base_size = 9,
                                                   theme_fn = theme_publication) {
  plot_data <- panel_data %>%
    dplyr::filter(.data$predictor_label == panel_label)

  if (nrow(plot_data) == 0) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate("text", x = 0, y = 0, label = "No significant traits", colour = "grey40") +
        ggplot2::theme_void()
    )
  }

  hit_data <- plot_data %>%
    dplyr::filter(.data$hit)

  if (is.null(fill_limits)) {
    lim <- max(abs(hit_data$stripe_fill), na.rm = TRUE)
    lim <- max(lim, -log10(0.05))
    fill_limits <- c(-lim, lim)
  }

  p <- plot_data %>%
    ggplot2::ggplot(ggplot2::aes(y = .data$trait_label)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey70", linewidth = 0.45)

  if (isTRUE(show_non_sig) && any(!plot_data$hit)) {
    p <- p +
      ggplot2::geom_col(
        data = dplyr::filter(plot_data, !.data$hit),
        ggplot2::aes(x = 0, y = .data$trait_label),
        fill = "grey92",
        width = 0.12
      )
  }

  p <- p +
    ggplot2::geom_col(
      data = hit_data,
      ggplot2::aes(
        x = .data$stripe_value,
        fill = .data$stripe_fill
      ),
      width = 0.78
    ) +
    ggplot2::scale_fill_gradientn(
      colours = functional_climate_palette(),
      limits = fill_limits,
      na.value = "grey92",
      name = fill_lab
    ) +
    ggplot2::scale_x_continuous(
      breaks = scales::pretty_breaks(n = 4),
      expand = ggplot2::expansion(mult = c(0.06, 0.06))
    ) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(
      title = panel_label,
      x = x_lab,
      y = NULL
    )

  use_func_groups <- isTRUE(group_by_function) &&
    "func_group" %in% names(plot_data) &&
    any(!is.na(plot_data$func_group))

  if (use_func_groups) {
    plot_data <- plot_data %>%
      dplyr::filter(!is.na(.data$func_group)) %>%
      dplyr::mutate(
        func_group = droplevels(.data$func_group)
      )
    p <- p +
      ggplot2::facet_grid(
        func_group ~ .,
        scales = "free_y",
        space = "free_y",
        switch = "y"
      )
  }

  p <- p +
    theme_fn(base_size = base_size) +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(colour = "grey93", linewidth = 0.25),
      plot.title = ggplot2::element_text(face = "bold", hjust = 0.5, size = base_size * 1.05),
      axis.text.y = ggplot2::element_text(size = base_size * 0.85),
      axis.text.x = ggplot2::element_text(size = base_size * 0.9),
      axis.title.x = ggplot2::element_text(size = base_size * 0.95, margin = ggplot2::margin(t = 6)),
      plot.margin = ggplot2::margin(8, 10, 8, 6),
      legend.position = "none"
    )

  if (use_func_groups) {
    p <- p +
      ggplot2::theme(
        strip.placement = "outside",
        strip.background = ggplot2::element_blank(),
        strip.text.y.left = ggplot2::element_text(
          angle = 0,
          hjust = 1,
          size = base_size * 0.72,
          face = "italic",
          colour = "grey35"
        ),
        panel.spacing.y = grid::unit(0.4, "lines")
      )
  }

  p
}

create_functional_climate_comparison_plot <- function(functional_diff_list,
                                                    predictor_labels,
                                                    gift_colors,
                                                    fc_threshold = 0.2,
                                                    fdr_threshold = 0.05,
                                                    shared_limits = TRUE,
                                                    trait_set = c("per_panel", "union"),
                                                    x_labs = NULL,
                                                    theme_fn = theme_publication) {
  trait_set <- match.arg(trait_set)
  if (is.null(predictor_labels)) {
    predictor_labels <- names(functional_diff_list)
  }

  fc_thresholds <- rep(fc_threshold, length(functional_diff_list))
  if (length(fc_threshold) > 1) {
    if (length(fc_threshold) != length(functional_diff_list)) {
      stop("fc_threshold must be length 1 or match functional_diff_list", call. = FALSE)
    }
    fc_thresholds <- fc_threshold
  }

  if (is.null(x_labs)) {
    x_labs <- rep("Mean abundance difference", length(predictor_labels))
    if (length(predictor_labels) >= 3L) {
      x_labs[[3]] <- "Mean interaction beta"
    }
  }

  plot_data <- prepare_functional_predictor_comparison(
    functional_diff_list = functional_diff_list,
    predictor_labels = predictor_labels,
    gift_colors = gift_colors,
    fc_threshold = fc_threshold,
    fdr_threshold = fdr_threshold,
    trait_set = trait_set
  )

  if (nrow(plot_data) == 0) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate(
          "text",
          x = 0,
          y = 0,
          label = "No GIFT elements pass significance thresholds",
          size = 3.5,
          colour = "grey40"
        ) +
        ggplot2::theme_void()
    )
  }

  fill_limits <- if (shared_limits) {
    lim <- max(abs(plot_data$stripe_fill), na.rm = TRUE)
    lim <- max(lim, -log10(fdr_threshold))
    c(-lim, lim)
  } else {
    NULL
  }

  show_non_sig <- identical(trait_set, "union")

  panels <- purrr::imap(
    predictor_labels,
    function(label, idx) {
      panel_limits <- if (shared_limits) {
        fill_limits
      } else {
        NULL
      }
      p <- create_functional_climate_stripe_panel(
        panel_data = plot_data,
        panel_label = label,
        fill_limits = panel_limits,
        x_lab = x_labs[[as.integer(idx)]],
        fill_lab = expression(-log[10](FDR)),
        show_non_sig = show_non_sig,
        theme_fn = theme_fn
      )
      if (as.integer(idx) == length(predictor_labels)) {
        p <- p + ggplot2::theme(legend.position = "bottom")
      }
      p
    }
  )

  patchwork::wrap_plots(panels, ncol = length(panels)) +
    patchwork::plot_layout(guides = "collect")
}

create_functional_climate_stripe_figure <- function(predictor_label,
                                                    functional_diff_list,
                                                    gift_colors,
                                                    predictor_labels = NULL,
                                                    fc_threshold = 0.2,
                                                    fdr_threshold = 0.05,
                                                    trait_set = c("per_panel", "union"),
                                                    truncate_func_label = NULL,
                                                    group_by_function = TRUE,
                                                    x_lab = NULL,
                                                    negative_label = "Negative association",
                                                    positive_label = "Positive association",
                                                    base_size = 11,
                                                    theme_fn = theme_publication) {
  trait_set <- match.arg(trait_set)
  if (is.null(predictor_labels)) {
    predictor_labels <- names(functional_diff_list)
  }

  if (is.null(x_lab)) {
    x_lab <- if (grepl("interaction", predictor_label, ignore.case = TRUE)) {
      "Mean interaction beta"
    } else {
      "Mean abundance difference"
    }
  }

  fill_lab <- expression(-log[10](FDR))

  plot_data <- prepare_functional_predictor_comparison(
    functional_diff_list = functional_diff_list,
    predictor_labels = predictor_labels,
    gift_colors = gift_colors,
    fc_threshold = fc_threshold,
    fdr_threshold = fdr_threshold,
    trait_set = trait_set,
    truncate_func_label = truncate_func_label
  )

  p <- create_functional_climate_stripe_panel(
    panel_data = plot_data,
    panel_label = predictor_label,
    fill_limits = NULL,
    x_lab = x_lab,
    fill_lab = fill_lab,
    show_non_sig = identical(trait_set, "union"),
    group_by_function = group_by_function && identical(trait_set, "per_panel"),
    negative_label = negative_label,
    positive_label = positive_label,
    base_size = base_size,
    theme_fn = theme_fn
  )

  if (nrow(plot_data) > 0L && any(plot_data$hit)) {
    p <- p +
      ggplot2::theme(
        legend.position = "bottom",
        axis.text.y = ggplot2::element_text(
          size = base_size * 0.85,
          hjust = 1,
          colour = "grey15"
        ),
        plot.margin = ggplot2::margin(14, 12, 10, 2)
      )
  }

  p
}

functional_climate_stripe_union_trait_count <- function(functional_diff_list,
                                                        fc_threshold = 0.2,
                                                        fdr_threshold = 0.05) {
  fc_thresholds <- rep(fc_threshold, length(functional_diff_list))
  if (length(fc_threshold) > 1) {
    if (length(fc_threshold) != length(functional_diff_list)) {
      stop("fc_threshold must be length 1 or match functional_diff_list", call. = FALSE)
    }
    fc_thresholds <- fc_threshold
  }

  purrr::map2(functional_diff_list, fc_thresholds, function(df, fc) {
    df %>%
      dplyr::filter(
        !is.na(.data$p_adj),
        .data$p_adj < fdr_threshold,
        abs(.data$diff) >= fc
      ) %>%
      dplyr::pull(.data$GIFT)
  }) %>%
    unlist() %>%
    unique() %>%
    length()
}

functional_climate_stripe_dims_mm <- function(functional_differences = NULL,
                                              functional_diff_list = NULL,
                                              trait_labels = NULL,
                                              fc_threshold = 0.2,
                                              fdr_threshold = 0.05,
                                              width_mm = NULL,
                                              mm_per_trait = 6.5,
                                              min_mm = 95,
                                              label_char_mm = 1.55) {
  n_traits <- if (!is.null(functional_diff_list)) {
    functional_climate_stripe_union_trait_count(
      functional_diff_list,
      fc_threshold = fc_threshold,
      fdr_threshold = fdr_threshold
    )
  } else if (!is.null(trait_labels)) {
    length(trait_labels)
  } else if (!is.null(functional_differences)) {
    functional_differences %>%
      dplyr::filter(
        !is.na(.data$p_adj),
        .data$p_adj < fdr_threshold,
        abs(.data$diff) >= fc_threshold
      ) %>%
      nrow()
  } else {
    0L
  }

  if (is.null(width_mm)) {
    if (!is.null(trait_labels)) {
      width_mm <- max(185, 95 + max(nchar(trait_labels), na.rm = TRUE) * label_char_mm)
    } else {
      width_mm <- 185
    }
  }

  n_groups <- 0L
  if (!is.null(functional_differences) && n_traits > 0L) {
    fc_val <- if (length(fc_threshold) > 1) fc_threshold[[1]] else fc_threshold
    n_groups <- functional_differences %>%
      dplyr::filter(
        !is.na(.data$p_adj),
        .data$p_adj < fdr_threshold,
        abs(.data$diff) >= fc_val
      ) %>%
      dplyr::mutate(func_major = substr(.data$GIFT, 1, 1)) %>%
      dplyr::pull(.data$func_major) %>%
      unique() %>%
      length()
  }

  list(
    width_mm = width_mm,
    height_mm = max(min_mm, 48 + n_traits * mm_per_trait + max(n_groups - 1L, 0L) * 8)
  )
}

functional_comparison_height_mm <- function(functional_diff_list,
                                          fc_threshold = 0.2,
                                          fdr_threshold = 0.05,
                                          trait_set = c("per_panel", "union"),
                                          min_mm = 95,
                                          mm_per_trait = 6) {
  trait_set <- match.arg(trait_set)
  fc_thresholds <- rep(fc_threshold, length(functional_diff_list))
  if (length(fc_threshold) > 1) {
    if (length(fc_threshold) != length(functional_diff_list)) {
      stop("fc_threshold must be length 1 or match functional_diff_list", call. = FALSE)
    }
    fc_thresholds <- fc_threshold
  }

  sig_counts <- purrr::map2(functional_diff_list, fc_thresholds, function(df, fc) {
    df %>%
      dplyr::filter(
        !is.na(.data$p_adj),
        .data$p_adj < fdr_threshold,
        abs(.data$diff) >= fc
      ) %>%
      nrow()
  })

  n_traits <- if (identical(trait_set, "per_panel")) {
    max(unlist(sig_counts, use.names = FALSE), 0L)
  } else {
    purrr::map2(functional_diff_list, fc_thresholds, function(df, fc) {
      df %>%
        dplyr::filter(
          !is.na(.data$p_adj),
          .data$p_adj < fdr_threshold,
          abs(.data$diff) >= fc
        ) %>%
        dplyr::pull(.data$GIFT)
    }) %>%
      unlist() %>%
      unique() %>%
      length()
  }

  max(min_mm, 48 + n_traits * mm_per_trait)
}

create_functional_significance_plot <- function(functional_differences,
                                                gift_colors,
                                                variable_label = NULL,
                                                fc_threshold = 0.2,
                                                fdr_threshold = 0.05,
                                                show_background = FALSE,
                                                max_background = 20,
                                                spotlight_cols = spotlight_palettes(),
                                                theme_fn = theme_publication) {
  plot_data <- prepare_functional_significance_data(
    functional_differences,
    gift_colors,
    fc_threshold = fc_threshold,
    fdr_threshold = fdr_threshold
  )

  hits <- plot_data %>%
    dplyr::filter(.data$hit) %>%
    dplyr::arrange(.data$diff)

  n_hits <- nrow(hits)
  if (n_hits == 0) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate(
          "text",
          x = 0,
          y = 0,
          label = "No GIFT elements pass significance thresholds",
          size = 3.5,
          colour = "grey40"
        ) +
        ggplot2::theme_void()
    )
  }

  n_pos_enriched <- sum(hits$direction == "Positive association")
  n_neg_enriched <- sum(hits$direction == "Negative association")
  comparison_n <- hits %>%
    dplyr::slice(1) %>%
    dplyr::select("n_pos", "n_neg")

  bg_data <- if (show_background) {
    plot_data %>%
      dplyr::filter(!.data$hit) %>%
      dplyr::slice_max(order_by = abs(.data$diff), n = max_background, with_ties = FALSE)
  } else {
    plot_data[0, ]
  }

  label_levels <- hits$gift_label
  if (nrow(bg_data) > 0) {
    label_levels <- c(label_levels, bg_data$gift_label)
  }

  all_data <- dplyr::bind_rows(
    hits %>% dplyr::mutate(layer = "hit"),
    bg_data %>% dplyr::mutate(layer = "background", direction = "Not significant")
  ) %>%
    dplyr::mutate(
      gift_label = factor(.data$gift_label, levels = label_levels),
      direction = factor(
        .data$direction,
        levels = c("Positive association", "Negative association", "Not significant")
      ),
      func = factor(.data$func)
    )

  direction_border_colors <- c(
    "Positive association" = spotlight_cols$congruent,
    "Negative association" = spotlight_cols$discordant,
    "Not significant" = "grey75"
  )

  func_levels <- sort(unique(all_data$func))
  func_palette <- gift_colors %>%
    dplyr::filter(.data$Code_function %in% func_levels) %>%
    dplyr::transmute(func = .data$Code_function, color = .data$Color)
  func_color_map <- stats::setNames(func_palette$color, func_palette$func)
  missing_funcs <- setdiff(func_levels, names(func_color_map))
  if (length(missing_funcs) > 0) {
    func_color_map <- c(func_color_map, stats::setNames(rep("grey70", length(missing_funcs)), missing_funcs))
  }

  x_range <- range(c(all_data$diff, -fc_threshold, fc_threshold), na.rm = TRUE)
  x_pad <- max(0.06, diff(x_range) * 0.18)
  x_left <- x_range[1] - x_pad
  x_right <- x_range[2] + x_pad
  x_mid_pos <- (fc_threshold + x_right) / 2
  x_mid_neg <- (x_left - fc_threshold) / 2

  title_text <- if (is.null(variable_label)) {
    "Significant GIFT functional shifts"
  } else {
    paste0(variable_label, ": significant GIFT functional shifts")
  }

  direction_summary <- if (n_pos_enriched > 0 && n_neg_enriched > 0) {
    paste0(
      n_hits, " significant elements (",
      n_pos_enriched, " higher with positive HMSC association, ",
      n_neg_enriched, " higher with negative HMSC association)"
    )
  } else if (n_pos_enriched > 0) {
    paste0(
      n_hits, " significant elements higher in genomes with positive HMSC association"
    )
  } else {
    paste0(
      n_hits, " significant elements higher in genomes with negative HMSC association"
    )
  }

  p <- all_data %>%
    ggplot2::ggplot(
      ggplot2::aes(
        x = .data$diff,
        y = .data$gift_label,
        fill = .data$func,
        colour = .data$direction
      )
    ) +
    ggplot2::geom_vline(
      xintercept = c(-fc_threshold, fc_threshold),
      linetype = "dashed",
      colour = "grey45",
      linewidth = 0.4
    ) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey60", linewidth = 0.35)

  if (nrow(bg_data) > 0) {
    p <- p +
      ggplot2::geom_col(
        data = dplyr::filter(all_data, .data$layer == "background"),
        fill = "grey85",
        colour = "grey75",
        alpha = 0.35,
        width = 0.68,
        linewidth = 0.2
      )
  }

  p <- p +
    ggplot2::geom_col(
      data = dplyr::filter(all_data, .data$layer == "hit"),
      alpha = 0.92,
      width = 0.68,
      linewidth = 0.55
    ) +
    ggplot2::coord_cartesian(xlim = c(x_left, x_right), clip = "off") +
    ggplot2::scale_fill_manual(values = func_color_map, name = "GIFT function") +
    ggplot2::scale_colour_manual(
      values = direction_border_colors,
      guide = "none"
    ) +
    ggplot2::guides(fill = ggplot2::guide_legend(order = 1, ncol = min(3, length(func_levels)))) +
    ggplot2::labs(
      title = title_text,
      subtitle = paste0(
        direction_summary,
        "\nThresholds: |mean diff| >= ", fc_threshold, ", FDR < ", fdr_threshold,
        "  |  Genome groups: ", comparison_n$n_pos, " positive vs ", comparison_n$n_neg, " negative"
      ),
      x = "Mean abundance difference",
      y = NULL,
      caption = "Bar colour = GIFT function."
    ) +
    theme_fn() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_line(colour = "grey93", linewidth = 0.25),
      axis.text.y = ggplot2::element_text(size = 8),
      plot.subtitle = ggplot2::element_text(size = 8, colour = "grey30", lineheight = 0.95),
      plot.caption = ggplot2::element_text(size = 7, colour = "grey35", hjust = 0),
      plot.margin = ggplot2::margin(18, 8, 8, 8),
      legend.position = "bottom",
      legend.box = "vertical"
    )

  p
}

functional_significance_figure_height_mm <- function(functional_differences,
                                                     fc_threshold = 0.2,
                                                     fdr_threshold = 0.05,
                                                     min_mm = 75,
                                                     mm_per_hit = 7) {
  n_hits <- functional_differences %>%
    dplyr::mutate(
      hit = !is.na(.data$p_adj) &
        .data$p_adj < fdr_threshold &
        abs(.data$diff) >= fc_threshold
    ) %>%
    dplyr::filter(.data$hit) %>%
    nrow()

  max(min_mm, 36 + n_hits * mm_per_hit)
}

spotlight_figure_height_mm <- function(functional_differences,
                                       fc_threshold = 0.2,
                                       fdr_threshold = 0.05,
                                       include_genome_panel = FALSE,
                                       genome_panel_mm = 72) {
  func_h <- functional_significance_figure_height_mm(
    functional_differences,
    fc_threshold = fc_threshold,
    fdr_threshold = fdr_threshold
  )
  if (include_genome_panel) {
    genome_panel_mm + func_h
  } else {
    func_h
  }
}

spotlight_panel_set_dims_mm <- function(functional_diff_list,
                                        width_mm = publication_figure_defaults()$width_mm,
                                        fc_threshold = 0.2,
                                        fdr_threshold = 0.05,
                                        include_genome_panel = FALSE,
                                        genome_panel_mm = 72) {
  if (!is.list(functional_diff_list) || is.data.frame(functional_diff_list)) {
    stop("functional_diff_list must be a named list of functional difference data frames", call. = FALSE)
  }

  fc_thresholds <- rep(fc_threshold, length(functional_diff_list))
  if (length(fc_threshold) > 1) {
    if (length(fc_threshold) != length(functional_diff_list)) {
      stop("fc_threshold must be length 1 or match functional_diff_list", call. = FALSE)
    }
    fc_thresholds <- fc_threshold
  }

  height_mm <- max(purrr::map2_dbl(
    functional_diff_list,
    fc_thresholds,
    function(df, fc) {
      spotlight_figure_height_mm(
        df,
        fc_threshold = fc,
        fdr_threshold = fdr_threshold,
        include_genome_panel = include_genome_panel,
        genome_panel_mm = genome_panel_mm
      )
    }
  ))

  list(width_mm = width_mm, height_mm = height_mm)
}

create_spotlight_threshold_figure <- function(beta_support_data,
                                              functional_differences,
                                              x_lab,
                                              variable_label,
                                              phylum_colors,
                                              gift_colors,
                                              support_threshold = 0.9,
                                              include_genome_panel = FALSE,
                                              spotlight_cols = spotlight_palettes(),
                                              theme_fn = theme_publication) {
  panel_b <- create_functional_trait_forest_plot(
    functional_differences,
    gift_colors = gift_colors,
    variable_label = variable_label,
    spotlight_cols = spotlight_cols,
    theme_fn = theme_fn
  )

  if (!include_genome_panel) {
    return(panel_b)
  }

  panel_a <- create_beta_support_scatter(
    beta_support_data,
    x_lab = x_lab,
    phylum_colors = phylum_colors,
    support_threshold = support_threshold,
    highlight_thresholds = TRUE,
    spotlight_cols = spotlight_cols,
    theme_fn = theme_fn
  ) +
    ggplot2::labs(title = "Genome-level HMSC support") +
    ggplot2::theme(legend.position = "none")

  panel_a / panel_b +
    patchwork::plot_layout(heights = c(0.72, 1), guides = "keep") +
    patchwork::plot_annotation(tag_levels = "A")
}

aggregate_by_taxonomy <- function(ci_data, tax_level = "phylum") {
  tax_sym <- rlang::sym(tax_level)

  ci_data %>%
    group_by(!!tax_sym) %>%
    summarise(
      mean_beta = mean(mean, na.rm = TRUE),
      q10 = stats::quantile(mean, 0.1, na.rm = TRUE),
      q90 = stats::quantile(mean, 0.9, na.rm = TRUE),
      .groups = "drop"
    )
}

aggregate_by_function <- function(ci_data, elements_response, gift_colors, n_top = 15,
                                  min_genomes = 3) {
  genome_effects <- ci_data %>%
    dplyr::select(genome, mean, q10, q90)

  genome_func <- elements_response %>%
    dplyr::filter(value > 0) %>%
    dplyr::mutate(func = substr(GIFT, 1, 3)) %>%
    dplyr::distinct(genome, func)

  func_summary <- genome_func %>%
    dplyr::left_join(genome_effects, by = "genome") %>%
    dplyr::group_by(func) %>%
    dplyr::summarise(
      n_genomes = sum(!is.na(mean)),
      mean_beta = mean(mean, na.rm = TRUE),
      q10_fun = stats::quantile(mean, 0.10, na.rm = TRUE),
      q90_fun = stats::quantile(mean, 0.90, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::filter(n_genomes >= min_genomes)

  func_top <- dplyr::bind_rows(
    func_summary %>%
      dplyr::slice_max(order_by = mean_beta, n = n_top, with_ties = FALSE),
    func_summary %>%
      dplyr::slice_min(order_by = mean_beta, n = n_top, with_ties = FALSE)
  ) %>%
    dplyr::distinct(func, .keep_all = TRUE)

  func_top %>%
    dplyr::left_join(
      gift_colors %>%
        dplyr::transmute(
          func = Code_function,
          func_label = legend,
          color = Color
        ),
      by = "func"
    ) %>%
    dplyr::mutate(
      func_label = ifelse(is.na(func_label), func, func_label)
    )
}

create_forest_plot <- function(data, x_var = "mean", y_var = NULL, xmin_var = "q10",
                               xmax_var = "q90", color_var = NULL, color_values = NULL,
                               x_lab = "β coefficient", y_lab = NULL, show_legend = TRUE,
                               base_size = 10, errorbar_width = 0, facet_var = NULL,
                               theme_fn = theme_publication) {
  if (is.null(y_var)) {
    y_var <- if ("genome" %in% names(data)) {
      "genome"
    } else if ("phylum" %in% names(data)) {
      "phylum"
    } else if ("func_label" %in% names(data)) {
      "func_label"
    } else {
      names(data)[1]
    }
  }

  y_sym <- rlang::sym(y_var)
  x_sym <- rlang::sym(x_var)
  data <- data %>%
    mutate(!!y_sym := forcats::fct_reorder(!!y_sym, !!x_sym))

  p <- ggplot(data, aes_string(x = x_var, y = y_var, xmin = xmin_var, xmax = xmax_var))

  if (!is.null(color_var) && color_var %in% names(data)) {
    p <- p + aes_string(colour = color_var)
  }

  p <- p +
    geom_point(size = 2) +
    geom_errorbar(width = errorbar_width) +
    geom_vline(xintercept = 0) +
    theme_fn(base_size = base_size) +
    labs(x = x_lab, y = ifelse(is.null(y_lab), y_var, y_lab))

  if (!is.null(color_var) && !is.null(color_values)) {
    p <- p + scale_color_manual(values = color_values)
  }

  if (!is.null(facet_var) && facet_var %in% names(data)) {
    p <- p + facet_grid(paste0(facet_var, " ~ ."), scales = "free_y", space = "free_y")
  }

  if (!show_legend) {
    p <- p + theme(legend.position = "none")
  } else {
    p <- p + theme(legend.position = "right")
  }

  p
}

publication_legend_size_delta <- function() {
  2L
}

publication_legend_text_size <- function(base_size = 10) {
  base_size + publication_legend_size_delta()
}

publication_legend_title_size <- function(base_size = 10) {
  base_size + publication_legend_size_delta() + 0.5
}

publication_legend_geom_text_mm <- function(size_mm) {
  size_mm + publication_legend_size_delta() / ggplot2::.pt
}

publication_legend_theme <- function(base_size = 10, text_face = "bold") {
  key_scale <- publication_legend_text_size(base_size) / 10
  ggplot2::theme(
    legend.position = "bottom",
    legend.title = ggplot2::element_text(
      size = publication_legend_title_size(base_size),
      face = "bold"
    ),
    legend.text = ggplot2::element_text(
      size = publication_legend_text_size(base_size),
      face = text_face
    ),
    legend.key.size = ggplot2::unit(0.35 * key_scale, "cm"),
    legend.key.height = ggplot2::unit(0.35 * key_scale, "cm"),
    legend.key.width = ggplot2::unit(0.35 * key_scale, "cm")
  )
}

theme_publication <- function(base_size = 11, base_family = "") {
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "grey92", linewidth = 0.3),
      strip.text = element_text(face = "bold", inherit.blank = TRUE),
      plot.title = element_text(face = "bold", size = base_size + 1, inherit.blank = TRUE),
      plot.title.position = "plot",
      plot.subtitle = element_text(colour = "grey30", inherit.blank = TRUE),
      plot.caption.position = "plot",
      axis.title = element_text(face = "bold", inherit.blank = TRUE)
    ) +
    publication_legend_theme(base_size = base_size)
}

spotlight_palettes <- function() {
  list(
    devil = "#B2182B",
    temperature = "#2166AC",
    interaction = "#762A83",
    diversity = "#35978F",
    congruent = "#1B7837",
    discordant = "#D73027",
    neutral = "grey75"
  )
}

publication_figure_defaults <- function() {
  list(
    width_mm = 180,
    height_mm = 120,
    dpi = 600,
    dir = "figures"
  )
}

landcover_group_colors <- function() {
  c(
    "Cultivated Vegetation - Woody" = "#6a51a3",
    "Cultivated Vegetation - Herbaceous" = "#9e9ac8",
    "Natural Vegetation - Woody" = "#006400",
    "Natural Vegetation - Herbaceous" = "#1b9e77",
    "Natural Vegetation - General" = "#b2df8a",
    "Aquatic Vegetation" = "#41b6c4",
    "Bare Surface" = "#e6ab02",
    "Urban/Artificial" = "#757575",
    "Other" = "#cccccc"
  )
}

assign_landcover_group <- function(land_cover_label) {
  dplyr::case_when(
    stringr::str_detect(land_cover_label, "^Water") ~ "Water",
    stringr::str_detect(land_cover_label, "^Cultivated Terrestrial Vegetated: Woody") ~
      "Cultivated Vegetation - Woody",
    stringr::str_detect(land_cover_label, "^Cultivated Terrestrial Vegetated: Herbaceous") ~
      "Cultivated Vegetation - Herbaceous",
    stringr::str_detect(land_cover_label, "^Natural Terrestrial Vegetated: Woody") ~
      "Natural Vegetation - Woody",
    stringr::str_detect(land_cover_label, "^Natural Terrestrial Vegetated: Herbaceous") ~
      "Natural Vegetation - Herbaceous",
    stringr::str_detect(land_cover_label, "^Natural Terrestrial Vegetated:") ~
      "Natural Vegetation - General",
    stringr::str_detect(land_cover_label, "Aquatic Vegetated") ~ "Aquatic Vegetation",
    stringr::str_detect(land_cover_label, "Scattered|Sparse|Natural Surface:") ~ "Bare Surface",
    stringr::str_detect(land_cover_label, "^Artificial Surface:") ~ "Urban/Artificial",
    TRUE ~ "Other"
  )
}

prepare_landcover_plot_df <- function(landcover_wide, sample_ids = NULL) {
  summary_cols <- c(
    "Cultivated_Total", "Native_Terrestrial_Total", "Native_Aquatic_Total",
    "Bare_Urban", "EnvGradient_PC1"
  )
  id_col <- if ("sample" %in% names(landcover_wide)) "sample" else "id"
  group_colors <- landcover_group_colors()

  long_df <- landcover_wide %>%
    dplyr::select(-dplyr::any_of(summary_cols)) %>%
    tidyr::pivot_longer(
      cols = -dplyr::all_of(id_col),
      names_to = "land_cover_label",
      values_to = "percent"
    ) %>%
    dplyr::mutate(
      group = assign_landcover_group(land_cover_label),
      group = factor(group, levels = names(group_colors))
    ) %>%
    dplyr::filter(!is.na(land_cover_label), group != "Water")

  if (!is.null(sample_ids)) {
    long_df <- long_df %>% dplyr::filter(.data[[id_col]] %in% sample_ids)
  }

  long_df %>%
    dplyr::group_by(.data[[id_col]], group) %>%
    dplyr::summarise(pct = sum(percent, na.rm = TRUE), .groups = "drop") %>%
    dplyr::group_by(.data[[id_col]]) %>%
    dplyr::mutate(pct = pct / sum(pct) * 100) %>%
    dplyr::mutate(pct = dplyr::coalesce(pct, 0)) %>%
    dplyr::ungroup() %>%
    dplyr::rename(sample = dplyr::all_of(id_col))
}

create_landcover_stacked_bar <- function(plot_df, group_colors = landcover_group_colors(),
                                         sample_order = NULL, theme_fn = theme_publication) {
  if (!is.null(sample_order)) {
    plot_df <- plot_df %>%
      dplyr::mutate(sample = factor(sample, levels = sample_order))
  } else {
    plot_df <- plot_df %>%
      dplyr::mutate(sample = factor(sample))
  }

  ggplot2::ggplot(plot_df, ggplot2::aes(x = sample, y = pct, fill = group)) +
    ggplot2::geom_col(width = 0.85) +
    ggplot2::scale_fill_manual(values = group_colors) +
    ggplot2::labs(
      x = "Sample",
      y = "Percent cover",
      fill = "Landcover group"
    ) +
    theme_fn() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5, size = 7),
      panel.grid.major.x = ggplot2::element_blank(),
      legend.position = "bottom"
    )
}

calculate_alpha_diversity <- function(genome_counts, genome_tree, genome_gifts, GIFT_db) {
  otus <- genome_counts$genome
  tips <- genome_tree$tip.label
  common <- intersect(tips, otus)
  tree_pruned <- ape::drop.tip(genome_tree, setdiff(tips, common))

  counts_mat <- genome_counts %>%
    tibble::column_to_rownames(var = "genome") %>%
    dplyr::select(where(~ !all(. == 0)))

  richness <- counts_mat %>%
    hilldiv(., q = 0) %>%
    t() %>%
    as.data.frame() %>%
    dplyr::rename(richness = 1) %>%
    tibble::rownames_to_column(var = "sample")

  neutral <- counts_mat %>%
    hilldiv(., q = 1) %>%
    t() %>%
    as.data.frame() %>%
    dplyr::rename(neutral = 1) %>%
    tibble::rownames_to_column(var = "sample")

  phylogenetic <- counts_mat %>%
    hilldiv(., q = 1, tree = tree_pruned) %>%
    t() %>%
    as.data.frame() %>%
    dplyr::rename(phylogenetic = 1) %>%
    tibble::rownames_to_column(var = "sample")

  dist <- genome_gifts %>%
    to.elements(., GIFT_db) %>%
    traits2dist(., method = "gower")

  functional <- genome_counts %>%
    dplyr::filter(genome %in% rownames(dist)) %>%
    dplyr::arrange(match(genome, rownames(dist))) %>%
    tibble::column_to_rownames(var = "genome") %>%
    dplyr::select(where(~ !all(. == 0))) %>%
    hilldiv(., q = 1, dist = dist) %>%
    t() %>%
    as.data.frame() %>%
    dplyr::rename(functional = 1) %>%
    tibble::rownames_to_column(var = "sample") %>%
    dplyr::filter(!is.nan(functional), !is.na(functional))

  richness %>%
    dplyr::full_join(neutral, by = dplyr::join_by(sample)) %>%
    dplyr::full_join(phylogenetic, by = dplyr::join_by(sample)) %>%
    dplyr::full_join(functional, by = dplyr::join_by(sample))
}

create_alpha_environment_plot <- function(alpha_div, sample_metadata, target_metric,
                                        ylab = NULL, env_settings = environment_plot_settings(),
                                        show_legend = TRUE, theme_fn = theme_publication) {
  ylab <- if (is.null(ylab)) {
    unname(alpha_metric_labels[target_metric])
  } else {
    ylab
  }

  plot_data <- alpha_div %>%
    tidyr::pivot_longer(-sample, names_to = "metric", values_to = "value") %>%
    dplyr::inner_join(sample_metadata, by = dplyr::join_by(sample)) %>%
    dplyr::filter(metric == target_metric)

  p <- plot_data %>%
    ggplot2::ggplot(ggplot2::aes(x = broad_environment, y = value)) +
    ggplot2::geom_boxplot(
      ggplot2::aes(fill = broad_environment),
      width = 0.65, alpha = 0.75, outlier.shape = NA,
      show.legend = show_legend, linewidth = 0.6
    ) +
    ggplot2::geom_jitter(
      ggplot2::aes(color = broad_environment),
      width = 0.3, size = 1.8, alpha = 0.65,
      show.legend = FALSE
    ) +
    ggplot2::scale_fill_manual(
      values = env_settings$colors,
      labels = env_settings$labels_long,
      breaks = env_settings$limits,
      drop = FALSE
    ) +
    ggplot2::scale_color_manual(values = env_settings$colors, guide = "none") +
    ggplot2::scale_x_discrete(
      limits = env_settings$limits,
      labels = env_settings$labels_short,
      drop = FALSE
    ) +
    ggpubr::stat_compare_means(
      method = "kruskal.test",
      label = "p.format",
      geom = "label",
      fill = "white",
      label.padding = ggplot2::unit(0.2, "lines"),
      label.r = ggplot2::unit(0.15, "lines"),
      color = "black",
      label.y.npc = 0.98,
      label.x = 3,
      size = 3,
      fontface = "bold"
    ) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0.08, 0.12))) +
    ggplot2::coord_cartesian(clip = "off") +
    theme_fn() +
    ggplot2::theme(
      legend.position = if (show_legend) "top" else "none",
      legend.title = ggplot2::element_blank(),
      axis.title.x = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(4, 6, 4, 4, unit = "pt")
    ) +
    ggplot2::labs(y = ylab)

  p
}

calculate_nmds_limits <- function(beta_matrices, seed = 2025L) {
  all_scores <- purrr::map_dfr(beta_matrices, function(beta_mat) {
    set.seed(seed)
    beta_mat$S %>%
      vegan::metaMDS(trymax = 500, k = 2, trace = 0) %>%
      vegan::scores() %>%
      tibble::as_tibble(rownames = "sample")
  })

  x_range <- range(all_scores$NMDS1, na.rm = TRUE)
  y_range <- range(all_scores$NMDS2, na.rm = TRUE)
  x_padding <- diff(x_range) * 0.05
  y_padding <- diff(y_range) * 0.05

  list(
    xlim = c(x_range[1] - x_padding, x_range[2] + x_padding),
    ylim = c(y_range[1] - y_padding, y_range[2] + y_padding)
  )
}

fit_nmds_ordination <- function(beta_matrix, seed = 2025L) {
  set.seed(seed)
  nmds_obj <- beta_matrix$S %>%
    vegan::metaMDS(trymax = 500, k = 2, trace = 0)
  list(
    nmds_obj = nmds_obj,
    stress = nmds_obj$stress
  )
}

align_metadata_beta <- function(sample_metadata, dist_obj, sample_col = "sample") {
  sample_labels <- attr(dist_obj, "Labels")
  sample_metadata %>%
    dplyr::filter(.data[[sample_col]] %in% sample_labels) %>%
    dplyr::arrange(match(.data[[sample_col]], sample_labels))
}

env_hill_column_map <- function() {
  c(
    env_hill_h0 = "h0",
    env_hill_h1 = "h1",
    env_hill_h2 = "h2"
  )
}

create_nmds_plot <- function(beta_matrix,
                             sample_metadata,
                             env_settings = environment_plot_settings(),
                             show_labels = FALSE,
                             point_size = 2.5,
                             segment_alpha = 0.3,
                             show_ellipses = FALSE,
                             show_centroids = TRUE,
                             env_vars = NULL,
                             envfit_p_threshold = 0.05,
                             xlim = NULL,
                             ylim = NULL,
                             panel_tag = NULL,
                             nmds_obj = NULL,
                             theme_fn = theme_publication) {
  if (is.null(nmds_obj)) {
    nmds_obj <- fit_nmds_ordination(beta_matrix)$nmds_obj
  }

  stress_value <- nmds_obj$stress

  nmds_scores <- nmds_obj %>%
    vegan::scores() %>%
    tibble::as_tibble(rownames = "sample") %>%
    dplyr::inner_join(sample_metadata, by = dplyr::join_by(sample)) %>%
    dplyr::group_by(broad_environment) %>%
    dplyr::mutate(
      x_cen = mean(NMDS1, na.rm = TRUE),
      y_cen = mean(NMDS2, na.rm = TRUE)
    ) %>%
    dplyr::ungroup()

  p <- nmds_scores %>%
    ggplot2::ggplot(ggplot2::aes(
      x = NMDS1, y = NMDS2,
      color = broad_environment,
      shape = as.factor(island)
    )) +
    ggplot2::geom_segment(
      ggplot2::aes(x = x_cen, y = y_cen, xend = NMDS1, yend = NMDS2),
      alpha = segment_alpha,
      linewidth = 0.3,
      color = "gray60",
      show.legend = FALSE
    ) +
    ggplot2::geom_point(size = point_size, alpha = 0.8) +
    ggplot2::scale_color_manual(
      values = env_settings$colors,
      labels = env_settings$labels_long,
      breaks = env_settings$limits,
      drop = FALSE,
      name = "Environment"
    ) +
    ggplot2::scale_shape_discrete(name = "Island")

  if (show_ellipses) {
    p <- p + ggplot2::stat_ellipse(
      ggplot2::aes(color = broad_environment),
      type = "norm",
      level = 0.95,
      linetype = 2,
      alpha = 0.5,
      linewidth = 0.5,
      show.legend = FALSE
    )
  }

  if (show_centroids) {
    p <- p + ggplot2::geom_point(
      data = nmds_scores %>%
        dplyr::distinct(broad_environment, x_cen, y_cen),
      ggplot2::aes(x = x_cen, y = y_cen, color = broad_environment),
      shape = 21,
      size = 5,
      stroke = 1.5,
      fill = "white",
      show.legend = FALSE
    )
  }

  if (!is.null(env_vars)) {
    env_vars <- env_vars[env_vars %in% names(sample_metadata)]
    if (length(env_vars) > 0) {
      aligned_meta <- align_metadata_beta(sample_metadata, beta_matrix$S)
      env_mat <- aligned_meta %>%
        dplyr::select(dplyr::all_of(env_vars)) %>%
        as.data.frame()
      fit <- vegan::envfit(nmds_obj, env_mat, permutations = 999)
      vec_scores <- vegan::scores(fit, display = "vectors")
      if (!is.null(vec_scores) && nrow(vec_scores) > 0) {
        vec_cols <- colnames(vec_scores)
        hill_map <- env_hill_column_map()
        fit_df <- as.data.frame(vec_scores) %>%
          tibble::rownames_to_column("variable") %>%
          dplyr::mutate(
            p_value = fit$vectors$pvals,
            label = dplyr::case_when(
              variable == "env_hill_h0" ~ env_hill_metric_labels[["h0"]],
              variable == "env_hill_h1" ~ env_hill_metric_labels[["h1"]],
              variable == "env_hill_h2" ~ env_hill_metric_labels[["h2"]],
              TRUE ~ variable
            )
          ) %>%
          dplyr::filter(p_value < envfit_p_threshold)

        if (nrow(fit_df) > 0) {
          xend <- vec_cols[[1]]
          yend <- vec_cols[[2]]
          p <- p +
            ggplot2::geom_segment(
              data = fit_df,
              ggplot2::aes(
                x = 0, y = 0,
                xend = .data[[xend]],
                yend = .data[[yend]]
              ),
              inherit.aes = FALSE,
              arrow = ggplot2::arrow(
                length = ggplot2::unit(0.2, "cm"),
                type = "closed"
              ),
              colour = "#2166AC",
              linewidth = 0.9
            ) +
            ggplot2::geom_text(
              data = fit_df,
              ggplot2::aes(
                x = .data[[xend]] * 1.12,
                y = .data[[yend]] * 1.12,
                label = label
              ),
              inherit.aes = FALSE,
              colour = "#2166AC",
              size = 3,
              fontface = "bold"
            )
        }
      }
    }
  }

  panel_title <- panel_tag %||% "NMDS ordination"
  p <- p +
    theme_fn() +
    ggplot2::labs(
      title = panel_title,
      subtitle = paste0("stress = ", round(stress_value, 3)),
      x = "NMDS1",
      y = "NMDS2"
    ) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = 9, face = "bold", inherit.blank = TRUE),
      plot.subtitle = ggplot2::element_text(size = 7.5, colour = "grey35", inherit.blank = TRUE),
      plot.margin = ggplot2::margin(4, 6, 4, 4, unit = "pt")
    ) +
    ggplot2::guides(
      color = ggplot2::guide_legend(order = 1, override.aes = list(size = 3)),
      shape = ggplot2::guide_legend(order = 2, override.aes = list(size = 3))
    )

  if (!is.null(xlim) && !is.null(ylim)) {
    p <- p + ggplot2::coord_fixed(ratio = 1, xlim = xlim, ylim = ylim, expand = TRUE)
  } else {
    p <- p + ggplot2::coord_fixed(ratio = 1, expand = TRUE)
  }

  p
}

four_panel_diversity_figure_dims <- function() {
  list(width_mm = 200, height_mm = 165)
}

build_publication_environment_fill_legend_grob <- function(
    env_settings = environment_plot_settings(),
    legend_position = c("left", "right")) {
  legend_position <- match.arg(legend_position)
  legend_df <- tibble::tibble(
    environment = factor(env_settings$limits, levels = env_settings$limits)
  )

  legend_plot <- ggplot2::ggplot(
    legend_df,
    ggplot2::aes(
      x = 1,
      y = .data$environment,
      fill = .data$environment
    )
  ) +
    ggplot2::geom_point(shape = 22, size = 3) +
    ggplot2::scale_fill_manual(
      name = "Environment",
      values = env_settings$colors,
      labels = env_settings$labels_long,
      drop = FALSE
    ) +
    ggplot2::theme_void() +
    circular_phylogeny_legend_theme(base_size = publication_legend_text_size(7L)) +
    ggplot2::theme(legend.position = legend_position)

  cowplot::get_legend(legend_plot)
}

build_island_shape_legend_grob <- function(legend_position = c("left", "right")) {
  legend_position <- match.arg(legend_position)
  legend_df <- tibble::tibble(
    island = factor(c("Australia", "Tasmania"), levels = c("Australia", "Tasmania"))
  )

  legend_plot <- ggplot2::ggplot(
    legend_df,
    ggplot2::aes(
      x = 1,
      y = .data$island,
      shape = .data$island
    )
  ) +
    ggplot2::geom_point(size = 3) +
    ggplot2::scale_shape_discrete(name = "Island") +
    ggplot2::theme_void() +
    circular_phylogeny_legend_theme(base_size = publication_legend_text_size(7L)) +
    ggplot2::theme(legend.position = legend_position)

  cowplot::get_legend(legend_plot)
}

build_diversity_composite_legend_grob <- function(
    env_settings = environment_plot_settings(),
    show_environment = TRUE,
    show_island = TRUE,
    legend_position = c("left", "right")) {
  legend_position <- match.arg(legend_position)
  legend_parts <- list()
  if (isTRUE(show_environment)) {
    legend_parts <- c(
      legend_parts,
      list(build_publication_environment_fill_legend_grob(
        env_settings = env_settings,
        legend_position = legend_position
      ))
    )
  }
  if (isTRUE(show_island)) {
    legend_parts <- c(
      legend_parts,
      list(build_island_shape_legend_grob(legend_position = legend_position))
    )
  }
  if (length(legend_parts) == 0L) {
    return(NULL)
  }
  if (length(legend_parts) == 1L) {
    return(legend_parts[[1]])
  }
  cowplot::plot_grid(plotlist = legend_parts, ncol = 1, align = "v")
}

build_four_panel_diversity_grid <- function(panels, tag_levels = "A") {
  if (length(panels) != 4L) {
    stop("build_four_panel_diversity_grid() expects exactly four panels.", call. = FALSE)
  }

  panel_theme <- ggplot2::theme(legend.position = "none")
  panels <- purrr::map(panels, ~ .x + panel_theme)

  (panels[[1]] | panels[[2]]) / (panels[[3]] | panels[[4]]) +
    patchwork::plot_layout(widths = c(1, 1), heights = c(1, 1)) +
    patchwork::plot_annotation(tag_levels = tag_levels) &
    ggplot2::theme(
      plot.tag = ggplot2::element_text(face = "bold", size = 12),
      plot.tag.position = "topleft"
    )
}

alpha_beta_composite_figure_dims <- function(
    fig_dims = four_panel_diversity_figure_dims(),
    legend_rel_width = 0.22,
    row_gap_mm = 6) {
  plot_width_mm <- fig_dims$width_mm
  legend_width_mm <- plot_width_mm * legend_rel_width
  list(
    width_mm = plot_width_mm + legend_width_mm,
    height_mm = fig_dims$height_mm * 2 + row_gap_mm,
    plot_width_mm = plot_width_mm,
    legend_width_mm = legend_width_mm
  )
}

compose_alpha_beta_diversity_composite <- function(
    alpha_panels,
    beta_panels,
    env_settings = environment_plot_settings(),
    fig_dims = four_panel_diversity_figure_dims(),
    legend_rel_width = 0.22) {
  if (length(alpha_panels) != 4L || length(beta_panels) != 4L) {
    stop("compose_alpha_beta_diversity_composite() expects four alpha and four beta panels.",
         call. = FALSE)
  }

  dims <- alpha_beta_composite_figure_dims(
    fig_dims = fig_dims,
    legend_rel_width = legend_rel_width
  )

  alpha_grid <- build_four_panel_diversity_grid(alpha_panels, tag_levels = "a")
  beta_grid <- build_four_panel_diversity_grid(beta_panels, tag_levels = "a")

  legend_grob <- build_diversity_composite_legend_grob(
    env_settings = env_settings,
    show_environment = TRUE,
    show_island = TRUE,
    legend_position = "right"
  )

  composite <- alpha_grid +
    beta_grid +
    patchwork::wrap_elements(full = legend_grob) +
    patchwork::plot_layout(
      design = "
        AA#
        BB#
      ",
      widths = c(dims$plot_width_mm, dims$legend_width_mm),
      heights = c(1, 1)
    ) +
    patchwork::plot_annotation(
      tag_levels = list(c("A", "B")),
      theme = ggplot2::theme(
        plot.tag = ggplot2::element_text(face = "bold", size = 16),
        plot.tag.position = "topleft"
      )
    )

  list(
    plot = composite,
    width_mm = dims$width_mm,
    height_mm = dims$height_mm
  )
}

compose_four_panel_environment_figure <- function(panels,
                                                  env_settings = environment_plot_settings(),
                                                  legend_rel_width = 0.17,
                                                  show_environment_legend = TRUE,
                                                  show_island_legend = FALSE,
                                                  legend_position = c("left", "right"),
                                                  tag_levels = "A") {
  legend_position <- match.arg(legend_position)
  if (length(panels) != 4L) {
    stop("compose_four_panel_environment_figure() expects exactly four panels.", call. = FALSE)
  }

  panel_theme <- ggplot2::theme(legend.position = "none")
  panels <- purrr::map(panels, ~ .x + panel_theme)

  panel_grid <- build_four_panel_diversity_grid(panels, tag_levels = tag_levels)

  legend_parts <- list()
  if (isTRUE(show_environment_legend)) {
    legend_parts <- c(legend_parts, list(build_publication_environment_fill_legend_grob(
      env_settings = env_settings,
      legend_position = legend_position
    )))
  }
  if (isTRUE(show_island_legend)) {
    legend_parts <- c(legend_parts, list(build_island_shape_legend_grob(
      legend_position = legend_position
    )))
  }

  if (length(legend_parts) == 0L) {
    return(panel_grid)
  }

  legend_grob <- if (length(legend_parts) == 1L) {
    legend_parts[[1]]
  } else {
    cowplot::plot_grid(plotlist = legend_parts, ncol = 1, align = "v")
  }

  legend_panel <- patchwork::wrap_elements(full = legend_grob)
  if (legend_position == "left") {
    legend_panel + panel_grid +
      patchwork::plot_layout(widths = c(legend_rel_width, 1 - legend_rel_width))
  } else {
    panel_grid + legend_panel +
      patchwork::plot_layout(widths = c(1 - legend_rel_width, legend_rel_width))
  }
}

compose_tagged_figure_stack <- function(panels,
                                        layout_heights = NULL,
                                        tag_levels = "a",
                                        tag_size = 12) {
  if (length(panels) < 2L) {
    stop("compose_tagged_figure_stack() expects at least two panels.", call. = FALSE)
  }
  if (is.null(layout_heights)) {
    layout_heights <- rep(1, length(panels))
  }
  if (length(layout_heights) != length(panels)) {
    stop("layout_heights must match the number of panels.", call. = FALSE)
  }

  wrapped_panels <- lapply(panels, patchwork::wrap_elements)
  patchwork::wrap_plots(
    plotlist = wrapped_panels,
    ncol = 1,
    heights = layout_heights
  ) +
    patchwork::plot_annotation(
      tag_levels = tag_levels,
      theme = ggplot2::theme(
        plot.tag = ggplot2::element_text(face = "bold", size = tag_size),
        plot.tag.position = "topleft"
      )
    )
}

compose_study_context_overview_figure <- function(panel_a,
                                                 panel_b,
                                                 layout_heights = c(1, 1.05),
                                                 tag_levels = "a",
                                                 tag_size = 12) {
  compose_tagged_figure_stack(
    panels = list(panel_a, panel_b),
    layout_heights = layout_heights,
    tag_levels = tag_levels,
    tag_size = tag_size
  )
}

study_context_overview_figure_dims <- function(width_mm = 200,
                                               panel_a_height_mm = 120,
                                               panel_b_height_mm = NULL,
                                               panel_b_facet_env = TRUE) {
  if (is.null(panel_b_height_mm)) {
    panel_b_height_mm <- phylum_stacked_figure_dims(facet_env = panel_b_facet_env)$height_mm
  }
  list(
    width_mm = width_mm,
    height_mm = round(panel_a_height_mm + panel_b_height_mm + 8)
  )
}

compose_study_context_sankey_figure <- function(panel_a,
                                                panel_b,
                                                sankey_plot,
                                                layout_heights = c(1, 1.05),
                                                left_width = 0.52,
                                                tag_levels = "a",
                                                tag_size = 12) {
  tag_theme <- ggplot2::theme(
    plot.tag = ggplot2::element_text(face = "bold", size = tag_size),
    plot.tag.position = "topleft"
  )

  patchwork::wrap_plots(
    A = panel_a,
    B = patchwork::wrap_elements(full = panel_b, clip = FALSE),
    C = patchwork::wrap_elements(full = sankey_plot, clip = FALSE),
    design = "
      AC
      BC
    ",
    widths = c(left_width, 1 - left_width),
    heights = layout_heights
  ) +
    patchwork::plot_annotation(
      tag_levels = tag_levels,
      theme = tag_theme
    )
}

study_context_sankey_figure_dims <- function(width_mm = 360,
                                             left_width = 0.52,
                                             panel_a_height_mm = 120,
                                             panel_b_facet_env = TRUE,
                                             sankey_height_mm = 145) {
  left_width_mm <- round(width_mm * left_width)
  left_dims <- study_context_overview_figure_dims(
    width_mm = left_width_mm,
    panel_a_height_mm = panel_a_height_mm,
    panel_b_facet_env = panel_b_facet_env
  )
  list(
    width_mm = width_mm,
    height_mm = max(left_dims$height_mm, sankey_height_mm + 8)
  )
}

compose_phylogeny_family_sankey_figure <- function(phylogeny_plot,
                                                  sankey_plot,
                                                  layout_heights = c(1.12, 0.88),
                                                  tag_levels = NULL,
                                                  tag_size = 12) {
  panels <- list(phylogeny_plot, sankey_plot)
  if (is.null(tag_levels)) {
    patchwork::wrap_plots(
      plotlist = lapply(panels, patchwork::wrap_elements),
      ncol = 1,
      heights = layout_heights
    )
  } else {
    compose_tagged_figure_stack(
      panels = panels,
      layout_heights = layout_heights,
      tag_levels = tag_levels,
      tag_size = tag_size
    )
  }
}

phylogeny_family_sankey_figure_dims <- function(n_tips,
                                              width_mm = 200,
                                              sankey_height_mm = 145) {
  g1b_dims <- circular_phylogeny_detailed_figure_dims(n_tips = n_tips, tight = TRUE)
  height_scale <- width_mm / g1b_dims$width_mm
  list(
    width_mm = width_mm,
    height_mm = round(g1b_dims$height_mm * height_scale + sankey_height_mm + 8)
  )
}

subset_dist_matrix <- function(dist_obj, sample_ids) {
  mat <- as.matrix(dist_obj)
  mat <- mat[sample_ids, sample_ids, drop = FALSE]
  stats::as.dist(mat)
}

run_permanova_terms <- function(beta_matrix,
                                sample_metadata,
                                formula = as.formula("broad_environment * island"),
                                permutations = 999) {
  dist_obj <- beta_matrix$S
  samples <- attr(dist_obj, "Labels")

  meta <- sample_metadata %>%
    dplyr::filter(sample %in% samples) %>%
    dplyr::filter(!is.na(broad_environment), !is.na(island)) %>%
    dplyr::arrange(match(sample, samples))

  common <- intersect(meta$sample, samples)
  meta <- meta %>%
    dplyr::filter(sample %in% common) %>%
    dplyr::arrange(match(sample, common))

  dist_sub <- subset_dist_matrix(dist_obj, meta$sample)

  res <- vegan::adonis2(
    dist_sub ~ formula,
    data = meta,
    permutations = permutations,
    by = "terms"
  )

  as.data.frame(res) %>%
    tibble::rownames_to_column("term") %>%
    dplyr::filter(term != "Residual") %>%
    dplyr::transmute(
      term = term,
      r2 = R2,
      p_value = `Pr(>F)`
    )
}

summarise_permanova_figures <- function(beta_matrices,
                                        sample_metadata,
                                        formula = as.formula("broad_environment * island")) {
  purrr::imap_dfr(
    beta_matrices,
    function(beta_mat, beta_id) {
      run_permanova_terms(beta_mat, sample_metadata, formula = formula) %>%
        dplyr::mutate(
          beta_metric = beta_id,
          beta_label = beta_metric_labels[[beta_id]]
        )
    }
  )
}

create_permanova_r2_plot <- function(permanova_df,
                                     term_labels = NULL,
                                     theme_fn = theme_publication) {
  if (is.null(term_labels)) {
    term_labels <- c(
      "broad_environment" = "Environment",
      "island" = "Island",
      "broad_environment:island" = "Environment × island"
    )
  }

  plot_df <- permanova_df %>%
    dplyr::mutate(
      beta_label = factor(
        beta_label,
        levels = unname(beta_metric_labels)[names(beta_metric_labels) %in% unique(beta_metric)]
      ),
      term_lab = dplyr::recode(term, !!!term_labels),
      term_lab = factor(term_lab, levels = unname(term_labels)),
      r2_pct = r2 * 100,
      sig = !is.na(p_value) & p_value < 0.05
    )

  plot_df %>%
    ggplot2::ggplot(ggplot2::aes(x = term_lab, y = r2_pct, fill = term_lab)) +
    ggplot2::geom_col(width = 0.65, alpha = 0.85) +
    ggplot2::geom_text(
      ggplot2::aes(
        label = ifelse(sig, "*", ""),
        y = r2_pct
      ),
      vjust = -0.3,
      size = 4,
      fontface = "bold"
    ) +
    ggplot2::facet_wrap(~beta_label, ncol = 2, scales = "free_y") +
    ggplot2::scale_fill_manual(values = c(
      "Environment" = "#429ef5",
      "Island" = "#42f58d",
      "Environment × island" = "#b142f5"
    ), guide = "none") +
    ggplot2::labs(
      x = NULL,
      y = expression(R^2 ~ " (%)"),
      title = "PERMANOVA effect sizes"
    ) +
    theme_fn() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 25, hjust = 1),
      strip.text = ggplot2::element_text(size = 8)
    )
}

run_mantel_env_hill <- function(beta_matrix,
                                sample_metadata,
                                hill_cols = c("env_hill_h0", "env_hill_h1", "env_hill_h2"),
                                permutations = 999) {
  dist_obj <- beta_matrix$S
  meta <- align_metadata_beta(sample_metadata, dist_obj)
  hill_cols <- hill_cols[hill_cols %in% names(meta)]

  purrr::map_dfr(hill_cols, function(col) {
    meta_col <- meta %>%
      dplyr::filter(!is.na(.data[[col]]))
    dist_sub <- subset_dist_matrix(dist_obj, meta_col$sample)
    env_dist <- stats::dist(meta_col[[col]])
    mantel_res <- vegan::mantel(dist_sub, env_dist, permutations = permutations)
    tibble::tibble(
      env_hill = col,
      r = unname(mantel_res$statistic),
      p_value = mantel_res$signif
    )
  })
}

summarise_mantel_figures <- function(beta_matrices, sample_metadata) {
  hill_map <- env_hill_column_map()

  purrr::imap_dfr(
    beta_matrices,
    function(beta_mat, beta_id) {
      run_mantel_env_hill(beta_mat, sample_metadata) %>%
        dplyr::mutate(
          beta_metric = beta_id,
          beta_label = beta_metric_labels[[beta_id]],
          env_label = env_hill_metric_labels[hill_map[env_hill]]
        )
    }
  )
}

create_mantel_summary_plot <- function(mantel_df, theme_fn = theme_publication) {
  plot_df <- mantel_df %>%
    dplyr::mutate(
      beta_label = factor(
        beta_label,
        levels = unname(beta_metric_labels)[names(beta_metric_labels) %in% unique(beta_metric)]
      ),
      env_label = factor(
        env_label,
        levels = unname(env_hill_metric_labels)
      ),
      sig = !is.na(p_value) & p_value < 0.05,
      label = ifelse(sig, sprintf("%.2f*", r), sprintf("%.2f", r))
    )

  plot_df %>%
    ggplot2::ggplot(ggplot2::aes(x = env_label, y = beta_label, fill = r)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.4) +
    ggplot2::geom_text(
      ggplot2::aes(label = label),
      colour = "white",
      size = 3,
      fontface = "bold"
    ) +
    ggplot2::scale_fill_gradient2(
      low = "#2166AC",
      mid = "grey95",
      high = "#B2182B",
      midpoint = 0,
      limits = c(-1, 1),
      name = "Mantel r"
    ) +
    ggplot2::labs(
      x = NULL,
      y = NULL,
      title = "Mantel correlation: environmental Hill vs beta diversity"
    ) +
    theme_fn() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 25, hjust = 1)
    )
}

prepare_alpha_env_hill_data <- function(alpha_div, sample_metadata) {
  alpha_div %>%
    dplyr::inner_join(sample_metadata, by = dplyr::join_by(sample)) %>%
    dplyr::select(
      sample,
      broad_environment,
      richness,
      neutral,
      phylogenetic,
      functional,
      dplyr::any_of(c("env_hill_h0", "env_hill_h1", "env_hill_h2"))
    )
}

create_alpha_env_hill_scatter <- function(plot_data,
                                          alpha_var,
                                          env_var,
                                          alpha_lab = NULL,
                                          env_lab = NULL,
                                          env_settings = environment_plot_settings(),
                                          theme_fn = theme_publication) {
  alpha_lab <- alpha_lab %||% unname(alpha_metric_labels[[alpha_var]])
  hill_map <- env_hill_column_map()
  env_lab <- env_lab %||% env_hill_metric_labels[[hill_map[[env_var]]]]

  plot_df <- plot_data %>%
    dplyr::filter(
      !is.na(.data[[alpha_var]]),
      !is.na(.data[[env_var]])
    )

  cor_text <- ""
  if (nrow(plot_df) >= 3) {
    ct <- stats::cor.test(
      plot_df[[env_var]],
      plot_df[[alpha_var]],
      method = "spearman"
    )
    cor_text <- paste0(
      "rho = ", round(unname(ct$estimate), 2),
      ", p = ", format.pval(ct$p.value, digits = 2)
    )
  }

  plot_df %>%
    ggplot2::ggplot(ggplot2::aes(
      x = .data[[env_var]],
      y = .data[[alpha_var]],
      colour = broad_environment
    )) +
    ggplot2::geom_point(alpha = 0.75, size = 2.2) +
    ggplot2::geom_smooth(
      method = "lm",
      se = TRUE,
      colour = "black",
      linewidth = 0.7,
      linetype = "dashed",
      inherit.aes = FALSE,
      mapping = ggplot2::aes(
        x = .data[[env_var]],
        y = .data[[alpha_var]]
      )
    ) +
    ggplot2::scale_colour_manual(
      values = env_settings$colors,
      labels = env_settings$labels_long,
      breaks = env_settings$limits,
      drop = FALSE,
      name = "Environment"
    ) +
    ggplot2::labs(
      x = env_lab,
      y = alpha_lab,
      subtitle = cor_text
    ) +
    theme_fn() +
    ggplot2::theme(legend.position = "none")
}

hmsc_spotlight_variables <- function() {
  c("devil", "temperature", "devil:temperature", "diversity", "logseqdepth")
}

hmsc_varpart_levels <- function() {
  rev(c(
    "devil", "temperature", "diversity",
    "logseqdepth", "devil:temperature",
    "Random: animal", "Random: site"
  ))
}

varpart_fill_colors <- function(spotlight_cols = spotlight_palettes()) {
  c(
    "devil" = spotlight_cols$devil,
    "temperature" = spotlight_cols$temperature,
    "devil:temperature" = spotlight_cols$interaction,
    "diversity" = spotlight_cols$diversity,
    "logseqdepth" = "grey60",
    "Random: animal" = "grey75",
    "Random: site" = "grey85"
  )
}

prepare_covariate_ci <- function(fit_model, model_obj, covariate_name, genome_metadata) {
  estimate <- get_beta_estimate(fit_model, model_obj, covariate_name)
  get_beta_ci(fit_model, model_obj, covariate_name) %>%
    dplyr::right_join(estimate, by = "genome") %>%
    dplyr::left_join(genome_metadata, by = "genome")
}

prepare_beta_support_data <- function(fit_model, model_obj, covariate_name, genome_metadata,
                                      support_threshold = 0.9) {
  negsupport_threshold <- 1 - support_threshold
  estimate <- get_beta_estimate(fit_model, model_obj, covariate_name)
  support <- get_beta_support(fit_model, model_obj, covariate_name)

  dplyr::inner_join(estimate, support, by = "genome") %>%
    dplyr::left_join(genome_metadata, by = "genome") %>%
    dplyr::mutate(
      significant = support >= support_threshold | support <= negsupport_threshold,
      support_plot = ifelse(mean < 0, 1 - support, support),
      phylum_sig = ifelse(significant & support_plot > support_threshold, phylum, NA_character_),
      association = dplyr::case_when(
        significant & support_plot > support_threshold & mean > 0 ~ "Positive",
        significant & support_plot > support_threshold & mean < 0 ~ "Negative",
        TRUE ~ "Neutral"
      )
    )
}

summarise_beta_support_thresholds <- function(beta_support_data, support_threshold = 0.9) {
  beta_support_data %>%
    dplyr::filter(.data$significant, .data$support_plot > support_threshold) %>%
    dplyr::count(.data$association, name = "n") %>%
    tidyr::complete(association = c("Positive", "Negative"), fill = list(n = 0L))
}

enrich_beta_support_data <- function(beta_support_data, support_threshold = 0.9) {
  if ("association" %in% names(beta_support_data)) {
    return(beta_support_data)
  }

  beta_support_data %>%
    dplyr::mutate(
      association = dplyr::case_when(
        .data$significant & .data$support_plot > support_threshold & .data$mean > 0 ~ "Positive",
        .data$significant & .data$support_plot > support_threshold & .data$mean < 0 ~ "Negative",
        TRUE ~ "Neutral"
      )
    )
}

prepare_beta_support_from_post_table <- function(post_table,
                                                 ci_data,
                                                 covariate_name,
                                                 support_threshold = 0.9) {
  negsupport_threshold <- 1 - support_threshold

  post_table %>%
    tibble::rownames_to_column("genome") %>%
    dplyr::transmute(
      genome,
      trend = .data[[covariate_name]]
    ) %>%
    dplyr::inner_join(
      ci_data %>% dplyr::select(genome, mean, phylum),
      by = "genome"
    ) %>%
    dplyr::mutate(
      significant = .data$trend != "Neutral",
      support = dplyr::case_when(
        .data$trend == "Positive" ~ support_threshold + 0.05,
        .data$trend == "Negative" ~ negsupport_threshold - 0.05,
        TRUE ~ 0.5
      ),
      support_plot = ifelse(.data$mean < 0, 1 - .data$support, .data$support),
      phylum_sig = ifelse(
        .data$significant & .data$support_plot > support_threshold,
        .data$phylum,
        NA_character_
      ),
      association = dplyr::case_when(
        .data$trend == "Positive" ~ "Positive",
        .data$trend == "Negative" ~ "Negative",
        TRUE ~ "Neutral"
      )
    )
}

create_beta_support_scatter <- function(beta_support_data,
                                        x_lab,
                                        phylum_colors,
                                        support_threshold = 0.9,
                                        highlight_thresholds = FALSE,
                                        spotlight_cols = spotlight_palettes(),
                                        point_color = NULL,
                                        theme_fn = theme_publication) {
  xrange <- range(beta_support_data$mean, na.rm = TRUE)
  xlim_pad <- xrange + c(-0.05, 0.05) * max(1, diff(xrange))
  sig_data <- if (highlight_thresholds) {
    beta_support_data %>%
      dplyr::filter(.data$association != "Neutral")
  } else {
    beta_support_data %>% dplyr::filter(!is.na(.data$phylum_sig))
  }

  threshold_counts <- summarise_beta_support_thresholds(
    beta_support_data,
    support_threshold = support_threshold
  )
  n_pos <- threshold_counts$n[threshold_counts$association == "Positive"]
  n_neg <- threshold_counts$n[threshold_counts$association == "Negative"]
  count_label <- paste0(
    "Supported genomes: ", n_pos, " positive / ", n_neg, " negative",
    " (support >= ", support_threshold, ")"
  )

  p <- beta_support_data %>%
    ggplot2::ggplot(ggplot2::aes(x = mean, y = support_plot)) +
    ggplot2::geom_point(colour = "grey80", alpha = if (highlight_thresholds) 0.35 else 0.45, size = 1.6)

  if (highlight_thresholds) {
    p <- p +
      ggplot2::geom_hline(
        yintercept = support_threshold,
        linetype = "dashed",
        colour = "grey30",
        linewidth = 0.5
      ) +
      ggplot2::geom_point(
        data = sig_data,
        ggplot2::aes(colour = association),
        alpha = 0.9,
        size = 2.4
      ) +
      ggplot2::scale_color_manual(
        values = c(
          "Positive" = spotlight_cols$congruent,
          "Negative" = spotlight_cols$discordant
        ),
        name = "Genome association",
        labels = c(
          "Positive" = "Positive association",
          "Negative" = "Negative association"
        )
      ) +
      ggplot2::annotate(
        "text",
        x = xlim_pad[2],
        y = support_threshold + 0.03,
        hjust = 1,
        vjust = 0,
        size = 2.8,
        colour = "grey25",
        label = paste0("Support >= ", support_threshold)
      ) +
      ggplot2::annotate(
        "label",
        x = xlim_pad[1],
        y = 0.06,
        hjust = 0,
        vjust = 0,
        size = 2.8,
        fill = "white",
        alpha = 0.92,
        colour = "grey20",
        label = count_label
      ) +
      ggplot2::coord_cartesian(xlim = xlim_pad, ylim = c(0, 1.05), clip = "off") +
      ggplot2::annotate(
        "text",
        x = xlim_pad[2],
        y = 0.04,
        hjust = 1,
        vjust = 0,
        size = 2.8,
        colour = spotlight_cols$congruent,
        fontface = "bold",
        label = "Positive beta ->"
      ) +
      ggplot2::annotate(
        "text",
        x = xlim_pad[1],
        y = 0.04,
        hjust = 0,
        vjust = 0,
        size = 2.8,
        colour = spotlight_cols$discordant,
        fontface = "bold",
        label = "<- Negative beta"
      )
  } else {
    p <- p +
      ggplot2::geom_point(
        data = sig_data,
        ggplot2::aes(colour = phylum_sig),
        alpha = 0.85,
        size = 2.2
      ) +
      ggplot2::scale_color_manual(values = phylum_colors, na.translate = FALSE) +
      ggplot2::coord_cartesian(xlim = xlim_pad)
  }

  p +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", colour = "grey40") +
    ggplot2::labs(
      x = x_lab,
      y = "Posterior probability (|beta| > 0)",
      colour = if (highlight_thresholds) "Genome association" else "Phylum"
    ) +
    theme_fn() +
    ggplot2::theme(
      plot.margin = if (highlight_thresholds) {
        ggplot2::margin(8, 10, 8, 10)
      } else {
        ggplot2::margin()
      }
    )
}

select_top_genomes_ci <- function(ci_data, n_top = 30) {
  ci_sig <- ci_data %>%
    dplyr::filter(q10 > 0 | q90 < 0)

  dplyr::bind_rows(
    ci_sig %>% dplyr::slice_max(order_by = mean, n = n_top, with_ties = FALSE),
    ci_sig %>% dplyr::slice_min(order_by = mean, n = n_top, with_ties = FALSE)
  ) %>%
    dplyr::distinct(genome, .keep_all = TRUE)
}

summarise_association_counts <- function(post_table, variables = hmsc_spotlight_variables()) {
  post_table %>%
    tibble::rownames_to_column("genome") %>%
    tidyr::pivot_longer(-genome, names_to = "variable", values_to = "trend") %>%
    dplyr::filter(variable %in% variables, trend != "Neutral") %>%
    dplyr::count(variable, trend)
}

create_association_count_plot <- function(count_data,
                                          spotlight_cols = spotlight_palettes(),
                                          theme_fn = theme_publication) {
  count_data %>%
    dplyr::mutate(
      variable = factor(variable, levels = hmsc_spotlight_variables()),
      trend = factor(trend, levels = c("Positive", "Negative"))
    ) %>%
    ggplot2::ggplot(ggplot2::aes(x = variable, y = n, fill = trend)) +
    ggplot2::geom_col(position = "stack", width = 0.7) +
    ggplot2::scale_fill_manual(
      values = c("Positive" = "#1B7837", "Negative" = "#D73027"),
      name = "Association"
    ) +
    ggplot2::labs(x = NULL, y = "Genomes (supported)") +
    theme_fn() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))
}

create_varpart_summary_plot <- function(varpart,
                                        spotlight_cols = spotlight_palettes(),
                                        theme_fn = theme_publication) {
  fill_cols <- varpart_fill_colors(spotlight_cols)

  varpart$vals %>%
    as.data.frame() %>%
    tibble::rownames_to_column("variable") %>%
    tidyr::pivot_longer(-variable, names_to = "genome", values_to = "value") %>%
    dplyr::group_by(variable) %>%
    dplyr::summarise(mean_pct = mean(value, na.rm = TRUE) * 100, .groups = "drop") %>%
    dplyr::mutate(
      variable = factor(variable, levels = hmsc_varpart_levels())
    ) %>%
    ggplot2::ggplot(ggplot2::aes(x = mean_pct, y = variable, fill = variable)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::scale_fill_manual(values = fill_cols, guide = "none") +
    ggplot2::labs(x = "Mean variance explained (%)", y = NULL) +
    theme_fn()
}

prepare_devil_temp_congruence_taxa <- function(post_table, genome_metadata) {
  post_table %>%
    tibble::rownames_to_column("genome") %>%
    dplyr::select(genome, devil, temperature) %>%
    dplyr::left_join(genome_metadata, by = "genome") %>%
    dplyr::filter(devil != "Neutral", temperature != "Neutral") %>%
    dplyr::mutate(
      congruence = ifelse(devil == temperature, "Congruent", "Discordant")
    ) %>%
    dplyr::count(phylum, devil, temperature, congruence, name = "n") %>%
    dplyr::group_by(phylum) %>%
    dplyr::mutate(prop = n / sum(n)) %>%
    dplyr::ungroup()
}

prepare_devil_temp_congruence_functional <- function(elements_response, GIFT_db, n_top = 12) {
  func_congruence_group <- elements_response %>%
    dplyr::filter(devil != "Neutral", temperature != "Neutral") %>%
    dplyr::mutate(
      devil = droplevels(devil),
      temperature = droplevels(temperature)
    ) %>%
    dplyr::group_by(GIFT, devil, temperature) %>%
    dplyr::summarise(mean_val = mean(value, na.rm = TRUE), .groups = "drop") %>%
    dplyr::left_join(
      GIFT_db %>% dplyr::distinct(.data$Code_element, .data$Code_function, .data$Function),
      by = c("GIFT" = "Code_element")
    ) %>%
    dplyr::group_by(Code_function, devil, temperature) %>%
    dplyr::summarise(mean_val = mean(mean_val, na.rm = TRUE), .groups = "drop") %>%
    dplyr::mutate(
      congruence = ifelse(devil == temperature, "Congruent", "Discordant")
    )

  interesting_funcs <- func_congruence_group %>%
    dplyr::group_by(Code_function) %>%
    dplyr::summarise(range_val = max(mean_val) - min(mean_val), .groups = "drop") %>%
    dplyr::slice_max(order_by = range_val, n = n_top) %>%
    dplyr::pull(Code_function)

  func_congruence_group %>%
    dplyr::filter(Code_function %in% interesting_funcs)
}

create_congruence_tile_plot <- function(tile_data,
                                        facet_var = NULL,
                                        value_var = "n",
                                        congruence_colors = spotlight_palettes(),
                                        theme_fn = theme_publication) {
  plot_data <- tile_data %>%
    dplyr::mutate(
      devil = factor(devil, levels = c("Positive", "Negative")),
      temperature = factor(temperature, levels = c("Positive", "Negative")),
      congruence = factor(congruence, levels = c("Congruent", "Discordant"))
    )

  if (is.null(value_var) || !value_var %in% names(plot_data)) {
    plot_data <- plot_data %>% dplyr::mutate(.alpha_val = 1)
  } else {
    if (!is.null(facet_var) && facet_var %in% names(plot_data)) {
      facet_sym <- rlang::sym(facet_var)
      plot_data <- plot_data %>%
        dplyr::group_by(!!facet_sym) %>%
        dplyr::mutate(
          .alpha_val = .data[[value_var]] / max(.data[[value_var]], na.rm = TRUE)
        ) %>%
        dplyr::ungroup()
    } else {
      max_val <- max(plot_data[[value_var]], na.rm = TRUE)
      plot_data <- plot_data %>%
        dplyr::mutate(.alpha_val = .data[[value_var]] / max_val)
    }
    plot_data <- plot_data %>%
      dplyr::mutate(.alpha_val = dplyr::if_else(is.finite(.alpha_val), .alpha_val, 0.25))
  }

  p <- plot_data %>%
    ggplot2::ggplot(ggplot2::aes(
      x = devil,
      y = temperature,
      fill = congruence,
      alpha = .alpha_val
    )) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.4) +
    ggplot2::scale_fill_manual(
      values = c(
        "Congruent" = congruence_colors$congruent,
        "Discordant" = congruence_colors$discordant
      ),
      name = "Congruence"
    ) +
    ggplot2::scale_alpha_continuous(range = c(0.25, 1), guide = "none") +
    ggplot2::labs(
      x = "Devil association",
      y = "Temperature association"
    ) +
    theme_fn(base_size = 8)

  if (!is.null(facet_var) && facet_var %in% names(plot_data)) {
    facet_sym <- rlang::sym(facet_var)
    p <- p + ggplot2::facet_wrap(ggplot2::vars(!!facet_sym), scales = "free")
  }

  p
}

summarise_devil_temp_congruence <- function(post_table) {
  post_table %>%
    tibble::rownames_to_column("genome") %>%
    dplyr::select(genome, devil, temperature) %>%
    dplyr::filter(devil != "Neutral", temperature != "Neutral") %>%
    dplyr::mutate(
      congruence = ifelse(devil == temperature, "Congruent", "Discordant")
    ) %>%
    dplyr::count(congruence, name = "n")
}

create_congruence_summary_plot <- function(congruence_summary,
                                           congruence_colors = spotlight_palettes(),
                                           theme_fn = theme_publication) {
  congruence_summary %>%
    dplyr::mutate(congruence = factor(congruence, levels = c("Congruent", "Discordant"))) %>%
    ggplot2::ggplot(ggplot2::aes(x = congruence, y = n, fill = congruence)) +
    ggplot2::geom_col(width = 0.6) +
    ggplot2::scale_fill_manual(
      values = c(
        "Congruent" = congruence_colors$congruent,
        "Discordant" = congruence_colors$discordant
      ),
      guide = "none"
    ) +
    ggplot2::labs(x = NULL, y = "Genomes") +
    theme_fn()
}

env_hill_metric_labels <- c(
  h0 = "Environmental richness (Hill h0)",
  h1 = "Environmental neutral diversity (Hill h1)",
  h2 = "Environmental Hill h2"
)

landcover_summary_vars <- function() {
  c(
    "Cultivated_Total" = "Cultivated landcover (%)",
    "Native_Terrestrial_Total" = "Native terrestrial (%)",
    "Native_Aquatic_Total" = "Native aquatic (%)",
    "Bare_Urban" = "Bare / urban (%)"
  )
}

compute_hill_from_proportions <- function(prop_mat) {
  h0 <- rowSums(prop_mat > 0)
  h_vals <- -rowSums(ifelse(prop_mat > 0, prop_mat * log(prop_mat), 0), na.rm = TRUE)
  h1 <- exp(h_vals)
  h2 <- 1 / rowSums(prop_mat^2)
  tibble::tibble(h0 = h0, h1 = h1, h2 = h2)
}

compute_broad_landcover_hills <- function(landcover_wide, sample_ids = NULL) {
  plot_df <- prepare_landcover_plot_df(landcover_wide, sample_ids = sample_ids)
  broad_mat <- plot_df %>%
    tidyr::pivot_wider(names_from = group, values_from = pct) %>%
    dplyr::mutate(dplyr::across(-sample, ~ .x / 100)) %>%
    tibble::column_to_rownames("sample") %>%
    as.matrix()
  broad_mat[is.na(broad_mat)] <- 0

  hills <- compute_hill_from_proportions(broad_mat)
  tibble::tibble(sample = rownames(broad_mat)) %>%
    dplyr::bind_cols(hills) %>%
    tidyr::pivot_longer(
      cols = c(h0, h1, h2),
      names_to = "q",
      values_to = "value_broad"
    )
}

prepare_fine_broad_hill_compare <- function(hill_long_fig, landcover_wide, sample_ids = NULL) {
  fine_long <- hill_long_fig %>%
    dplyr::filter(q %in% names(env_hill_metric_labels)) %>%
    dplyr::mutate(q = factor(q, levels = names(env_hill_metric_labels)))

  broad_long <- compute_broad_landcover_hills(landcover_wide, sample_ids = sample_ids) %>%
    dplyr::mutate(q = factor(q, levels = names(env_hill_metric_labels)))

  fine_long %>%
    dplyr::rename(value_fine = value) %>%
    dplyr::inner_join(broad_long, by = c("sample", "q"))
}

create_env_hill_distribution_plot <- function(hill_long_fig,
                                              theme_fn = theme_publication) {
  plot_data <- hill_long_fig %>%
    dplyr::filter(q %in% names(env_hill_metric_labels)) %>%
    dplyr::mutate(
      q = factor(q, levels = names(env_hill_metric_labels)),
      q_lab = env_hill_metric_labels[as.character(q)]
    )

  plot_data %>%
    ggplot2::ggplot(ggplot2::aes(x = q_lab, y = value, fill = q_lab)) +
    ggplot2::geom_violin(trim = FALSE, alpha = 0.35, colour = NA, show.legend = FALSE) +
    ggplot2::geom_boxplot(width = 0.15, fill = "white", outlier.shape = NA, alpha = 0.9) +
    ggplot2::geom_jitter(width = 0.08, alpha = 0.55, size = 1.6, colour = "grey25") +
    ggplot2::scale_fill_manual(
      values = stats::setNames(
        c("#429ef5", "#42f58d", "#b142f5"),
        unname(env_hill_metric_labels)
      ),
      guide = "none"
    ) +
    ggplot2::labs(x = NULL, y = "Environmental Hill diversity") +
    theme_fn() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 25, hjust = 1))
}

create_landcover_hill_scatter <- function(plot_data, x_var, x_lab,
                                          y_var = "value",
                                          y_lab = "Environmental Hill diversity",
                                          show_smooth = TRUE,
                                          theme_fn = theme_publication) {
  p <- plot_data %>%
    ggplot2::ggplot(ggplot2::aes(x = .data[[x_var]], y = .data[[y_var]])) +
    ggplot2::geom_point(alpha = 0.7, size = 2.2, colour = "#2166AC")

  if (show_smooth) {
    p <- p + ggplot2::geom_smooth(method = "lm", se = TRUE, colour = "black",
                                  linewidth = 0.7, linetype = "dashed")
  }

  cor_text <- ""
  cor_data <- plot_data %>%
    dplyr::filter(!is.na(.data[[x_var]]), !is.na(.data[[y_var]]))
  if (nrow(cor_data) >= 3) {
    ct <- stats::cor.test(cor_data[[x_var]], cor_data[[y_var]], method = "spearman")
    cor_text <- paste0(
      "rho = ", round(unname(ct$estimate), 2),
      ", p = ", format.pval(ct$p.value, digits = 2)
    )
  }

  p +
    ggplot2::labs(x = x_lab, y = y_lab, subtitle = cor_text) +
    theme_fn()
}

create_fine_broad_hill_scatter <- function(compare_data, q_level,
                                           theme_fn = theme_publication) {
  plot_data <- compare_data %>%
    dplyr::filter(q == q_level)

  create_landcover_hill_scatter(
    plot_data,
    x_var = "value_broad",
    x_lab = paste0("Broad-scale landcover Hill ", q_level),
    y_var = "value_fine",
    y_lab = paste0("Fine-scale landcover Hill ", q_level),
    theme_fn = theme_fn
  )
}

prepare_env_ancom_inputs <- function(sample_metadata, genome_counts,
                                     hill_wide, genome_metadata = NULL) {
  hill_info <- tibble::tribble(
    ~q,  ~hill_col,        ~group_col,        ~outname,
    "0", "env_hill_h0",    "env_div_group0",  "q0",
    "1", "env_hill_h1",    "env_div_group1",  "q1",
    "2", "env_hill_h2",    "env_div_group2",  "q2"
  )

  purrr::pmap(hill_info, function(q, hill_col, group_col, outname) {
    hill_sym <- rlang::sym(hill_col)
    group_sym <- rlang::sym(group_col)

    md <- sample_metadata %>%
      dplyr::select(-dplyr::any_of(c("env_hill_h0", "env_hill_h1", "env_hill_h2"))) %>%
      dplyr::left_join(hill_wide, by = "sample") %>%
      dplyr::filter(!is.na(!!hill_sym)) %>%
      dplyr::mutate(
        !!group_sym := ggplot2::cut_number(
          !!hill_sym, 3, labels = c("Low", "Mid", "High")
        )
      ) %>%
      dplyr::filter(!!group_sym %in% c("Low", "High"))

    sel <- md$sample
    gc <- genome_counts %>%
      dplyr::select(genome, tidyselect::any_of(sel)) %>%
      dplyr::filter(dplyr::if_any(-genome, ~ .x > 0))

    list(
      q = q,
      hill_col = hill_col,
      group_col = group_col,
      outname = outname,
      metadata_div = md,
      genome_counts = gc
    )
  }) %>%
    stats::setNames(hill_info$outname)
}

build_env_ancom_phyloseq <- function(filtered_inputs, genome_metadata) {
  purrr::imap(filtered_inputs, function(f, name) {
    md_tbl <- f$metadata_div %>%
      dplyr::mutate(
        !!f$group_col := factor(.data[[f$group_col]], levels = c("Low", "High"))
      ) %>%
      tibble::column_to_rownames("sample")

    mat <- f$genome_counts %>%
      dplyr::mutate(dplyr::across(-genome, ~ as.integer(round(.x)))) %>%
      tibble::column_to_rownames("genome") %>%
      as.matrix()

    otu <- phyloseq::otu_table(mat, taxa_are_rows = TRUE)
    tax <- genome_metadata %>%
      dplyr::filter(genome %in% phyloseq::taxa_names(otu)) %>%
      dplyr::select(domain, phylum, class, order, family, genus, species, genome) %>%
      dplyr::mutate(dplyr::across(-genome, ~ dplyr::coalesce(as.character(.), ""))) %>%
      tibble::column_to_rownames("genome") %>%
      as.matrix() %>%
      phyloseq::tax_table()

    phyloseq::phyloseq(otu, tax, phyloseq::sample_data(md_tbl))
  })
}

run_env_ancombc <- function(phylo_list, filtered_inputs) {
  purrr::imap(phylo_list, function(ps, name) {
    group_col <- filtered_inputs[[name]]$group_col

    args <- list(
      data = ps,
      assay_name = "counts",
      fix_formula = group_col,
      struc_zero = TRUE,
      group = group_col,
      p_adj_method = "BH",
      prv_cut = 0.05,
      lib_cut = 0,
      verbose = FALSE
    )

    fmls <- names(formals(ANCOMBC::ancombc2))
    if ("tax_level" %in% fmls) args$tax_level <- NULL
    if ("taxa_rank" %in% fmls) args$taxa_rank <- NULL

    tryCatch(
      do.call(ANCOMBC::ancombc2, args),
      error = function(e) {
        warning("ANCOMBC2 failed for ", name, ": ", conditionMessage(e), call. = FALSE)
        NULL
      }
    )
  })
}

extract_ancombc_diff_table <- function(ancom_result, genome_metadata = NULL,
                                         p_threshold = 0.05) {
  if (is.null(ancom_result)) {
    return(NULL)
  }

  dt <- if (!is.null(ancom_result$res) && "diff_abn" %in% names(ancom_result$res)) {
    ancom_result$res$diff_abn
  } else if (!is.null(ancom_result$res) && "taxon" %in% names(ancom_result$res)) {
    ancom_result$res
  } else {
    return(NULL)
  }

  if (!("taxon" %in% names(dt))) {
    dt <- tibble::rownames_to_column(dt, "taxon")
  }

  lfc_cols <- grep("^lfc_", names(dt), value = TRUE)
  lfc_cols <- lfc_cols[!grepl("\\(Intercept\\)", lfc_cols, fixed = FALSE)]
  p_cols <- grep("^p_", names(dt), value = TRUE)
  p_cols <- p_cols[!grepl("\\(Intercept\\)", p_cols, fixed = FALSE)]

  lfc_col <- lfc_cols[1]
  p_col <- p_cols[1]
  if (is.na(lfc_col) || is.na(p_col)) {
    return(NULL)
  }

  out <- dt %>%
    dplyr::mutate(
      neglogp = -log10(.data[[p_col]]),
      sig = .data[[p_col]] < p_threshold
    )

  if (!is.null(genome_metadata)) {
    out <- out %>%
      dplyr::left_join(
        genome_metadata %>% dplyr::select(genome, phylum),
        by = c("taxon" = "genome")
      )
  }

  attr(out, "lfc_col") <- lfc_col
  attr(out, "p_col") <- p_col
  out
}

create_ancombc_volcano_plot <- function(diff_table, title = NULL,
                                        theme_fn = theme_publication) {
  if (is.null(diff_table) || nrow(diff_table) == 0) {
    return(NULL)
  }

  lfc_col <- attr(diff_table, "lfc_col")
  p_col <- attr(diff_table, "p_col")

  diff_table %>%
    ggplot2::ggplot(ggplot2::aes(
      x = .data[[lfc_col]],
      y = neglogp,
      colour = sig
    )) +
    ggplot2::geom_point(alpha = 0.75, size = 1.8) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", colour = "grey40") +
    ggplot2::scale_color_manual(
      values = c(`TRUE` = "#D73027", `FALSE` = "grey70"),
      labels = c("ns", "p < 0.05"),
      name = NULL
    ) +
    ggplot2::labs(
      x = "log2 fold-change (High vs Low env diversity)",
      y = expression(-log[10](p)),
      title = title
    ) +
    theme_fn()
}

create_ancombc_barplot <- function(diff_table, n_top = 12, title = NULL,
                                   phylum_colors = NULL,
                                   theme_fn = theme_publication) {
  if (is.null(diff_table)) {
    return(NULL)
  }

  lfc_col <- attr(diff_table, "lfc_col")
  p_col <- attr(diff_table, "p_col")

  sig <- diff_table %>%
    dplyr::filter(sig) %>%
    dplyr::arrange(dplyr::desc(abs(.data[[lfc_col]]))) %>%
    dplyr::slice_head(n = n_top)

  if (nrow(sig) == 0) {
    return(NULL)
  }

  p <- sig %>%
    ggplot2::ggplot(ggplot2::aes(
      x = .data[[lfc_col]],
      y = forcats::fct_reorder(taxon, .data[[lfc_col]]),
      fill = phylum
    )) +
    ggplot2::geom_col() +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed", colour = "grey40") +
    ggplot2::labs(
      x = "log2 fold-change (High vs Low)",
      y = NULL,
      title = title
    ) +
    theme_fn()

  if (!is.null(phylum_colors)) {
    p <- p + ggplot2::scale_fill_manual(values = phylum_colors)
  }

  p
}

prepare_taxonomy_relabun <- function(genome_counts, genome_metadata, sample_metadata,
                                     tax_level = c("phylum", "family", "genus"),
                                     group_vars = character()) {
  tax_level <- match.arg(tax_level)

  genome_counts %>%
    dplyr::mutate(dplyr::across(-genome, ~ .x / sum(.x))) %>%
    tidyr::pivot_longer(-genome, names_to = "sample", values_to = "count") %>%
    dplyr::left_join(sample_metadata, by = dplyr::join_by(sample)) %>%
    dplyr::left_join(genome_metadata, by = dplyr::join_by(genome)) %>%
    dplyr::group_by(
      sample,
      dplyr::across(dplyr::all_of(c(
        if (tax_level == "genus" && "phylum" %in% group_vars) "phylum",
        tax_level,
        group_vars
      )))
    ) %>%
    dplyr::summarise(relabun = sum(count), .groups = "drop")
}

prepare_phylum_stacked_data <- function(genome_counts, genome_metadata, sample_metadata,
                                        sample_order = NULL, n_top = NULL,
                                        other_label = "Other",
                                        env_settings = environment_plot_settings()) {
  short_by_full <- environment_short_label_map(env_settings)
  env_order <- phylum_stacked_environment_order(sample_metadata, env_settings)
  short_order <- unname(short_by_full[env_order])

  plot_df <- genome_counts %>%
    dplyr::mutate(dplyr::across(-genome, ~ .x / sum(.x))) %>%
    tidyr::pivot_longer(-genome, names_to = "sample", values_to = "count") %>%
    dplyr::left_join(genome_metadata %>% dplyr::select(genome, phylum), by = "genome") %>%
    dplyr::left_join(
      sample_metadata %>% dplyr::select(sample, dplyr::any_of("broad_environment")),
      by = "sample"
    ) %>%
    dplyr::filter(count > 0) %>%
    dplyr::mutate(
      broad_environment = factor(.data$broad_environment, levels = env_order),
      broad_environment_short = factor(
        short_by_full[as.character(.data$broad_environment)],
        levels = short_order
      )
    )

  if (!is.null(n_top)) {
    phylum_levels <- plot_df %>%
      dplyr::group_by(phylum) %>%
      dplyr::summarise(total = sum(count), .groups = "drop") %>%
      dplyr::arrange(dplyr::desc(total)) %>%
      dplyr::pull(phylum)
    top_phyla <- utils::head(phylum_levels, n_top)
    plot_df <- plot_df %>%
      dplyr::mutate(
        phylum = ifelse(phylum %in% top_phyla, phylum, other_label)
      )
  }

  if (is.null(sample_order)) {
    sample_order <- sample_metadata %>%
      dplyr::mutate(broad_environment = factor(.data$broad_environment, levels = env_order)) %>%
      dplyr::arrange(.data$broad_environment, .data$sample) %>%
      dplyr::pull(.data$sample)
  }

  plot_df <- plot_df %>%
    dplyr::mutate(sample = factor(sample, levels = sample_order))

  plot_df
}

phylum_stacked_legend_theme <- function(base_size = publication_legend_text_size(5.5),
                                        legend_position = "right") {
  circular_phylogeny_legend_theme(base_size = base_size) +
    ggplot2::theme(
      legend.position = legend_position,
      legend.box = "vertical",
      legend.box.spacing = ggplot2::unit(1.8, "mm")
    )
}

build_phylum_stacked_legend_panel <- function(plot,
                                              env_order = NULL,
                                              phylum_colors = NULL,
                                              legend_base_size = publication_legend_text_size(5),
                                              match_ring_phylogeny = TRUE,
                                              show_phylum_legend = TRUE,
                                              show_env_legend = TRUE,
                                              legend_layout = c("stacked", "columns")) {
  legend_layout <- match.arg(legend_layout)
  env_settings <- environment_plot_settings()
  if (is.null(env_order)) {
    env_order <- env_settings$limits
  }
  env_order <- intersect(as.character(env_order), env_settings$limits)

  plot_df <- plot$data
  phylum_levels <- if (is.factor(plot_df$phylum)) {
    levels(plot_df$phylum)
  } else {
    unique(plot_df$phylum)
  }

  if (!is.null(phylum_colors) && isTRUE(match_ring_phylogeny)) {
    phylum_colors <- prepare_ring_phylogeny_phylum_colors(phylum_colors)
  }
  phylum_labels <- format_phylum_label(phylum_levels)
  phylum_fill <- if (!is.null(phylum_colors)) {
    dplyr::coalesce(phylum_colors[phylum_levels], rep("grey80", length(phylum_levels)))
  } else {
    rep("grey80", length(phylum_levels))
  }

  env_labels <- paste0(
    unname(environment_short_label_map(env_settings)[env_order]),
    " - ",
    gsub(
      "\\s*\\([^)]+\\)$",
      "",
      unname(env_settings$labels_long[env_order])
    )
  )

  n_phyla <- length(phylum_levels)
  n_env <- length(env_labels)
  section_gap <- 0.9
  title_gap <- 0.65
  key_width <- 0.09

  use_columns <- legend_layout == "columns" &&
    isTRUE(show_phylum_legend) &&
    isTRUE(show_env_legend) &&
    n_phyla > 0L &&
    n_env > 0L

  if (isTRUE(use_columns)) {
    n_rows <- max(n_phyla, n_env)
    phylum_y <- seq_len(n_phyla)
    env_y <- seq_len(n_env)
    title_y <- n_rows + title_gap
    phylum_title_y <- title_y
    env_title_y <- title_y
    y_max <- title_y + 0.35
    x_key <- 0.04
    x_text <- 0.15
    x_env_text <- 0.52
  } else {
    x_key <- 0.05
    x_text <- 0.16
    x_env_text <- x_text
    env_y <- if (isTRUE(show_env_legend) && n_env > 0L) seq_len(n_env) else numeric(0)
    env_title_y <- if (length(env_y) > 0L) max(env_y) + title_gap else 0
    phylum_y <- if (isTRUE(show_phylum_legend) && n_phyla > 0L) {
      if (length(env_y) > 0L) {
        env_title_y + section_gap + seq_len(n_phyla)
      } else {
        rev(seq_len(n_phyla))
      }
    } else {
      numeric(0)
    }
    phylum_title_y <- if (length(phylum_y) > 0L) {
      if (length(env_y) > 0L) {
        max(phylum_y) + title_gap
      } else {
        max(phylum_y) + title_gap
      }
    } else {
      0
    }
    y_max <- max(c(env_title_y, phylum_title_y, max(env_y, 0), max(phylum_y, 0))) + 0.35
  }

  phylum_df <- if (length(phylum_y) > 0L) {
    tibble::tibble(
      y = phylum_y,
      label = phylum_labels,
      fill_color = unname(phylum_fill)
    )
  } else {
    NULL
  }
  env_df <- if (length(env_y) > 0L) {
    tibble::tibble(
      y = env_y,
      label = env_labels
    )
  } else {
    NULL
  }

  p <- ggplot2::ggplot()

  if (!is.null(phylum_df)) {
    p <- p +
      ggplot2::geom_tile(
        data = phylum_df,
        ggplot2::aes(x = x_key, y = .data$y, fill = I(.data$fill_color)),
        width = key_width,
        height = 0.72,
        color = NA
      ) +
      ggplot2::geom_text(
        data = phylum_df,
        ggplot2::aes(x = x_text, y = .data$y, label = .data$label),
        hjust = 0,
        size = legend_base_size / .pt
      ) +
      ggplot2::annotate(
        "text",
        x = x_text,
        y = phylum_title_y,
        label = "Phylum",
        hjust = 0,
        fontface = "bold",
        size = (legend_base_size + 0.5) / .pt
      )
  }

  if (!is.null(env_df)) {
    p <- p +
      ggplot2::geom_text(
        data = env_df,
        ggplot2::aes(x = x_env_text, y = .data$y, label = .data$label),
        hjust = 0,
        size = legend_base_size / .pt
      ) +
      ggplot2::annotate(
        "text",
        x = x_env_text,
        y = env_title_y,
        label = "Environment",
        hjust = 0,
        fontface = "bold",
        size = (legend_base_size + 0.5) / .pt
      )
  }

  p +
    ggplot2::coord_cartesian(
      xlim = c(0, 1),
      ylim = c(0.35, y_max),
      clip = "off"
    ) +
    ggplot2::theme_void() +
    ggplot2::theme(plot.margin = ggplot2::margin(0, 0, 0, 0))
}

compose_phylum_stacked_bar <- function(plot,
                                       env_order = NULL,
                                       show_env_legend = TRUE,
                                       show_phylum_legend = TRUE,
                                       phylum_colors = NULL,
                                       match_ring_phylogeny = TRUE,
                                       legend_rel_width = NULL,
                                       legend_base_size = publication_legend_text_size(5),
                                       legend_layout = c("stacked", "columns"),
                                       plot_margin = ggplot2::margin(5, 5, 5, 5)) {
  legend_layout <- match.arg(legend_layout)
  if (is.null(legend_rel_width)) {
    legend_rel_width <- if (legend_layout == "columns") {
      0.22
    } else if (isTRUE(show_phylum_legend) && isTRUE(show_env_legend)) {
      0.32
    } else if (isTRUE(show_env_legend) || isTRUE(show_phylum_legend)) {
      0.22
    } else {
      0.32
    }
  }

  legend_panel <- if (isTRUE(show_env_legend) || isTRUE(show_phylum_legend)) {
    build_phylum_stacked_legend_panel(
      plot = plot,
      env_order = env_order,
      phylum_colors = phylum_colors,
      legend_base_size = legend_base_size,
      match_ring_phylogeny = match_ring_phylogeny,
      show_phylum_legend = show_phylum_legend,
      show_env_legend = show_env_legend,
      legend_layout = legend_layout
    )
  } else {
    legend_theme <- phylum_stacked_legend_theme(
      base_size = legend_base_size,
      legend_position = "right"
    )
    patchwork::wrap_elements(
      full = cowplot::get_legend(plot + legend_theme),
      clip = FALSE
    )
  }

  plot_panel <- plot +
    ggplot2::theme(
      legend.position = "none",
      plot.margin = plot_margin
    )

  if (isTRUE(show_env_legend)) {
    plot_panel +
      patchwork::wrap_elements(full = legend_panel, clip = FALSE) +
      patchwork::plot_layout(widths = c(1 - legend_rel_width, legend_rel_width))
  } else {
    plot_panel +
      legend_panel +
      patchwork::plot_layout(widths = c(1 - legend_rel_width, legend_rel_width))
  }
}

create_phylum_stacked_bar <- function(plot_df, phylum_colors = NULL,
                                      facet_env = FALSE,
                                      style = c("chapter", "publication"),
                                      legend_position = "right",
                                      legend_ncol = 1L,
                                      match_ring_phylogeny = TRUE,
                                      show_env_legend = TRUE,
                                      show_phylum_legend = TRUE,
                                      legend_rel_width = NULL,
                                      wide_layout = FALSE,
                                      legend_base_size = publication_legend_text_size(5),
                                      theme_fn = theme_publication) {
  style <- match.arg(style)

  if (isTRUE(wide_layout) && is.null(legend_rel_width)) {
    legend_rel_width <- if (isTRUE(show_env_legend)) 0.22 else 0.11
  }
  legend_layout <- "stacked"
  plot_margin <- if (isTRUE(wide_layout)) {
    ggplot2::margin(4, 0, 4, 0)
  } else {
    ggplot2::margin(5, 5, 5, 5)
  }

  if (!is.null(phylum_colors) && isTRUE(match_ring_phylogeny)) {
    phylum_colors <- prepare_ring_phylogeny_phylum_colors(phylum_colors)
  }

  p <- ggplot2::ggplot(
    plot_df,
    ggplot2::aes(x = sample, y = count, fill = phylum, group = phylum)
  ) +
    ggplot2::geom_bar(
      stat = "identity",
      colour = "white",
      linewidth = 0.1,
      width = 1
    ) +
    ggplot2::labs(
      x = "Samples",
      y = "Relative abundance",
      fill = "Phylum"
    ) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0))) +
    ggplot2::guides(fill = ggplot2::guide_legend(ncol = legend_ncol))

  if (style == "chapter") {
    p <- p +
      ggplot2::theme(
        axis.text.x = ggplot2::element_blank(),
        axis.ticks.x = ggplot2::element_blank(),
        axis.title.x = ggplot2::element_blank(),
        panel.background = ggplot2::element_blank(),
        panel.border = ggplot2::element_blank(),
        panel.grid.major = ggplot2::element_blank(),
        panel.grid.minor = ggplot2::element_blank(),
        strip.background = ggplot2::element_rect(fill = "white"),
        strip.text = ggplot2::element_text(size = 10.5, lineheight = 0.6, face = "bold"),
        axis.line = ggplot2::element_line(linewidth = 0.5, linetype = "solid", colour = "black"),
        legend.position = legend_position,
        legend.title = ggplot2::element_text(
          face = "bold",
          size = publication_legend_title_size()
        ),
        legend.text = ggplot2::element_text(
          size = publication_legend_text_size(),
          face = "bold"
        ),
        legend.key.height = ggplot2::unit(0.45, "cm"),
        legend.key.width = ggplot2::unit(0.45, "cm"),
        plot.margin = ggplot2::margin(5, 5, 5, 5)
      )
  } else {
    p <- p +
      theme_fn() +
      ggplot2::theme(
        axis.text.x = ggplot2::element_blank(),
        axis.ticks.x = ggplot2::element_blank(),
        panel.grid.major.x = ggplot2::element_blank(),
        legend.position = legend_position,
        legend.title = ggplot2::element_text(
          face = "bold",
          size = publication_legend_title_size()
        ),
        legend.text = ggplot2::element_text(
          size = publication_legend_text_size(),
          face = "bold"
        ),
        legend.key.height = ggplot2::unit(0.45, "cm"),
        legend.key.width = ggplot2::unit(0.45, "cm"),
        plot.margin = ggplot2::margin(5, 5, 5, 5)
      )
  }

  if (!is.null(phylum_colors)) {
    p <- p + ggplot2::scale_fill_manual(
      values = phylum_colors,
      labels = if (isTRUE(match_ring_phylogeny)) format_phylum_label else ggplot2::waiver()
    )
  }

  if (facet_env && "broad_environment_short" %in% names(plot_df)) {
    p <- p + ggplot2::facet_grid(
      . ~ broad_environment_short,
      scales = "free_x",
      space = "free_x"
    )
  } else if (facet_env && "broad_environment" %in% names(plot_df)) {
    p <- p + ggplot2::facet_grid(. ~ broad_environment, scales = "free_x", space = "free_x")
  }

  if (isTRUE(wide_layout)) {
    p <- p +
      ggplot2::scale_x_discrete(expand = ggplot2::expansion(add = 0.12)) +
      ggplot2::theme(
        panel.spacing.x = ggplot2::unit(0.12, "lines")
      )
  }

  env_order <- if ("broad_environment" %in% names(plot_df)) {
    levels(plot_df$broad_environment)
  } else {
    NULL
  }

  if (isTRUE(show_env_legend) || isTRUE(show_phylum_legend)) {
    p <- compose_phylum_stacked_bar(
      plot = p,
      env_order = env_order,
      phylum_colors = phylum_colors,
      match_ring_phylogeny = match_ring_phylogeny,
      show_env_legend = show_env_legend,
      show_phylum_legend = show_phylum_legend,
      legend_rel_width = legend_rel_width,
      legend_base_size = legend_base_size,
      legend_layout = legend_layout,
      plot_margin = plot_margin
    )
  }

  p
}

phylum_stacked_figure_dims <- function(facet_env = FALSE) {
  if (facet_env) {
    list(width_mm = 180, height_mm = 120)
  } else {
    list(width_mm = 180, height_mm = 100)
  }
}

clean_taxonomy_label <- function(x, prefix = NULL) {
  if (!is.null(prefix)) {
    x <- gsub(paste0("^", prefix, "__"), "", x)
  }
  x <- gsub("^[dpcofgs]__", "", x)
  dplyr::if_else(is.na(x) | x == "", "Unclassified", x)
}

prepare_family_sankey_data <- function(genome_counts, genome_metadata, n_top = 18,
                                       other_label = "Other families") {
  pooled_df <- genome_counts %>%
    dplyr::mutate(dplyr::across(-genome, ~ .x / sum(.x))) %>%
    tidyr::pivot_longer(-genome, names_to = "sample", values_to = "count") %>%
    dplyr::left_join(
      genome_metadata %>% dplyr::select(genome, phylum, family),
      by = "genome"
    ) %>%
    dplyr::group_by(sample, phylum, family) %>%
    dplyr::summarise(relabun = sum(count), .groups = "drop") %>%
    dplyr::group_by(phylum, family) %>%
    dplyr::summarise(relabun = mean(relabun), .groups = "drop")

  top_families <- pooled_df %>%
    dplyr::group_by(family) %>%
    dplyr::summarise(total = sum(relabun), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(total)) %>%
    dplyr::slice_head(n = n_top) %>%
    dplyr::pull(family)

  plot_df <- pooled_df %>%
    dplyr::mutate(
      family_plot = dplyr::if_else(family %in% top_families, family, NA_character_)
    ) %>%
    dplyr::group_by(phylum, family_plot) %>%
    dplyr::summarise(relabun = sum(relabun), .groups = "drop") %>%
    dplyr::mutate(
      family_plot = dplyr::coalesce(family_plot, other_label),
      phylum_label = clean_taxonomy_label(phylum),
      family_label = dplyr::if_else(
        family_plot == other_label,
        other_label,
        clean_taxonomy_label(family_plot, "f")
      )
    ) %>%
    dplyr::filter(relabun > 0)

  ph_order <- plot_df %>%
    dplyr::group_by(phylum_label) %>%
    dplyr::summarise(total = sum(relabun), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(total)) %>%
    dplyr::pull(phylum_label)

  fam_order <- plot_df %>%
    dplyr::group_by(family_label) %>%
    dplyr::summarise(total = sum(relabun), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(total)) %>%
    dplyr::pull(family_label)

  plot_df %>%
    dplyr::mutate(
      phylum_label = factor(phylum_label, levels = ph_order),
      family_label = factor(family_label, levels = fam_order)
    )
}

family_sankey_stratum_labels <- function(plot, label_min = 0.008) {
  built <- ggplot2::ggplot_build(plot)
  stratum_layers <- which(vapply(
    built$data,
    function(d) all(c("stratum", "ymax", "ymin", "x") %in% names(d)),
    logical(1)
  ))
  if (length(stratum_layers) == 0) {
    return(NULL)
  }

  stratum_df <- built$data[[stratum_layers[length(stratum_layers)]]] %>%
    dplyr::mutate(
      height = .data$ymax - .data$ymin,
      ymid = (.data$ymin + .data$ymax) / 2,
      label = as.character(.data$stratum)
    ) %>%
    dplyr::filter(.data$height >= label_min) %>%
    dplyr::group_by(.data$x, .data$label) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      side = dplyr::if_else(.data$x < 1.5, "phylum", "family")
    )

  stratum_df
}

create_family_sankey_plot <- function(plot_df, phylum_colors = NULL,
                                      label_min = 0.008,
                                      label_style = c("external", "internal"),
                                      label_size = NULL,
                                      legend_position = c("bottom", "left", "right", "none"),
                                      legend_ncol = NULL,
                                      theme_fn = theme_publication) {
  label_style <- match.arg(label_style)
  legend_position <- match.arg(legend_position)
  if (is.null(legend_ncol)) {
    legend_ncol <- if (legend_position == "bottom") 5L else 1L
  }
  if (is.null(label_size)) {
    label_size <- if (label_style == "external") 2.5 else 2.8
  }
  if (!requireNamespace("ggalluvial", quietly = TRUE)) {
    stop(
      "Package 'ggalluvial' is required for family Sankey plots. ",
      "Install with install.packages('ggalluvial').",
      call. = FALSE
    )
  }

  phylum_lookup <- plot_df %>%
    dplyr::distinct(phylum, phylum_label) %>%
    dplyr::arrange(phylum_label)

  fill_vals <- if (!is.null(phylum_colors)) {
    stats::setNames(
      dplyr::coalesce(phylum_colors[phylum_lookup$phylum], rep("grey80", nrow(phylum_lookup))),
      phylum_lookup$phylum_label
    )
  } else {
    NULL
  }

  x_expand <- if (label_style == "external") {
    ggplot2::expansion(mult = c(0.42, 0.48))
  } else {
    ggplot2::expansion(mult = c(0.12, 0.08))
  }

  p <- ggplot2::ggplot(
    plot_df,
    ggplot2::aes(
      axis1 = phylum_label,
      axis2 = family_label,
      y = relabun
    )
  ) +
    ggalluvial::geom_alluvium(
      ggplot2::aes(fill = phylum_label),
      width = 1 / 6,
      alpha = 0.85,
      knot.pos = 0.4
    ) +
    ggalluvial::geom_stratum(
      width = 1 / 6,
      fill = "grey95",
      colour = "black",
      linewidth = 0.25
    )

  if (label_style == "internal") {
    p <- p + ggplot2::geom_text(
      stat = "stratum",
      ggplot2::aes(label = ggplot2::after_stat(stratum)),
      min.y = label_min,
      size = label_size,
      lineheight = 0.85
    )
  }

  p <- p +
    ggplot2::scale_x_discrete(
      limits = c("Phylum", "Family"),
      expand = x_expand
    ) +
    ggplot2::scale_y_continuous(
      labels = function(x) paste0(round(100 * x, 1), "%"),
      expand = if (label_style == "external") {
        ggplot2::expansion(mult = c(0.03, 0.03))
      } else {
        ggplot2::expansion(mult = c(0, 0))
      }
    ) +
    ggplot2::labs(
      x = NULL,
      y = "Mean relative abundance",
      fill = "Phylum",
      title = "Family contribution to the microbiome"
    ) +
    ggplot2::guides(
      fill = ggplot2::guide_legend(
        ncol = legend_ncol,
        byrow = legend_position == "bottom",
        override.aes = list(alpha = 1)
      )
    ) +
    theme_fn() +
    ggplot2::theme(
      legend.position = legend_position,
      legend.title = ggplot2::element_text(
        face = "bold",
        size = publication_legend_title_size(6)
      ),
      legend.text = ggplot2::element_text(
        size = publication_legend_text_size(6),
        face = "bold"
      ),
      legend.key.height = ggplot2::unit(0.35, "cm"),
      legend.key.width = ggplot2::unit(0.35, "cm"),
      legend.spacing.y = ggplot2::unit(0.1, "cm"),
      legend.box.spacing = ggplot2::unit(0.2, "cm"),
      axis.text.x = ggplot2::element_text(face = "bold"),
      plot.margin = switch(
        legend_position,
        left = ggplot2::margin(5, 5, 5, 2),
        right = ggplot2::margin(5, 2, 5, 5),
        bottom = ggplot2::margin(5, 5, 2, 5),
        none = ggplot2::margin(5, 5, 5, 5)
      )
    )

  if (!is.null(fill_vals)) {
    p <- p + ggplot2::scale_fill_manual(values = fill_vals)
  }

  if (label_style == "external") {
    if (!requireNamespace("ggrepel", quietly = TRUE)) {
      stop(
        "Package 'ggrepel' is required for external Sankey labels. ",
        "Install with install.packages('ggrepel').",
        call. = FALSE
      )
    }

    label_df <- family_sankey_stratum_labels(p, label_min = label_min)
    if (!is.null(label_df) && nrow(label_df) > 0) {
      repel_args <- list(
        inherit.aes = FALSE,
        direction = "y",
        size = label_size,
        lineheight = 0.85,
        segment.size = 0.2,
        segment.color = "grey60",
        min.segment.length = 0,
        max.overlaps = Inf,
        box.padding = 0.2,
        point.padding = 0.15,
        seed = 42
      )

      phylum_labels <- label_df %>% dplyr::filter(.data$side == "phylum")
      family_labels <- label_df %>% dplyr::filter(.data$side == "family")

      if (nrow(phylum_labels) > 0) {
        p <- p + do.call(
          ggrepel::geom_text_repel,
          c(
            list(
              data = phylum_labels,
              mapping = ggplot2::aes(
                x = .data$x,
                y = .data$ymid,
                label = .data$label
              ),
              hjust = 1,
              nudge_x = -0.1
            ),
            repel_args
          )
        )
      }

      if (nrow(family_labels) > 0) {
        p <- p + do.call(
          ggrepel::geom_text_repel,
          c(
            list(
              data = family_labels,
              mapping = ggplot2::aes(
                x = .data$x,
                y = .data$ymid,
                label = .data$label
              ),
              hjust = 0,
              nudge_x = 0.1
            ),
            repel_args
          )
        )
      }
    }
  }

  p
}

order_taxa_by_abundance <- function(summary_df, tax_col, n_top = 20) {
  summary_df %>%
    dplyr::group_by(.data[[tax_col]]) %>%
    dplyr::summarise(mean_abun = sum(relabun), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(mean_abun)) %>%
    dplyr::slice_head(n = n_top) %>%
    dplyr::pull(.data[[tax_col]])
}

create_taxonomy_jitter_plot <- function(summary_df, tax_col, facet_var = "broad_environment",
                                        n_top = 20, phylum_colors = NULL,
                                        y_lab = NULL, theme_fn = theme_publication) {
  top_taxa <- order_taxa_by_abundance(summary_df, tax_col, n_top = n_top)

  plot_df <- summary_df %>%
    dplyr::filter(.data[[tax_col]] %in% top_taxa, relabun > 0) %>%
    dplyr::mutate(
      tax_label = factor(.data[[tax_col]], levels = rev(top_taxa))
    )

  color_aes <- if (tax_col == "phylum") "tax_label" else "phylum"

  p <- plot_df %>%
    ggplot2::ggplot(ggplot2::aes(
      x = relabun,
      y = tax_label,
      colour = .data[[color_aes]]
    )) +
    ggplot2::geom_jitter(alpha = 0.55, size = 1.6, width = 0, height = 0.15) +
    ggplot2::facet_grid(
      cols = ggplot2::vars(!!rlang::sym(facet_var)),
      scales = "free_x"
    ) +
    ggplot2::labs(
      x = "Relative abundance",
      y = y_lab %||% stringr::str_to_title(tax_col),
      colour = if (tax_col == "phylum") "Phylum" else "Phylum"
    ) +
    theme_fn() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = if (tax_col == "genus") 6 else 8)
    )

  if (!is.null(phylum_colors)) {
    p <- p + ggplot2::scale_color_manual(values = phylum_colors)
  }

  p
}

prepare_dominant_mag_tile_data <- function(genome_counts, genome_metadata, sample_metadata,
                                           n_mags = 35, sample_order = NULL) {
  rel_df <- genome_counts %>%
    dplyr::mutate(dplyr::across(-genome, ~ .x / sum(.x))) %>%
    tidyr::pivot_longer(-genome, names_to = "sample", values_to = "relabun") %>%
    dplyr::left_join(
      genome_metadata %>% dplyr::select(genome, phylum, genus),
      by = "genome"
    ) %>%
    dplyr::left_join(
      sample_metadata %>% dplyr::select(sample, broad_environment),
      by = "sample"
    )

  top_mags <- rel_df %>%
    dplyr::group_by(genome) %>%
    dplyr::summarise(mean_abun = mean(relabun), .groups = "drop") %>%
    dplyr::arrange(dplyr::desc(mean_abun)) %>%
    dplyr::slice_head(n = n_mags) %>%
    dplyr::pull(genome)

  mag_order <- top_mags

  if (!is.null(sample_order)) {
    sample_levels <- sample_order
  } else {
    sample_levels <- sample_metadata %>%
      dplyr::arrange(broad_environment, sample) %>%
      dplyr::pull(sample) %>%
      unique()
  }

  rel_df %>%
    dplyr::filter(genome %in% top_mags) %>%
    dplyr::mutate(
      genome = factor(genome, levels = mag_order),
      sample = factor(sample, levels = sample_levels),
      genus_label = ifelse(genus == "g__" | is.na(genus), genome, genus)
    )
}

create_dominant_mag_tile_plot <- function(tile_df, phylum_colors = NULL,
                                          theme_fn = theme_publication) {
  if (!is.null(phylum_colors) && "phylum" %in% names(tile_df)) {
  tile_df %>%
    ggplot2::ggplot(ggplot2::aes(x = sample, y = genome, fill = phylum, alpha = relabun)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.15) +
    ggplot2::scale_fill_manual(values = phylum_colors, name = "Phylum") +
    ggplot2::scale_alpha_continuous(range = c(0.15, 1), name = "Rel. abun.", guide = "none") +
    ggplot2::facet_grid(. ~ broad_environment, scales = "free_x", space = "free_x") +
    ggplot2::labs(x = "Sample", y = "MAG") +
    theme_fn() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = 5),
      panel.grid = ggplot2::element_blank(),
      legend.position = "right"
    )
  } else {
  tile_df %>%
    ggplot2::ggplot(ggplot2::aes(x = sample, y = genome, fill = relabun)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.15) +
    ggplot2::scale_fill_gradientn(
      colours = c("#f7fbff", "#6baed6", "#08306b"),
      name = "Rel. abun.",
      limits = c(0, NA),
      oob = scales::squish
    ) +
    ggplot2::facet_grid(. ~ broad_environment, scales = "free_x", space = "free_x") +
    ggplot2::labs(x = "Sample", y = "MAG") +
    theme_fn() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_text(size = 5),
      panel.grid = ggplot2::element_blank(),
      legend.position = "right"
    )
  }
}

hmsc_spotlight_association_vars <- function() {
  c("devil", "temperature", "diversity", "devil:temperature")
}

hmsc_phylo_palette <- function() {
  list(
    purple = "#440154",
    yellow = "#FDE725"
  )
}

hmsc_trend_fill_colors <- function() {
  pal <- hmsc_phylo_palette()
  c(
    "Positive" = pal$yellow,
    "Neutral" = "grey92",
    "Negative" = pal$purple
  )
}

hmsc_trend_display_names <- function() {
  c(
    "devil" = "Devil",
    "temperature" = "Temperature",
    "diversity" = "Diversity",
    "devil:temperature" = "Interaction"
  )
}

hmsc_covariate_display_names <- function() {
  c(
    "devil" = "Devil density",
    "temperature" = "Temperature",
    "diversity" = "Diversity",
    "logseqdepth" = "log sequencing depth",
    "devil:temperature" = "Devil × temperature"
  )
}

prepare_hmsc_predictor_correlation_matrix <- function(model_obj,
                                                     method = c("pearson", "spearman", "kendall")) {
  method <- match.arg(method)
  if (is.null(model_obj$XData) || nrow(model_obj$XData) == 0L) {
    return(NULL)
  }

  formula_vars <- setdiff(model_obj$covNames, "(Intercept)")
  base_cols <- intersect(
    c("devil", "temperature", "diversity", "logseqdepth"),
    colnames(model_obj$XData)
  )
  if (length(base_cols) == 0L) {
    return(NULL)
  }

  mat <- as.data.frame(model_obj$XData)[, base_cols, drop = FALSE]
  if ("devil:temperature" %in% formula_vars &&
      all(c("devil", "temperature") %in% colnames(mat))) {
    mat$`devil:temperature` <- mat$devil * mat$temperature
  }

  keep <- intersect(formula_vars, colnames(mat))
  if (length(keep) == 0L) {
    return(NULL)
  }
  mat <- mat[, keep, drop = FALSE]

  stats::cor(mat, use = "pairwise.complete.obs", method = method)
}

create_hmsc_predictor_correlation_plot <- function(cor_mat,
                                                   display_names = hmsc_covariate_display_names(),
                                                   title = "Pearson correlations among HMSC predictors",
                                                   fill_label = "Pearson r",
                                                   theme_fn = theme_publication) {
  if (is.null(cor_mat) || ncol(cor_mat) == 0L) {
    return(NULL)
  }

  vars <- colnames(cor_mat)
  labels <- vapply(vars, function(v) display_names[[v]] %||% v, character(1))

  long <- cor_mat %>%
    as.data.frame() %>%
    tibble::rownames_to_column("var1") %>%
    tidyr::pivot_longer(-"var1", names_to = "var2", values_to = "r") %>%
    dplyr::mutate(
      var1 = factor(.data$var1, levels = vars, labels = labels),
      var2 = factor(.data$var2, levels = vars, labels = labels),
      label = sprintf("%.2f", .data$r)
    )

  pal <- hmsc_phylo_palette()
  ggplot2::ggplot(long, ggplot2::aes(x = .data$var1, y = .data$var2, fill = .data$r)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.4) +
    ggplot2::geom_text(
      ggplot2::aes(label = .data$label),
      size = 3.2,
      color = "grey15"
    ) +
    ggplot2::scale_fill_gradient2(
      low = pal$purple,
      mid = "white",
      high = pal$yellow,
      midpoint = 0,
      limits = c(-1, 1),
      name = fill_label
    ) +
    ggplot2::coord_fixed() +
    ggplot2::labs(x = NULL, y = NULL, title = title) +
    theme_fn() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid = ggplot2::element_blank()
    )
}

hmsc_beta_gradient_colors <- function() {
  pal <- hmsc_phylo_palette()
  list(
    low = pal$purple,
    mid = "white",
    high = pal$yellow
  )
}

phylo_gift_capacity_colors <- function() {
  c(low = "#f7fbff", high = "#2166AC")
}

hmsc_beta_fill_scale <- function(limits = c(-1, 1),
                                 guide = ggplot2::guide_colorbar(),
                                 na.value = "white") {
  ggplot2::scale_fill_gradientn(
    colours = functional_climate_palette(),
    limits = limits,
    breaks = c(-1, -0.5, 0, 0.5, 1),
    labels = c("-1.0", "-0.5", "0", "0.5", "1.0"),
    oob = scales::squish,
    na.value = na.value,
    guide = guide
  )
}

hmsc_beta_limits <- function(beta_matrix) {
  if (isTRUE(attr(beta_matrix, "column_scaled"))) {
    return(c(-1, 1))
  }
  lim <- max(abs(beta_matrix), na.rm = TRUE)
  if (!is.finite(lim) || lim == 0) {
    lim <- 1
  }
  c(-lim, lim)
}

spotlight_beta_ci_list <- function(devil_ci,
                                   temperature_ci,
                                   interaction_ci,
                                   diversity_ci = NULL,
                                   post_table = NULL) {
  beta_list <- list(
    devil = devil_ci,
    temperature = temperature_ci
  )
  if (!is.null(diversity_ci)) {
    beta_list$diversity <- diversity_ci
  } else if (!is.null(post_table) && "diversity" %in% colnames(post_table)) {
    beta_list$diversity <- post_table %>%
      tibble::rownames_to_column("genome") %>%
      dplyr::transmute(
        genome = .data$genome,
        mean = dplyr::case_when(
          .data$diversity == "Positive" ~ 1,
          .data$diversity == "Negative" ~ -1,
          TRUE ~ 0
        )
      )
  }
  beta_list$`devil:temperature` <- interaction_ci
  beta_list
}

prepare_spotlight_beta_matrix <- function(beta_ci_list, tip_order,
                                          post_table = NULL,
                                          variables = hmsc_spotlight_association_vars(),
                                          scale_columns = TRUE) {
  vars_present <- variables[variables %in% names(beta_ci_list)]
  if (length(vars_present) == 0) {
    return(NULL)
  }

  label_map <- hmsc_trend_display_names()
  col_labels <- vapply(vars_present, function(var) label_map[[var]] %||% var, character(1))

  mat <- matrix(
    NA_real_,
    nrow = length(tip_order),
    ncol = length(vars_present),
    dimnames = list(tip_order, col_labels)
  )

  for (i in seq_along(vars_present)) {
    beta_vals <- beta_ci_list[[vars_present[[i]]]] %>%
      dplyr::select(genome, mean) %>%
      dplyr::distinct(genome, .keep_all = TRUE)
    mat[, i] <- beta_vals$mean[match(tip_order, beta_vals$genome)]
  }

  mat <- order_matrix_by_tips(mat, tip_order)

  if (!is.null(post_table)) {
    trend_mat <- prepare_spotlight_trend_matrix(post_table, tip_order, variables = vars_present)
    for (i in seq_along(vars_present)) {
      neutral <- trend_mat[, vars_present[[i]]] == "Neutral" |
        is.na(trend_mat[, vars_present[[i]]])
      mat[neutral, i] <- NA_real_
    }
  }

  if (!scale_columns) {
    return(mat)
  }

  scaled <- mat
  for (j in seq_len(ncol(scaled))) {
    col_lim <- max(abs(scaled[, j]), na.rm = TRUE)
    if (is.finite(col_lim) && col_lim > 0) {
      scaled[, j] <- scaled[, j] / col_lim
    }
  }
  attr(scaled, "column_scaled") <- TRUE
  scaled
}

rename_trend_matrix_cols <- function(mat) {
  labels <- hmsc_trend_display_names()
  nm <- colnames(mat)
  colnames(mat) <- ifelse(nm %in% names(labels), labels[nm], nm)
  mat
}

phylo_gift_hmsc_strip_width <- function(n_cols, col_width = 0.12) {
  max(col_width, col_width * n_cols)
}

phylo_gift_hmsc_colname_fontsize <- function(n_cols) {
  if (n_cols <= 3) {
    return(2.5)
  }
  if (n_cols <= 6) {
    return(2.8)
  }
  3.2
}

compact_phylo_gift_hmsc_colnames <- function(mat) {
  nm <- colnames(mat)
  colnames(mat) <- ifelse(
    nm == "Temperature",
    "Temp.",
    ifelse(
      nm == "Diversity",
      "Div.",
      ifelse(nm == "Interaction", "Int.", nm)
    )
  )
  mat
}

phylo_gift_gift_offset <- function(hmsc_offset, hmsc_width, tree_pad = 0.54, gap = 0.06) {
  hmsc_offset + hmsc_width + tree_pad + gap
}

order_matrix_by_tips <- function(mat, tip_order) {
  tips <- intersect(tip_order, rownames(mat))
  if (length(tips) != length(tip_order)) {
    tip_order <- tip_order[tip_order %in% tips]
  }
  mat[tip_order, , drop = FALSE]
}

select_spotlight_significant_genomes <- function(post_table,
                                                 variables = hmsc_spotlight_association_vars(),
                                                 max_genomes = 120L,
                                                 method = c("stratified", "ranked")) {
  method <- match.arg(method)
  vars_present <- intersect(variables, colnames(post_table))
  if (length(vars_present) == 0) {
    return(character())
  }

  sig <- post_table %>%
    tibble::rownames_to_column("genome") %>%
    tidyr::pivot_longer(-genome, names_to = "variable", values_to = "trend") %>%
    dplyr::filter(.data$variable %in% vars_present, .data$trend != "Neutral")

  if (nrow(sig) == 0) {
    return(character())
  }

  if (method == "ranked") {
    return(sig %>%
      dplyr::count(genome, name = "n_sig", sort = TRUE) %>%
      dplyr::slice_head(n = max_genomes) %>%
      dplyr::pull(genome))
  }

  int_var <- if ("devil:temperature" %in% vars_present) "devil:temperature" else NULL
  genome_df <- post_table %>%
    tibble::rownames_to_column("genome") %>%
    dplyr::filter(.data$genome %in% unique(sig$genome))

  if (!is.null(int_var) &&
      all(c("devil", "temperature", int_var) %in% colnames(genome_df))) {
    genome_df <- genome_df %>%
      dplyr::mutate(
        pattern = classify_threeway_congruence(
          .data$devil,
          .data$temperature,
          .data[[int_var]]
        )
      )
  } else {
    genome_df <- genome_df %>%
      dplyr::mutate(pattern = "Other")
  }

  pattern_counts <- genome_df %>%
    dplyr::count(.data$pattern, name = "n_available") %>%
    dplyr::arrange(dplyr::desc(.data$n_available))

  per_pattern <- floor(max_genomes / nrow(pattern_counts))
  remainder <- max_genomes - per_pattern * nrow(pattern_counts)
  selected <- character()

  for (i in seq_len(nrow(pattern_counts))) {
    n_take <- per_pattern + if (i <= remainder) 1L else 0L
    pat_genomes <- genome_df %>%
      dplyr::filter(.data$pattern == pattern_counts$pattern[[i]]) %>%
      dplyr::arrange(.data$genome) %>%
      dplyr::slice_head(n = min(n_take, pattern_counts$n_available[[i]])) %>%
      dplyr::pull(.data$genome)
    selected <- c(selected, pat_genomes)
  }

  if (length(selected) < max_genomes) {
    remaining <- setdiff(unique(sig$genome), selected)
  } else {
    remaining <- character()
  }
  if (length(remaining) > 0 && length(selected) < max_genomes) {
    fill <- genome_df %>%
      dplyr::filter(.data$genome %in% remaining) %>%
      dplyr::arrange(.data$genome) %>%
      dplyr::slice_head(n = max_genomes - length(selected)) %>%
      dplyr::pull(.data$genome)
    selected <- c(selected, fill)
  }

  selected[seq_len(min(length(selected), max_genomes))]
}

prepare_hmsc_subtree <- function(genome_tree, genome_ids) {
  ape::keep.tip(genome_tree, tip = genome_ids) %>%
    phytools::force.ultrametric(method = "extend")
}

prepare_phylo_annotation_matrix <- function(genome_metadata, tip_order,
                                            annotation_col = "phylum") {
  genome_metadata %>%
    dplyr::filter(.data$genome %in% tip_order) %>%
    dplyr::arrange(match(.data$genome, tip_order)) %>%
    tibble::column_to_rownames("genome") %>%
    dplyr::select(dplyr::all_of(annotation_col))
}

prepare_spotlight_trend_matrix <- function(post_table, tip_order,
                                           variables = hmsc_spotlight_association_vars()) {
  vars_present <- variables[variables %in% colnames(post_table)]
  order_matrix_by_tips(post_table, tip_order)[, vars_present, drop = FALSE]
}

phylo_gift_gift_colname_fontsize <- function(n_cols) {
  if (n_cols > 100) {
    return(2.2)
  }
  if (n_cols > 60) {
    return(2.6)
  }
  if (n_cols > 30) {
    return(3)
  }
  if (n_cols > 20) {
    return(3.2)
  }
  3.8
}

phylo_gift_gift_colname_offset <- function(n_cols) {
  if (n_cols > 100) {
    return(1.4)
  }
  if (n_cols > 60) {
    return(1.1)
  }
  0.8
}

prepare_gift_element_matrix <- function(genome_gifts, tip_order, GIFT_db) {
  bundle_cols <- colnames(genome_gifts) %in% GIFT_db$Code_bundle
  mat <- genome_gifts[intersect(tip_order, rownames(genome_gifts)), bundle_cols, drop = FALSE]
  mat <- distillR::to.elements(mat, GIFT_db = GIFT_db)

  present <- colSums(mat, na.rm = TRUE) > 0
  mat <- mat[, present, drop = FALSE]

  element_order <- GIFT_db %>%
    dplyr::distinct(.data$Code_element, .keep_all = TRUE) %>%
    dplyr::filter(.data$Code_element %in% colnames(mat)) %>%
    dplyr::pull(.data$Code_element)

  mat <- mat[, intersect(element_order, colnames(mat)), drop = FALSE]
  mat <- order_matrix_by_tips(mat, tip_order)
  attr(mat, "gift_level") <- "element"
  mat
}

prepare_gift_function_matrix <- function(genome_gifts, tip_order, GIFT_db) {
  bundle_cols <- colnames(genome_gifts) %in% GIFT_db$Code_bundle
  mat <- genome_gifts[intersect(tip_order, rownames(genome_gifts)), bundle_cols, drop = FALSE]
  mat <- distillR::to.elements(mat, GIFT_db = GIFT_db)
  mat <- distillR::to.functions(mat, GIFT_db = GIFT_db)

  present <- colSums(mat, na.rm = TRUE) > 0
  mat <- mat[, present, drop = FALSE]

  func_order <- GIFT_db %>%
    dplyr::distinct(.data$Code_function, .keep_all = TRUE) %>%
    dplyr::filter(.data$Code_function %in% colnames(mat)) %>%
    dplyr::pull(.data$Code_function)

  mat <- mat[, intersect(func_order, colnames(mat)), drop = FALSE]
  mat <- order_matrix_by_tips(mat, tip_order)
  attr(mat, "gift_level") <- "function"
  mat
}

prepare_gift_heatmap_matrix <- function(genome_gifts, tip_order, GIFT_db,
                                        level = c("function", "element")) {
  level <- match.arg(level)
  if (level == "function") {
    prepare_gift_function_matrix(genome_gifts, tip_order, GIFT_db)
  } else {
    prepare_gift_element_matrix(genome_gifts, tip_order, GIFT_db)
  }
}

build_phylo_gift_fig_data <- function(genome_tree, genome_metadata, genome_gifts, GIFT_db,
                                      post_table, max_genomes = 120L,
                                      beta_ci_list = NULL,
                                      genome_selection = c("stratified", "ranked"),
                                      gift_level = c("function", "element")) {
  genome_selection <- match.arg(genome_selection)
  gift_level <- match.arg(gift_level)
  sig_genomes <- select_spotlight_significant_genomes(
    post_table,
    max_genomes = max_genomes,
    method = genome_selection
  )
  if (length(sig_genomes) == 0) {
    return(NULL)
  }

  tree <- prepare_hmsc_subtree(genome_tree, sig_genomes)
  tips <- tree$tip.label

  phylum <- prepare_phylo_annotation_matrix(genome_metadata, tips)
  post <- prepare_spotlight_trend_matrix(post_table, tips)
  beta <- if (!is.null(beta_ci_list)) {
    prepare_spotlight_beta_matrix(beta_ci_list, tips, post_table = post_table)
  } else {
    NULL
  }
  gift_mat <- prepare_gift_heatmap_matrix(genome_gifts, tips, GIFT_db, level = gift_level)
  tip_sets <- list(tips, rownames(phylum), rownames(post), rownames(gift_mat))
  if (!is.null(beta)) {
    tip_sets <- c(tip_sets, list(rownames(beta)))
  }
  tips <- Reduce(intersect, tip_sets)
  if (length(tips) == 0) {
    return(NULL)
  }
  if (length(tips) < length(tree$tip.label)) {
    tree <- prepare_hmsc_subtree(genome_tree, tips)
  }

  gift <- gift_mat[tips, , drop = FALSE]
  attr(gift, "gift_level") <- gift_level

  list(
    tree = tree,
    phylum = prepare_phylo_annotation_matrix(genome_metadata, tips),
    post = prepare_spotlight_trend_matrix(post_table, tips),
    beta = if (!is.null(beta_ci_list)) {
      prepare_spotlight_beta_matrix(beta_ci_list, tips, post_table = post_table)
    } else {
      NULL
    },
    gift = gift,
    n_genomes = length(tips),
    genome_selection = genome_selection,
    gift_level = gift_level
  )
}

phylo_gift_legend_inset_mm <- function() {
  16
}

phylo_gift_legend_base_size <- function() {
  publication_legend_text_size(7.5)
}

phylo_gift_legend_theme <- function() {
  circular_phylogeny_legend_theme(base_size = phylo_gift_legend_base_size()) +
    ggplot2::theme(
      legend.box = "vertical",
      legend.position = "left"
    )
}

phylo_gift_colorbar_guide <- function() {
  ggplot2::guide_colorbar(
    direction = "horizontal",
    barwidth = ggplot2::unit(2.5, "cm"),
    barheight = ggplot2::unit(0.4, "cm"),
    title.position = "top",
    title.hjust = 0.5,
    label.position = "bottom",
    ticks = TRUE,
    frame.colour = "grey75",
    ticks.colour = "grey50",
    label.theme = ggplot2::element_text(
      size = publication_legend_text_size(8),
      face = "bold",
      hjust = 0.5
    ),
    title.theme = ggplot2::element_text(
      size = publication_legend_title_size(8),
      face = "bold",
      hjust = 0.5
    )
  )
}

phylo_gift_stacked_colorbar_guide <- function() {
  ggplot2::guide_colorbar(
    direction = "vertical",
    barwidth = ggplot2::unit(0.5, "cm"),
    barheight = ggplot2::unit(2.8, "cm"),
    title.position = "top",
    title.hjust = 0.5,
    label.position = "right",
    ticks = TRUE,
    frame.colour = "grey75",
    ticks.colour = "grey50",
    label.theme = ggplot2::element_text(
      size = publication_legend_text_size(7.5),
      face = "bold",
      hjust = 0
    ),
    title.theme = ggplot2::element_text(
      size = publication_legend_title_size(7.5),
      face = "bold",
      hjust = 0.5,
      margin = ggplot2::margin(b = 2)
    )
  )
}

phylo_gift_stacked_legend_theme <- function() {
  circular_phylogeny_legend_theme(base_size = phylo_gift_legend_base_size()) +
    ggplot2::theme(
      legend.box = "vertical",
      legend.position = "left",
      legend.box.spacing = ggplot2::unit(4, "mm"),
      legend.spacing.y = ggplot2::unit(2.5, "mm"),
      legend.margin = ggplot2::margin(0, 0, 0, 0)
    )
}

compose_phylo_gift_figure <- function(tree_plot,
                                      legend_rel_width = 0.18,
                                      legend_source = NULL,
                                      legend_inset_mm = phylo_gift_legend_inset_mm()) {
  legend_plot <- (legend_source %||% tree_plot) + phylo_gift_legend_theme()
  g <- ggplot2::ggplotGrob(legend_plot)
  guide_idx <- which(g$layout$name == "guide-box-left")
  if (length(guide_idx) == 0) {
    guide_idx <- which(g$layout$name == "guide-box")
  }
  if (length(guide_idx) == 0) {
    return(tree_plot)
  }
  legend_grob <- g$grobs[[guide_idx[1]]]

  tree_panel <- tree_plot +
    ggplot2::theme(
      legend.position = "none",
      plot.caption = ggplot2::element_text(size = 7, colour = "grey30", hjust = 0)
    )

  legend_panel <- patchwork::wrap_elements(full = legend_grob) +
    ggplot2::theme(
      plot.margin = ggplot2::margin(0, 1, 0, legend_inset_mm, unit = "mm")
    )

  legend_panel +
    tree_panel +
    patchwork::plot_layout(widths = c(legend_rel_width, 1 - legend_rel_width))
}

create_phylo_gift_heatmap_plot <- function(phylo_tree,
                                           phylum_matrix,
                                           gift_matrix,
                                           beta_matrix = NULL,
                                           post_matrix = NULL,
                                           phylum_colors = NULL,
                                           trend_colors = hmsc_trend_fill_colors(),
                                           beta_colors = hmsc_beta_gradient_colors(),
                                           gift_colors = phylo_gift_capacity_colors(),
                                           tree_size = 0.25,
                                           show_post_heatmap = TRUE,
                                           legend_position = "left") {
  if (length(phylo_tree$tip.label) == 0 || ncol(gift_matrix) == 0) {
    return(NULL)
  }

  association_matrix <- beta_matrix %||% post_matrix
  use_continuous_beta <- !is.null(beta_matrix)

  p <- ggtree::ggtree(phylo_tree, size = tree_size)

  p <- ggtree::gheatmap(
    p, phylum_matrix,
    offset = -0.15, width = 0.08,
    colnames = FALSE
  )
  if (!is.null(phylum_colors)) {
    phylum_labels <- stats::setNames(
      format_phylum_label(names(phylum_colors)),
      names(phylum_colors)
    )
    p <- p + ggplot2::scale_fill_manual(
      values = phylum_colors,
      labels = phylum_labels,
      na.value = "grey80"
    )
  }
  p <- p + ggplot2::labs(fill = "Phylum")
  p <- p + ggnewscale::new_scale_fill()

  gift_offset <- 0.05
  hmsc_offset <- 0.02
  if (show_post_heatmap && !is.null(association_matrix) && ncol(association_matrix) > 0) {
    if (!use_continuous_beta) {
      association_matrix <- rename_trend_matrix_cols(association_matrix)
    }
    hmsc_width <- phylo_gift_hmsc_strip_width(ncol(association_matrix))
    hmsc_n_cols <- ncol(association_matrix)
    association_plot <- compact_phylo_gift_hmsc_colnames(association_matrix)
    p <- ggtree::gheatmap(
      p, association_plot,
      offset = hmsc_offset, width = hmsc_width,
      colnames = TRUE,
      colnames_position = "top",
      colnames_angle = 90,
      colnames_offset_y = 0.35,
      hjust = 0,
      font.size = phylo_gift_hmsc_colname_fontsize(hmsc_n_cols)
    )
    if (use_continuous_beta) {
      beta_lim <- hmsc_beta_limits(association_matrix)
      p <- p +
        ggplot2::scale_fill_gradient2(
          low = beta_colors$low,
          mid = beta_colors$mid,
          high = beta_colors$high,
          midpoint = 0,
          limits = beta_lim,
          breaks = c(-1, -0.5, 0, 0.5, 1),
          labels = c("-1.0", "-0.5", "0", "0.5", "1.0"),
          oob = scales::squish,
          na.value = "white",
          guide = phylo_gift_colorbar_guide()
        ) +
        ggplot2::labs(fill = "HMSC beta\n(scaled)")
    } else {
      p <- p +
        ggplot2::scale_fill_manual(values = trend_colors, drop = FALSE) +
        ggplot2::labs(fill = "HMSC trend")
    }
    p <- p + ggnewscale::new_scale_fill()
    gift_offset <- phylo_gift_gift_offset(hmsc_offset, hmsc_width)
  }

  gift_width <- min(4, max(1.5, ncol(gift_matrix) * 0.04))
  gift_n_cols <- ncol(gift_matrix)
  gift_level <- attr(gift_matrix, "gift_level") %||% "element"
  gift_display <- gift_matrix

  if (identical(gift_level, "function")) {
    gift_width <- min(2.8, max(0.9, gift_n_cols * 0.055))
  }

  gift_fill_scale <- if (identical(gift_level, "function")) {
    ggplot2::scale_fill_gradient(
      low = gift_colors["low"],
      high = gift_colors["high"],
      limits = c(0, 1),
      breaks = c(0, 0.5, 1),
      labels = c("None", "Partial", "Full"),
      na.value = "white",
      guide = phylo_gift_colorbar_guide()
    )
  } else {
    ggplot2::scale_fill_gradient(
      low = gift_colors["low"],
      high = gift_colors["high"],
      limits = c(0, 1),
      breaks = c(0, 1),
      labels = c("Absent", "Present"),
      na.value = "white",
      guide = phylo_gift_colorbar_guide()
    )
  }

  gift_fill_label <- if (identical(gift_level, "function")) {
    "GIFT function\ncapacity"
  } else {
    "GIFT element\nin MAG"
  }

  p <- ggtree::gheatmap(
    p, gift_display,
    offset = gift_offset,
    width = gift_width,
    colnames = TRUE,
    colnames_position = "top",
    colnames_angle = 90,
    colnames_offset_y = phylo_gift_gift_colname_offset(gift_n_cols),
    hjust = 0,
    font.size = phylo_gift_gift_colname_fontsize(gift_n_cols)
  ) +
    gift_fill_scale +
    ggplot2::labs(fill = gift_fill_label) +
    ggplot2::coord_cartesian(clip = "off")

  hmsc_panel_name <- if (use_continuous_beta) {
    "HMSC beta (scaled)"
  } else {
    "HMSC association"
  }
  gift_panel_name <- if (identical(gift_level, "function")) {
    "GIFT function families"
  } else {
    "GIFT elements"
  }
  p <- p +
    ggplot2::labs(
      x = NULL,
      caption = paste0(
        "Panels left to right: phylogeny, phylum, ",
        hmsc_panel_name,
        ", ",
        gift_panel_name,
        "."
      )
    ) +
    ggplot2::theme(
      axis.title.x = ggplot2::element_blank(),
      plot.caption = ggplot2::element_text(size = 7, colour = "grey30", hjust = 0),
      plot.margin = ggplot2::margin(
        t = 12 + min(18, gift_n_cols * 0.06),
        r = 20,
        b = 14,
        l = 2
      )
    ) +
    ggtree::vexpand(min(0.14, 0.05 + gift_n_cols * 0.0007), direction = 1)

  if (identical(legend_position, "left")) {
    compose_phylo_gift_figure(p)
  } else {
    p +
      ggplot2::theme(
        legend.position = legend_position,
        plot.margin = ggplot2::margin(8, 20, 14, 5)
      )
  }
}

phylo_gift_tip_x_positions <- function(phylo_tree, tree_size = 0.25) {
  p <- ggtree::ggtree(phylo_tree, size = tree_size) +
    ggplot2::coord_flip() +
    ggplot2::scale_x_reverse()
  # After coord_flip tips spread along data$y, which maps to the horizontal axis.
  p$data %>%
    dplyr::filter(.data$isTip) %>%
    dplyr::arrange(.data$y) %>%
    dplyr::transmute(genome = .data$label, x = .data$y)
}

phylo_gift_stacked_x_limits <- function(tip_pos, pad = 0.5) {
  xr <- range(tip_pos$x, na.rm = TRUE)
  c(xr[1] - pad, xr[2] + pad)
}

phylo_gift_stacked_x_scale <- function(tip_pos) {
  ggplot2::scale_x_continuous(
    limits = phylo_gift_stacked_x_limits(tip_pos),
    expand = c(0, 0)
  )
}

phylo_gift_tile_width <- function(tip_pos) {
  xs <- sort(tip_pos$x)
  if (length(xs) < 2L) {
    return(0.5)
  }
  spacing <- stats::median(diff(xs), na.rm = TRUE)
  if (!is.finite(spacing) || spacing <= 0) {
    return(0.5)
  }
  min(0.9, max(0.12, spacing * 0.85))
}

phylo_gift_row_labels <- function(codes, GIFT_db, gift_level = c("function", "element")) {
  gift_level <- match.arg(gift_level)
  if (gift_level == "element") {
    lookup <- GIFT_db %>%
      dplyr::distinct(.data$Code_element, .data$Element, .data$Function) %>%
      dplyr::mutate(
        label = dplyr::if_else(
          is.na(.data$Element) | .data$Element == "",
          .data$Code_element,
          .data$Element
        )
      )
    labels <- lookup$label[match(codes, lookup$Code_element)]
  } else {
    lookup <- GIFT_db %>%
      dplyr::distinct(.data$Code_function, .data$Function)
    labels <- lookup$Function[match(codes, lookup$Code_function)]
  }
  labels[is.na(labels)] <- codes[is.na(labels)]
  trunc_len <- if (gift_level == "element") 48L else 42L
  stringr::str_trunc(labels, trunc_len, "right")
}

phylo_gift_gift_stack_height <- function(n_gift, gift_level = c("function", "element")) {
  gift_level <- match.arg(gift_level)
  if (identical(gift_level, "element")) {
    return(max(3, min(10, 1.2 + n_gift * 0.055)))
  }
  max(1.8, min(5.5, 0.9 + n_gift * 0.045))
}

phylo_gift_stacked_row_fontsize <- function(n_rows) {
  if (n_rows > 120) {
    return(5.5)
  }
  if (n_rows > 80) {
    return(6)
  }
  if (n_rows > 50) {
    return(6.5)
  }
  if (n_rows > 30) {
    return(7)
  }
  7.5
}

phylo_gift_hmsc_row_fontsize <- function(n_rows) {
  if (n_rows <= 4L) {
    return(8)
  }
  phylo_gift_stacked_row_fontsize(n_rows)
}

phylo_gift_stacked_tree_plot <- function(phylo_tree, tree_size = 0.25, tip_pos = NULL) {
  p <- ggtree::ggtree(phylo_tree, size = tree_size) +
    ggplot2::coord_flip() +
    # Hang the tree downward: tips at the bottom, root at the top.
    ggplot2::scale_x_reverse()
  # Tip spread lives in data$y; after coord_flip that maps to the horizontal axis.
  if (!is.null(tip_pos) && nrow(tip_pos) > 0L) {
    p <- p + ggplot2::scale_y_continuous(
      limits = phylo_gift_stacked_x_limits(tip_pos),
      expand = c(0, 0)
    )
  }
  p +
    ggplot2::theme(
      plot.margin = ggplot2::margin(2, 2, 0, 2),
      legend.position = "none"
    )
}

phylo_gift_stacked_strip_theme <- function() {
  ggplot2::theme_minimal() +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank(),
      axis.title.x = ggplot2::element_blank(),
      axis.title.y = ggplot2::element_text(
        angle = 90,
        size = 8,
        face = "bold",
        margin = ggplot2::margin(r = 4)
      ),
      plot.margin = ggplot2::margin(0, 2, 0, 2),
      legend.position = "none"
    )
}

phylo_gift_aligned_matrix_plot <- function(tip_pos,
                                           mat,
                                           row_levels = colnames(mat),
                                           row_labels = row_levels,
                                           tile_width = phylo_gift_tile_width(tip_pos),
                                           row_height = NULL,
                                           fill_scale,
                                           ylab = NULL,
                                           y_text_size = NULL) {
  if (ncol(mat) == 0L || nrow(mat) == 0L) {
    return(NULL)
  }

  mat <- mat[tip_pos$genome, , drop = FALSE]
  n_rows <- ncol(mat)
  if (is.null(row_height)) {
    row_height <- if (n_rows <= 1L) {
      0.45
    } else if (n_rows <= 4L) {
      0.55
    } else if (n_rows > 80L) {
      0.82
    } else if (n_rows > 30L) {
      0.9
    } else {
      1
    }
  }
  if (is.null(y_text_size)) {
    y_text_size <- phylo_gift_stacked_row_fontsize(n_rows)
  }

  long <- as.data.frame(mat) %>%
    tibble::rownames_to_column("genome") %>%
    tidyr::pivot_longer(-genome, names_to = "row_var", values_to = "value") %>%
    dplyr::left_join(tip_pos, by = "genome") %>%
    dplyr::mutate(
      row_var = factor(.data$row_var, levels = row_levels),
      row_idx = as.numeric(.data$row_var),
      y = (.data$row_idx - 0.5) * row_height
    )

  show_y_labels <- length(row_labels) > 0L &&
    any(nzchar(as.character(row_labels)))
  y_breaks <- if (show_y_labels) {
    seq(row_height / 2, (n_rows - 0.5) * row_height, by = row_height)
  } else {
    NULL
  }
  y_labels <- if (show_y_labels) {
    row_labels[match(row_levels, row_levels)]
  } else {
    NULL
  }

  ggplot2::ggplot(long, ggplot2::aes(x = .data$x, y = .data$y, fill = .data$value)) +
    ggplot2::geom_tile(
      width = tile_width,
      height = row_height * 0.95,
      colour = NA
    ) +
    fill_scale +
    phylo_gift_stacked_x_scale(tip_pos) +
    ggplot2::scale_y_continuous(
      breaks = y_breaks,
      labels = y_labels,
      expand = ggplot2::expansion(mult = c(0.02, 0.02))
    ) +
    phylo_gift_stacked_strip_theme() +
    ggplot2::theme(
      axis.text.y = if (show_y_labels) {
        ggplot2::element_text(size = y_text_size)
      } else {
        ggplot2::element_blank()
      },
      axis.ticks.y = if (show_y_labels) {
        ggplot2::element_line()
      } else {
        ggplot2::element_blank()
      }
    ) +
    ggplot2::labs(x = NULL, y = ylab, fill = NULL)
}

phylo_gift_stacked_legend_geom <- function() {
  list(
    swatch_x = 0.14,
    swatch_w = 0.06,
    label_x = 0.21,
    title_x = 0.1,
    xlim = c(0.08, 1)
  )
}

phylo_gift_stacked_legend_colors <- function(values,
                                             low,
                                             high,
                                             limits,
                                             mid = NULL,
                                             midpoint = 0) {
  values <- pmax(limits[1], pmin(limits[2], values))
  vapply(values, function(value) {
    rgb_vals <- if (!is.null(mid)) {
      if (value <= midpoint) {
        denom <- midpoint - limits[1]
        t <- if (denom == 0) 0 else (value - limits[1]) / denom
        grDevices::colorRamp(c(low, mid))(t)
      } else {
        denom <- limits[2] - midpoint
        t <- if (denom == 0) 1 else (value - midpoint) / denom
        grDevices::colorRamp(c(mid, high))(t)
      }
    } else {
      normed <- (value - limits[1]) / diff(limits)
      grDevices::colorRamp(c(low, high))(normed)
    }
    grDevices::rgb(rgb_vals, maxColorValue = 255)
  }, character(1))
}

phylo_gift_stacked_gradient_legend_layers <- function(y_base,
                                                      title,
                                                      limits,
                                                      breaks,
                                                      labels,
                                                      low,
                                                      high,
                                                      mid = NULL,
                                                      midpoint = 0,
                                                      n_steps = 48L) {
  geom <- phylo_gift_stacked_legend_geom()
  row_h <- 0.085
  vals <- seq(limits[1], limits[2], length.out = n_steps)
  tile_df <- tibble::tibble(
    x = geom$swatch_x,
    y = y_base + seq_along(vals) * row_h,
    fill = phylo_gift_stacked_legend_colors(
      values = vals,
      low = low,
      high = high,
      limits = limits,
      mid = mid,
      midpoint = midpoint
    ),
    kind = "gradient"
  )
  y_range <- range(tile_df$y)
  break_df <- tibble::tibble(
    x = geom$label_x,
    label = labels,
    y = y_range[1] + (breaks - limits[1]) / diff(limits) * diff(y_range)
  )
  title_df <- tibble::tibble(
    x = geom$title_x,
    y = y_range[2] + 0.55,
    label = title
  )
  list(
    tiles = tile_df,
    labels = break_df,
    title = title_df,
    y_top = title_df$y[1] + 0.2
  )
}

phylo_gift_stacked_phylum_legend_layers <- function(y_base,
                                                    phylum_colors,
                                                    present_phyla = NULL) {
  geom <- phylo_gift_stacked_legend_geom()
  phylum_names <- names(phylum_colors)
  if (!is.null(present_phyla)) {
    present_phyla <- unique(as.character(present_phyla))
    phylum_names <- intersect(phylum_names, present_phyla)
  }
  if (length(phylum_names) == 0L) {
    return(NULL)
  }

  row_height <- 0.52
  tile_df <- tibble::tibble(
    x = geom$swatch_x,
    y = y_base + seq_along(phylum_names) * row_height,
    fill = unname(phylum_colors[phylum_names]),
    kind = "phylum"
  )
  label_df <- tibble::tibble(
    x = geom$label_x,
    y = tile_df$y,
    label = format_phylum_label(phylum_names)
  )
  title_df <- tibble::tibble(
    x = geom$title_x,
    y = max(tile_df$y) + 0.55,
    label = "Phylum"
  )
  list(
    tiles = tile_df,
    labels = label_df,
    title = title_df,
    y_top = title_df$y[1] + 0.2
  )
}

phylo_gift_stacked_legend_plot <- function(phylum_colors = NULL,
                                           present_phyla = NULL,
                                           beta_colors = NULL,
                                           beta_lim = NULL,
                                           gift_colors = NULL,
                                           gift_level = c("function", "element"),
                                           show_hmsc = TRUE) {
  gift_level <- match.arg(gift_level)
  geom <- phylo_gift_stacked_legend_geom()
  gap <- 0.85
  y_base <- 0
  tile_parts <- list()
  label_parts <- list()
  title_parts <- list()

  if (!is.null(gift_colors)) {
    gift_layer <- if (identical(gift_level, "function")) {
      phylo_gift_stacked_gradient_legend_layers(
        y_base = y_base,
        title = "GIFT function capacity",
        limits = c(0, 1),
        breaks = c(0, 0.5, 1),
        labels = c("None", "Partial", "Full"),
        low = gift_colors["low"],
        high = gift_colors["high"]
      )
    } else {
      phylo_gift_stacked_gradient_legend_layers(
        y_base = y_base,
        title = "GIFT element in MAG",
        limits = c(0, 1),
        breaks = c(0, 1),
        labels = c("Absent", "Present"),
        low = gift_colors["low"],
        high = gift_colors["high"]
      )
    }
    tile_parts <- c(tile_parts, list(gift_layer$tiles))
    label_parts <- c(label_parts, list(gift_layer$labels))
    title_parts <- c(title_parts, list(gift_layer$title))
    y_base <- gift_layer$y_top + gap
  }

  if (isTRUE(show_hmsc) && !is.null(beta_colors) && !is.null(beta_lim)) {
    hmsc_layer <- phylo_gift_stacked_gradient_legend_layers(
      y_base = y_base,
      title = "HMSC beta (scaled)",
      limits = beta_lim,
      breaks = c(-1, -0.5, 0, 0.5, 1),
      labels = c("-1.0", "-0.5", "0", "0.5", "1.0"),
      low = beta_colors$low,
      mid = beta_colors$mid,
      high = beta_colors$high
    )
    tile_parts <- c(tile_parts, list(hmsc_layer$tiles))
    label_parts <- c(label_parts, list(hmsc_layer$labels))
    title_parts <- c(title_parts, list(hmsc_layer$title))
    y_base <- hmsc_layer$y_top + gap
  }

  if (!is.null(phylum_colors) && length(phylum_colors) > 0L) {
    phylum_layer <- phylo_gift_stacked_phylum_legend_layers(
      y_base = y_base,
      phylum_colors = phylum_colors,
      present_phyla = present_phyla
    )
    if (!is.null(phylum_layer)) {
      tile_parts <- c(tile_parts, list(phylum_layer$tiles))
      label_parts <- c(label_parts, list(phylum_layer$labels))
      title_parts <- c(title_parts, list(phylum_layer$title))
      y_base <- phylum_layer$y_top
    }
  }

  if (length(tile_parts) == 0L) {
    return(NULL)
  }

  tile_df <- dplyr::bind_rows(tile_parts)
  label_df <- dplyr::bind_rows(label_parts)
  title_df <- dplyr::bind_rows(title_parts)
  tile_df$height <- ifelse(
    tile_df$kind == "gradient",
    0.085 * 0.92,
    0.52 * 0.82
  )
  y_min <- min(tile_df$y) - max(tile_df$height) / 2
  y_max <- max(title_df$y) + 0.2

  ggplot2::ggplot() +
    ggplot2::geom_tile(
      data = tile_df,
      ggplot2::aes(x = .data$x, y = .data$y),
      fill = tile_df$fill,
      width = geom$swatch_w,
      height = tile_df$height,
      colour = NA
    ) +
    ggplot2::geom_text(
      data = label_df,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$label),
      hjust = 0,
      size = publication_legend_geom_text_mm(2.85),
      inherit.aes = FALSE
    ) +
    ggplot2::geom_text(
      data = title_df,
      ggplot2::aes(x = .data$x, y = .data$y, label = .data$label),
      hjust = 0,
      fontface = "bold",
      size = publication_legend_geom_text_mm(3.2),
      inherit.aes = FALSE
    ) +
    ggplot2::scale_x_continuous(limits = geom$xlim, expand = c(0, 0)) +
    ggplot2::scale_y_continuous(limits = c(y_min, y_max), expand = c(0, 0)) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.margin = ggplot2::margin(0, 0, 0, phylo_gift_legend_inset_mm(), unit = "mm")
    )
}

build_phylo_gift_phylum_legend_grob <- function(phylum_colors, present_phyla = NULL) {
  phylo_gift_phylum_legend_plot(phylum_colors, present_phyla = present_phyla)
}

compose_phylo_gift_stacked_legends <- function(phylum_colors = NULL,
                                               present_phyla = NULL,
                                               hmsc_fill_scale = NULL,
                                               hmsc_fill_label = NULL,
                                               gift_fill_scale = NULL,
                                               gift_fill_label = NULL,
                                               beta_colors = NULL,
                                               beta_lim = NULL,
                                               gift_colors = NULL,
                                               gift_level = c("function", "element"),
                                               hmsc_values = c(-1, 0, 1),
                                               gift_values = c(0, 0.5, 1)) {
  gift_level <- match.arg(gift_level)
  phylo_gift_stacked_legend_plot(
    phylum_colors = phylum_colors,
    present_phyla = present_phyla,
    beta_colors = if (!is.null(hmsc_fill_scale)) beta_colors else NULL,
    beta_lim = if (!is.null(hmsc_fill_scale)) beta_lim else NULL,
    gift_colors = gift_colors,
    gift_level = gift_level,
    show_hmsc = !is.null(hmsc_fill_scale)
  )
}

compose_phylo_gift_stacked_figure <- function(combo,
                                              legend_grob,
                                              legend_rel_width = 0.17,
                                              legend_inset_frac = 0.18) {
  main_grob <- grid::grid.grabExpr(print(combo))
  legend_raw <- grid::grid.grabExpr(print(legend_grob))
  legend_panel <- cowplot::ggdraw() +
    cowplot::draw_plot(
      legend_raw,
      x = legend_inset_frac,
      y = 0,
      width = 1 - legend_inset_frac,
      height = 1
    )
  cowplot::plot_grid(
    legend_panel,
    main_grob,
    ncol = 2,
    rel_widths = c(legend_rel_width, 1 - legend_rel_width),
    align = "h",
    axis = "lr"
  )
}

phylo_gift_legend_only_plot <- function(fill_scale, fill_label, values = c(0, 1)) {
  legend_df <- data.frame(
    x = 1,
    y = seq_along(values),
    value = values
  )
  ggplot2::ggplot(legend_df, ggplot2::aes(x = .data$x, y = .data$y, fill = .data$value)) +
    ggplot2::geom_tile(alpha = 0) +
    fill_scale +
    ggplot2::labs(fill = fill_label) +
    ggplot2::theme_void() +
    phylo_gift_stacked_legend_theme()
}

phylo_gift_phylum_legend_plot <- function(phylum_colors, present_phyla = NULL) {
  phylum_names <- names(phylum_colors)
  if (!is.null(present_phyla)) {
    present_phyla <- unique(as.character(present_phyla))
    phylum_names <- intersect(phylum_names, present_phyla)
  }
  if (length(phylum_names) == 0L) {
    return(NULL)
  }

  geom <- phylo_gift_stacked_legend_geom()
  phylum_labels <- format_phylum_label(phylum_names)
  row_height <- 0.52
  legend_df <- tibble::tibble(
    y = seq_along(phylum_names) * row_height,
    label = phylum_labels,
    fill_color = unname(phylum_colors[phylum_names])
  )
  title_y <- max(legend_df$y) + 0.55

  ggplot2::ggplot() +
    ggplot2::annotate(
      "text",
      x = geom$title_x,
      y = title_y,
      label = "Phylum",
      hjust = 0,
      fontface = "bold",
      size = publication_legend_geom_text_mm(3.2)
    ) +
    ggplot2::geom_tile(
      data = legend_df,
      ggplot2::aes(x = geom$swatch_x, y = .data$y, fill = .data$fill_color),
      width = geom$swatch_w,
      height = row_height * 0.82,
      colour = NA
    ) +
    ggplot2::geom_text(
      data = legend_df,
      ggplot2::aes(x = geom$label_x, y = .data$y, label = .data$label),
      hjust = 0,
      size = publication_legend_geom_text_mm(2.85)
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::scale_x_continuous(limits = geom$xlim, expand = c(0, 0)) +
    ggplot2::scale_y_continuous(limits = c(row_height * 0.45, title_y + 0.2), expand = c(0, 0)) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.margin = ggplot2::margin(0, 0, 0, phylo_gift_legend_inset_mm(), unit = "mm")
    )
}

phylo_gift_stack_aligned_panels <- function(panels, heights) {
  if (!requireNamespace("aplot", quietly = TRUE)) {
    stop(
      "Package 'aplot' is required for stacked phylo + GIFT heatmaps.",
      call. = FALSE
    )
  }
  keep <- !vapply(panels, is.null, logical(1L))
  panels <- panels[keep]
  heights <- heights[keep]
  if (length(panels) == 0L) {
    return(NULL)
  }
  combo <- panels[[1]]
  if (length(panels) > 1L) {
    for (i in seq(2, length(panels))) {
      combo <- combo %>%
        aplot::insert_bottom(panels[[i]], height = heights[[i]])
    }
  }
  combo
}

create_phylo_gift_heatmap_plot_stacked <- function(phylo_tree,
                                                   phylum_matrix,
                                                   gift_matrix,
                                                   GIFT_db = NULL,
                                                   beta_matrix = NULL,
                                                   post_matrix = NULL,
                                                   phylum_colors = NULL,
                                                   trend_colors = hmsc_trend_fill_colors(),
                                                   beta_colors = hmsc_beta_gradient_colors(),
                                                   gift_colors = phylo_gift_capacity_colors(),
                                                   tree_size = 0.25,
                                                   show_post_heatmap = TRUE,
                                                   legend_position = "left") {
  if (length(phylo_tree$tip.label) == 0L || ncol(gift_matrix) == 0L) {
    return(NULL)
  }

  tip_pos <- phylo_gift_tip_x_positions(phylo_tree, tree_size = tree_size)
  tile_width <- phylo_gift_tile_width(tip_pos)
  gift_level <- attr(gift_matrix, "gift_level") %||% "element"
  gift_codes <- colnames(gift_matrix)
  gift_labels <- if (!is.null(GIFT_db)) {
    phylo_gift_row_labels(gift_codes, GIFT_db, gift_level = gift_level)
  } else {
    gift_codes
  }

  tree_plot <- phylo_gift_stacked_tree_plot(
    phylo_tree,
    tree_size = tree_size,
    tip_pos = tip_pos
  )

  phylum_fill_scale <- if (!is.null(phylum_colors)) {
    phylum_labels <- stats::setNames(
      format_phylum_label(names(phylum_colors)),
      names(phylum_colors)
    )
    ggplot2::scale_fill_manual(
      values = phylum_colors,
      labels = phylum_labels,
      na.value = "grey80"
    )
  } else {
    ggplot2::scale_fill_grey(na.value = "grey80")
  }

  phylum_plot <- phylo_gift_aligned_matrix_plot(
    tip_pos = tip_pos,
    mat = phylum_matrix,
    row_levels = colnames(phylum_matrix),
    row_labels = character(0),
    tile_width = tile_width,
    row_height = 0.4,
    fill_scale = phylum_fill_scale,
    ylab = NULL
  )

  present_phyla <- unique(as.character(phylum_matrix[, 1, drop = TRUE]))

  association_matrix <- beta_matrix %||% post_matrix
  use_continuous_beta <- !is.null(beta_matrix)
  hmsc_plot <- NULL
  hmsc_fill_scale <- NULL
  hmsc_fill_label <- NULL
  beta_lim <- NULL
  if (show_post_heatmap && !is.null(association_matrix) && ncol(association_matrix) > 0) {
    if (!use_continuous_beta) {
      association_matrix <- rename_trend_matrix_cols(association_matrix)
    }
    hmsc_fill_scale <- if (use_continuous_beta) {
      beta_lim <- hmsc_beta_limits(association_matrix)
      hmsc_fill_label <- "HMSC beta (scaled)"
      ggplot2::scale_fill_gradient2(
        low = beta_colors$low,
        mid = beta_colors$mid,
        high = beta_colors$high,
        midpoint = 0,
        limits = beta_lim,
        breaks = c(-1, -0.5, 0, 0.5, 1),
        labels = c("-1.0", "-0.5", "0", "0.5", "1.0"),
        oob = scales::squish,
        na.value = "white",
        guide = phylo_gift_stacked_colorbar_guide()
      )
    } else {
      hmsc_fill_label <- "HMSC trend"
      ggplot2::scale_fill_manual(values = trend_colors, drop = FALSE)
    }
    hmsc_plot <- phylo_gift_aligned_matrix_plot(
      tip_pos = tip_pos,
      mat = association_matrix,
      row_levels = colnames(association_matrix),
      row_labels = colnames(association_matrix),
      tile_width = tile_width,
      row_height = 0.72,
      fill_scale = hmsc_fill_scale,
      ylab = NULL,
      y_text_size = phylo_gift_hmsc_row_fontsize(ncol(association_matrix))
    )
  }

  gift_fill_scale <- if (identical(gift_level, "function")) {
    ggplot2::scale_fill_gradient(
      low = gift_colors["low"],
      high = gift_colors["high"],
      limits = c(0, 1),
      breaks = c(0, 0.5, 1),
      labels = c("None", "Partial", "Full"),
      na.value = "white",
      guide = phylo_gift_stacked_colorbar_guide()
    )
  } else {
    ggplot2::scale_fill_gradient(
      low = gift_colors["low"],
      high = gift_colors["high"],
      limits = c(0, 1),
      breaks = c(0, 1),
      labels = c("Absent", "Present"),
      na.value = "white",
      guide = phylo_gift_stacked_colorbar_guide()
    )
  }
  gift_fill_label <- if (identical(gift_level, "function")) {
    "GIFT function capacity"
  } else {
    "GIFT element in MAG"
  }
  gift_ylab <- if (identical(gift_level, "function")) {
    "GIFT function families"
  } else {
    "GIFT elements"
  }

  gift_plot <- phylo_gift_aligned_matrix_plot(
    tip_pos = tip_pos,
    mat = gift_matrix,
    row_levels = gift_codes,
    row_labels = gift_labels,
    tile_width = tile_width,
    fill_scale = gift_fill_scale,
    ylab = gift_ylab
  )
  gift_plot <- gift_plot +
    ggplot2::labs(fill = gift_fill_label) +
    ggplot2::theme(
      plot.margin = ggplot2::margin(0, 2, 4, 2),
      legend.position = if (identical(legend_position, "left")) {
        "none"
      } else {
        legend_position
      }
    )

  n_gift <- ncol(gift_matrix)
  gift_stack_height <- phylo_gift_gift_stack_height(n_gift, gift_level = gift_level)
  stack_panels <- list(tree_plot, phylum_plot, hmsc_plot, gift_plot)
  stack_heights <- c(2.2, 0.12, 0.28, gift_stack_height)
  if (is.null(hmsc_plot)) {
    stack_panels <- stack_panels[c(1L, 2L, 4L)]
    stack_heights <- stack_heights[c(1L, 2L, 4L)]
  }
  combo <- phylo_gift_stack_aligned_panels(
    panels = stack_panels,
    heights = as.list(stack_heights)
  )
  if (is.null(combo)) {
    return(NULL)
  }

  if (identical(legend_position, "left")) {
    legend_grob <- compose_phylo_gift_stacked_legends(
      phylum_colors = phylum_colors,
      present_phyla = present_phyla,
      hmsc_fill_scale = hmsc_fill_scale,
      hmsc_fill_label = hmsc_fill_label,
      gift_fill_scale = gift_fill_scale,
      gift_fill_label = gift_fill_label,
      beta_colors = if (use_continuous_beta) beta_colors else NULL,
      beta_lim = if (use_continuous_beta) beta_lim else NULL,
      gift_colors = gift_colors,
      gift_level = gift_level
    )
    combo <- compose_phylo_gift_stacked_figure(
      combo = combo,
      legend_grob = legend_grob,
      legend_rel_width = 0.17
    )
    attr(combo, "phylo_gift_stacked_figure") <- TRUE
  }

  combo
}

phylo_gift_stacked_figure_dims <- function(n_genomes,
                                           n_gift_rows,
                                           gift_level = c("function", "element"),
                                           width_mm = 200,
                                           min_height_mm = 250,
                                           max_height_mm = NULL,
                                           legend_width_mm = 52) {
  gift_level <- match.arg(gift_level)
  if (is.null(max_height_mm)) {
    max_height_mm <- if (identical(gift_level, "element")) 620 else 460
  }
  row_mm <- if (identical(gift_level, "element")) 2.35 else 3.2
  list(
    width_mm = legend_width_mm + max(width_mm, min(380, width_mm + n_genomes * 2.2)),
    height_mm = max(
      min_height_mm,
      min(max_height_mm, 150 + n_gift_rows * row_mm + min(70, n_genomes * 0.2))
    )
  )
}

phylo_gift_figure_dims <- function(n_genomes, n_gift_elements,
                                   width_mm = 200, min_height_mm = 200,
                                   max_height_mm = 320, legend_width_mm = 32) {
  list(
    width_mm = legend_width_mm + max(width_mm, min(260, width_mm + n_gift_elements * 0.6)),
    height_mm = max(
      min_height_mm,
      min(max_height_mm, 1.6 * n_genomes + 40 + min(24, n_gift_elements * 0.08))
    )
  )
}

hmsc_interaction_var <- function() {
  "devil:temperature"
}

classify_threeway_congruence <- function(devil, temperature, interaction) {
  dplyr::case_when(
    devil == "Neutral" | temperature == "Neutral" | interaction == "Neutral" ~ "Incomplete",
    devil == temperature & temperature == interaction ~ "Triple congruent",
    devil == temperature & interaction != temperature ~
      "Main effects congruent, interaction discordant",
    devil != temperature ~ "Main effects discordant",
    TRUE ~ "Other"
  )
}

prepare_threeway_congruence_genomes <- function(post_table, genome_metadata) {
  int_col <- hmsc_interaction_var()

  post_table %>%
    tibble::rownames_to_column("genome") %>%
    dplyr::select(genome, devil, temperature, dplyr::all_of(int_col)) %>%
    dplyr::rename(interaction = dplyr::all_of(int_col)) %>%
    dplyr::left_join(
      genome_metadata %>% dplyr::select(genome, phylum),
      by = "genome"
    ) %>%
    dplyr::mutate(
      pattern = classify_threeway_congruence(devil, temperature, interaction),
      triple_sig = devil != "Neutral" & temperature != "Neutral" & interaction != "Neutral",
      triple_congruent = triple_sig & devil == temperature & temperature == interaction
    )
}

summarise_threeway_congruence <- function(genome_df) {
  genome_df %>%
    dplyr::count(pattern, name = "n") %>%
    dplyr::mutate(
      pattern = factor(
        pattern,
        levels = c(
          "Triple congruent",
          "Main effects congruent, interaction discordant",
          "Main effects discordant",
          "Incomplete",
          "Other"
        )
      )
    )
}

prepare_threeway_congruence_taxa <- function(genome_df) {
  genome_df %>%
    dplyr::filter(triple_sig) %>%
    dplyr::mutate(
      combo_congruence = ifelse(
        devil == temperature & temperature == interaction,
        "Triple congruent",
        "Triple discordant"
      )
    ) %>%
    dplyr::count(phylum, devil, temperature, interaction, combo_congruence, name = "n")
}

threeway_pattern_colors <- function(spotlight_cols = spotlight_palettes()) {
  c(
    "Triple congruent" = spotlight_cols$congruent,
    "Main effects congruent, interaction discordant" = spotlight_cols$interaction,
    "Main effects discordant" = spotlight_cols$discordant,
    "Incomplete" = spotlight_cols$neutral,
    "Other" = "grey55"
  )
}

create_threeway_congruence_summary_plot <- function(summary_df,
                                                  spotlight_cols = spotlight_palettes(),
                                                  theme_fn = theme_publication) {
  fill_cols <- threeway_pattern_colors(spotlight_cols)

  summary_df %>%
    dplyr::filter(!is.na(pattern), n > 0) %>%
    ggplot2::ggplot(ggplot2::aes(x = n, y = pattern, fill = pattern)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::scale_fill_manual(values = fill_cols, guide = "none") +
    ggplot2::labs(
      x = "Genomes",
      y = NULL,
      title = "Three-way association patterns"
    ) +
    theme_fn()
}

create_threeway_interaction_tile_plot <- function(genome_df,
                                                congruence_colors = spotlight_palettes(),
                                                theme_fn = theme_publication) {
  plot_data <- genome_df %>%
    dplyr::filter(triple_sig) %>%
    dplyr::mutate(
      interaction = factor(interaction, levels = c("Positive", "Negative")),
      devil = factor(devil, levels = c("Positive", "Negative")),
      temperature = factor(temperature, levels = c("Positive", "Negative")),
      main_congruence = ifelse(devil == temperature, "Congruent", "Discordant")
    ) %>%
    dplyr::count(interaction, devil, temperature, main_congruence, name = "n")

  if (nrow(plot_data) == 0) {
    return(NULL)
  }

  plot_data %>%
    ggplot2::ggplot(ggplot2::aes(
      x = devil,
      y = temperature,
      fill = main_congruence,
      alpha = n
    )) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.4) +
    ggplot2::facet_wrap(~interaction, labeller = ggplot2::labeller(
      interaction = c(
        "Positive" = "Interaction (+)",
        "Negative" = "Interaction (-)"
      )
    )) +
    ggplot2::scale_fill_manual(
      values = c(
        "Congruent" = congruence_colors$congruent,
        "Discordant" = congruence_colors$discordant
      ),
      name = "Devil vs temperature"
    ) +
    ggplot2::scale_alpha_continuous(range = c(0.25, 1), guide = "none") +
    ggplot2::labs(
      x = "Devil association",
      y = "Temperature association",
      title = "Triple-supported genomes"
    ) +
    theme_fn(base_size = 8)
}

create_threeway_phylum_congruence_plot <- function(genome_df,
                                                  phylum_colors = NULL,
                                                  n_top = 8,
                                                  theme_fn = theme_publication) {
  plot_data <- genome_df %>%
    dplyr::filter(triple_sig) %>%
    dplyr::mutate(
      combo_congruence = ifelse(
        devil == temperature & temperature == interaction,
        "Triple congruent",
        "Triple discordant"
      )
    ) %>%
    dplyr::group_by(phylum) %>%
    dplyr::summarise(
      congruent = sum(combo_congruence == "Triple congruent"),
      discordant = sum(combo_congruence == "Triple discordant"),
      total = dplyr::n(),
      .groups = "drop"
    ) %>%
    dplyr::slice_max(total, n = n_top) %>%
    tidyr::pivot_longer(
      c(congruent, discordant),
      names_to = "category",
      values_to = "n"
    ) %>%
    dplyr::mutate(
      category = dplyr::recode(category,
        congruent = "Triple congruent",
        discordant = "Triple discordant"
      ),
      category = factor(category, levels = c("Triple congruent", "Triple discordant"))
    )

  if (nrow(plot_data) == 0) {
    return(NULL)
  }

  plot_data %>%
    ggplot2::ggplot(ggplot2::aes(x = n, y = phylum, fill = category)) +
    ggplot2::geom_col(position = "stack", width = 0.7) +
    ggplot2::scale_fill_manual(
      values = c(
        "Triple congruent" = spotlight_palettes()$congruent,
        "Triple discordant" = spotlight_palettes()$discordant
      ),
      name = NULL
    ) +
    ggplot2::labs(
      x = "Genomes",
      y = NULL,
      title = "Phylum breakdown (triple-supported)"
    ) +
    theme_fn(base_size = 8)
}

load_australia_map_sf <- function() {
  rnaturalearth::ne_countries(scale = "medium", returnclass = "sf") %>%
    dplyr::filter(admin == "Australia")
}

prepare_study_map_points <- function(sample_metadata,
                                     sample_points,
                                     env_variables = NULL,
                                     island = NULL) {
  map_df <- sample_metadata %>%
    dplyr::select(
      sample,
      dplyr::any_of(c("broad_environment", "island"))
    )

  if (!is.null(island)) {
    map_df <- map_df %>%
      dplyr::filter(.data$island == .env$island)
  }

  map_df <- map_df %>%
    dplyr::left_join(
      sample_points %>% dplyr::select(sample, longitude, latitude),
      by = "sample"
    )

  if (!is.null(env_variables)) {
    env_df <- env_variables %>%
      dplyr::rename(sample = id)
    map_df <- map_df %>%
      dplyr::left_join(env_df, by = "sample")
  }

  map_df %>%
    dplyr::filter(!is.na(longitude), !is.na(latitude))
}

prepare_tasmania_map_points <- function(sample_metadata,
                                        sample_points,
                                        env_variables = NULL,
                                        island = "Tasmania") {
  prepare_study_map_points(
    sample_metadata = sample_metadata,
    sample_points = sample_points,
    env_variables = env_variables,
    island = island
  )
}

tasmania_island_limits <- function(map_sf, padding = 0.12) {
  search_bb <- sf::st_bbox(
    c(xmin = 143.5, ymin = -44.2, xmax = 149.0, ymax = -38.8),
    crs = sf::st_crs(map_sf)
  )
  tas_land <- sf::st_intersection(
    map_sf,
    sf::st_as_sfc(search_bb)
  )
  bb <- sf::st_bbox(tas_land)
  list(
    xlim = c(bb[["xmin"]] - padding, bb[["xmax"]] + padding),
    ylim = c(bb[["ymin"]] - padding, bb[["ymax"]] + padding)
  )
}

tasmania_map_limits <- function(map_sf = NULL, padding = 0.12) {
  if (!is.null(map_sf)) {
    return(tasmania_island_limits(map_sf, padding = padding))
  }
  list(
    xlim = c(144, 148.6),
    ylim = c(-43.7, -39.0)
  )
}

australia_study_map_limits <- function(padding = 0.04) {
  list(
    xlim = c(110 - padding * 40, 150 + padding * 40),
    ylim = c(-45 - padding * 17, -28 + padding * 17)
  )
}

compose_tasmania_map_with_legend <- function(map_plot,
                                             devil_border = FALSE,
                                             legend_position = c("left", "right", "none")) {
  legend_position <- match.arg(legend_position)
  if (legend_position == "none") {
    return(
      map_plot +
        ggplot2::theme(
          legend.position = "none",
          plot.title.position = "panel",
          plot.title = ggplot2::element_text(
            hjust = 0.5,
            margin = ggplot2::margin(b = 4, unit = "pt")
          ),
          plot.margin = ggplot2::margin(4, 4, 4, 4, "pt")
        )
    )
  }

  legend_text_size <- if (isTRUE(devil_border)) {
    publication_legend_text_size(7)
  } else {
    publication_legend_text_size(8)
  }
  legend_title_size <- if (isTRUE(devil_border)) {
    publication_legend_title_size(7)
  } else {
    publication_legend_title_size(8)
  }
  legend_key_size <- if (isTRUE(devil_border)) 0.42 else 0.5
  legend_key_height <- if (isTRUE(devil_border)) 0.38 else 0.45
  legend_spacing <- if (isTRUE(devil_border)) 0.22 else 0.4
  outer_margin <- if (isTRUE(devil_border)) 4 else 8
  inner_margin <- if (isTRUE(devil_border)) 2 else 4
  top_margin <- if (isTRUE(devil_border)) 4 else 5

  margin_spec <- switch(
    legend_position,
    left = ggplot2::margin(top_margin, outer_margin, 4, inner_margin, "pt"),
    right = ggplot2::margin(top_margin, inner_margin, 4, outer_margin, "pt")
  )

  map_plot +
    ggplot2::theme(
      legend.position = legend_position,
      legend.box = "vertical",
      legend.box.just = "left",
      legend.box.spacing = ggplot2::unit(legend_spacing, "cm"),
      legend.key.size = ggplot2::unit(legend_key_size, "cm"),
      legend.key.height = ggplot2::unit(legend_key_height, "cm"),
      legend.text = ggplot2::element_text(size = legend_text_size, face = "bold"),
      legend.title = ggplot2::element_text(size = legend_title_size, face = "bold"),
      legend.title.align = 0,
      plot.title.position = "panel",
      plot.title = ggplot2::element_text(
        hjust = 0.5,
        margin = ggplot2::margin(b = 4, unit = "pt")
      ),
      plot.margin = margin_spec
    )
}

compose_tasmania_map_with_left_legend <- function(map_plot, devil_border = FALSE) {
  compose_tasmania_map_with_legend(
    map_plot,
    devil_border = devil_border,
    legend_position = "left"
  )
}

tasmania_devil_density_limits <- function(devil_values) {
  lim <- range(devil_values, na.rm = TRUE)
  pad <- diff(lim) * 0.04
  c(lim[1] - pad, lim[2] + pad)
}

tasmania_devil_density_colour_limits <- function(devil_values) {
  c(0, max(devil_values, na.rm = TRUE) * 1.02)
}

tasmania_devil_ring_style <- function() {
  list(
    outline_colour = "#1a1a1a",
    outer_outline_stroke = 1.75,
    ring_stroke = 1.5,
    inner_outline_stroke = 0.5,
    gradient_colours = c("#ffffff", "#c8e6c8", "#5a9e5a", "#1f5c1f", "#0a2e0a"),
    gradient_values = c(0, 0.22, 0.5, 0.78, 1)
  )
}

resolve_map_env_legend_levels <- function(plot_data,
                                          env_settings = environment_plot_settings(),
                                          env_legend_levels = NULL) {
  if (!is.null(env_legend_levels)) {
    return(intersect(as.character(env_legend_levels), env_settings$limits))
  }
  env_settings$limits[
    env_settings$limits %in% unique(as.character(plot_data$broad_environment))
  ]
}

aggregate_tasmania_map_sites <- function(map_points, devil_var = NULL) {
  grp_cols <- c("longitude", "latitude", "broad_environment")
  if (!is.null(devil_var)) {
    if (!devil_var %in% names(map_points)) {
      stop("Column '", devil_var, "' not found in map_points.", call. = FALSE)
    }
    map_points %>%
      dplyr::group_by(dplyr::across(dplyr::all_of(grp_cols))) %>%
      dplyr::summarise(
        n_samples = dplyr::n(),
        devil_density = mean(.data[[devil_var]], na.rm = TRUE),
        .groups = "drop"
      )
  } else {
    map_points %>%
      dplyr::group_by(dplyr::across(dplyr::all_of(grp_cols))) %>%
      dplyr::summarise(n_samples = dplyr::n(), .groups = "drop")
  }
}

create_tasmania_environment_map <- function(map_points,
                                            env_settings = environment_plot_settings(),
                                            map_sf = NULL,
                                            title = "Tasmania samples by environment",
                                            aggregate_sites = TRUE,
                                            devil_var = NULL,
                                            map_limits = NULL,
                                            legend_position = "left",
                                            env_legend_levels = NULL,
                                            theme_fn = theme_publication) {
  if (is.null(map_sf)) {
    map_sf <- load_australia_map_sf()
  }

  plot_data <- if (isTRUE(aggregate_sites)) {
    aggregate_tasmania_map_sites(map_points, devil_var = devil_var)
  } else {
    map_points %>%
      dplyr::mutate(n_samples = 1L) %>%
      {
        if (!is.null(devil_var)) {
          if (!devil_var %in% names(.)) {
            stop("Column '", devil_var, "' not found in map_points.", call. = FALSE)
          }
          dplyr::mutate(., devil_density = .data[[devil_var]])
        } else {
          .
        }
      }
  }

  plot_data <- plot_data %>%
    dplyr::mutate(
      broad_environment = factor(broad_environment, levels = env_settings$limits)
    )

  size_breaks <- sort(unique(plot_data$n_samples))
  use_devil_border <- !is.null(devil_var) && "devil_density" %in% names(plot_data)
  limits <- map_limits %||% tasmania_map_limits(map_sf)

  p <- plot_data %>%
    ggplot2::ggplot() +
    ggplot2::geom_sf(
      data = map_sf,
      fill = "grey92",
      colour = "grey35",
      linewidth = 0.3
    )

  if (isTRUE(use_devil_border)) {
    devil_lim <- tasmania_devil_density_colour_limits(plot_data$devil_density)
    devil_breaks <- pretty(devil_lim, n = 5)
    env_present <- resolve_map_env_legend_levels(
      plot_data = plot_data,
      env_settings = env_settings,
      env_legend_levels = env_legend_levels
    )
    env_colors <- environment_color_values(env_settings)
    ring_style <- tasmania_devil_ring_style()

    p <- p +
      ggplot2::geom_point(
        ggplot2::aes(
          x = longitude,
          y = latitude,
          fill = broad_environment,
          size = n_samples
        ),
        shape = 21,
        colour = ring_style$outline_colour,
        stroke = ring_style$outer_outline_stroke,
        alpha = 1
      ) +
      ggplot2::geom_point(
        ggplot2::aes(
          x = longitude,
          y = latitude,
          fill = broad_environment,
          colour = devil_density,
          size = n_samples
        ),
        shape = 21,
        stroke = ring_style$ring_stroke,
        alpha = 1
      ) +
      ggplot2::geom_point(
        ggplot2::aes(
          x = longitude,
          y = latitude,
          fill = broad_environment,
          size = n_samples
        ),
        shape = 21,
        colour = ring_style$outline_colour,
        stroke = ring_style$inner_outline_stroke,
        alpha = 1
      ) +
      ggplot2::scale_fill_manual(
        values = env_colors,
        labels = unname(env_settings$labels_long[env_present]),
        breaks = env_present,
        drop = FALSE,
        name = "Environment",
        guide = ggplot2::guide_legend(
          order = 1,
          override.aes = list(
            colour = "grey40",
            stroke = 0.7,
            size = 4
          )
        )
      ) +
      ggplot2::scale_colour_gradientn(
        colours = ring_style$gradient_colours,
        values = ring_style$gradient_values,
        limits = devil_lim,
        breaks = devil_breaks,
        labels = scales::label_number(accuracy = 0.01),
        oob = scales::squish,
        name = "Devil density ring (200 m)",
        guide = ggplot2::guide_colourbar(
          order = 3,
          direction = "horizontal",
          barwidth = ggplot2::unit(2.0, "cm"),
          barheight = ggplot2::unit(0.32, "cm"),
          frame.colour = "grey70",
          ticks.colour = "grey40",
          title.position = "top",
          title.hjust = 0,
          label.position = "bottom"
        )
      ) +
      ggplot2::guides(
        size = ggplot2::guide_legend(
          order = 2,
          ncol = 2,
          byrow = FALSE,
          override.aes = list(
            fill = "grey78",
            colour = "#1f5c1f",
            shape = 21,
            stroke = 0.7
          )
        )
      )
  } else {
    p <- p +
      ggplot2::geom_point(
        ggplot2::aes(
          x = longitude,
          y = latitude,
          colour = broad_environment,
          size = n_samples
        ),
        alpha = 0.85
      ) +
      ggplot2::scale_colour_manual(
        values = environment_color_values(env_settings),
        labels = env_settings$labels_long,
        breaks = env_settings$limits,
        drop = FALSE,
        name = "Environment"
      )
  }

  p <- p +
    ggplot2::scale_size_continuous(
      range = if (isTRUE(use_devil_border)) c(3, 8) else c(2.5, 7),
      breaks = size_breaks,
      name = "Samples per site"
    ) +
    ggplot2::coord_sf(
      xlim = limits$xlim,
      ylim = limits$ylim,
      expand = FALSE
    ) +
    ggplot2::labs(
      title = title,
      x = "Longitude",
      y = "Latitude"
    ) +
    theme_fn() +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank()
    )

  compose_tasmania_map_with_legend(
    p,
    devil_border = use_devil_border,
    legend_position = legend_position
  )
}

create_australia_tasmania_context_map <- function(map_points_all,
                                                  map_points_tasmania,
                                                  env_settings = environment_plot_settings(),
                                                  map_sf = NULL,
                                                  devil_var = "devil",
                                                  australia_width = 1,
                                                  tasmania_width = 1.15,
                                                  tag_size = 12,
                                                  theme_fn = theme_publication) {
  if (is.null(map_sf)) {
    map_sf <- load_australia_map_sf()
  }

  tag_theme <- ggplot2::theme(
    plot.tag = ggplot2::element_text(face = "bold", size = tag_size),
    plot.tag.position = "topleft"
  )

  env_legend_levels <- env_settings$limits[
    env_settings$limits %in% c(
      unique(as.character(map_points_all$broad_environment)),
      unique(as.character(map_points_tasmania$broad_environment))
    )
  ]

  fig_australia <- create_tasmania_environment_map(
    map_points_all,
    env_settings = env_settings,
    map_sf = map_sf,
    title = NULL,
    devil_var = devil_var,
    map_limits = australia_study_map_limits(),
    legend_position = "none",
    theme_fn = theme_fn
  )

  fig_tasmania <- create_tasmania_environment_map(
    map_points_tasmania,
    env_settings = env_settings,
    map_sf = map_sf,
    title = NULL,
    devil_var = devil_var,
    legend_position = "right",
    env_legend_levels = env_legend_levels,
    theme_fn = theme_fn
  )

  patchwork::wrap_plots(
    fig_australia,
    fig_tasmania,
    ncol = 2,
    widths = c(australia_width, tasmania_width)
  ) +
    patchwork::plot_layout(guides = "keep") +
    patchwork::plot_annotation(
      tag_levels = "a",
      theme = tag_theme
    )
}

australia_tasmania_context_map_dims <- function(width_mm = 280,
                                                  height_mm = 120) {
  list(width_mm = width_mm, height_mm = height_mm)
}

compose_australia_tasmania_relabund_figure <- function(map_panel,
                                                       relabund_panel,
                                                       layout_heights = c(1, 1.05),
                                                       tag_size = 12) {
  if (!requireNamespace("cowplot", quietly = TRUE)) {
    stop("Package 'cowplot' is required for Australia/Tasmania composites.", call. = FALSE)
  }

  rel_heights <- layout_heights / sum(layout_heights)

  cowplot::plot_grid(
    map_panel,
    relabund_panel,
    ncol = 1,
    rel_heights = rel_heights,
    labels = c("", "c"),
    label_size = tag_size,
    label_fontface = "bold"
  )
}

australia_tasmania_relabund_figure_dims <- function(width_mm = 280,
                                                    map_height_mm = 120,
                                                    facet_env = TRUE) {
  relabund_dims <- phylum_stacked_figure_dims(facet_env = facet_env)
  list(
    width_mm = width_mm,
    height_mm = round(map_height_mm + relabund_dims$height_mm + 8)
  )
}

create_tasmania_devil_density_map <- function(map_points,
                                              devil_var = "devil",
                                              map_sf = NULL,
                                              title = "Tasmania samples - devil density (200 m buffer)",
                                              theme_fn = theme_publication) {
  if (is.null(map_sf)) {
    map_sf <- load_australia_map_sf()
  }
  if (!devil_var %in% names(map_points)) {
    stop("Column '", devil_var, "' not found in map_points.", call. = FALSE)
  }

  limits <- tasmania_map_limits(map_sf)

  map_points %>%
    ggplot2::ggplot() +
    ggplot2::geom_sf(
      data = map_sf,
      fill = "grey92",
      colour = "grey35",
      linewidth = 0.3
    ) +
    ggplot2::geom_point(
      ggplot2::aes(
        x = longitude,
        y = latitude,
        colour = .data[[devil_var]]
      ),
      size = 2.8,
      alpha = 0.9
    ) +
    ggplot2::scale_colour_gradient(
      low = "#f7f7f7",
      high = spotlight_palettes()$devil,
      name = "Devil density"
    ) +
    ggplot2::coord_sf(
      xlim = limits$xlim,
      ylim = limits$ylim,
      expand = FALSE
    ) +
    ggplot2::labs(
      title = title,
      x = "Longitude",
      y = "Latitude"
    ) +
    theme_fn() +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid = ggplot2::element_blank()
    )
}

`%||%` <- function(x, y) if (is.null(x)) y else x

study_genome_ids <- function(genome_counts) {
  count_cols <- setdiff(names(genome_counts), "genome")
  genome_counts %>%
    dplyr::mutate(.total = rowSums(dplyr::across(dplyr::all_of(count_cols)))) %>%
    dplyr::filter(.total > 0) %>%
    dplyr::pull(genome)
}

prepare_phylum_ring_matrix <- function(genome_metadata, tip_order) {
  genome_metadata %>%
    dplyr::filter(genome %in% tip_order) %>%
    dplyr::arrange(match(genome, tip_order)) %>%
    dplyr::select(genome, phylum) %>%
    tibble::column_to_rownames("genome")
}

prepare_circular_phylo_tip_data <- function(genome_metadata, tip_labels) {
  genome_metadata %>%
    dplyr::filter(genome %in% tip_labels) %>%
    dplyr::transmute(
      label = genome,
      phylum = as.character(phylum)
    )
}

prepare_genome_relab_data <- function(genome_counts, tip_labels) {
  count_cols <- setdiff(names(genome_counts), "genome")
  genome_counts %>%
    dplyr::filter(genome %in% tip_labels) %>%
    dplyr::mutate(
      relab = rowSums(dplyr::across(dplyr::all_of(count_cols)))
    ) %>%
    dplyr::mutate(
      relab = relab / sum(relab, na.rm = TRUE),
      abun_bar = scales::rescale(
        log10(relab + 1e-8),
        to = c(0.03, 1)
      )
    ) %>%
    dplyr::select(genome, relab, abun_bar)
}

group_phylo_tree_by_phylum <- function(phylo_tree, tip_data) {
  phylum_counts <- tip_data %>%
    dplyr::count(phylum, name = "n", sort = TRUE)
  phylum_groups <- stats::setNames(
    lapply(phylum_counts$phylum, function(ph) tip_data$label[tip_data$phylum == ph]),
    phylum_counts$phylum
  )
  list(
    tree = ggtree::groupOTU(phylo_tree, phylum_groups),
    phylum_order = phylum_counts$phylum,
    phylum_groups = phylum_groups,
    phylum_counts = phylum_counts
  )
}

circular_phylogeny_readability_scale <- function() {
  2
}

circular_phylo_tree_linewidth <- function(n_tips) {
  scale <- circular_phylogeny_readability_scale()
  max(0.14, min(0.45, 320 / n_tips)) * scale
}

circular_phylo_tree_radial_scale <- function() {
  0.5 * circular_phylogeny_readability_scale()
}

# >1 compresses the inner backbone toward the root (smaller grey centre disc).
circular_phylo_tree_inner_power <- function() {
  1
}

scale_phylo_tree_radii <- function(phylo_tree,
                                   scale = circular_phylo_tree_radial_scale(),
                                   inner_power = 1) {
  if (!inherits(phylo_tree, "phylo") || is.null(phylo_tree$edge.length)) {
    return(phylo_tree)
  }
  if (!is.finite(scale) || scale <= 0) {
    stop("tree radial scale must be a positive finite number.", call. = FALSE)
  }
  if (!is.finite(inner_power) || inner_power <= 0) {
    stop("inner_power must be a positive finite number.", call. = FALSE)
  }

  if (inner_power == 1) {
    phylo_tree$edge.length <- phylo_tree$edge.length * scale
    return(phylo_tree)
  }

  depth <- ape::node.depth.edgelength(phylo_tree)
  n_tip <- length(phylo_tree$tip.label)
  max_depth <- max(depth[seq_len(n_tip)])
  if (max_depth <= 0) {
    phylo_tree$edge.length <- phylo_tree$edge.length * scale
    return(phylo_tree)
  }

  transform_depth <- function(d) {
    scale * max_depth * (pmax(d, 0) / max_depth) ^ inner_power
  }

  edge <- phylo_tree$edge
  phylo_tree$edge.length <- vapply(seq_len(nrow(edge)), function(i) {
    parent <- edge[i, 1]
    child <- edge[i, 2]
    pmax(transform_depth(depth[child]) - transform_depth(depth[parent]), 0)
  }, numeric(1))

  phylo_tree
}

circular_phylo_ring_width <- function(n_tips) {
  max(0.09, min(0.15, 160 / n_tips))
}

# Negative offset pulls the phylum ring inward to meet scaled tree tips (no white gap).
circular_phylo_phylum_ring_offset <- function() {
  -0.06
}

# ggtree::gheatmap radial span is wider than the width argument on circular trees.
circular_gheatmap_span_factor <- function() {
  2.63
}

circular_phylogeny_ring_gap <- function() {
  0.01
}

circular_phylogeny_ring_span_multiplier <- function() {
  1.25
}

circular_phylogeny_min_inter_ring_gap_frac <- function() {
  # Residual phylum→env rendered gap at gap_scale = 0, as a fraction of gap_scale = 1.
  0.48
}

circular_phylogeny_phylum_env_gap_scale <- function(gap_reduction = 0.75) {
  circular_phylogeny_inter_ring_gap_scale(gap_reduction)
}

circular_phylogeny_inter_ring_gap_scale <- function(gap_reduction = 0.75,
                                                    min_frac = circular_phylogeny_min_inter_ring_gap_frac()) {
  target_frac <- 1 - gap_reduction
  (target_frac - min_frac) / (1 - min_frac)
}

circular_phylogeny_outer_offset <- function(inner_offset,
                                            inner_width,
                                            gap = circular_phylogeny_ring_gap(),
                                            gap_scale = 1) {
  span_mult <- 1 +
    (circular_phylogeny_ring_span_multiplier() - 1) * gap_scale
  inner_offset +
    inner_width * circular_gheatmap_span_factor() * span_mult +
    gap * gap_scale
}

circular_phylogeny_ring_width <- function(n_cols, base_width, min_width = 0.04) {
  max(min_width, base_width * 0.35, n_cols * 0.008)
}

# G1b environment plots: narrower phylum band, wider per-environment columns.
circular_phylogeny_environment_plot_phylum_ring_scale <- function() {
  0.25
}

circular_phylogeny_environment_plot_env_ring_scale <- function() {
  1.265 * circular_phylogeny_readability_scale()
}

circular_phylogeny_environment_plot_genome_size_ring_scale <- function() {
  circular_phylogeny_readability_scale()
}

# Scale all annotation rings (not the tree) on G1b environment plots.
circular_phylogeny_environment_plot_annotation_scale <- function() {
  2.07
}

# Shift the full annotation stack inward over the tree (fraction of tree→phylum gap).
circular_phylogeny_environment_plot_annotation_inward_frac <- function() {
  0.15
}

# Pull env ring inward over phylum outer edge (fraction of phylum radial span).
circular_phylogeny_environment_plot_phylum_env_overlap_frac <- function() {
  0.35
}

# Widen phylum ring inward only (outer edge fixed); fraction of current radial span.
circular_phylogeny_environment_plot_phylum_inward_expand_frac <- function() {
  0.25
}

circular_phylogeny_phylum_ring_inward_expand <- function(ring_width,
                                                         ring_offset,
                                                         expand_frac) {
  inward <- expand_frac * ring_width * circular_gheatmap_span_factor()
  list(
    width = ring_width * (1 + expand_frac),
    offset = ring_offset - inward
  )
}

circular_phylogeny_gheatmap_offset_from_tips_flush <- function(tip_radius,
                                                              heatmap_outer_radius,
                                                              overlap = 0) {
  heatmap_outer_radius - tip_radius - overlap
}

circular_phylogeny_genome_size_color <- function() {
  "#1e6e55"
}

fade_phylum_ring_colors <- function(phylum_colors, alpha = 0.2) {
  stats::setNames(
    scales::alpha(unname(phylum_colors), alpha),
    names(phylum_colors)
  )
}

circular_phylogeny_heatmap_outer_from_tips <- function(tip_radius, offset, width) {
  tip_radius + offset + width * circular_gheatmap_span_factor()
}

circular_phylogeny_heatmap_center_from_tips <- function(tip_radius, offset, width) {
  tip_radius + offset + width * circular_gheatmap_span_factor() / 2
}

read_circular_gheatmap_outer_radius <- function(p) {
  bd <- ggplot2::ggplot_build(p)$data
  xmax_vals <- vapply(
    bd,
    function(d) {
      if (!is.null(d$xmax) && is.numeric(d$xmax)) {
        max(d$xmax, na.rm = TRUE)
      } else {
        NA_real_
      }
    },
    numeric(1)
  )
  max(xmax_vals, na.rm = TRUE)
}

read_circular_gheatmap_inner_radius <- function(p) {
  bd <- ggplot2::ggplot_build(p)$data
  xmin_vals <- vapply(
    bd,
    function(d) {
      if (!is.null(d$xmin) && is.numeric(d$xmin)) {
        min(d$xmin, na.rm = TRUE)
      } else {
        NA_real_
      }
    },
    numeric(1)
  )
  min(xmin_vals, na.rm = TRUE)
}

circular_phylogeny_tree_tip_xmax <- function(p) {
  max(ggplot2::ggplot_build(p)$data[[1]]$x, na.rm = TRUE)
}

probe_circular_phylum_ring_inner_radius <- function(tree_plot,
                                                    phylum_mat,
                                                    offset,
                                                    width) {
  p <- ggtree::gheatmap(
    tree_plot,
    phylum_mat,
    offset = offset,
    width = width,
    colnames = FALSE,
    color = NA
  )
  read_circular_gheatmap_inner_radius(p)
}

circular_phylogeny_phylum_ring_offset_inward_shift <- function(tree_plot,
                                                              phylum_mat,
                                                              ring_width,
                                                              base_offset,
                                                              inward_frac = NULL,
                                                              inward_distance = NULL) {
  inner_base <- probe_circular_phylum_ring_inner_radius(
    tree_plot,
    phylum_mat,
    base_offset,
    ring_width
  )

  if (!is.null(inward_distance) && inward_distance > 0) {
    target_inner <- inner_base - inward_distance
  } else if (!is.null(inward_frac) && inward_frac > 0) {
    tree_max <- circular_phylogeny_tree_tip_xmax(tree_plot)
    gap <- inner_base - tree_max
    if (gap <= 0) {
      return(base_offset)
    }
    target_inner <- inner_base - inward_frac * gap
  } else {
    return(base_offset)
  }

  lo <- base_offset - ring_width * circular_gheatmap_span_factor() * 8
  hi <- base_offset
  for (i in seq_len(30)) {
    mid <- (lo + hi) / 2
    inner <- probe_circular_phylum_ring_inner_radius(
      tree_plot,
      phylum_mat,
      mid,
      ring_width
    )
    if (inner > target_inner) {
      hi <- mid
    } else {
      lo <- mid
    }
  }
  hi
}

circular_phylogeny_environment_plot_annotation_stack_span <- function(phylum_ring_width,
                                                                      env_ring_width,
                                                                      genome_ring_width) {
  phylum_span <- phylum_ring_width * circular_gheatmap_span_factor()
  env_span <- env_ring_width * circular_gheatmap_span_factor()
  genome_span <- genome_ring_width / circular_phylogeny_fruit_offset_scale()
  phylum_span + env_span + genome_span
}

# geom_fruit offset is from branch tips; radial shift per unit offset matches gheatmap.
circular_phylogeny_fruit_offset_scale <- function() {
  circular_gheatmap_span_factor()
}

circular_phylogeny_fruit_offset_from_tips_flush_heatmap <- function(tip_radius,
                                                                    heatmap_outer_radius) {
  (heatmap_outer_radius - tip_radius) / circular_phylogeny_fruit_offset_scale()
}

circular_phylogeny_contamination_ring_alpha <- function() {
  0.5
}

circular_phylogeny_contamination_colors <- function(
    alpha = circular_phylogeny_contamination_ring_alpha()) {
  list(
    low = scales::alpha("#d1f4ba", alpha),
    high = scales::alpha("#f4baba", alpha)
  )
}

append_circular_contamination_ring <- function(p,
                                               genome_metadata,
                                               tip_order,
                                               offset,
                                               ring_width,
                                               alpha = circular_phylogeny_contamination_ring_alpha()) {
  fruit_data <- prepare_genome_fruit_metadata(genome_metadata, tip_order) %>%
    dplyr::mutate(
      completeness_bar = scales::rescale(
        .data$completeness,
        to = range(.data$length, na.rm = TRUE)
      )
    )
  cols <- circular_phylogeny_contamination_colors(alpha)

  p +
    ggnewscale::new_scale_fill() +
    ggtreeExtra::geom_fruit(
      data = fruit_data,
      geom = geom_bar,
      mapping = ggplot2::aes(
        x = completeness_bar,
        y = label,
        fill = contamination
      ),
      stat = "identity",
      offset = offset,
      pwidth = ring_width,
      orientation = "y"
    ) +
    ggplot2::scale_fill_gradient(
      low = cols$low,
      high = cols$high,
      name = "Contamination",
      guide = "none"
    )
}

append_circular_genome_size_ring <- function(p,
                                             genome_metadata,
                                             tip_order,
                                             tip_radius,
                                             ring_width,
                                             heatmap_outer_radius = NULL) {
  fruit_data <- prepare_genome_fruit_metadata(genome_metadata, tip_order)
  if (is.null(heatmap_outer_radius)) {
    heatmap_outer_radius <- read_circular_gheatmap_outer_radius(p)
  }
  size_offset <- circular_phylogeny_fruit_offset_from_tips_flush_heatmap(
    tip_radius,
    heatmap_outer_radius
  )

  list(
    plot = p +
      ggtreeExtra::geom_fruit(
        data = fruit_data,
        geom = geom_bar,
        mapping = ggplot2::aes(x = length, y = label),
        fill = circular_phylogeny_genome_size_color(),
        stat = "identity",
        offset = size_offset,
        pwidth = ring_width,
        orientation = "y"
      ),
    offset = size_offset,
    width = ring_width,
    heatmap_outer_radius = heatmap_outer_radius
  )
}

circular_phylogeny_tip_radius <- function(phylo_tree) {
  depth <- ape::node.depth.edgelength(phylo_tree)
  n_tip <- length(phylo_tree$tip.label)
  max(depth[seq_len(n_tip)], na.rm = TRUE)
}

circular_phylogeny_fruit_ring_center_radius <- function(previous_outer, pwidth) {
  previous_outer + pwidth / (2 * circular_phylogeny_fruit_offset_scale())
}

compute_circular_phylogeny_ring_label_positions <- function(phylum_x,
                                                            env_x,
                                                            env_outer_radius = NULL,
                                                            genome_size_width = NULL) {
  labels <- list(
    list(x = phylum_x, label = "Phylum"),
    list(x = env_x, label = "Environment")
  )
  if (!is.null(genome_size_width) && !is.null(env_outer_radius)) {
    labels <- c(
      labels,
      list(
        list(
          x = circular_phylogeny_fruit_ring_center_radius(
            env_outer_radius,
            genome_size_width
          ),
          label = "Genome size"
        )
      )
    )
  }
  labels
}

read_circular_phylogeny_core_ring_x <- function(p) {
  bd <- ggplot2::ggplot_build(p)$data
  list(
    phylum_x = bd[[3]]$x[[1]],
    env_x = mean(bd[[4]]$x, na.rm = TRUE)
  )
}

add_circular_phylogeny_ring_labels <- function(p,
                                               labels,
                                               opening_y,
                                               size = 3.2,
                                               family = "",
                                               color = "grey20") {
  for (lab in labels) {
    p <- p + ggplot2::annotate(
      "text",
      x = lab$x,
      y = opening_y,
      label = lab$label,
      family = family,
      size = size,
      hjust = 0.5,
      vjust = 0.5,
      colour = color
    )
  }
  p
}

tighten_circular_phylogeny_canvas <- function(p,
                                              y_expand = c(0, 0),
                                              x_expand = c(0, 0),
                                              plot_margin = 0) {
  p <- p +
    ggplot2::scale_y_continuous(
      expand = ggplot2::expansion(mult = y_expand, add = 0)
    ) +
    ggplot2::scale_x_continuous(
      expand = ggplot2::expansion(mult = x_expand, add = 0)
    ) +
    ggplot2::theme(
      plot.margin = ggplot2::margin(plot_margin, plot_margin, plot_margin, plot_margin)
    )
  p
}

enhance_phylum_plot_colors <- function(phylum_colors,
                                       washout = 0.1) {
  # washout = 1 reproduces the legacy lightening; lower values keep more of the EHI colour.
  stats::setNames(
    vapply(phylum_colors, function(col) {
      rgb <- grDevices::col2rgb(col)
      washed <- pmin(255, rgb * 0.88 + 18)
      rgb_out <- pmin(255, rgb * (1 - washout) + washed * washout)
      grDevices::rgb(rgb_out[1], rgb_out[2], rgb_out[3], maxColorValue = 255)
    }, character(1)),
    names(phylum_colors)
  )
}

circular_phylogeny_tree_color <- function() {
  grDevices::grey(55 / 100)
}

# G1b-only nudges for phylum colours that clash with the tree grey or env ring reds.
circular_phylogeny_grey_phylum_overrides <- function() {
  c(
    Methanobacteriota = "#D8D8D8",
    Spirochaetota     = "#C0C0C0",
    Verrucomicrobiota = "#585858",
    Thermoplasmatota  = "#282828"
  )
}

resolve_circular_phylogeny_environment_phylum_colors <- function(phylum_colors) {
  out <- phylum_colors

  grey_overrides <- circular_phylogeny_grey_phylum_overrides()
  for (phylum_label in names(grey_overrides)) {
    keys <- grep(phylum_label, names(out), value = TRUE)
    if (length(keys) > 0) {
      out[keys] <- grey_overrides[[phylum_label]]
    }
  }

  camp_keys <- grep("Campylobacterota", names(out), value = TRUE)
  if (length(camp_keys) > 0) {
    out[camp_keys] <- "#A81828"
  }

  out
}

prepare_ring_phylogeny_phylum_colors <- function(phylum_colors,
                                                   environment_overrides = TRUE) {
  out <- enhance_phylum_plot_colors(phylum_colors)
  if (isTRUE(environment_overrides)) {
    out <- resolve_circular_phylogeny_environment_phylum_colors(out)
  }
  out
}

circular_phylogeny_legend_base_size <- function() {
  10L
}

circular_phylogeny_environment_legend_base_size <- function() {
  circular_phylogeny_legend_base_size() + 4L
}

circular_phylogeny_g1b_legend_mm <- function(show_hmsc_legend = FALSE,
                                           show_contamination_legend = FALSE) {
  legend_scale <- circular_phylogeny_environment_legend_base_size() / 10
  if (isTRUE(show_hmsc_legend)) {
    return(round(68 * legend_scale))
  }
  if (isTRUE(show_contamination_legend)) {
    return(round(55 * legend_scale))
  }
  round(48 * legend_scale)
}

circular_phylogeny_environment_legend_inset_mm <- function() {
  10
}

circular_phylogeny_g1b_figure_layout <- function(n_tips,
                                                 show_hmsc_legend = FALSE,
                                                 show_contamination_legend = FALSE,
                                                 tight = TRUE) {
  inset_mm <- circular_phylogeny_environment_legend_inset_mm()
  legend_mm <- circular_phylogeny_g1b_legend_mm(
    show_hmsc_legend = show_hmsc_legend,
    show_contamination_legend = show_contamination_legend
  ) + inset_mm
  dims <- circular_phylogeny_figure_dims(
    n_tips = n_tips,
    legend_mm = legend_mm,
    tight = tight
  )
  legend_width_mm <- dims$width_mm - dims$height_mm
  list(
    width_mm = dims$width_mm,
    height_mm = dims$height_mm,
    legend_rel_width = legend_width_mm / dims$width_mm,
    legend_inset_mm = inset_mm
  )
}

circular_phylogeny_environment_legend_rel_width <- function(show_hmsc_legend = FALSE,
                                                            show_contamination_legend = FALSE,
                                                            n_tips = NULL) {
  if (is.null(n_tips)) {
    legend_scale <- circular_phylogeny_environment_legend_base_size() / 10
    if (isTRUE(show_hmsc_legend)) {
      return(0.22 * legend_scale)
    }
    if (isTRUE(show_contamination_legend)) {
      return(0.20 * legend_scale)
    }
    return(0.18 * legend_scale)
  }
  circular_phylogeny_g1b_figure_layout(
    n_tips = n_tips,
    show_hmsc_legend = show_hmsc_legend,
    show_contamination_legend = show_contamination_legend
  )$legend_rel_width
}

circular_phylogeny_legend_theme <- function(base_size = circular_phylogeny_legend_base_size()) {
  key_scale <- base_size / 6
  ggplot2::theme(
    legend.position = "left",
    legend.title = ggplot2::element_text(size = base_size + 0.5, face = "bold"),
    legend.text = ggplot2::element_text(size = base_size),
    legend.key.size = ggplot2::unit(2.6 * key_scale, "mm"),
    legend.key.height = ggplot2::unit(2.8 * key_scale, "mm"),
    legend.key.width = ggplot2::unit(2.8 * key_scale, "mm"),
    legend.spacing.y = ggplot2::unit(0.8 * key_scale, "mm"),
    legend.box.spacing = ggplot2::unit(2 * key_scale, "mm"),
    legend.margin = ggplot2::margin(0, 0, 0, 0)
  )
}

compose_circular_phylogeny_figure <- function(tree_plot, legend_rel_width = 0.1) {
  legend_base_size <- circular_phylogeny_legend_base_size()
  key_scale <- legend_base_size / 6
  legend_plot <- tree_plot +
    circular_phylogeny_legend_theme(base_size = legend_base_size) +
    ggplot2::theme(
      legend.box = "vertical",
      legend.box.spacing = ggplot2::unit(2.5 * key_scale, "mm")
    )
  legend_grob <- cowplot::get_legend(legend_plot)
  tree_panel <- tree_plot +
    ggplot2::theme(
      legend.position = "none",
      plot.margin = ggplot2::margin(0, 0, 0, 0)
    )
  finalize_patchwork_tight_layout(
    patchwork::wrap_elements(full = legend_grob) +
      tree_panel +
      patchwork::plot_layout(widths = c(legend_rel_width, 1 - legend_rel_width))
  )
}

build_environment_legend_grob <- function(env_settings = environment_plot_settings(),
                                          env_levels = NULL,
                                          legend_theme = circular_phylogeny_legend_theme(),
                                          use_long_labels = TRUE) {
  if (is.null(env_levels)) {
    env_levels <- env_settings$limits
  }
  env_levels <- intersect(env_levels, env_settings$limits)
  short_by_full <- stats::setNames(env_settings$labels_short, env_settings$limits)
  legend_labels <- if (isTRUE(use_long_labels)) {
    unname(env_settings$labels_long[env_levels])
  } else {
    unname(short_by_full[env_levels])
  }
  legend_colors <- environment_ring_fill_values(env_settings, env_levels)
  legend_colors <- legend_colors[names(legend_colors) != "off"]
  if (isTRUE(use_long_labels)) {
    names(legend_colors) <- legend_labels[match(names(legend_colors), unname(short_by_full[env_levels]))]
  }

  legend_df <- tibble::tibble(
    environment = factor(legend_labels, levels = legend_labels)
  )

  legend_plot <- ggplot2::ggplot(
    legend_df,
    ggplot2::aes(
      x = 1,
      y = .data$environment,
      fill = .data$environment
    )
  ) +
    ggplot2::geom_tile(width = 0.55, height = 0.8) +
    ggplot2::scale_fill_manual(
      name = "Environment",
      values = legend_colors,
      drop = FALSE,
      guide = ggplot2::guide_legend(
        ncol = 1,
        override.aes = list(alpha = 1, linewidth = 0)
      )
    ) +
    ggplot2::theme_void() +
    legend_theme +
    ggplot2::theme(
      legend.key = ggplot2::element_rect(color = NA)
    )

  cowplot::get_legend(legend_plot)
}

build_contamination_legend_grob <- function(
    alpha = circular_phylogeny_contamination_ring_alpha(),
    legend_theme = circular_phylogeny_legend_theme(),
    legend_base_size = circular_phylogeny_legend_base_size()) {
  cols <- circular_phylogeny_contamination_colors(alpha)
  bar_mm <- 2.8 * legend_base_size / 6
  legend_df <- tibble::tibble(
    x = seq(0, 1, length.out = 50),
    y = 1,
    contamination = seq(0, 1, length.out = 50)
  )

  legend_plot <- ggplot2::ggplot(
    legend_df,
    ggplot2::aes(x = .data$x, y = .data$y, fill = .data$contamination)
  ) +
    ggplot2::geom_tile(height = 0.1, width = 0.02) +
    ggplot2::scale_fill_gradient(
      low = cols$low,
      high = cols$high,
      name = "Contamination",
      limits = c(0, 1),
      breaks = c(0, 1),
      labels = c("Low", "High"),
      guide = ggplot2::guide_colourbar(
        barwidth = grid::unit(bar_mm * 3, "mm"),
        barheight = grid::unit(bar_mm, "mm")
      )
    ) +
    ggplot2::theme_void() +
    legend_theme

  cowplot::get_legend(legend_plot)
}

build_genome_size_legend_grob <- function(
    color = circular_phylogeny_genome_size_color(),
    legend_theme = circular_phylogeny_legend_theme()) {
  legend_df <- tibble::tibble(
    ring = factor("Genome size", levels = "Genome size")
  )

  legend_plot <- ggplot2::ggplot(
    legend_df,
    ggplot2::aes(
      x = 1,
      y = .data$ring,
      fill = .data$ring
    )
  ) +
    ggplot2::geom_tile(width = 0.55, height = 0.8) +
    ggplot2::scale_fill_manual(
      name = "Genome size",
      values = c("Genome size" = color),
      drop = FALSE,
      guide = ggplot2::guide_legend(
        ncol = 1,
        override.aes = list(alpha = 1, linewidth = 0)
      )
    ) +
    ggplot2::theme_void() +
    legend_theme +
    ggplot2::theme(
      legend.key = ggplot2::element_rect(color = NA)
    )

  cowplot::get_legend(legend_plot)
}

compose_circular_phylogeny_environment_figure <- function(tree_plot,
                                                          phylum_plot,
                                                          env_settings,
                                                          env_levels,
                                                          legend_rel_width = 0.18,
                                                          legend_inset_mm = circular_phylogeny_environment_legend_inset_mm(),
                                                          show_genome_size_legend = FALSE,
                                                          show_contamination_legend = FALSE,
                                                          show_hmsc_legend = FALSE,
                                                          spotlight_cols = spotlight_palettes()) {
  legend_base_size <- circular_phylogeny_environment_legend_base_size()
  key_scale <- legend_base_size / 6
  legend_theme <- circular_phylogeny_legend_theme(base_size = legend_base_size) +
    ggplot2::theme(
      legend.position = "left",
      legend.box = "vertical",
      legend.box.spacing = ggplot2::unit(2 * key_scale, "mm"),
      legend.key.size = ggplot2::unit(2.2 * key_scale, "mm"),
      legend.key.height = ggplot2::unit(2.4 * key_scale, "mm"),
      legend.key.width = ggplot2::unit(2.4 * key_scale, "mm"),
      legend.spacing.y = ggplot2::unit(0.6 * key_scale, "mm"),
      legend.title = ggplot2::element_text(size = legend_base_size + 0.25, face = "bold")
    )
  phylum_legend <- cowplot::get_legend(phylum_plot + legend_theme)
  env_legend <- build_environment_legend_grob(
    env_settings = env_settings,
    env_levels = env_levels,
    legend_theme = legend_theme
  )
  legend_parts <- list(phylum_legend)
  if (isTRUE(show_genome_size_legend)) {
    legend_parts <- c(
      legend_parts,
      list(build_genome_size_legend_grob(legend_theme = legend_theme))
    )
  }
  legend_parts <- c(legend_parts, list(env_legend))
  if (isTRUE(show_contamination_legend)) {
    legend_parts <- c(
      legend_parts,
      list(
        build_contamination_legend_grob(
          legend_theme = legend_theme,
          legend_base_size = legend_base_size
        )
      )
    )
  }
  if (show_hmsc_legend) {
    legend_parts <- c(
      legend_parts,
      list(
        build_hmsc_context_legend_grob(
          spotlight_cols = spotlight_cols,
          legend_theme = legend_theme,
          legend_base_size = legend_base_size
        )
      )
    )
  }
  legend_grob <- cowplot::plot_grid(
    plotlist = legend_parts,
    ncol = 1,
    align = "v"
  )

  tree_panel <- tree_plot +
    ggplot2::theme(
      legend.position = "none",
      plot.margin = ggplot2::margin(0, 0, 0, 0)
    )

  legend_panel <- patchwork::wrap_elements(full = legend_grob) +
    ggplot2::theme(
      plot.margin = ggplot2::margin(
        0,
        1,
        0,
        legend_inset_mm,
        unit = "mm"
      )
    )

  finalize_patchwork_tight_layout(
    legend_panel +
      tree_panel +
      patchwork::plot_layout(widths = c(legend_rel_width, 1 - legend_rel_width))
  )
}

finalize_circular_phylogeny_environment_plot <- function(p,
                                                           phylum_plot,
                                                           env_settings,
                                                           env_levels,
                                                           legend_rel_width = 0.18,
                                                           legend_inset_mm = circular_phylogeny_environment_legend_inset_mm(),
                                                           show_hmsc_legend = FALSE,
                                                           spotlight_cols = spotlight_palettes(),
                                                           open_angle = 18,
                                                           rotate_angle = 90,
                                                           tighten_canvas = TRUE,
                                                           show_genome_size_legend = FALSE,
                                                           show_contamination_legend = FALSE,
                                                           ring_labels = NULL,
                                                           opening_y = NULL) {
  if (isTRUE(tighten_canvas)) {
    p <- tighten_circular_phylogeny_canvas(p)
  }

  p <- p %>%
    ggtree::open_tree(angle = open_angle) %>%
    ggtree::rotate_tree(angle = rotate_angle)

  if (!is.null(ring_labels) && length(ring_labels) > 0) {
    if (is.null(opening_y)) {
      stop("opening_y is required when ring_labels are provided.", call. = FALSE)
    }
    p <- add_circular_phylogeny_ring_labels(
      p = p,
      labels = ring_labels,
      opening_y = opening_y
    )
  }

  compose_circular_phylogeny_environment_figure(
    tree_plot = p,
    phylum_plot = phylum_plot,
    env_settings = env_settings,
    env_levels = env_levels,
    legend_rel_width = legend_rel_width,
    legend_inset_mm = legend_inset_mm,
    show_genome_size_legend = show_genome_size_legend,
    show_contamination_legend = show_contamination_legend,
    show_hmsc_legend = show_hmsc_legend,
    spotlight_cols = spotlight_cols
  )
}

format_phylum_label <- function(phylum) {
  gsub("^p__", "", phylum)
}

prepare_newspecies_ring_matrix <- function(genome_metadata, tip_order) {
  genome_metadata %>%
    dplyr::filter(genome %in% tip_order) %>%
    dplyr::arrange(match(genome, tip_order)) %>%
    dplyr::mutate(newspecies = ifelse(species == "s__", "Y", "N")) %>%
    dplyr::select(genome, newspecies) %>%
    tibble::column_to_rownames("genome")
}

prepare_genome_fruit_metadata <- function(genome_metadata, tip_labels) {
  genome_metadata %>%
    dplyr::filter(genome %in% tip_labels) %>%
    dplyr::transmute(
      label = genome,
      completeness = completeness,
      contamination = contamination,
      length = length
    )
}

circular_phylo_detailed_ring_width <- function(n_tips) {
  max(0.05, min(0.09, 150 / n_tips))
}

build_circular_phylogeny_base <- function(genome_tree,
                                          genome_metadata,
                                          genome_ids = NULL,
                                          phylum_colors = NULL,
                                          tree_linewidth = NULL,
                                          phylum_ring_width = NULL,
                                          phylum_ring_offset = NULL,
                                          phylum_ring_inward_frac = NULL,
                                          phylum_ring_inward_distance = NULL,
                                          fan_open_angle = 5,
                                          phylum_ring_alpha = NULL,
                                          tree_radial_scale = circular_phylo_tree_radial_scale(),
                                          tree_inner_power = circular_phylo_tree_inner_power(),
                                          skip_phylum_color_enhancement = FALSE) {
  if (!is.null(genome_ids)) {
    keep_ids <- intersect(genome_ids, genome_tree$tip.label)
    genome_tree <- ape::keep.tip(genome_tree, keep_ids)
  }

  if (length(genome_tree$tip.label) == 0) {
    return(NULL)
  }

  phylo_tree <- phytools::force.ultrametric(genome_tree, method = "extend")
  n_tips <- length(phylo_tree$tip.label)
  tree_linewidth <- tree_linewidth %||% circular_phylo_tree_linewidth(n_tips)
  phylum_ring_width <- phylum_ring_width %||% circular_phylo_ring_width(n_tips)

  tip_data <- prepare_circular_phylo_tip_data(genome_metadata, phylo_tree$tip.label)
  grouped <- group_phylo_tree_by_phylum(phylo_tree, tip_data)
  phylo_tree <- scale_phylo_tree_radii(
    grouped$tree,
    scale = tree_radial_scale,
    inner_power = tree_inner_power
  )
  phylum_mat <- prepare_phylum_ring_matrix(genome_metadata, phylo_tree$tip.label)

  present_phyla <- grouped$phylum_order
  phylum_labels <- NULL
  if (!is.null(phylum_colors)) {
    phylum_colors <- phylum_colors[names(phylum_colors) %in% present_phyla]
    if (!isTRUE(skip_phylum_color_enhancement)) {
      phylum_colors <- enhance_phylum_plot_colors(phylum_colors)
    }
    if (!is.null(phylum_ring_alpha)) {
      phylum_colors <- fade_phylum_ring_colors(phylum_colors, alpha = phylum_ring_alpha)
    }
    phylum_mat$phylum <- factor(phylum_mat$phylum, levels = present_phyla)
    phylum_labels <- stats::setNames(
      format_phylum_label(names(phylum_colors)),
      names(phylum_colors)
    )
  }

  p <- ggtree::ggtree(
    phylo_tree,
    layout = "fan",
    open.angle = fan_open_angle,
    linewidth = tree_linewidth,
    color = circular_phylogeny_tree_color()
  )

  phylum_ring_offset <- phylum_ring_offset %||% circular_phylo_phylum_ring_offset()
  if ((!is.null(phylum_ring_inward_frac) && phylum_ring_inward_frac > 0) ||
      (!is.null(phylum_ring_inward_distance) && phylum_ring_inward_distance > 0)) {
    phylum_ring_offset <- circular_phylogeny_phylum_ring_offset_inward_shift(
      tree_plot = p,
      phylum_mat = phylum_mat,
      ring_width = phylum_ring_width,
      base_offset = phylum_ring_offset,
      inward_frac = phylum_ring_inward_frac,
      inward_distance = phylum_ring_inward_distance
    )
  }

  p <- ggtree::gheatmap(
    p,
    phylum_mat,
    offset = phylum_ring_offset,
    width = phylum_ring_width,
    colnames = FALSE,
    color = NA
  )

  if (!is.null(phylum_colors)) {
    p <- p +
      ggplot2::scale_fill_manual(
        values = phylum_colors,
        labels = phylum_labels,
        na.value = "grey80",
        drop = FALSE,
        guide = ggplot2::guide_legend(
          ncol = 1,
          byrow = FALSE,
          override.aes = list(alpha = 1, linewidth = 0)
        )
      )
  }

  p <- p +
    ggplot2::labs(fill = "Phylum") +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.margin = ggplot2::margin(0, 0, 0, 0)
    )

  list(
    plot = p,
    phylo_tree = phylo_tree,
    tip_data = tip_data,
    phylum_ring_width = phylum_ring_width,
    phylum_ring_offset = phylum_ring_offset,
    n_tips = n_tips
  )
}

finalize_circular_phylogeny_plot <- function(p,
                                             legend_position = "left",
                                             legend_rel_width = 0.1,
                                             open_angle = 18,
                                             rotate_angle = 90,
                                             tighten_canvas = TRUE) {
  if (isTRUE(tighten_canvas)) {
    p <- tighten_circular_phylogeny_canvas(p)
  }

  p <- p %>%
    ggtree::open_tree(angle = open_angle) %>%
    ggtree::rotate_tree(angle = rotate_angle)

  if (identical(legend_position, "left")) {
    p <- compose_circular_phylogeny_figure(p, legend_rel_width = legend_rel_width)
  } else if (identical(legend_position, "bottom")) {
    p <- p +
      ggplot2::theme(
        legend.position = "bottom",
        legend.text = ggplot2::element_text(
          size = publication_legend_text_size(circular_phylogeny_legend_base_size()),
          face = "bold"
        )
      )
  } else {
    p <- p + ggplot2::theme(legend.position = "none")
  }

  p
}

prepare_environment_ring_matrices <- function(genome_counts,
                                              sample_metadata,
                                              tip_order,
                                              env_settings = environment_plot_settings(),
                                              presence_threshold = 0) {
  count_cols <- intersect(
    setdiff(names(genome_counts), "genome"),
    sample_metadata$sample
  )
  if (length(count_cols) == 0) {
    stop("No overlapping samples between genome_counts and sample_metadata.", call. = FALSE)
  }

  meta <- sample_metadata %>%
    dplyr::filter(.data$sample %in% count_cols) %>%
    dplyr::select("sample", "broad_environment")

  pa <- genome_counts %>%
    dplyr::filter(.data$genome %in% tip_order) %>%
    dplyr::select("genome", dplyr::all_of(count_cols)) %>%
    tibble::column_to_rownames("genome") %>%
    dplyr::mutate(dplyr::across(
      dplyr::everything(),
      ~ as.integer(.x > presence_threshold)
    ))

  missing_tips <- setdiff(tip_order, rownames(pa))
  if (length(missing_tips) > 0) {
    pa <- rbind(
      pa,
      matrix(
        0L,
        nrow = length(missing_tips),
        ncol = ncol(pa),
        dimnames = list(missing_tips, colnames(pa))
      )
    )
  }
  pa <- pa[tip_order, , drop = FALSE]

  env_by_sample <- stats::setNames(meta$broad_environment, meta$sample)
  env_vec <- unname(env_by_sample[colnames(pa)])

  presence_agg <- stats::aggregate(
    t(pa),
    by = list(env = env_vec),
    FUN = function(x) as.integer(sum(x) > 0)
  )
  presence_mat <- t(as.matrix(presence_agg[, -1, drop = FALSE]))
  colnames(presence_mat) <- presence_agg$env

  prevalence_agg <- stats::aggregate(
    t(pa),
    by = list(env = env_vec),
    FUN = function(x) mean(x)
  )
  prevalence_mat <- t(as.matrix(prevalence_agg[, -1, drop = FALSE]))
  colnames(prevalence_mat) <- prevalence_agg$env

  env_levels <- env_settings$limits
  present_envs <- intersect(env_levels, colnames(presence_mat))
  if (length(present_envs) == 0) {
    stop("No broad_environment levels matched env_settings$limits.", call. = FALSE)
  }

  presence_mat <- presence_mat[, present_envs, drop = FALSE]
  prevalence_mat <- prevalence_mat[, present_envs, drop = FALSE]

  list(
    presence = presence_mat,
    prevalence = prevalence_mat
  )
}

hmsc_context_association_vars <- function() {
  c("devil", "temperature", "diversity")
}

hmsc_context_display_names <- function() {
  c(
    devil = "Devil",
    temperature = "Temperature",
    diversity = "Diversity"
  )
}

hmsc_context_gradient_colors <- function(spotlight_cols = spotlight_palettes()) {
  list(
    low = spotlight_cols$temperature,
    mid = "grey94",
    high = spotlight_cols$devil
  )
}

prepare_hmsc_context_beta_ci_list <- function(devil_ci,
                                              temperature_ci,
                                              diversity_ci = NULL,
                                              post_table = NULL) {
  beta_list <- list(
    devil = devil_ci,
    temperature = temperature_ci
  )
  if (!is.null(diversity_ci)) {
    beta_list$diversity <- diversity_ci
  } else if (!is.null(post_table) && "diversity" %in% colnames(post_table)) {
    beta_list$diversity <- post_table %>%
      tibble::rownames_to_column("genome") %>%
      dplyr::transmute(
        genome = .data$genome,
        mean = dplyr::case_when(
          .data$diversity == "Positive" ~ 1,
          .data$diversity == "Negative" ~ -1,
          TRUE ~ 0
        )
      )
  }
  beta_list
}

prepare_hmsc_context_ring_matrix <- function(post_table,
                                             beta_ci_list,
                                             tip_order,
                                             variables = hmsc_context_association_vars()) {
  vars_present <- intersect(variables, colnames(post_table))
  if (length(vars_present) == 0) {
    return(NULL)
  }

  trend_mat <- prepare_hmsc_association_ring_matrix(
    post_table = post_table,
    tip_order = tip_order,
    variables = vars_present,
    missing_value = NA
  )
  label_map <- hmsc_context_display_names()
  col_labels <- vapply(vars_present, function(var) label_map[[var]] %||% var, character(1))

  mat <- matrix(
    NA_real_,
    nrow = length(tip_order),
    ncol = length(vars_present),
    dimnames = list(tip_order, col_labels)
  )

  for (i in seq_along(vars_present)) {
    var <- vars_present[[i]]
    if (var %in% names(beta_ci_list) && !is.null(beta_ci_list[[var]])) {
      ci_vals <- beta_ci_list[[var]] %>%
        dplyr::select(genome, mean) %>%
        dplyr::distinct(genome, .keep_all = TRUE)
      mat[, i] <- ci_vals$mean[match(tip_order, ci_vals$genome)]
    }

    missing_ci_pos <- is.na(mat[, i]) & trend_mat[, var] == "Positive"
    missing_ci_neg <- is.na(mat[, i]) & trend_mat[, var] == "Negative"
    mat[missing_ci_pos, i] <- 1
    mat[missing_ci_neg, i] <- -1
    mat[trend_mat[, var] == "Neutral" | is.na(trend_mat[, var]), i] <- NA
  }

  scaled <- mat
  for (j in seq_len(ncol(scaled))) {
    col_lim <- max(abs(scaled[, j]), na.rm = TRUE)
    if (is.finite(col_lim) && col_lim > 0) {
      scaled[, j] <- scaled[, j] / col_lim
    }
  }
  attr(scaled, "column_scaled") <- TRUE
  scaled
}

build_hmsc_context_legend_grob <- function(spotlight_cols = spotlight_palettes(),
                                         legend_theme = circular_phylogeny_legend_theme(),
                                         legend_base_size = circular_phylogeny_legend_base_size()) {
  cols <- hmsc_context_gradient_colors(spotlight_cols)
  bar_mm <- 2.8 * legend_base_size / 6
  legend_df <- tibble::tibble(
    x = seq(-1, 1, length.out = 50),
    y = 1,
    strength = seq(-1, 1, length.out = 50)
  )

  legend_plot <- ggplot2::ggplot(
    legend_df,
    ggplot2::aes(x = .data$x, y = .data$y, fill = .data$strength)
  ) +
    ggplot2::geom_tile(height = 0.1, width = 0.04) +
    ggplot2::scale_fill_gradient2(
      low = cols$low,
      mid = cols$mid,
      high = cols$high,
      midpoint = 0,
      limits = c(-1, 1),
      name = "HMSC association",
      breaks = c(-1, 0, 1),
      labels = c("Negative", "Not tested", "Positive"),
      guide = ggplot2::guide_colourbar(
        barwidth = grid::unit(bar_mm * 3, "mm"),
        barheight = grid::unit(bar_mm, "mm")
      )
    ) +
    ggplot2::theme_void() +
    legend_theme

  cowplot::get_legend(legend_plot)
}

prepare_hmsc_association_ring_matrix <- function(post_table,
                                                 tip_order,
                                                 variables = c("devil", "temperature", "diversity"),
                                                 missing_value = "Neutral") {
  vars_present <- intersect(variables, colnames(post_table))
  if (length(vars_present) == 0) {
    stop("None of the requested HMSC variables found in post_table columns.", call. = FALSE)
  }

  pt <- post_table %>%
    tibble::rownames_to_column("genome") %>%
    dplyr::filter(.data$genome %in% tip_order) %>%
    dplyr::select("genome", dplyr::all_of(vars_present)) %>%
    tibble::column_to_rownames("genome")

  missing_tips <- setdiff(tip_order, rownames(pt))
  if (length(missing_tips) > 0 && !is.na(missing_value)) {
    filler <- matrix(
      missing_value,
      nrow = length(missing_tips),
      ncol = length(vars_present),
      dimnames = list(missing_tips, vars_present)
    )
    pt <- rbind(pt, filler)
  }

  if (length(missing_tips) > 0 && is.na(missing_value)) {
    out <- matrix(
      NA_character_,
      nrow = length(tip_order),
      ncol = length(vars_present),
      dimnames = list(tip_order, vars_present)
    )
    if (nrow(pt) > 0) {
      out[rownames(pt), ] <- as.matrix(pt[rownames(pt), vars_present, drop = FALSE])
    }
    return(out)
  }

  as.matrix(pt[tip_order, vars_present, drop = FALSE])
}

hmsc_association_fill_values <- function(spotlight_cols = spotlight_palettes()) {
  c(
    "Positive"  = spotlight_cols$devil,
    "Negative"  = spotlight_cols$temperature,
    "Neutral"   = "grey94"
  )
}

create_circular_community_phylogeny_plot <- function(genome_tree,
                                                     genome_metadata,
                                                     genome_ids = NULL,
                                                     genome_counts = NULL,
                                                     phylum_colors = NULL,
                                                     tree_linewidth = NULL,
                                                     phylum_ring_width = NULL,
                                                     show_abundance_ring = TRUE,
                                                     legend_position = "left",
                                                     open_angle = 18,
                                                     rotate_angle = 90,
                                                     fan_open_angle = 5,
                                                     tighten_canvas = TRUE) {
  base <- build_circular_phylogeny_base(
    genome_tree = genome_tree,
    genome_metadata = genome_metadata,
    genome_ids = genome_ids,
    phylum_colors = phylum_colors,
    tree_linewidth = tree_linewidth,
    phylum_ring_width = phylum_ring_width,
    fan_open_angle = fan_open_angle
  )
  if (is.null(base)) {
    return(NULL)
  }

  p <- base$plot
  ring_w <- base$phylum_ring_width

  if (show_abundance_ring && !is.null(genome_counts)) {
    fruit_data <- base$tip_data %>%
      dplyr::left_join(
        prepare_genome_relab_data(genome_counts, base$phylo_tree$tip.label),
        by = c("label" = "genome")
      ) %>%
      dplyr::mutate(abun_bar = tidyr::replace_na(abun_bar, 0.03))

    p <- p +
      ggtreeExtra::geom_fruit(
        data = fruit_data,
        geom = geom_bar,
        mapping = ggplot2::aes(x = abun_bar, y = label),
        fill = "#1e6e55",
        stat = "identity",
        offset = ring_w + 0.04,
        pwidth = ring_w * 0.65,
        orientation = "y"
      )
  }

  finalize_circular_phylogeny_plot(
    p = p,
    legend_position = legend_position,
    open_angle = open_angle,
    rotate_angle = rotate_angle,
    tighten_canvas = tighten_canvas
  )
}

prepare_environment_presence_display_matrix <- function(presence_mat,
                                                        env_settings = environment_plot_settings(),
                                                        tip_order = rownames(presence_mat)) {
  env_levels <- intersect(env_settings$limits, colnames(presence_mat))
  short_by_full <- stats::setNames(env_settings$labels_short, env_settings$limits)
  col_labels <- unname(short_by_full[env_levels])

  display_mat <- matrix(
    "off",
    nrow = nrow(presence_mat),
    ncol = length(env_levels),
    dimnames = list(rownames(presence_mat), col_labels)
  )

  for (j in seq_along(env_levels)) {
    env_name <- env_levels[j]
    short <- col_labels[j]
    display_mat[presence_mat[, env_name, drop = TRUE] > 0, j] <- short
  }

  display_mat <- display_mat[tip_order, , drop = FALSE]

  list(matrix = display_mat, env_levels = env_levels)
}

environment_presence_fill_values <- function(env_settings = environment_plot_settings(),
                                             env_levels = NULL) {
  if (is.null(env_levels)) {
    env_levels <- env_settings$limits
  }
  env_levels <- intersect(env_levels, env_settings$limits)
  short_by_full <- stats::setNames(env_settings$labels_short, env_settings$limits)
  colors_by_full <- stats::setNames(env_settings$colors, env_settings$limits)
  fill_vals <- stats::setNames(
    unname(colors_by_full[env_levels]),
    unname(short_by_full[env_levels])
  )
  fill_vals["off"] <- "white"
  fill_vals
}

environment_ring_fill_values <- function(env_settings = environment_plot_settings(),
                                         env_levels = NULL) {
  fill_vals <- environment_presence_fill_values(env_settings, env_levels)
  on_names <- setdiff(names(fill_vals), "off")
  fill_vals[on_names] <- stats::setNames(
    vapply(fill_vals[on_names], function(col) {
      rgb <- grDevices::col2rgb(col)
      rgb <- pmax(0, rgb - 25)
      grDevices::rgb(rgb[1], rgb[2], rgb[3], maxColorValue = 255)
    }, character(1)),
    on_names
  )
  fill_vals
}

create_circular_community_phylogeny_environment_plot <- function(genome_tree,
                                                                 genome_metadata,
                                                                 genome_counts,
                                                                 sample_metadata,
                                                                 genome_ids = NULL,
                                                                 phylum_colors = NULL,
                                                                 env_settings = environment_plot_settings(),
                                                                 post_table = NULL,
                                                                 beta_ci_list = NULL,
                                                                 hmsc_variables = hmsc_context_association_vars(),
                                                                 spotlight_cols = spotlight_palettes(),
                                                                 tree_linewidth = NULL,
                                                                 phylum_ring_width = NULL,
                                                                 show_genome_size_ring = TRUE,
                                                                 show_contamination_ring = FALSE,
                                                                 contamination_ring_alpha = circular_phylogeny_contamination_ring_alpha(),
                                                                 show_ring_labels = FALSE,
                                                                 phylum_ring_alpha = 0.9,
                                                                 legend_position = "left",
                                                                 open_angle = 18,
                                                                 rotate_angle = 90,
                                                                 fan_open_angle = 5,
                                                                 tighten_canvas = TRUE) {
  n_tips_est <- length(genome_tree$tip.label)
  if (!is.null(genome_ids)) {
    n_tips_est <- length(intersect(genome_ids, genome_tree$tip.label))
  }

  default_phylum_w <- phylum_ring_width %||% circular_phylo_ring_width(n_tips_est)
  ring_scale <- circular_phylogeny_environment_plot_annotation_scale()
  scaled_phylum_w <- default_phylum_w *
    circular_phylogeny_environment_plot_phylum_ring_scale() *
    ring_scale
  phylum_geom <- circular_phylogeny_phylum_ring_inward_expand(
    ring_width = scaled_phylum_w,
    ring_offset = circular_phylo_phylum_ring_offset(),
    expand_frac = circular_phylogeny_environment_plot_phylum_inward_expand_frac()
  )
  env_width_est <- circular_phylogeny_ring_width(
    n_cols = length(environment_plot_settings()$limits),
    base_width = default_phylum_w
  ) * circular_phylogeny_environment_plot_env_ring_scale() * ring_scale
  genome_width_est <- default_phylum_w * ring_scale *
    circular_phylogeny_environment_plot_genome_size_ring_scale()
  stack_inward_distance <- circular_phylogeny_environment_plot_annotation_inward_frac() *
    circular_phylogeny_environment_plot_annotation_stack_span(
      phylum_ring_width = phylum_geom$width,
      env_ring_width = env_width_est,
      genome_ring_width = genome_width_est
    )

  if (!is.null(phylum_colors)) {
    phylum_colors <- resolve_circular_phylogeny_environment_phylum_colors(
      enhance_phylum_plot_colors(phylum_colors)
    )
  }

  base <- build_circular_phylogeny_base(
    genome_tree = genome_tree,
    genome_metadata = genome_metadata,
    genome_ids = genome_ids,
    phylum_colors = phylum_colors,
    tree_linewidth = tree_linewidth,
    phylum_ring_width = phylum_geom$width,
    phylum_ring_offset = phylum_geom$offset,
    phylum_ring_inward_distance = stack_inward_distance,
    fan_open_angle = fan_open_angle,
    phylum_ring_alpha = phylum_ring_alpha,
    skip_phylum_color_enhancement = !is.null(phylum_colors)
  )
  if (is.null(base)) {
    return(NULL)
  }

  tip_order <- base$phylo_tree$tip.label
  env_mats <- prepare_environment_ring_matrices(
    genome_counts = genome_counts,
    sample_metadata = sample_metadata,
    tip_order = tip_order,
    env_settings = env_settings
  )

  presence_mat <- env_mats$presence
  env_display <- prepare_environment_presence_display_matrix(
    presence_mat,
    env_settings = env_settings,
    tip_order = tip_order
  )
  env_levels <- env_display$env_levels
  display_mat <- env_display$matrix

  phylum_w <- base$phylum_ring_width
  tip_r <- circular_phylogeny_tip_radius(base$phylo_tree)
  phylum_outer <- read_circular_gheatmap_outer_radius(base$plot)
  phylum_overlap <- phylum_w * circular_gheatmap_span_factor() *
    circular_phylogeny_environment_plot_phylum_env_overlap_frac()
  env_offset <- circular_phylogeny_gheatmap_offset_from_tips_flush(
    tip_r,
    phylum_outer,
    overlap = phylum_overlap
  )
  env_width <- circular_phylogeny_ring_width(
    n_cols = ncol(display_mat),
    base_width = default_phylum_w
  ) * circular_phylogeny_environment_plot_env_ring_scale() * ring_scale

  p <- base$plot
  p <- p + ggnewscale::new_scale_fill()
  p <- ggtree::gheatmap(
    p,
    display_mat,
    offset = env_offset,
    width = env_width,
    colnames = FALSE,
    color = NA
  )
  p <- p +
    ggplot2::scale_fill_manual(
      values = environment_ring_fill_values(env_settings, env_levels),
      guide = "none"
    )

  genome_size_offset <- NULL
  genome_size_width <- NULL
  env_outer_radius <- read_circular_gheatmap_outer_radius(p)
  if (isTRUE(show_genome_size_ring)) {
    tip_r <- circular_phylogeny_tip_radius(base$phylo_tree)
    size_ring <- append_circular_genome_size_ring(
      p = p,
      genome_metadata = genome_metadata,
      tip_order = tip_order,
      tip_radius = tip_r,
      ring_width = default_phylum_w * ring_scale *
        circular_phylogeny_environment_plot_genome_size_ring_scale(),
      heatmap_outer_radius = env_outer_radius
    )
    p <- size_ring$plot
    genome_size_offset <- size_ring$offset
    genome_size_width <- size_ring$width
    env_outer_radius <- size_ring$heatmap_outer_radius

    if (isTRUE(show_contamination_ring)) {
      p <- append_circular_contamination_ring(
        p = p,
        genome_metadata = genome_metadata,
        tip_order = tip_order,
        offset = genome_size_offset,
        ring_width = genome_size_width,
        alpha = contamination_ring_alpha
      )
    }
  }

  ring_labels <- NULL
  if (isTRUE(show_ring_labels)) {
    ring_label_x <- read_circular_phylogeny_core_ring_x(p)
    ring_labels <- compute_circular_phylogeny_ring_label_positions(
      phylum_x = ring_label_x$phylum_x,
      env_x = ring_label_x$env_x,
      env_outer_radius = env_outer_radius,
      genome_size_width = genome_size_width
    )
  }

  show_hmsc_legend <- FALSE
  if (!is.null(post_table) && !is.null(beta_ci_list)) {
    hmsc_mat <- prepare_hmsc_context_ring_matrix(
      post_table = post_table,
      beta_ci_list = beta_ci_list,
      tip_order = tip_order,
      variables = hmsc_variables
    )
    if (!is.null(hmsc_mat) && ncol(hmsc_mat) > 0) {
      if (!is.null(genome_size_offset)) {
        tip_r <- circular_phylogeny_tip_radius(base$phylo_tree)
        fruit_outer <- env_outer_radius +
          genome_size_width / circular_phylogeny_fruit_offset_scale()
        hmsc_offset <- circular_phylogeny_fruit_offset_from_tips_flush_heatmap(
          tip_r,
          fruit_outer
        ) + circular_phylogeny_ring_gap() *
          circular_phylogeny_inter_ring_gap_scale()
      } else {
        hmsc_offset <- circular_phylogeny_outer_offset(
          env_offset,
          env_width,
          gap_scale = circular_phylogeny_inter_ring_gap_scale()
        )
      }
      hmsc_width <- circular_phylogeny_ring_width(
        n_cols = ncol(hmsc_mat),
        base_width = default_phylum_w,
        min_width = 0.035
      ) * ring_scale

      hmsc_cols <- hmsc_context_gradient_colors(spotlight_cols)

      p <- p + ggnewscale::new_scale_fill()
      p <- ggtree::gheatmap(
        p,
        hmsc_mat,
        offset = hmsc_offset,
        width = hmsc_width,
        colnames = FALSE,
        color = NA
      )
      p <- p +
        ggplot2::scale_fill_gradient2(
          low = hmsc_cols$low,
          mid = hmsc_cols$mid,
          high = hmsc_cols$high,
          midpoint = 0,
          limits = c(-1, 1),
          oob = scales::squish,
          na.value = "white",
          guide = "none"
        )
      show_hmsc_legend <- TRUE
    }
  }

  finalize_circular_phylogeny_environment_plot(
    p = p,
    phylum_plot = base$plot,
    env_settings = env_settings,
    env_levels = env_levels,
    legend_rel_width = circular_phylogeny_environment_legend_rel_width(
      show_hmsc_legend = show_hmsc_legend,
      show_contamination_legend = isTRUE(show_contamination_ring),
      n_tips = length(tip_order)
    ),
    show_hmsc_legend = show_hmsc_legend,
    spotlight_cols = spotlight_cols,
    open_angle = open_angle,
    rotate_angle = rotate_angle,
    tighten_canvas = tighten_canvas,
    show_genome_size_legend = isTRUE(show_genome_size_ring),
    show_contamination_legend = isTRUE(show_contamination_ring),
    ring_labels = ring_labels,
    opening_y = length(tip_order)
  )
}

create_circular_community_phylogeny_detailed_plot <- function(genome_tree,
                                                              genome_metadata,
                                                              genome_ids = NULL,
                                                              phylum_colors = NULL,
                                                              tree_linewidth = NULL,
                                                              phylum_ring_width = NULL,
                                                              legend_position = "left",
                                                              open_angle = 18,
                                                              rotate_angle = 90,
                                                              fan_open_angle = 5,
                                                              tighten_canvas = TRUE) {
  n_tips_est <- length(genome_tree$tip.label)
  if (!is.null(genome_ids)) {
    n_tips_est <- length(intersect(genome_ids, genome_tree$tip.label))
  }
  ring_w <- phylum_ring_width %||% circular_phylo_detailed_ring_width(n_tips_est)

  base <- build_circular_phylogeny_base(
    genome_tree = genome_tree,
    genome_metadata = genome_metadata,
    genome_ids = genome_ids,
    phylum_colors = phylum_colors,
    tree_linewidth = tree_linewidth,
    phylum_ring_width = ring_w,
    fan_open_angle = fan_open_angle
  )
  if (is.null(base)) {
    return(NULL)
  }

  fruit_data <- prepare_genome_fruit_metadata(genome_metadata, base$phylo_tree$tip.label)
  newspecies_mat <- prepare_newspecies_ring_matrix(
    genome_metadata,
    base$phylo_tree$tip.label
  )

  p <- base$plot +
    ggnewscale::new_scale_fill() +
    ggtreeExtra::geom_fruit(
      data = fruit_data,
      geom = geom_bar,
      mapping = ggplot2::aes(
        x = completeness,
        y = label,
        fill = contamination
      ),
      stat = "identity",
      offset = ring_w + 0.025,
      pwidth = ring_w * 1.25,
      orientation = "y"
    ) +
    ggplot2::scale_fill_gradient(
      low = "#d1f4ba",
      high = "#f4baba",
      name = "Contamination"
    )

  p <- p +
    ggnewscale::new_scale_fill()

  p <- ggtree::gheatmap(
    p,
    newspecies_mat,
    offset = 2 * ring_w + 0.05,
    width = ring_w * 0.85,
    colnames = FALSE,
    color = "white"
  ) +
    ggplot2::scale_fill_manual(
      values = c("N" = "#f4f4f4", "Y" = "#74C8AE"),
      name = "New species",
      guide = ggplot2::guide_legend(
        ncol = 1,
        override.aes = list(alpha = 1, linewidth = 0)
      )
    )

  p <- p +
    ggtreeExtra::geom_fruit(
      data = fruit_data,
      geom = geom_bar,
      mapping = ggplot2::aes(x = length, y = label),
      fill = "#1e6e55",
      stat = "identity",
      offset = 3 * ring_w + 0.08,
      pwidth = ring_w * circular_phylogeny_environment_plot_genome_size_ring_scale(),
      orientation = "y"
    )

  finalize_circular_phylogeny_plot(
    p = p,
    legend_position = legend_position,
    legend_rel_width = 0.18,
    open_angle = open_angle,
    rotate_angle = rotate_angle,
    tighten_canvas = tighten_canvas
  )
}

circular_phylogeny_figure_dims <- function(width_mm = NULL,
                                           height_mm = NULL,
                                           n_tips = NULL,
                                           legend_mm = round(22 * circular_phylogeny_legend_base_size() / 6),
                                           tight = TRUE) {
  size_scale <- sqrt(circular_phylogeny_readability_scale())
  if (is.null(height_mm)) {
    height_mm <- if (isTRUE(tight)) 172 * size_scale else 220 * size_scale
  }
  tree_mm <- height_mm
  if (!is.null(n_tips) && n_tips > 400) {
    if (isTRUE(tight)) {
      tree_mm <- max(172, min(205, 128 + sqrt(n_tips) * 1.75)) * size_scale
    } else {
      tree_mm <- max(tree_mm, min(275, 175 + sqrt(n_tips) * 2.65)) * size_scale
    }
  }
  if (isTRUE(tight)) {
    legend_mm <- legend_mm * 0.9
  }
  list(
    width_mm = if (is.null(width_mm)) tree_mm + legend_mm else width_mm,
    height_mm = tree_mm
  )
}

circular_phylogeny_detailed_figure_dims <- function(n_tips = NULL, tight = TRUE) {
  layout <- circular_phylogeny_g1b_figure_layout(
    n_tips = n_tips,
    show_hmsc_legend = FALSE,
    show_contamination_legend = FALSE,
    tight = tight
  )
  list(
    width_mm = layout$width_mm,
    height_mm = layout$height_mm
  )
}

mm_to_inches <- function(mm) {
  mm / 25.4
}

tight_layout_figure <- function(plot) {
  if (inherits(plot, "patchwork")) {
    return(finalize_patchwork_tight_layout(plot))
  }
  if (inherits(plot, "ggplot")) {
    return(plot + ggplot2::theme(
      plot.margin = ggplot2::margin(0, 0, 0, 0, unit = "pt"),
      plot.background = ggplot2::element_blank()
    ))
  }
  plot
}

finalize_patchwork_tight_layout <- function(plot) {
  if (!inherits(plot, "patchwork")) {
    return(plot)
  }
  tight_theme <- ggplot2::theme(
    plot.margin = ggplot2::margin(0, 0, 0, 0, unit = "pt"),
    plot.background = ggplot2::element_blank()
  )
  (plot & tight_theme) +
    patchwork::plot_annotation(theme = tight_theme)
}

publication_cache_paths <- function() {
  list(
    base = "data/publication_base.Rdata",
    hmsc = "data/publication_hmsc.Rdata"
  )
}

load_phylum_colors_fallback <- function() {
  if (exists("phylum_colors", envir = .GlobalEnv, inherits = FALSE)) {
    return(get("phylum_colors", envir = .GlobalEnv))
  }
  readr::read_tsv(
    "https://raw.githubusercontent.com/earthhologenome/EHI_taxonomy_colour/main/ehi_phylum_colors.tsv",
    show_col_types = FALSE
  ) %>%
    tibble::deframe()
}

build_publication_base_cache <- function(sample_metadata,
                                         genome_counts_filt,
                                         genome_tree,
                                         genome_gifts,
                                         GIFT_db,
                                         landcover_wide,
                                         beta_mats) {
  env_settings <- environment_plot_settings()
  filtered <- filter_study_samples(sample_metadata, genome_counts_filt)
  env_order <- phylum_stacked_environment_order(filtered$metadata, env_settings)

  landcover_wide <- landcover_wide %>%
    dplyr::rename(sample = dplyr::any_of(c("sample", "id")))

  sample_metadata_fig <- filtered$metadata %>%
    dplyr::mutate(
      broad_environment = factor(broad_environment, levels = env_order)
    ) %>%
    dplyr::left_join(landcover_wide, by = "sample")

  sample_order_fig <- sample_metadata_fig %>%
    dplyr::arrange(broad_environment, sample) %>%
    dplyr::pull(sample) %>%
    unique()

  alpha_div_fig <- calculate_alpha_diversity(
    genome_counts = filtered$genome_counts,
    genome_tree = genome_tree,
    genome_gifts = genome_gifts,
    GIFT_db = GIFT_db
  )

  nmds_limits_fig <- calculate_nmds_limits(beta_mats)
  nmds_fits_fig <- purrr::imap(
    beta_mats,
    ~ fit_nmds_ordination(.x)$nmds_obj
  )

  list(
    sample_metadata_fig = sample_metadata_fig,
    genome_counts_fig = filtered$genome_counts,
    sample_order_fig = sample_order_fig,
    alpha_div_fig = alpha_div_fig,
    beta_mats_fig = beta_mats,
    nmds_limits_fig = nmds_limits_fig,
    nmds_fits_fig = nmds_fits_fig,
    cache_built_at = Sys.time()
  )
}

build_publication_hmsc_cache <- function(fit_model,
                                         model_obj,
                                         post_table,
                                         elements_response,
                                         genome_metadata,
                                         genome_tree,
                                         GIFT_db,
                                         support_threshold = 0.9) {
  negsupport_threshold <- 1 - support_threshold
  hmsc_tree <- genome_tree %>%
    ape::keep.tip(tip = model_obj$spNames)

  devil_ci_fig <- prepare_covariate_ci(fit_model, model_obj, "devil", genome_metadata)
  temp_ci_fig <- prepare_covariate_ci(fit_model, model_obj, "temperature", genome_metadata)
  interaction_ci_fig <- prepare_covariate_ci(
    fit_model, model_obj, "devil:temperature", genome_metadata
  )
  diversity_ci_fig <- prepare_covariate_ci(fit_model, model_obj, "diversity", genome_metadata)
  threeway_genomes_fig <- prepare_threeway_congruence_genomes(post_table, genome_metadata)

  list(
    hmsc_tree = hmsc_tree,
    post_table = post_table,
    elements_response = elements_response,
    support_threshold = support_threshold,
    negsupport_threshold = negsupport_threshold,
    varpart_fig = computeVariancePartitioning(fit_model),
    association_counts_fig = summarise_association_counts(post_table),
    congruence_summary_fig = summarise_devil_temp_congruence(post_table),
    congruence_taxa_fig = prepare_devil_temp_congruence_taxa(post_table, genome_metadata),
    congruence_func_fig = prepare_devil_temp_congruence_functional(elements_response, GIFT_db),
    devil_beta_fig = prepare_beta_support_data(
      fit_model, model_obj, "devil", genome_metadata, support_threshold
    ),
    temp_beta_fig = prepare_beta_support_data(
      fit_model, model_obj, "temperature", genome_metadata, support_threshold
    ),
    interaction_beta_fig = prepare_beta_support_data(
      fit_model, model_obj, "devil:temperature", genome_metadata, support_threshold
    ),
    devil_ci_fig = devil_ci_fig,
    temp_ci_fig = temp_ci_fig,
    interaction_ci_fig = interaction_ci_fig,
    diversity_ci_fig = diversity_ci_fig,
    devil_ci_top_fig = select_top_genomes_ci(devil_ci_fig, n_top = 20),
    temp_ci_top_fig = select_top_genomes_ci(temp_ci_fig, n_top = 20),
    interaction_ci_top_fig = select_top_genomes_ci(interaction_ci_fig, n_top = 20),
    interaction_phylum_ci_fig = aggregate_by_taxonomy(interaction_ci_fig, tax_level = "phylum"),
    functional_diff_devil_fig = calculate_functional_differences(elements_response, "devil"),
    functional_diff_temp_fig = calculate_functional_differences(elements_response, "temperature"),
    functional_diff_interaction_fig = calculate_functional_beta_by_gift(
      interaction_ci_fig,
      elements_response,
      min_genomes = 10
    ),
    functional_diff_diversity_fig = calculate_functional_differences(elements_response, "diversity"),
    threeway_genomes_fig = threeway_genomes_fig,
    threeway_summary_fig = summarise_threeway_congruence(threeway_genomes_fig),
    cache_built_at = Sys.time()
  )
}

save_publication_cache <- function(cache, path) {
  dir <- dirname(path)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
  cache_env <- list2env(cache, parent = emptyenv())
  save(list = names(cache), file = path, envir = cache_env)
  invisible(path)
}

require_publication_cache <- function(path, chapter_hint) {
  if (!file.exists(path)) {
    stop(
      "Missing ", path, ". ", chapter_hint,
      call. = FALSE
    )
  }
}

#' Load publication figure caches into the global environment.
#'
#' @param base_hint Error message if `publication_base.Rdata` is missing.
#' @param hmsc_hint Error message if `publication_hmsc.Rdata` is missing.
load_publication_figure_caches <- function(
    base_hint = paste(
      "Knit chapter 7 (beta diversity; requires chapters 1 and 5) to build",
      publication_cache_paths()$base, "."
    ),
    hmsc_hint = paste(
      "Knit chapter 14 (HMSC analysis; requires chapters 5 and 13) to build",
      publication_cache_paths()$hmsc, "."
    )) {
  paths <- publication_cache_paths()
  require_publication_cache(paths$base, base_hint)
  require_publication_cache(paths$hmsc, hmsc_hint)
  load(paths$base, envir = .GlobalEnv)
  load(paths$hmsc, envir = .GlobalEnv)
  if (!exists("nmds_fits_fig", envir = .GlobalEnv, inherits = FALSE)) {
    assign(
      "nmds_fits_fig",
      purrr::imap(beta_mats_fig, ~ fit_nmds_ordination(.x)$nmds_obj),
      envir = .GlobalEnv
    )
  }
  invisible(paths)
}

save_publication_base_cache_from_disk <- function(
    landcover_path = "landcover_wide.csv",
    data_path = "data/data.Rdata",
    beta_path = "data/beta.Rdata",
    cache_path = publication_cache_paths()$base,
    skip_if_no_landcover = TRUE) {
  if (!requireNamespace("hilldiv2", quietly = TRUE)) {
    stop("Package hilldiv2 is required to build the publication base cache.", call. = FALSE)
  }
  if (!requireNamespace("distillR", quietly = TRUE)) {
    stop("Package distillR is required to build the publication base cache.", call. = FALSE)
  }
  suppressPackageStartupMessages({
    library(hilldiv2)
    library(distillR)
  })

  if (!file.exists(landcover_path)) {
    if (isTRUE(skip_if_no_landcover)) {
      message(
        "Skipping publication base cache: ", landcover_path,
        " not found. Knit chapter 5 to export land cover."
      )
      return(invisible(FALSE))
    }
    stop(landcover_path, " does not exist.", call. = FALSE)
  }
  if (!file.exists(beta_path)) {
    stop(
      "Missing ", beta_path, ". Knit chapter 7 (beta diversity) first.",
      call. = FALSE
    )
  }
  if (!file.exists(data_path)) {
    stop("Missing ", data_path, ". Knit chapter 1 first.", call. = FALSE)
  }

  data_env <- new.env()
  load(data_path, envir = data_env)
  beta_env <- new.env()
  load(beta_path, envir = beta_env)
  beta_mats <- list(
    beta_q0n = beta_env$beta_q0n,
    beta_q1n = beta_env$beta_q1n,
    beta_q1p = beta_env$beta_q1p,
    beta_q1f = beta_env$beta_q1f
  )

  landcover_wide <- readr::read_csv(landcover_path, show_col_types = FALSE) %>%
    dplyr::rename(sample = dplyr::any_of(c("sample", "id")))

  gift_db <- if (exists("GIFT_db", envir = data_env, inherits = FALSE)) {
    data_env$GIFT_db
  } else {
    get("GIFT_db", envir = asNamespace("distillR"))
  }

  cache <- build_publication_base_cache(
    sample_metadata = data_env$sample_metadata,
    genome_counts_filt = data_env$genome_counts_filt,
    genome_tree = data_env$genome_tree,
    genome_gifts = data_env$genome_gifts,
    GIFT_db = gift_db,
    landcover_wide = landcover_wide,
    beta_mats = beta_mats
  )

  save_publication_cache(cache, cache_path)
  message("Saved publication base cache: ", cache_path)
  invisible(TRUE)
}

save_publication_figure <- function(plot, filename, width_mm = NULL, height_mm = NULL,
                                    dpi = NULL, dir = NULL, tight_layout = FALSE) {
  defaults <- publication_figure_defaults()
  dir <- if (is.null(dir)) defaults$dir else dir
  width_mm <- if (is.null(width_mm)) defaults$width_mm else width_mm
  height_mm <- if (is.null(height_mm)) defaults$height_mm else height_mm
  dpi <- if (is.null(dpi)) defaults$dpi else dpi

  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }

  out_path <- file.path(dir, filename)
  ext <- tolower(tools::file_ext(filename))
  device <- switch(
    ext,
    pdf = "pdf",
    png = "png",
    tiff = "tiff",
    tif = "tiff",
    jpg = "jpeg",
    jpeg = "jpeg",
    NULL
  )

  if (isTRUE(tight_layout)) {
    plot <- tight_layout_figure(plot)
    cowplot::save_plot(
      filename = out_path,
      plot = plot,
      base_width = mm_to_inches(width_mm),
      base_height = mm_to_inches(height_mm),
      dpi = dpi,
      bg = "white"
    )
  } else if (isTRUE(attr(plot, "phylo_gift_stacked_figure"))) {
    cowplot::save_plot(
      filename = out_path,
      plot = plot,
      base_width = mm_to_inches(width_mm),
      base_height = mm_to_inches(height_mm),
      dpi = dpi,
      bg = "white"
    )
  } else {
    ggplot2::ggsave(
      filename = out_path,
      plot = plot,
      width = width_mm,
      height = height_mm,
      units = "mm",
      dpi = dpi,
      device = device
    )
  }
  invisible(out_path)
}
