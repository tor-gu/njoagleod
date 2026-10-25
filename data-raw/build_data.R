## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)


## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(dplyr)
library(magrittr)
library(stringr)


## -----------------------------------------------------------------------------
read_release <- function(file) {
  system.file("extdata", file, package = "njoagleod") %>%
    readxl::read_excel() %>%
    mutate(Year = as.integer(Year))
}
agency_raw <- read_release(
  "2025_Law_Enforcement_Diversity_Data_Agency_Information.xlsx")
officer_raw <- read_release(
  "2025_Law_Enforcement_Diversity_Data_Officer_Table.xlsx")
applicant_raw <- read_release(
  "2025_Law_Enforcement_Diversity_Data_Applicant_Table.xlsx")


## -----------------------------------------------------------------------------
to_factor <- function(x, levels, na_values = "Not Provided") {
  stopifnot(all(x %in% c(levels, na_values)))
  factor(if_else(x %in% na_values, NA_character_, x), levels = levels)
}

to_logical <- function(x, true, false, na_values = c(NA, "Not Provided", "Blank")) {
  stopifnot(all(x %in% c(true, false, na_values)))
  case_when(x == true ~ TRUE, x == false ~ FALSE, .default = NA)
}


## -----------------------------------------------------------------------------
read_registry <- function(file, col_types) {
  system.file("extdata", file, package = "njoagleod") %>%
    readr::read_csv(col_types = col_types, na = "")
}
county_levels <- njmunicipalities::counties$county
agency_type_levels <- c("State-wide", "County", "Municipal",
                        "Multiple Municipalities", "Other")

agency <- read_registry("agency_registry.csv", "ciicccc") %>%
  mutate(agency_county = to_factor(agency_county, county_levels, NA),
         agency_type = to_factor(agency_type, agency_type_levels, character()))
agency_alias <- read_registry("agency_alias.csv", "cccc")
agency_municipality <- read_registry("agency_municipality.csv", "cciicc") %>%
  select(agency_id, GEOID_Y2K, first_year, final_year)


## -----------------------------------------------------------------------------
stopifnot(
  !anyDuplicated(agency %>% select(agency_id, first_year)),
  !anyDuplicated(agency_alias %>% select(source, agency_county, agency_name)),
  !anyDuplicated(agency_municipality %>% select(agency_id, GEOID_Y2K, first_year)),
  all(agency$first_year <= agency$final_year),
  all(agency_municipality$first_year <= agency_municipality$final_year)
)
stopifnot(
  0 == agency %>%
    inner_join(agency, by = join_by(agency_id, first_year < first_year,
                                    final_year >= first_year)) %>%
    nrow()
)


## -----------------------------------------------------------------------------
stopifnot(all(agency_alias$agency_id %in% agency$agency_id))
agency_span <- agency %>%
  group_by(agency_id) %>%
  summarize(agency_first = min(first_year), agency_final = max(final_year))
stopifnot(
  agency_municipality %>%
    left_join(agency_span, by = "agency_id") %>%
    with(all(first_year >= agency_first & final_year <= agency_final))
)


## -----------------------------------------------------------------------------
stopifnot(
  all(agency_municipality$GEOID_Y2K %in%
        njmunicipalities::get_municipalities(2000)$GEOID)
)
municipality_counts <- agency %>%
  distinct(agency_id, agency_type) %>%
  left_join(agency_municipality %>% count(agency_id), by = "agency_id") %>%
  mutate(n = coalesce(n, 0L))
stopifnot(
  municipality_counts %>%
    with(all(n[agency_type == "Municipal"] == 1) &&
           all(n[agency_type == "Multiple Municipalities"] >= 2))
)


## -----------------------------------------------------------------------------
add_agency_id <- function(tbl, source_name = "njoag-leod-2025") {
  aliases <- agency_alias %>%
    filter(source == source_name) %>%
    select(County = agency_county, Agency = agency_name, agency_id)
  result <- tbl %>% left_join(aliases, by = c("County", "Agency"))
  stopifnot(nrow(result) == nrow(tbl), !anyNA(result$agency_id))
  result %>% select(-County, -Agency) %>% relocate(Year, agency_id)
}


