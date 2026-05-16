# Internal matrixStats-based prediction summary helpers.
# The prediction pipeline is always matrix-based: an n_grid x B numeric matrix
# is the internal representation; summaries computed via
# matrixStats::rowQuantiles, rowMeans2, rowSds. No nest()/unnest() in the
# hot path.
