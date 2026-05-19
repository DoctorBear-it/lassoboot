#' Standard k-fold cross-validation fold generator
#'
#' @param k Number of folds. Default `10`.
#'
#' @return A fold-generator closure `function(data) -> integer vector` of fold
#'   IDs the same length as `nrow(data)`.
#' @examples
#' gen   <- lb_folds_kfold(k = 5)
#' folds <- gen(concrete)
#' table(folds)
#' @export
lb_folds_kfold <- function(k = 10) {
  k <- .check_k(k, "k")
  function(data) {
    n <- nrow(data)
    if (n < k) {
      cli::cli_abort(
        "Cannot create {k} folds from {n} row{?s}; reduce {.arg k}."
      )
    }
    sample(rep_len(seq_len(k), n))
  }
}

#' Grouped k-fold fold generator (prevents within-group train/test leakage)
#'
#' Assigns whole groups to the same fold so that no group's observations appear
#' in both training and test sets.
#'
#' @param group Column name (string) whose levels define groups.
#' @param k Number of folds. Default `10`.
#'
#' @return A fold-generator closure `function(data) -> integer vector`.
#' @examples
#' gen   <- lb_folds_grouped("mixture", k = 5)
#' folds <- gen(concrete)
#' # Each mixture's observations share the same fold
#' tapply(folds, concrete$mixture, unique)
#' @export
lb_folds_grouped <- function(group, k = 10) {
  if (!is.character(group) || length(group) != 1L || group == "") {
    cli::cli_abort("{.arg group} must be a single non-empty string.")
  }
  k <- .check_k(k, "k")
  function(data) {
    if (!group %in% names(data)) {
      cli::cli_abort(
        "Group column {.val {group}} not found in data."
      )
    }
    col      <- as.character(data[[group]])
    groups   <- unique(col)
    n_groups <- length(groups)
    if (n_groups < k) {
      cli::cli_abort(
        "Cannot create {k} folds from {n_groups} group{?s}; reduce {.arg k}."
      )
    }
    # Shuffle groups, then assign folds round-robin so all folds are filled.
    shuffled   <- sample(groups)
    fold_ids   <- rep_len(seq_len(k), n_groups)   # 1,2,...,k,1,2,...
    group_fold <- stats::setNames(fold_ids, shuffled)
    as.integer(group_fold[col])
  }
}

#' Nested fold generator with outer grouping and optional inner stratification
#'
#' Places whole outer groups in the same fold (no leakage of group identity
#' across train/test) and, when `inner` is supplied, stratifies the assignment
#' of outer groups to folds so each fold sees a balanced distribution of the
#' inner variable.
#'
#' @param outer Column name (string) defining the outer grouping (no leakage).
#' @param inner Column name (string) for inner stratification within each fold,
#'   or `NULL`. Default `NULL`.
#' @param k_outer Number of outer folds. Default `5`.
#' @param k_inner Reserved for future sub-folding; must be `NULL` in v0.1.
#'
#' @return A fold-generator closure `function(data) -> integer vector`.
#' @examples
#' # Each mixture has exactly one clay type, so inner stratification works
#' gen   <- lb_folds_nested(outer = "mixture", inner = "clay", k_outer = 5)
#' folds <- gen(concrete)
#' table(folds)
#' @export
lb_folds_nested <- function(outer, inner = NULL, k_outer = 5, k_inner = NULL) {
  if (!is.character(outer) || length(outer) != 1L || outer == "") {
    cli::cli_abort("{.arg outer} must be a single non-empty string.")
  }
  if (!is.null(inner) && (!is.character(inner) || length(inner) != 1L || inner == "")) {
    cli::cli_abort("{.arg inner} must be a single non-empty string or NULL.")
  }
  k_outer <- .check_k(k_outer, "k_outer")
  if (!is.null(k_inner)) {
    cli::cli_inform(
      c("i" = "{.arg k_inner} is reserved for future use and is ignored in v0.1.")
    )
  }

  function(data) {
    if (!outer %in% names(data)) {
      cli::cli_abort("Outer grouping column {.val {outer}} not found in data.")
    }
    outer_vals <- unique(data[[outer]])
    n_outer    <- length(outer_vals)
    if (n_outer < k_outer) {
      cli::cli_abort(
        "Cannot create {k_outer} outer folds from {n_outer} group{?s}."
      )
    }

    if (!is.null(inner)) {
      if (!inner %in% names(data)) {
        cli::cli_abort("Inner stratification column {.val {inner}} not found in data.")
      }
      # Require each outer group to have exactly one unique inner value.
      # Mixed-stratum groups are not supported: stratification on a modal inner
      # value would silently collapse all mixed groups to the same stratum,
      # defeating the purpose of inner stratification.
      outer_col <- data[[outer]]
      inner_col <- data[[inner]]
      for (g in outer_vals) {
        inner_for_g <- unique(inner_col[outer_col == g])
        if (length(inner_for_g) > 1L) {
          cli::cli_abort(c(
            "Outer group {.val {g}} contains multiple inner values \\
             ({.val {as.character(inner_for_g)}}).",
            "i" = "Nested fold stratification requires one inner value per \\
                   outer group.",
            "i" = "Pre-aggregate to one row per ({.arg outer}, {.arg inner}) \\
                   combination, or use {.fn lb_folds_grouped} without inner \\
                   stratification."
          ))
        }
      }
      group_inner <- stats::setNames(
        as.character(inner_col[match(outer_vals, outer_col)]),
        as.character(outer_vals)
      )

      # Stratified cyclic assignment:
      # 1. Within each stratum, shuffle the groups.
      # 2. Concatenate strata: [shuffled_lvl1, shuffled_lvl2, ...].
      # 3. Assign folds cyclically across the concatenated list.
      # This guarantees all k_outer folds are filled (no per-stratum restart).
      inner_levels   <- unique(group_inner)
      ordered_groups <- character(0L)
      for (lvl in inner_levels) {
        in_stratum     <- outer_vals[group_inner == lvl]
        ordered_groups <- c(ordered_groups, sample(in_stratum))
      }
      fold_ids      <- rep_len(seq_len(k_outer), n_outer)
      fold_of_group <- stats::setNames(fold_ids, as.character(ordered_groups))
    } else {
      shuffled      <- sample(outer_vals)
      fold_of_group <- stats::setNames(
        rep_len(seq_len(k_outer), n_outer),
        as.character(shuffled)
      )
    }

    as.integer(fold_of_group[as.character(data[[outer]])])
  }
}