## -----------------------------------------------------------------------------
practice_columns <- c(
  applications_received =
    "Did your agency receive any applications for employment during the above time period?",
  hiring_civil_service = "Agency Hiring Process Governed by Civil Service",
  hire_method_civil_service_list = "Hire Method - Civil Service Exam List",
  hire_method_non_civil_service_list = "Hire Method - Non-civil service exam list",
  hire_method_intergovernmental_transfer = "Hire Method - Inter-Governmental Transfer",
  hire_method_waiver = "Hire Method - Waiver Hire",
  hire_method_bcpo_direct = "Hire Method - Direc hire of a BCPO Officer",
  hire_element_return_the_card = "Hire Elements - Return the Card",
  hire_element_formal_application = "Hire Elements - Formal Application",
  hire_element_interview_board = "Hire Elements - Interview Board",
  hire_element_written_exam = "Hire Elements - Written exam",
  hire_element_local_preference =
    "Hire Elements - Preference for local or county applicants",
  hire_element_veteran_preference = "Hire Elements - Preference for veteran applicants",
  hire_element_drug_test = "Hire Elements - Drug testing",
  hire_element_medical_exam = "Hire Elements - Medical Exam",
  hire_element_psychiatric_exam = "Hire Elements - Psychiatric Exam",
  appointed_before_academy = "Officer is appointed prior to entry in the academy?",
  appointed_after_academy =
    "Officer is appointed after successful completion of the academy?",
  promotion_applications_received =
    "Did your agency receive any applications for promotion during the above time period?",
  promotion_civil_service = "Promotion governed by Civil Service Regulations?",
  promotion_civil_service_all_ranks =
    "Promotions governed by Civil Service Regulations for all ranks?",
  promotion_practice_civil_service_list = "Promotion Practices - Civil service exam list",
  promotion_practice_non_civil_service_list =
    "Promotion Practices - Non-civil service exam list",
  promotion_practice_interview = "Promotion practices - Promotional Interview"
)
stopifnot(setequal(names(agency_raw),
                   c("Year", "County", "Agency", practice_columns)))

agency_practice <- agency_raw %>%
  add_agency_id() %>%
  rename(year = Year, all_of(practice_columns)) %>%
  mutate(across(all_of(names(practice_columns)), ~ to_logical(.x, "Yes", "No")))


## -----------------------------------------------------------------------------
race_levels <- c("American Indian or Alaska Native", "Asian", "Black or African American",
                 "Hispanic", "Native Hawaiian or other Pacific Islander", "Other",
                 "Two or more races", "White")
gender_levels <- c("Male", "Female", "X or Non-Binary")
age_range_levels <- c("25 or less", "26-35", "36-45", "46-55", "56-65", "66+")
rank_levels <- c("Police Aide", "Officer", "Corporal", "Investigator", "Detective",
                 "Special Agent", "Correctional Officer", "Sergeant", "Detective Sergeant",
                 "Lieutenant", "Detective Lieutenant", "Captain", "Detective Captain",
                 "Major", "Lt. Colonel", "Deputy Chief", "Chief", "Warden",
                 "Undersheriff", "Sheriff")

to_age_range <- function(x) {
  to_factor(x, age_range_levels) %>% factor(levels = age_range_levels, ordered = TRUE)
}

officer <- officer_raw %>%
  add_agency_id() %>%
  transmute(
    year = Year,
    agency_id,
    officer_race = to_factor(`Rae/Ethnicity`, race_levels),
    officer_age_range = to_age_range(`Age Range`),
    officer_gender = to_factor(Gender, gender_levels),
    eligible_for_promotion = to_logical(`Eligible for Promotion?`,
                                        "Eligible for promotion", "Not eligible"),
    applied_for_promotion = to_logical(`Applied for Promotion?`,
                                       "Applied for promotion", "Did not apply"),
    promoted = to_logical(`Promoted?`, "Promoted", "Not promoted"),
    old_rank = to_factor(`Old Rank`, rank_levels),
    new_rank = to_factor(`New Rank`, rank_levels),
    officer_count = as.integer(`Number of Officers`)
  )


