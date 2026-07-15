context("Logging")

test_that("logger can be created and deleted", {
  logger <- create_logger()
  token <- "test"

  expect_false(exists(paste0("logger", token), envir = wilson.globals))
  set_logger(logger = logger, token = token)
  expect_identical(logger, get(paste0("logger", token), envir = wilson.globals))
  set_logger(logger = NULL, token = token)
  expect_false(exists(paste0("logger", token), envir = wilson.globals))
})

test_that("message can be logged", {
  logfile <- tempfile()
  logger <- create_logger(logfile = logfile, level = "DEBUG", name = "test_log")
  token <- "test_log"

  set_logger(logger = logger, token = token)
  # lgr's AppenderFile creates the (empty) file on construction, so check for
  # content rather than existence.
  expect_equal(file.size(logfile), 0)
  log_message("test message", level = "DEBUG", token = token)
  expect_gt(file.size(logfile), 0)
  expect_true(any(grepl("test message", readLines(logfile))))

  file.remove(logfile)
  set_logger(logger = NULL, token = token)
  # with no logger registered for the token, nothing is written / no file created
  log_message("test message", level = "DEBUG", token = token)
  expect_false(file.exists(logfile))
})
