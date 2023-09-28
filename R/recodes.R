
#' Recode Yes vs. no
recode_issues <- function(candidate) {
  case_when(
    str_detect(candidate, regex("^YES", ignore_case = TRUE)) ~ 1,
    str_detect(candidate, regex("^NO", ignore_case = TRUE)) ~ 0,
    str_detect(candidate, regex(", YES$", ignore_case = TRUE)) ~ 1,
    str_detect(candidate, regex(", NO$", ignore_case = TRUE)) ~ 0,
    str_detect(candidate, "undervote") ~ NA_integer_,
    str_detect(candidate, "overvote") ~ NA_integer_,
  )
}

#' Recode offices
cat_office <- function(contest) {
  case_when(
    str_detect(contest, regex("Presidential Electors", ignore_case = TRUE)) ~ "us_pres",
    str_detect(contest, regex("(U.S.|UNITED STATES) Senator", ignore_case = TRUE)) ~ "us_sen",
    str_detect(contest, regex("Representative in Congress", ignore_case = TRUE)) ~ "us_rep",
    str_detect(contest, regex("State Senator", ignore_case = TRUE)) ~ "st_sen",
    str_detect(contest, regex("State Representative", ignore_case = TRUE)) ~ "st_rep",
    str_detect(contest, regex("County Attorney", ignore_case = TRUE)) ~ "ct_att",
    str_detect(contest, regex("County Recorder", ignore_case = TRUE)) ~ "ct_rec",
    str_detect(contest, regex("County Treasurer", ignore_case = TRUE)) ~ "ct_trs",
    str_detect(contest, regex("Sheriff", ignore_case = TRUE)) ~ "ct_shf",
    str_detect(contest, regex("County School Superintendent", ignore_case = TRUE)) ~ "ct_ssi"
  )
}
