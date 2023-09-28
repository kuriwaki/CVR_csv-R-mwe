source("00_setup.R")

cvr_cols <- read_melt("data/Yuma/cvr.csv", colnames_only = TRUE)
cvr_orig <- read_melt("data/Yuma/cvr.csv")


office_cat <- cvr_cols |>
  filter(var_num >= 4) |>
  mutate(office = cat_office(contest))

cvr_long <- cvr_orig |>
  left_join(office_cat)


cvr_long |>
  filter(str_detect(contest, "PROPOSITION|QUESTION")) |>
  transmute(
    cvr_id,
    contest = str_replace(contest, "PROPOSITION ", "P"),
    contest = str_replace(contest, "QUESTION ", "Q"),
    choice = recode_issues(candidate)
  ) |>
  mutate(contest = word(contest, 1, 1)) |>
  pivot_wider(id_cols = cvr_id, names_from = contest, values_from = choice) |>
  rename(Q1_yuma = Q1) |>
  rename_with(~ str_c(.x, "_yuma"), .cols = starts_with("P4")) |>
  write_feather("release/yuma_issues.feather")


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
    dist = str_extract(contest, "(?<=Dist\\s)[0-9]+"),
    party = str_sub(str_extract(candidate, "^(DEM|REP|LBT)"), 1, 1),
    candidate =  str_trim(str_remove(candidate, "^(DEM|REP|LBT)")),
    cand_code = parse_number(str_remove_all(code, "[\\(CND\\)]")),
  ) |>
  arrange(cvr_id, var_num) |>
  write_feather("release/yuma_offices.feather")
