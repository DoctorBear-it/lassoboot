# Claude Code Instructions for lassoboot

## Read first, every session

1.  `specs/lassoboot-SPEC.md` — the authoritative package specification.
    This is the source of truth. If you disagree with it, say so before
    changing anything.
2.  `specs/SPEC.md` — the pixi + R-package development environment
    setup. This is the environment spec (despite the generic filename).
    Read it once per session. Do not invent your own dev workflow.
3.  Any `specs/phase*-carryforward-SPEC.md` or
    `specs/phase*-implementation-plan.md` files — these capture
    in-flight design decisions from prior phases.
4.  `reference/lasso_bootstrap_prototype.qmd` — read-only prototype. Do
    NOT visually port code from this file. Reimplement against the spec.

## Shell and execution environment — read this BEFORE running any command

This project is on **Windows 11**. The Bash tool you have available runs
Git Bash (MSYS), NOT PowerShell or cmd. Use POSIX-style commands and
paths (forward slashes, `$VAR`-style env vars, `export`, `&&`).

### How to run pixi tasks

**Always use the Bash tool, never PowerShell.** The standard incantation
is:

``` bash
pixi run <task>
```

The Bash tool runs in the project root by default
(`C:/Projects/lassoboot`). You do not need to `cd` first.

### The Rtools44 PATH requirement (Windows-specific)

`pixi run check` and `pixi run check-fast` invoke `R CMD CHECK`, which
on Windows requires **Rtools44** on `PATH` to run `make`/`gcc`. Rtools44
is installed at `C:\rtools44` but **not** added to PATH by default —
pixi does not manage Rtools.

Every time you run `check` or `check-fast`, prepend the Rtools paths to
`PATH` in the **same Bash command** as the pixi invocation:

``` bash
export PATH="/c/rtools44/usr/bin:/c/rtools44/mingw64/bin:$PATH" && pixi run check-fast
```

Notes: - Forward slashes and `/c/` instead of `C:\` — this is Git Bash,
not cmd. - `export ... && pixi run ...` chained in one command — each
Bash tool invocation runs in a fresh shell, so a separate `export` call
would be lost before the next `pixi run`. - Do NOT use PowerShell syntax
(`$env:PATH = ...`). It will not work through the Bash tool.

### Pixi tasks that do NOT need Rtools

These work with just `pixi run <task>`:

``` bash
pixi run bootstrap     # rewrite Rprofile.site .libPaths lock
pixi run document      # roxygen2::roxygenise()
pixi run test          # devtools::test()
pixi run install       # devtools::install()
pixi run libpaths      # diagnostic — shows .libPaths()
```

These DO require Rtools44 on PATH (use the `export` prefix):

``` bash
export PATH="/c/rtools44/usr/bin:/c/rtools44/mingw64/bin:$PATH" && pixi run check
export PATH="/c/rtools44/usr/bin:/c/rtools44/mingw64/bin:$PATH" && pixi run check-fast
export PATH="/c/rtools44/usr/bin:/c/rtools44/mingw64/bin:$PATH" && pixi run build
```

### If you see “Rtools is required” or “make not found”

That is the symptom of running `check` or `build` without the Rtools
PATH prefix. The fix is the `export PATH=...` line above. Do not try to
install Rtools yourself, do not invoke
[`pkgbuild::check_build_tools()`](https://pkgbuild.r-lib.org/reference/has_build_tools.html),
do not switch to PowerShell. Just prefix the PATH and rerun.

### Acceptable R CMD check output on this dev machine

The “future file timestamps / unable to verify current time” NOTE is a
build-environment artifact (no NTP reachable from the dev machine). It
is documented as ignorable in
`specs/phase3-postcommit-carryforward-SPEC.md`.

`0 errors, 0 warnings, 1 NOTE (timestamps)` is a clean run. Anything
else needs investigation.

A trailing “Error: Quarto is required” message after `R CMD check`
completes successfully is **unrelated** devtools noise — devtools probes
for Quarto when it sees `.qmd` files in the build directory. It does not
affect check status. Ignore it unless `R CMD check` itself reports
errors.

## Git workflow

`specs/`, `reference/`, and `CLAUDE.md` are gitignored. **Do not** try
to `git add specs/...` — it will fail with “ignored by .gitignore”.
Stage only `R/`, `tests/`, `man/`, `DESCRIPTION`, `NAMESPACE`, and
`.Rbuildignore` / `.gitignore` if you edit those.

If you need to record a Phase plan or carry-forward note, write it to
`specs/` locally; it stays out of git on purpose so we keep the public
history clean of in-flight artifacts.

## Execution discipline

- Follow the phased execution plan in §14 of `specs/lassoboot-SPEC.md`.
  Complete a phase before starting the next. Commit and tag at each
  phase boundary.
- Do not write tests for code that doesn’t exist.
- Do not write vignettes before the API stabilises (Phase 6, not
  earlier).
- Run `pixi run document` after any roxygen edit, before committing.
- Run `pixi run test` AND the PATH-prefixed `pixi run check-fast` before
  claiming a phase is done. Both must pass; do not commit if one is red.

## Tests

- Use `expect_equal`, `expect_named`, `expect_error`, etc. with concrete
  values. Never write `expect_true(TRUE)` or `expect_equal(1, 1)` style
  placeholder assertions.
- When the bootstrap’s randomness makes a behavioral assertion flaky,
  either fix the seed and assert deterministically, or replace the
  behavioral assertion with a stronger schema check plus a separate
  deterministic unit test on the underlying primitive. A test that
  passes regardless of whether the function works is worse than no test
  at all.
- Integration tests that take more than ~30 seconds should be gated
  behind `skip_on_cran()` plus an env-var opt-in
  (`Sys.getenv("LASSOBOOT_<NAME>_TEST")`). See
  `tests/testthat/test-integration-coverage.R` for the pattern.

## When in doubt

- If the spec is ambiguous, ask before guessing.
- If you find yourself wanting to deviate from the spec, propose the
  change in chat before implementing it.
- If something the prototype does seems wrong, refer to §7 of the
  package spec (“Bugs and Smells”) — your concern may already be
  addressed there.
- If a tool call fails for environmental reasons (PATH, shell syntax,
  permissions), stop and re-read this file before flailing. Most
  environment failures here are documented above.
