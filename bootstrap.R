conda_prefix <- Sys.getenv("CONDA_PREFIX")

if (nchar(conda_prefix) == 0) {
  stop("CONDA_PREFIX is not set. Are you inside a pixi environment?")
}

to_forward <- function(p) chartr("\\", "/", p)

conda_prefix <- to_forward(conda_prefix)

pixi_lib <- to_forward(file.path(conda_prefix, "lib", "R", "library"))
rprofile <- to_forward(file.path(conda_prefix, "lib", "R", "etc", "Rprofile.site"))

if (!dir.exists(pixi_lib)) {
  stop("Pixi R library not found at: ", pixi_lib)
}

lock_line <- paste0('.libPaths(c("', pixi_lib, '"))')

existing <- if (file.exists(rprofile)) readLines(rprofile, warn = FALSE) else character(0)
existing <- existing[!grepl("^\\s*\\.libPaths\\(", existing)]
existing <- vapply(existing, to_forward, character(1), USE.NAMES = FALSE)

writeLines(c(lock_line, existing), rprofile)

message("bootstrap: .libPaths locked to ", pixi_lib)
