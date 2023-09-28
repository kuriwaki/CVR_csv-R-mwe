Working Example of Cleaning CVRs in CSVs
================

The goal of this repo is to serve as one example of cleaning CVRs that
come in csvs and spreadsheets.

This directory is formatted as follows

    ├── 00_setup.R
    ├── 01_yuma.R
    ├── 02_santacruz.R
    ├── 03_pima.R
    ├── 04_stack_AZ.R
    ├── CVR_csv-R-mwe.Rproj
    ├── R
    │   ├── read.R
    │   └── recodes.R
    ├── README.Rmd
    ├── data
    │   ├── Pima
    │   │   ├── 2020 General Post Election CVR - 1.xlsx
    │   │   └── 2020 General Post Election CVR - 2.xlsx
    │   ├── Santa Cruz
    │   │   └── cvr_skedit.txt
    │   └── Yuma
    │       └── cvr.csv
    └── release

The datasets are about cropped so they are manageable for github.

- Yuma is a single cvr with party in the cells (the easiest case)
- Santa Cruz is a txt file but otherwise not that bad
- Pima are excel files where there is no party information in the excel
  file itself.

The key function is `read_melt()`, which takes the standard wide format
CVR and turns it into a long file. It currently works for the three
types of files above. Each county’s file is output to a `feather` file
that is faster to read and write. They are then stacked together in
`04_stack_AZ.R`.

Edits welcome.

## Use

Test this github repo by opening it in Rstudio Projects, and then
running all scripts in sequence.
