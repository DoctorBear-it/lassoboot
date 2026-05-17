#' @export
format.lb_spec <- function(x, ...) {
  unc_str <- if (is.null(x$uncertainty)) {
    "none"
  } else {
    paste0(nrow(x$uncertainty), " column(s): ",
           paste(x$uncertainty$term, collapse = ", "))
  }
  drv_str <- if (is.null(x$derive)) "none" else paste0(length(x$derive), " expression(s)")
  lines <- c(
    "<lb_spec>",
    paste0("  formula:     ", deparse(x$formula, width.cutoff = 60L)),
    paste0("  data:        ", nrow(x$data), " rows x ", ncol(x$data), " columns"),
    paste0("  uncertainty: ", unc_str),
    paste0("  derive:      ", drv_str),
    paste0("  constraints: ", length(x$constraints), " column(s)"),
    paste0("  engine:      ", class(x$engine)[1L]),
    paste0("  control:     ", format(x$control))
  )
  paste(lines, collapse = "\n")
}

#' @export
print.lb_spec <- function(x, ...) {
  cat(format(x, ...), "\n")
  invisible(x)
}

#' @export
format.lb_fit <- function(x, ...) {
  lines <- c(
    format(x$spec),
    "<lb_fit>",
    paste0("  lambda:      ", signif(x$lambda, 4L)),
    paste0("  sigma_hat:   ", signif(x$sigma_hat, 4L),
           "  (method: ", x$spec$control$sigma_method, ")")
  )
  paste(lines, collapse = "\n")
}

#' @export
print.lb_fit <- function(x, ...) {
  cat(format(x, ...), "\n")
  invisible(x)
}

#' @export
format.lb_boot <- function(x, ...) {
  lines <- c(
    format(x$fit),
    "<lb_boot>",
    paste0("  B:           ", x$B, " iterations"),
    paste0("  elapsed:     ", round(x$elapsed_sec, 1L), "s"),
    paste0("  path stored: ", !is.null(x$path_coefs)),
    paste0("  models kept: ", !is.null(x$models))
  )
  paste(lines, collapse = "\n")
}

#' @export
print.lb_boot <- function(x, ...) {
  cat(format(x, ...), "\n")
  invisible(x)
}
