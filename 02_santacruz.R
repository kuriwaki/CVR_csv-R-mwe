library(tidyverse)
library(arrow)
library(janitor)

source("00_setup.R")

cvr_cols <- read_melt("data/Santa Cruz/cvr_skedit.txt", colnames_only = TRUE)
cvr_orig <- read_melt("data/Santa Cruz/cvr_skedit.txt")

office_cat <- cvr_cols |>
  filter(var_num >= 3) |>
  filter(var_num <= 34) |>  # rest is messed up in parsing and only a small fraction
  mutate(office = cat_office(contest))

cvr_long <- cvr_orig |>
  tidylog::inner_join(office_cat)


# Issues
cvr_long |>
  filter(str_detect(contest, "PROPOSITION|QUESTION")) |>
  transmute(
    cvr_id,
    contest = str_replace(contest, "PROPOSITION ", "P"),
    contest = str_replace(contest, "QUESTION DIST ", "Q"),
    choice = recode_issues(candidate)
  ) |>
  mutate(contest = word(contest, 1, 1)) |>
  pivot_wider(id_cols = cvr_id, names_from = contest, values_from = choice) |>
  rename(Q1_santacruz35 = Q35) |>
  write_feather("release/santacruz_issues.feather")


cvr_long |>
  filter(!is.na(office)) |>
  arrange(var_num, candidate) |>
  separate_wider_regex(candidate,
                       c(candidate = ".*", code = "\\(CND[0-9]+\\)"),
                       too_few = "align_start") |>
  transmute(
    cvr_id,
    var_num,
    contest,
    office,
    dist = str_extract(contest, "(?<=Dist\\.\\s)[0-9]+"),
    party = str_sub(str_extract(candidate, "^(DEM|REP|LBT)"), 1, 1),
    candidate =  str_trim(str_remove(candidate, "^(DEM|REP|LBT)")),
    cand_code = parse_number(str_remove_all(code, "[\\(CND\\)]")),
  ) |>
  arrange(cvr_id, var_num) |>
  write_feather("release/santacruz_offices.feather")
