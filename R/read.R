#' read, melt to long form, then bind
#' @param filepath Path of files
#' @param colnames_only FALSE to read data, TRUE to read only the first row of colnames
#' @param subset_cols Columns to subset if any
#' @param read Read all votes or just the id column
read_melt <- function(filepath,
                      colnames_only = FALSE,
                      subset_cols = NULL,
                      read = c("votes", "id")) {

  read <- match.arg(read)


  if (str_detect(filepath, "\\.csv$")) {
    suppressWarnings(
      rows_s <- read_csv(
        filepath,
        col_types = "c", n_max = ifelse(colnames_only, 1, Inf),
        name_repair = "unique")
    )
  } else if (str_detect(filepath, "\\.xlsx$")) {
    suppressWarnings(
      rows_s <- readxl::read_excel(
        filepath,
        col_types = "text", n_max = ifelse(colnames_only, 1, Inf),
        .name_repair = "unique")
    )
  } else if (str_detect(filepath, "\\.txt$")) {
    suppressWarnings(
      rows_s <- read_delim(
        filepath, delim = "|",
        col_types = "c", n_max = ifelse(colnames_only, 1, Inf),
        name_repair = "unique")
    )
  }

  cnames <- colnames(rows_s)
  cnames_ch <- multichoice_colnames(cnames) # add "Choice 2"
  cnames_ch <- extract_order(cnames_ch) # remove "(1)"
  colnames(rows_s) <- cnames_ch

  office_ord <- enframe(cnames_ch, value = "contest", name = "var_num") |>
    mutate(var_num = parse_number(var_num))

  if (colnames_only)
    return(office_ord)

  # often 2 and 3 are precinct and ballot style, but some like santa cruz does not have ballot style
  metadata_cols <- str_which(cnames_ch, regex("(Precinct|Ballot Style)", ignore_case = TRUE))

  if (!is.null(subset_cols)) {
    rows_s <- rows_s[, c(1, metadata_cols, subset_cols)]
  }

  # melt
  if (read == "votes") {
    rows_long <- pivot_longer(select(rows_s, -c(all_of(metadata_cols))), # remove precinct and ballot
                              -c(1),
                              values_drop_na = TRUE,
                              names_to = "contest",
                              values_to = "candidate")
  }

  if (read == "id") {
    rows_long <- rows_s |>
      select(c(1, all_of(metadata_cols)))
  }

  # add filename, format office names
  rows_fmt <- rows_long %>%
    clean_names() %>%
    rename(cvr_id = cast_vote_record) %>%
    mutate(cvr_id = as.integer(cvr_id))

  rows_fmt
}

#' Wrapper around read_melt, for multiple pages
read_page <- function(f) {
  cvr_cols <- read_melt(f, colnames_only = TRUE)
  cvr_orig <- read_melt(f)

  office_cat <- cvr_cols |>
    filter(var_num >= 4) |>
    mutate(office = cat_office(contest))

  cvr_long <- cvr_orig |>
    left_join(office_cat)

  cvr_long
}


#' Get new colnames that append "choice1", "choice2" to offices with multiple
#'  choices per office
multichoice_colnames <- function(cnames, tag = "Choice") {
  ind_missing <- str_which(cnames, "(^x[0-9]+$|\\.\\.\\.[0-9]+)")
  if (length(ind_missing) == 0)
    return(cnames)

  li <-  split(ind_missing, cumsum(diff(c(-Inf, ind_missing)) != 1))

  for (office in 1:length(li)) {
    ind_o <- li[[office]]
    ch1 <- min(ind_o) - 1
    cnames[c(ch1, ind_o)] <- str_c(cnames[ch1],
                                   tag,
                                   seq_len(length(ind_o) + 1),
                                   sep = " ")
  }
  cnames
}

#' Turn complicated column names into otders
extract_order <- function(cnames) {
  # non-missing numbers
  num <- seq_along(cnames)
  stopifnot(all(!is.na(num[-c(1:3)]))) # first three columns are cvr, precinct, and ballot style

  cnames <- str_squish(str_trim(str_remove_all(cnames, "\\([:digit:]{3,}\\)")))

  # duplication
  cnames <- base::make.unique(cnames, sep = " ")

  names(cnames) <- num
  cnames
}

