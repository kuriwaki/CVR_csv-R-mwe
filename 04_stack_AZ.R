library(haven)
source("00_setup.R")

# Paths to read ----
iss_paths <- rev(dir_ls("release", regexp = "issues"))
vot_paths <- rev(dir_ls("release", regexp = "office"))

names(iss_paths) <- names(vot_paths) <-
  str_to_title(recode(word(path_file(iss_paths), 1, 1, sep = "_"), `santacruz` = "santa cruz"))

az_order <- c("Yuma", "Pima", "Santa Cruz")
iss_paths <- iss_paths[az_order]
vot_paths <- vot_paths[az_order]

# Stack -----
vot_long <- vot_paths |>
  map(read_feather) |>
  list_rbind(names_to = "county")

iss_stck <- iss_paths |>
  map(read_feather) |>
  list_rbind(names_to = "county")


# Common IDs ------
stwide_codes <- vot_long |>
  distinct(county, cvr_id) |>
  mutate(state_id = 1:n())

vot_fmt <- vot_long |>
  left_join(stwide_codes) |>
  select(-cvr_id, -contest, -cand_code) |>
  relocate(county, cvr_id = state_id)

iss_fmt <- iss_stck |>
  left_join(stwide_codes, relationship = "one-to-one") |>
  select(-cvr_id) |>
  relocate(county, cvr_id = state_id, matches("^P"), matches("^Q"))


# Write ---
js_path <- NULL # REPLACE WITH REAL PATH

vot_fmt |>
  write_dta(path(js_path, "AZ", "offices_votes.dta"))

iss_fmt |>
  write_dta(path(js_path, "AZ", "issues_votes.dta"))