
wilson.globals <- new.env(parent = emptyenv())

#' create a logger used within the package
#'
#' @param logfile Path to a file log messages should be written to. NULL (default) logs to the console only.
#' @param level Threshold level of the logger. Messages below this level are dropped. One of "TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL".
#' @param name Name of the logger. \code{lgr} caches loggers by name, so distinct names (e.g. a Shiny session token) yield independent loggers.
#'
#' @details Thin convenience wrapper around \code{\link[lgr]{get_logger}} that sets the threshold and, optionally, attaches a file appender (\code{\link[lgr]{AppenderFile}}). The returned object can be handed to \code{\link{set_logger}}.
#'
#' @return An \code{lgr} \code{\link[lgr]{Logger}} object.
#'
#' @examples
#' logger <- create_logger(level = "INFO")
#' set_logger(logger, token = "example")
#'
#' @export
create_logger <- function(logfile = NULL, level = "INFO", name = "wilson") {
  logger <- lgr::get_logger(name)
  # lgr caches loggers by name, so reset appenders to keep repeated calls idempotent
  logger$set_appenders(list())
  logger$set_threshold(level)
  if (!is.null(logfile)) {
    logger$add_appender(lgr::AppenderFile$new(logfile), name = "file")
    # log to the file only (mirrors the old log4r file logger); without a file
    # appender we keep propagation so messages still reach the root console.
    logger$set_propagate(FALSE)
  }
  logger
}

#' set a logger used within the package
#'
#' @param logger A logger object, see \code{\link{create_logger}} or \code{\link[lgr]{get_logger}}. NULL to disable logging.
#' @param token Set a unique identifier for this logger.
#'
#' @details This function will save each logger in the wilson.globals environment. Each logger is stored by the name 'logger'[token] (e.g. 'logger6b821824b0b53b1a3e8f531a34d0d6e6').
#' @details Use onSessionEnded to clean up after logging. See \code{\link[shiny]{onFlush}}.
#'
#' @export
set_logger <- function(logger, token = NULL) {
  if (methods::is(logger, "Logger")) {
    assign(x = paste0("logger", token), value = logger, envir = wilson.globals)
  } else if (is.null(logger)) {
    rm(list = paste0("logger", token), envir = wilson.globals)
  }
}

#' logger message convenience function
#'
#' @param message String of message to be written in log. See \code{\link[lgr]{Logger}}.
#' @param level Set priority level of the message (number or character). See \code{\link[lgr]{Logger}}.
#' @param token Use token bound to this identifier.
#'
#' @details Does nothing if logger doesn't exist.
#'
log_message <- function(message, level = c("DEBUG", "INFO", "WARN", "ERROR", "FATAL"), token = NULL) {
  if (exists(paste0("logger", token), envir = wilson.globals)) {
    logger <- get(paste0("logger", token), envir = wilson.globals)

    # pass message as a value (not a format string) so a literal "%" cannot break logging
    switch(level,
      DEBUG = logger$debug("%s", message),
      INFO = logger$info("%s", message),
      WARN = logger$warn("%s", message),
      ERROR = logger$error("%s", message),
      FATAL = logger$fatal("%s", message)
    )
  }
}