#' Block fold generator
#'
#' Treats each unique value of `block` as an indivisible unit and assigns whole
#' blocks to folds in their natural order (no shuffling), preserving temporal or
#' spatial ordering.
#'
#' @param block Column name (string) defining contiguous blocks assigned as
#'   complete units to folds.
#' @param k Number of folds. Default `5`.
#'
#' @return A fold-generator closure `function(data) -> integer vector`.
#' @examples
#' gen   <- lb_folds_blocked("mixture", k = 5)
#' folds <- gen(concrete)
#' table(folds)
#' @export
lb_folds_blocked <- function(block, k = 5) {
  if (!is.character(block) || length(block) != 1L || block == "") {
    cli::cli_abort("{.arg block} must be a single non-empty string.")
  }
  k <- .check_k(k, "k")
  function(data) {
    if (!block %in% names(data)) {
      cli::cli_abort("Block column {.val {block}} not found in data.")
    }
    # Preserve appearance order of blocks
    blocks_ordered <- unique(data[[block]])
    n_blocks <- length(blocks_ordered)
    if (n_blocks < k) {
      cli::cli_abort(
        "Cannot create {k} folds from {n_blocks} block{?s}; reduce {.arg k}."
      )
    }
    fold_assignment <- stats::setNames(
      rep(seq_len(k), length.out = n_blocks),
      as.character(blocks_ordered)
    )
    as.integer(fold_assignment[as.character(data[[block]])])
  }
}

#' Custom fold generator
#'
#' @param fn A function with signature `function(data) -> integer vector` of
#'   fold IDs the same length as `nrow(data)`, with values in `1:k` for some
#'   `k`. The function is responsible for any re-randomisation across CV
#'   repetitions (typically by not closing over a fixed state).
#'
#' @return The input `fn`, validated and classed as an `lb_fold_generator`.
#' @examples
#' gen   <- lb_folds_custom(function(data) sample(rep(1:5, length.out = nrow(data))))
#' folds <- gen(concrete)
#' table(folds)
#' @export
lb_folds_custom <- function(fn) {
  if (!is.function(fn)) {
    cli::cli_abort(
      "{.arg fn} must be a function; got {.cls {class(fn)}}."
    )
  }
  # Wrap to validate output at call time
  function(data) {
    result <- fn(data)
    .validate_fold_ids(result, nrow(data), "lb_folds_custom")
    result
  }
}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

.check_k <- function(k, arg) {
  if (!is.numeric(k) || length(k) != 1L || !is.finite(k) || k < 2L) {
    cli::cli_abort(
      "{.arg {arg}} must be an integer >= 2; got {.val {k}}."
    )
  }
  as.integer(k)
}

.validate_fold_ids <- function(ids, n, src = "fold generator") {
  if (!is.integer(ids) && !is.numeric(ids)) {
    cli::cli_abort("{src} must return an integer vector; got {.cls {class(ids)}}.")
  }
  ids <- as.integer(ids)
  if (length(ids) != n) {
    cli::cli_abort(
      "{src} returned {length(ids)} fold ID{?s} but data has {n} row{?s}."
    )
  }
  if (any(is.na(ids))) {
    cli::cli_abort("{src} returned NA fold IDs.")
  }
  k <- max(ids)
  if (min(ids) < 1L) {
    cli::cli_abort("{src} returned fold IDs < 1.")
  }
  # Check no empty folds
  for (f in seq_len(k)) {
    if (!any(ids == f)) {
      cli::cli_abort("{src} produced empty fold {f}.")
    }
  }
  invisible(ids)
}
