
#' Progress bar in the terminal
#'
#' Progress bars are configurable, may include percentage, elapsed time,
#' and/or the estimated completion time. They work in the command line,
#' in Emacs and in R Studio. The progress package was heavily influenced by
#' https://github.com/tj/node-progress
#'
#' @section Creating the progress bar:
#' A progress bar is an R6 object, that can be created with
#' \code{progress_bar$new()}. It has the following arguments:
#' \describe{
#'   \item{format}{The format of the progress bar. A number of
#'     tokens can be used here, see them below. It defaults to
#'     \code{"[:bar] :percent"}, which means that the progress
#'     bar is within brackets on the left, and the percentage
#'     is printed on the right.}
#'   \item{total}{Total number of ticks to complete. Defaults to 100.}
#'   \item{width}{Width of the progress bar. Default is the current
#'     terminal width (see \code{options()} and \code{width}) minus two.}
#'   \item{stream}{The output stream to put the progress bar on.
#'     It defaults to \code{stderr()}, except in R Studio that has
#'     a bug when printing on the standard error, so there we use
#'     \code{stdout}. If the output stream is not a terminal and
#'     we are not in R Studio, then no progress bar is printed.}
#'   \item{complete}{Completion character, defaults to \code{=}.}
#'   \item{incomplete}{Incomplete character, defaults to \code{-}.}
#'   \item{callback}{Callback function to call when the progress
#'     bar finishes. The progress bar object itself is passed to it
#'     as the single parameter.}
#'   \item{clear}{Whether to clear the progress bar on completion.
#'     Defaults to \code{TRUE}.}
#'   \item{show_after}{Amount of time in seconds, after which the progress
#'     bar is shown on the screen. For very short processes,
#'     it is probably not worth showing it at all. Defaults to two
#'     tenth of a second.}
#'   \item{force}{Whether to force showing the progress bar,
#'     even if the given (or default) stream does not seem support it.}
#' }
#'
#' @section Using the progress bar:
#' Three functions can update a progress bar. \code{progress_bar$tick()}
#' increases the number of ticks by one (or another specified value).
#' \code{progress_bar$update()} sets a given ratio and
#' \code{progress_bar$terminate()} removes the progress bar.
#' \code{progress_bar$finished} can be used to see if the progress bar has
#' finished.
#'
#' The progress bar is displayed after the first `tick` command.
#' This might not be desirable for long computations, because
#' nothing is shown before the first tick. It is good practice to
#' call `tick(0)` at the beginning of the computation or download,
#' which shows the progress bar immediately.
#'
#' @section Tokens:
#' They can be used in the \code{format} argument when creating the
#' progress bar.
#' \describe{
#'   \item{:bar}{The progress bar itself.}
#'   \item{:current}{Current tick number.}
#'   \item{:total}{Total ticks.}
#'   \item{:elapsed}{Elapsed time in seconds.}
#'   \item{:elapsedfull}{Elapsed time in hh:mm:ss format.}
#'   \item{:eta}{Estimated completion time in seconds.}
#'   \item{:percent}{Completion percentage.}
#'   \item{:rate}{Download rate, bytes per second. See example below.}
#'   \item{:bytes}{Shows :current, formatted as bytes. Useful
#'      for downloads or file reads if you don't know the size of the
#'      file in advance. See example below.}
#'   \item{:spin}{Shows a spinner that updates even when progress is
#'      advanced by zero.}
#' }
#'
#' Custom tokens are also supported, and you need to pass their
#' values to \code{progress_bar$tick()} or \code{progress_bar$update()},
#' in a named list. See example below.
#'
#' @importFrom R6 R6Class
#'
#' @export
#' @examples
#'
#' ## We don't run the examples on CRAN, because they takes >10s
#' ## altogether. Unfortunately it is hard to create a set of
#' ## meaningful progress bar examples that also run quickly.
#' \dontrun{
#' 
#' ## Basic
#' pb <- progress_bar$new(total = 100)
#' for (i in 1:100) {
#'   pb$tick()
#'   Sys.sleep(1 / 100)
#' }
#'
#' ## ETA
#' pb <- progress_bar$new(
#'   format = "  downloading [:bar] :percent eta: :eta",
#'   total = 100, clear = FALSE, width= 60)
#' for (i in 1:100) {
#'   pb$tick()
#'   Sys.sleep(1 / 100)
#' }
#'
#' ## Elapsed time
#' pb <- progress_bar$new(
#'   format = "  downloading [:bar] :percent in :elapsed",
#'   total = 100, clear = FALSE, width= 60)
#' for (i in 1:100) {
#'   pb$tick()
#'   Sys.sleep(1 / 100)
#' }
#'
#' ## Spinner
#' pb <- progress_bar$new(
#'   format = "(:spin) [:bar] :percent",
#'   total = 30, clear = FALSE, width = 60)
#' for (i in 1:30) {
#'   pb$tick()
#'   Sys.sleep(3 / 100)
#' }
#'
#' ## Custom tokens
#' pb <- progress_bar$new(
#'   format = "  downloading :what [:bar] :percent eta: :eta",
#'   clear = FALSE, total = 200, width = 60)
#' f <- function() {
#'   for (i in 1:100) {
#'     pb$tick(tokens = list(what = "foo   "))
#'     Sys.sleep(2 / 100)
#'   }
#'   for (i in 1:100) {
#'     pb$tick(tokens = list(what = "foobar"))
#'     Sys.sleep(2 / 100)
#'   }
#' }
#' f()
#'
#' ## Download (or other) rates
#' pb <- progress_bar$new(
#'   format = "  downloading foobar at :rate, got :bytes in :elapsed",
#'   clear = FALSE, total = 1e7, width = 60)
#' f <- function() {
#'   for (i in 1:100) {
#'     pb$tick(sample(1:100 * 1000, 1))
#'     Sys.sleep(2/100)
#'   }
#'   pb$tick(1e7)
#'   invisible()
#' }
#' f()
#'
#' }
#'
#' @name progress_bar
NULL