## -----------------------------------------------------------------------------
applicant_type_levels <- c("Direct Hire", "CSC Exam Exempt Direct Hire", "Transfer",
                           "Waiver")
outcome_levels <- c("Appointed to Agency", "Not Appointed", "Pending")
reason_levels <- c("Academy Failure", "Applicant Withdrawal", "Defer",
                   "Did not meet minimum qualifications",
                   "Failed background check - Criminal History",
                   "Failed background check - Financial", "Failed Drug Test",
                   "Interview Panel Recommendation", "Physical Qualification Exam",
                   "Residency Requirement", "Written Exam", "Other")

applicant <- applicant_raw %>%
  add_agency_id() %>%
  transmute(
    year = Year,
    agency_id,
    applicant_race = to_factor(`Race/Ethnicity`, race_levels),
    applicant_age_range = to_age_range(`Age Range`),
    applicant_gender = to_factor(Gender, gender_levels),
    applicant_type = to_factor(`Applicant type`, applicant_type_levels),
    outcome = to_factor(Outcome, outcome_levels),
    no_appointment_reason =
      to_factor(str_trim(`Reason for no appointment`), reason_levels),
    applicant_count = as.integer(`Number of Applicants`)
  )


## -----------------------------------------------------------------------------
stopifnot(
  !anyDuplicated(agency_practice %>% select(year, agency_id)),
  !anyDuplicated(officer %>% select(-officer_count)),
  !anyDuplicated(applicant %>% select(-applicant_count))
)


## -----------------------------------------------------------------------------
stopifnot(
  all(officer$officer_count > 0),
  all(applicant$applicant_count > 0),
  sum(officer$officer_count) == sum(officer_raw$`Number of Officers`),
  sum(applicant$applicant_count) == sum(applicant_raw$`Number of Applicants`)
)
officer %>% count(year, wt = officer_count, name = "officers")
applicant %>% count(year, wt = applicant_count, name = "applicants")


## -----------------------------------------------------------------------------
agency_years <- bind_rows(
  agency_practice %>% distinct(agency_id, year),
  officer %>% distinct(agency_id, year),
  applicant %>% distinct(agency_id, year)
) %>%
  distinct()
stopifnot(
  agency_years %>%
    left_join(agency, by = join_by(agency_id, between(year, first_year, final_year))) %>%
    count(agency_id, year) %>%
    with(all(n == 1)),
  agency_years %>%
    inner_join(agency, by = join_by(agency_id, between(year, first_year, final_year))) %>%
    nrow() == nrow(agency_years)
)


## -----------------------------------------------------------------------------
stopifnot(setequal(agency$agency_id, agency_years$agency_id))


## -----------------------------------------------------------------------------
agency_practice %>%
  anti_join(officer, by = c("agency_id", "year")) %>%
  left_join(agency, by = join_by(agency_id, between(year, first_year, final_year))) %>%
  select(year, agency_county, agency_name)


## -----------------------------------------------------------------------------
uof_agencies <- njoaguof::incident %>%
  distinct(agency_county, agency_name) %>%
  mutate(agency_county = as.character(agency_county)) %>%
  filter(!str_detect(agency_name, "Corrections"),
         agency_name != "State Parole Board")
uof_aliases <- agency_alias %>% filter(source == "njoaguof")
stopifnot(
  0 == uof_agencies %>%
    anti_join(uof_aliases, by = c("agency_county", "agency_name")) %>%
    nrow()
)


## -----------------------------------------------------------------------------
agency_alias <- agency_alias %>% arrange(agency_id, source, agency_county, agency_name)
agency_municipality <- agency_municipality %>% arrange(agency_id, GEOID_Y2K, first_year)
agency_practice <- agency_practice %>% arrange(year, agency_id)
officer <- officer %>% arrange(year, agency_id)
applicant <- applicant %>% arrange(year, agency_id)

