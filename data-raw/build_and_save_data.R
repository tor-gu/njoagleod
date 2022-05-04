requireNamespace("usethis", quietly = TRUE)

knitr::purl("vignettes/data_cleaning_workbook.Rmd", "data-raw/build_data.R")
source("data-raw/build_data.R")

usethis::use_data(agency, overwrite = TRUE)
usethis::use_data(officer, overwrite = TRUE)