progress_bar <- R6Class("progress_bar",

  public = list(

    initialize = function(format = "[:bar] :percent", total = 100,
      width = getOption("width") - 2, stream = NULL, complete = "=",
      incomplete = "-", callback = function(self) {}, clear = TRUE,
      show_after = 0.2, force = FALSE) {
        pb_init(self, private, format, total, width, stream, complete,
          incomplete, callback, clear, show_after, force)
    },
    tick = function(len = 1, tokens = list()) {
      pb_tick(self, private, len, tokens) },
    update = function(ratio, tokens = list()) {
      pb_update(self, private, ratio, tokens) },
    message = function(msg) {
      pb_message(self, private, msg) },
    terminate = function() { pb_terminate(self, private) },
    finished = FALSE
  ),

  private = list(

    render = function(tokens) { pb_render(self, private, tokens) },
    ratio = function() { pb_ratio(self, private) },

    first = TRUE,
    supported = NA,
    format = NULL,
    total = NULL,
    current = 0,
    width = NULL,
    stream = NULL,
    chars = list(
      complete = "=",
      incomplete = "-"
    ),
    callback = NULL,
    clear = NULL,
    show_after = NULL,
    last_draw = "",

    start = NULL,
    toupdate = FALSE,
    complete = FALSE,

    spin = NULL,

    has_token = c(current = FALSE, total = FALSE, elapsedfull = FALSE,
      elapsed = FALSE, eta = FALSE, percent = FALSE, rate = FALSE,
      bytes = FALSE, bar = FALSE, spin = FALSE)
  )
)

pb_init <- function(self, private, format, total, width, stream,
                    complete, incomplete, callback, clear, show_after,
                    force) {

  stream <- default_stream(stream)

  assert_character_scalar(format)
  assert_positive_scalar(total)
  assert_nonzero_count(width)
  assert_connection(stream)
  assert_single_char(complete)
  assert_single_char(incomplete)
  assert_function(callback)
  assert_flag(clear)
  assert_nonnegative_scalar(show_after)

  private$first <- TRUE
  private$supported <- force || is_supported(stream)
  private$format <- format
  private$total <- total
  private$width <- width
  private$stream <- stream
  private$chars$complete <- complete
  private$chars$incomplete <- incomplete
  private$callback <- callback
  private$clear <- clear
  private$show_after <- as.difftime(show_after, units = "secs")
  private$spin <- spin_symbols()

  private$has_token <- pb_update_has_token(private$has_token, format)

  self
}

pb_update_has_token <- function(tokens, format) {
  for (n in names(tokens)) {
    tokens[n] <- grepl(paste0(":", n), format, fixed = TRUE)
  }

  tokens
}

pb_tick <- function(self, private, len, tokens) {

  assert_scalar(len)
  assert_named_or_empty_list(tokens)
  stopifnot(!self$finished)

  if (private$first) {
    private$first <- FALSE
    private$start <- Sys.time()
  }

  private$current <- private$current + len

  if (!private$toupdate) {
    if (Sys.time() - private$start >= private$show_after) {
      private$toupdate <- TRUE
    }
  }

  if (private$current >= private$total) private$complete <- TRUE

  if (private$toupdate) private$render(tokens)

  if (private$complete) {
    self$terminate()
    private$callback(self)
  }

  self
}

#' @importFrom prettyunits vague_dt pretty_bytes
#' @importFrom utils flush.console

pb_ratio <- function(self, private) {
  ratio <- (private$current / private$total)
  ratio <- max(ratio, 0)
  ratio <- min(ratio, 1)
  ratio
}

#' @importFrom hms as.hms
#' @importFrom crayon col_nchar col_substr

