## ---- include = FALSE-------------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)


## ----setup, include=FALSE---------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(dplyr)
library(magrittr)
library(stringr)
library(tidyr)
library(njoaguof)


## ---------------------------------------------------------------------------------
agency_2021_csv <- "2021_NJOAGLEOD_Agency_Information.csv"
officer_2021_csv <- "2021_NJOAGLEOD_Officer_Information.csv"

agency_2021 <- system.file("extdata", agency_2021_csv, package="njoagleod") %>%
  readr::read_csv()
officer_2021 <- system.file("extdata", officer_2021_csv, package="njoagleod") %>%
  readr::read_csv()


## ---------------------------------------------------------------------------------
agency <- agency_2021 %>%
  rename(agency_county=County,
         agency_name=Agency,
         agency_type=`Agency Type`,
         hiring_governed_by_civil_service=`Hiring governed by Civil Service?`) %>%
  mutate(year=2021) %>% 
  relocate(year)


## ---------------------------------------------------------------------------------
fix_agency_county <- function(tbl) {
  county_levels <- levels(njoaguof::incident$agency_county)
  stopifnot(
    "Statewide Or Regional Lea County" ==
      tbl %>% pull(agency_county) %>% str_to_title() %>%
      paste0(" County") %>% setdiff(county_levels)
  )
  tbl %>%
    mutate(agency_county=str_to_title(agency_county)) %>%
    mutate(agency_county=paste0(agency_county, " County")) %>%
    mutate(agency_county=factor(agency_county, county_levels))
}

agency <- agency %>% fix_agency_county()


## ---------------------------------------------------------------------------------
fix_agency_name <- function(tbl) {
  tbl %>%
    mutate(
      agency_name = case_when(
        agency_name == "Sussex Co Sheriff'S Dept" ~ "Sussex Co Sheriffs Dept",
        agency_name == "Cumberland Co Sheriff'S Dept" ~ "Cumberland Co Sheriffs Dept",
        agency_name == "Hunterdon Co Sheriff'S Dept" ~ "Hunterdon Co Sheriffs Dept",
        agency_name == "Burlington County Sheriffs Off" ~ "Burlington Co Sheriffs Office",
        agency_name == "Mercer Co Prosecutor Offfice" ~ "Mercer Co Prosecutors Office",
        agency_name == "Hudson Co Prosecutor Office" ~ "Hudson Co Prosecutors Office",
        agency_name == "Totowa Boro  PD" ~ "Totowa Boro PD",
        agency_name == "New Jersey Institute Of Technol" ~ "New Jersey Institute Of Technology",
        agency_name == "NJ Div Criminal Justice - Trenton" ~ "NJ Division of Criminal Justice",
        TRUE ~ agency_name
      )
    )
}

agency <- agency %>% fix_agency_name()


## ---------------------------------------------------------------------------------
agency_type_levels <- c("State-wide", "County", "Municipal", 
                        "Multiple Municipalities", "Not Provided")
agency <- agency %>%
  mutate(agency_type = factor(agency_type, agency_type_levels))

stopifnot(0 == agency %>% filter(is.na(agency_type)) %>% nrow())


## ---------------------------------------------------------------------------------
agency <- agency %>% 
  mutate(hiring_governed_by_civil_service = 
           str_to_lower(hiring_governed_by_civil_service)) %>%
  mutate(hiring_governed_by_civil_service=case_when(
    hiring_governed_by_civil_service == "yes" ~ TRUE,
    hiring_governed_by_civil_service == "no" ~ FALSE,
    TRUE ~ NA
  )) 


## ---------------------------------------------------------------------------------
officer <- officer_2021 %>%
  rename(agency_county=County,
         agency_name=Agency,
         officer_age=Age,
         officer_race=`Race/Ethnicity`,
         officer_gender=Gender2
         ) %>%
  mutate(year=2021) %>% 
  relocate(year)


## ---------------------------------------------------------------------------------
officer <- officer %>% 
  fix_agency_county() %>% 
  fix_agency_name()


## ---------------------------------------------------------------------------------
# Save this value for the check at the end
officer_race_not_provided <- officer %>% 
  filter(officer_race=="Not provided") %>%
  nrow()

# Now do the mapping
race_levels <- levels(incident$officer_race)
officer <- officer %>% 
  mutate(officer_race = str_to_title(officer_race)) %>%
  mutate(officer_race = case_when(
    officer_race == "American Indian Or Alaska Native" ~ "American Indian",
    officer_race == "Black Or African American" ~ "Black",
    officer_race == "Native Hawaiian Or Other Pacific Islander" ~ "Native Hawaiian or other Pacific Islander",
    officer_race == "Not Provided" ~ NA_character_,
    officer_race == "Two Or More Races" ~ "Two or more races",
    TRUE ~ officer_race
  )) %>% 
  mutate(officer_race=factor(officer_race, levels=race_levels))

# Check that we did not introduce any more `NA`s than we meant to.
stopifnot(
  officer_race_not_provided == 
    officer %>% filter(is.na(officer_race)) %>% nrow()
)


## ---------------------------------------------------------------------------------
# Save this value for the check at the end
officer_gender_not_provided <- officer %>% 
  filter(officer_gender=="Not Provided") %>%
  nrow()

# Now do the mapping
gender_levels <- levels(njoaguof::incident$officer_gender)
officer <- officer %>% 
  mutate(officer_gender=case_when(
    officer_gender == "Not Provided" ~ NA_character_,
    officer_gender == "X Or Non-Binary" ~ "Gender Non-Conforming/X",
    TRUE ~ officer_gender
  )) %>%
  mutate(officer_gender=factor(officer_gender, levels=gender_levels))

# Check that we did not introduce any more `NA`s than we meant to.
stopifnot(
  officer_gender_not_provided == 
    officer %>% filter(is.na(officer_gender)) %>% nrow()
)

