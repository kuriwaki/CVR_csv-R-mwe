library(rcces)
library(xml2)

source("00_setup.R")


pima_files <- fs::dir_ls("data/Pima", regexp = "Pima/2020")
pima_files <- c(tail(pima_files, 1), head(pima_files, -1)) # reorder

# party codes (need to get externally)
doc <- xml2::read_xml("https://oldcms.pima.gov/UserFiles/Servers/Server_6/File/Government/elections/Election%20Results/ENR%20STANDARD%20XML.txt")

conts <- xml_find_all(doc, '//Candidate')
party_df <- tibble(
  candidate = xml_attr(conts, "name"),
  partyId = xml_attr(conts, "partyId")) |>
  transmute(
    candidate = recode(candidate, OverVotes = "overvote", UnderVotes = "undervote"),
    party = recode(partyId, `11` = "D", `12` = "R", `13` = "L", `14` = "G", .default = NA_character_)) |>
  distinct()

# READ and stack
cvr_long <- pima_files |> map(read_page) |> list_rbind()

# with party
party_long <- cvr_long |>
  filter(!is.na(office)) |>
  tidylog::left_join(party_df, by = "candidate", relationship = "many-to-one") |>
  transmute(
    cvr_id,
    var_num,
    contest,
    office,
    dist = str_extract(contest, "(?<=DIST\\.\\s)[0-9]+"),
    party,
    candidate
  )

issues_long <- cvr_long |>
  filter(str_detect(contest, "PROPOSITION|QUESTION")) |>
  transmute(
    cvr_id,
    contest = str_replace(contest, "PROPOSITION ", "P"),
    contest = str_replace(contest, "QUESTION ", "Q"),
    choice = recode_issues(candidate)
  )

# codes for variable labels
issue_codes <- issues_long |>
  distinct(contest) |>
  separate_wider_delim(contest, " - ", names = c("contest", "descrip"),
                       too_few = "align_start") |>
  deframe()

# Issues
issues_long |>
  mutate(contest = word(contest, 1, 1)) |>
  pivot_wider(id_cols = cvr_id, names_from = contest, values_from = choice) |>
  attach_varlab(issue_codes) |>
  relocate(cvr_id, matches("P"), matches("Q")) |>
  write_feather("release/pima_issues.feather")


# Offices
party_long |>
  write_feather("release/pima_offices.feather")