pb_render <- function(self, private, tokens) {

  if (! private$supported) return(invisible())

  str <- private$format

  if (private$has_token["percent"]) {
    percent <- private$ratio() * 100
    str <- sub(str, pattern = ":percent", replacement =
                 paste0(format(round(percent), width = 3), "%"))
  }

  if (private$has_token["elapsedfull"]) {
    elapsed <- Sys.time() - private$start
    units(elapsed) <- "secs"
    elapsedfull <- format(as.hms(as.integer(elapsed)))
    str <- sub(str, pattern = ":elapsedfull", replacement = elapsedfull)
  }

  if (private$has_token["elapsed"]) {
    elapsed_secs <- Sys.time() - private$start
    elapsed <- vague_dt(elapsed_secs, format = "terse")
    str <- sub(str, pattern = ":elapsed", replacement = elapsed)
  }

  if (private$has_token["eta"]) {
    percent <- private$ratio() * 100
    elapsed_secs <- Sys.time() - private$start
    eta_secs <- if (percent == 100) {
      0
    } else {
      elapsed_secs * (private$total / private$current - 1.0)
    }
    eta <- as.difftime(eta_secs, units = "secs")
    if (is.nan(eta) || eta == Inf) {
      eta <- " ?s"
    } else {
      eta <- vague_dt(eta, format = "terse")
    }
    str <- sub(str, pattern = ":eta", replacement = eta)
  }

  if (private$has_token["rate"]) {
    elapsed_secs <- Sys.time() - private$start
    rate <- private$current / as.double(elapsed_secs, units = "secs")
    if (is.nan(rate)) rate <- 0
    rate <- paste0(pretty_bytes(round(rate)), "/s")
    str <- sub(str, pattern = ":rate", replacement = rate)
  }

  if (private$has_token["current"]) {
    str <- sub(str, pattern = ":current",
               replacement = round(private$current))
  }

  if (private$has_token["total"]) {
    str <- sub(str, pattern = ":total", replacement = round(private$total))
  }

  if (private$has_token["bytes"]) {
    bytes <- pretty_bytes(round(private$current))
    str <- sub(str, pattern = ":bytes", replacement = bytes)
  }

  if (private$has_token["spin"]) {
    ## NOTE: fixed = TRUE is needed here or "\\" causes trouble with
    ## the replacement (I think it's interpreted as an invalid
    ## backreference).
    str <- sub(str, pattern = ":spin", replacement = private$spin(), fixed = TRUE)
  }

  for (t in names(tokens)) {
    txt <- tryCatch(as.character(tokens[[t]])[[1]], error = function(e) "???")
    str <- gsub(paste0(":", t), txt, str, fixed = TRUE)
  }

  if (private$has_token["bar"]) {
    bar_width <- col_nchar(sub(str, pattern = ":bar", replacement = ""))
    bar_width <- private$width - bar_width
    bar_width <- max(0, bar_width)

    ratio <- private$ratio()
    complete_len <- round(bar_width * ratio)
    complete <- paste(rep("", complete_len + 1),
                      collapse = private$chars$complete)
    incomplete <- paste(rep("", bar_width - complete_len + 1),
                        collapse = private$chars$incomplete)

    str <- sub(":bar", paste0(complete, incomplete), str)
  }

  if (col_nchar(str) > private$width) {
    str <- paste0(col_substr(str, 1, private$width - 3), "...")
  }

  if (private$last_draw != str) {
    if (col_nchar(private$last_draw) > col_nchar(str)) {
      clear_line(private$stream, private$width)
    }
    cursor_to_start(private$stream)
    cat(str, file = private$stream)
    private$last_draw <- str
  }

  flush.console()

  self
}

pb_update <- function(self, private, ratio, tokens) {
  assert_ratio(ratio)
  stopifnot(!self$finished)

  goal <- floor(ratio * private$total)
  self$tick(goal - private$current, tokens)
}

pb_message <- function(self, private, msg) {
  assert_character(msg)
  stopifnot(!self$finished)

  too_long <- col_nchar(msg) > private$width
  if (any(too_long)) {
    msg[too_long] <- paste0(col_substr(msg[too_long], 1, private$width - 3), "...")
  }

  if (!private$supported) {
    cat(msg, sep = "\n", file = private$stream)
  } else {
    clear_line(private$stream, private$width)
    cursor_to_start(private$stream)
    cat(msg, sep = "\n", file = private$stream)
    if (!self$finished) {
      cat(private$last_draw, file = private$stream)
    }
  }
}

pb_terminate <- function(self, private) {
  self$finished <- TRUE
  if (!private$supported || !private$toupdate) return(invisible())
  if (private$clear) {
    clear_line(private$stream, private$width)
    cursor_to_start(private$stream)
  } else {
    cat("\n", file = private$stream)
  }
}

spin_symbols <- function() {
  sym <- c("-", "\\", "|", "/")
  i <- 0L
  n <- length(sym)
  function() {
    sym[[i <<- if (i >= n) 1L else i + 1L]]
  }
}
