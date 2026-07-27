context("MaxQuant parser")

test_that("all needed input parameteres are given", {

  expect_error(parse_MaxQuant(), "The proteinGroups file was not given")
  expect_error(parse_MaxQuant(proteinGroups_in = "./invalid/path/"), "The summary file was not given")
  expect_error(parse_MaxQuant(proteinGroups_in = "./invalid/path/", summary_in = "./invalid/path/"),
                                      "The output file was not given")
  expect_error(parse_MaxQuant(proteinGroups_in = "./invalid/path/", summary_in = "./invalid/path/",
                                      outfile = "./invalid/path/"), "The output_reduced file was not given")
})

test_that("mq_parser", {

  file_full <- tempfile(fileext = "_full.clarion")
  file_reduced <- tempfile(fileext = "_reduced.clarion")

  expect_error(parse_MaxQuant(proteinGroups_in = "proteinGroups_test.txt", summary_in = "summary_test_2.txt",
                                      outfile = file_full, outfile_reduced = file_reduced ),
               "wrong format on summary file: column \'Experiment\' misssing")
  expect_true(parse_MaxQuant(proteinGroups_in = "proteinGroups_test.txt", summary_in = "summary_test.txt",
                                      outfile = file_full, outfile_reduced = file_reduced, config = "success_config.json"))
  expect_error(parse_MaxQuant(proteinGroups_in = "proteinGroups_test.txt", summary_in = "summary_test.txt",
                                      outfile = file_full, outfile_reduced = file_reduced, config = "" ),
               "Could not read config file")
  expect_error(parse_MaxQuant(proteinGroups_in = "proteinGroups_test.txt", summary_in = "summary_test.txt",
                                      outfile = file_full, outfile_reduced = file_reduced, config = "fail_config.json" ),
               "reduced_list is missing in config file")
})
