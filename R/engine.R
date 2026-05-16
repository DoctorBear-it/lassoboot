# Internal: validate that an object conforms to the lb_engine interface.
# An engine must be a list with methods: fit, predict, coef, cv, sigma.
# Called by lb_spec() at construction time.
.validate_engine <- function(engine) {
  stop("Not yet implemented", call. = FALSE)
}
