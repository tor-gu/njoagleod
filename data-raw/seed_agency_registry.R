# One-time seeding of the agency registry.
#
# Writes the first versions of
#   inst/extdata/agency_registry.csv
#   inst/extdata/agency_alias.csv
#   inst/extdata/agency_municipality.csv
# from the 2025 NJOAG release, the 2021 release CSVs and njoaguof. After this script has run
# once, the three CSVs are maintained by hand and this script is kept only as a record of how
# they were seeded. It reads the 2021 CSVs, which have since been removed from inst/extdata,
# so it will not run again as-is.
#
# Run from the package root.

library(dplyr)
library(stringr)
library(tidyr)

extdata <- "inst/extdata"
release_files <- c(
  "2025 Law Enforcement Diversity Data - Agency Information.xlsx",
  "2025 Law Enforcement Diversity Data - Officer Table.xlsx",
  "2025 Law Enforcement Diversity Data - Applicant Table.xlsx"
)

county_levels <- njmunicipalities::counties$county

# Map a source county spelling ("Atlantic", "ESSEX", "Passaic ", "Statewide or Regional LEA",
# "State or Other Agency", njoaguof's "Atlantic County" or NA) to "Atlantic County" or NA.
normalize_county <- function(county) {
  county <- str_to_title(str_remove(str_trim(county), "(?i) county$"))
  if_else(is.na(county) | county %in% c("State Or Other Agency", "Statewide Or Regional Lea"),
          NA_character_, paste(county, "County"))
}

# ---- 2025 release: one entry per (County, Agency) -------------------------------------------
release <- release_files %>%
  lapply(function(f) readxl::read_excel(file.path(extdata, f)) %>%
           select(County, Agency, Year)) %>%
  bind_rows() %>%
  mutate(Year = as.integer(Year)) %>%
  group_by(County, Agency) %>%
  summarize(first_year = min(Year), final_year = max(Year), .groups = "drop")

# Canonical names: the release spelling, with truncations fixed and the "<town> Twp PD"
# convention applied (as fix_agency_name() did in 1.x).
canonical_name_fixes <- c(
  "New Jersey Institute Of Technol" = "New Jersey Institute Of Technology",
  "Burlington County Sheriffs Off" = "Burlington Co Sheriffs Office",
  "Park Police" = "New Jersey State Park Police",
  "Toms River Township" = "Toms River Twp PD",
  "Hardyston Twp Police Dept" = "Hardyston Twp PD",
  "Linden Police Department" = "Linden PD",
  "Robbinsville Township Police" = "Robbinsville Twp PD"
)

registry <- release %>%
  mutate(agency_county = factor(normalize_county(County), county_levels),
         agency_name = coalesce(canonical_name_fixes[Agency], Agency)) %>%
  arrange(agency_county, agency_name) %>%
  mutate(agency_id = sprintf("A%04d", row_number()))
stopifnot(!anyDuplicated(registry %>% select(agency_county, agency_name)))

release_key <- registry %>% select(County, Agency, agency_id)

# ---- Aliases ---------------------------------------------------------------------------------
# Resolve (county, name) spellings from another source to a release (County, Agency):
# first by exact match after county normalization, then through a manual table. The manual
# table is matched on the normalized county, so "Passaic" and "Passaic " both match.
resolve <- function(tbl, manual) {
  by_county <- registry %>% transmute(norm_county = as.character(agency_county), Agency, agency_id)
  manual <- manual %>%
    mutate(norm_county = normalize_county(agency_county)) %>%
    select(-agency_county)
  tbl %>%
    mutate(norm_county = normalize_county(agency_county)) %>%
    left_join(manual, by = c("norm_county", "agency_name")) %>%
    mutate(Agency = coalesce(release_agency, agency_name),
           norm_county = if_else(is.na(release_county), norm_county,
                                 normalize_county(release_county))) %>%
    left_join(by_county, by = c("norm_county", "Agency")) %>%
    select(agency_county, agency_name, agency_id)
}

# 2021 release (data dump of 2022-05-11)
old_agency <- readr::read_csv(file.path(extdata, "2021_NJOAGLEOD_Agency_Information.csv"),
                              show_col_types = FALSE)
old_officer <- readr::read_csv(file.path(extdata, "2021_NJOAGLEOD_Officer_Information.csv"),
                               show_col_types = FALSE)
old_manual <- tribble(
  ~agency_county,              ~agency_name,                                         ~release_county,          ~release_agency,
  "Burlington",                "Eastampton Twp PD",                                  NA,                       "Eastampton PD",
  "Burlington",                "Edgewater Park Twp PD",                              NA,                       "Edgewater Park PD",
  "Camden",                    "Cherry Hill Campus Police",                          NA,                       "Cherry Hill Campus PD",
  "Camden",                    "Delaware River Port Authority",                      NA,                       "Delaware River Port Authority PD",
  "Cape May",                  "Delaware River and Bay Authority Police Department", "State or Other Agency",  "Delaware River and Bay Authority PD",
  "Salem",                     "Delaware River and Bay Authority Police Department", "State or Other Agency",  "Delaware River and Bay Authority PD",
  "Cumberland",                "Cumberland Co Sheriff'S Dept",                       NA,                       "Cumberland Co Sheriffs Dept",
  "Essex",                     "Montclair State College PD",                         NA,                       "Montclair State University PD",
  "Hunterdon",                 "Hunterdon Co Sheriff'S Dept",                        NA,                       "Hunterdon Co Sheriffs Dept",
  "Mercer",                    "Mercer Co Prosecutor Offfice",                       NA,                       "Mercer Co Prosecutor Office",
  "Mercer",                    "Mercer Co Sheriffs Dept",                            NA,                       "Mercer County Sheriffs Office",
  "Mercer",                    "Princeton University Police",                        NA,                       "Princeton University PD",
  "Passaic ",                  "Totowa Boro  PD",                                    NA,                       "Totowa Boro PD",
  "Somerset",                  "Somerset County Sheriff's Office",                   NA,                       "Somerset Co Sheriffs Dept",
  "Statewide or Regional LEA", "Division of Taxation",                               NA,                       "NJ Division of Taxation",
  "Statewide or Regional LEA", "Juvenile Justice Commission",                        NA,                       "Youth Justice Commission",
  "Statewide or Regional LEA", "New Jersey State Park Police",                       NA,                       "Park Police",
  "Sussex",                    "Sussex Co Sheriff'S Dept",                           NA,                       "Sussex Co Sheriffs Dept",
  "Union",                     "Union Co Sheriffs Office",                           NA,                       "Union County Sheriffs Office",
  "Warren",                    "Warren Co Sheriff'S Dept",                           NA,                       "Warren Co Sheriffs Dept",
  # The 2021 release's "Washington Park PD" (Warren) is the 2025 release's
  # "Washington Twp PD" (Warren): same county, 2021 officers, and no NJ town named
  # Washington Park.
  "Warren",                    "Washington Park PD",                                 NA,                       "Washington Twp PD"
)
old_alias <- bind_rows(
  old_agency %>% select(agency_county = County, agency_name = Agency),
  old_officer %>% select(agency_county = County, agency_name = Agency)
) %>%
  distinct() %>%
  resolve(old_manual) %>%
  mutate(source = "njoag-leod-2021")

# njoaguof
uof_manual <- tribble(
  ~agency_county,         ~agency_name,                           ~release_county,         ~release_agency,
  "Burlington County",    "Burlington Co Sheriffs Office",        NA,                      "Burlington County Sheriffs Off",
  "Burlington County",    "Eastampton Twp PD",                    NA,                      "Eastampton PD",
  "Burlington County",    "Edgewater Park Twp PD",                NA,                      "Edgewater Park PD",
  "Camden County",        "Camden Co Sheriffs Office",            NA,                      "Camden Co Sheriffs Dept",
  "Camden County",        "Delaware River Port Authority",        NA,                      "Delaware River Port Authority PD",
  "Camden County",        "Rowan University of NJ",               "Gloucester",            "Rowan University Of NJ",
  "Gloucester County",    "Rowan University of NJ",               NA,                      "Rowan University Of NJ",
  "Cape May County",      "Delaware River and Bay Authority PD",  "State or Other Agency", "Delaware River and Bay Authority PD",
  "Essex County",         "Montclair State College PD",           NA,                      "Montclair State University PD",
  "Essex County",         "New Jersey Institute Of Technology",   NA,                      "New Jersey Institute Of Technol",
  "Hudson County",        "Hudson Co Prosecutors Office",         NA,                      "Hudson Co Prosecutor Office",
  "Hunterdon County",     "Hunterdon Co Prosecutors Office",      NA,                      "Hunterdon Co Prosecutor Office",
  "Mercer County",        "Mercer Co Prosecutors Office",         NA,                      "Mercer Co Prosecutor Office",
  "Mercer County",        "Mercer Co Sheriffs Dept",              NA,                      "Mercer County Sheriffs Office",
  "Mercer County",        "Princeton University Police",          NA,                      "Princeton University PD",
  "Mercer County",        "Robbinsville Twp PD",                  NA,                      "Robbinsville Township Police",
  "Middlesex County",     "North Brunswick PD",                   NA,                      "North Brunswick Twp PD",
  "Ocean County",         "Island Heights PD",                    NA,                      "Island Heights Boro PD",
  "Ocean County",         "Toms River Twp PD",                    NA,                      "Toms River Township",
  "Somerset County",      "Somerset Co Sheriffs Office",          NA,                      "Somerset Co Sheriffs Dept",
  "Sussex County",        "Hardyston Twp PD",                     NA,                      "Hardyston Twp Police Dept",
  "Union County",         "Linden PD",                            NA,                      "Linden Police Department",
  "Union County",         "Union Co Sheriffs Office",             NA,                      "Union County Sheriffs Office",
  NA,                     "NJ Division of Criminal Justice",      NA,                      "NJ Div Criminal Justice - Trenton",
  NA,                     "NJ Juvenile Justice Commission",       NA,                      "Youth Justice Commission",
  NA,                     "NJ State Human Services",              NA,                      "NJ Department Of Human Services",
  NA,                     "New Jersey State Park Police",         NA,                      "Park Police"
)
uof_alias <- njoaguof::incident %>%
  distinct(agency_county, agency_name) %>%
  mutate(agency_county = as.character(agency_county)) %>%
  filter(!str_detect(agency_name, "Corrections")) %>%
  resolve(uof_manual) %>%
  mutate(source = "njoaguof")

# Agencies njoaguof knows that are not in the LEOD data at all.
uof_not_in_leod <- c("State Parole Board")
stopifnot(setequal(uof_alias %>% filter(is.na(agency_id)) %>% pull(agency_name),
                   uof_not_in_leod))
uof_alias <- uof_alias %>% filter(!is.na(agency_id))
stopifnot(!anyNA(old_alias$agency_id))

alias <- bind_rows(
  release_key %>% transmute(source = "njoag-leod-2025", agency_county = County,
                            agency_name = Agency, agency_id),
  old_alias,
  uof_alias
) %>%
  select(source, agency_county, agency_name, agency_id) %>%
  arrange(source, agency_id, agency_county, agency_name)

# ---- agency_type -----------------------------------------------------------------------------
# Seeded from the 2021 release's "Agency Type", then corrected.
agency_type_levels <- c("State-wide", "County", "Municipal", "Multiple Municipalities", "Other")
old_type <- old_agency %>%
  select(agency_county = County, agency_name = Agency, old_type = `Agency Type`) %>%
  inner_join(old_alias, by = c("agency_county", "agency_name")) %>%
  distinct(agency_id, old_type)
stopifnot(!anyDuplicated(old_type$agency_id))

type_overrides <- tribble(
  ~agency_name,                          ~agency_type,
  # Not in the 2021 release
  "College Of New Jersey",               "State-wide",   # state college, like Kean or Rowan
  "Boonton Twp PD",                      "Municipal",
  "Freehold Boro PD",                    "Municipal",
  # 2021 "Not Provided"
  "Montvale PD",                         "Municipal",
  "Greenwich Twp PD",                    "Municipal",
  "Old Bridge Twp PD",                   "Municipal",
  "Roselle Park PD",                     "Municipal",
  # 2021 "State-wide", but Raritan borough's police department
  "Raritan PD",                          "Municipal",
  # 2021 "Municipal", but campus police of private institutions
  "Cherry Hill Campus PD",               "Other",
  "Stevens Institute Of Technology",     "Other",
  "Princeton University PD",             "Other",
  "Monmouth University PD",              "Other",
  # Interstate / bi-state authorities
  "Delaware River Port Authority PD",    "Other",
  "Delaware River and Bay Authority PD", "Other",
  "Palisades Inter. Parkway PD",         "Other",
  # 2021 "Municipal", but serves Chester borough and Chester township
  "Chester PD",                          "Multiple Municipalities",
  # 2021 "Multiple Municipalities", but no shared-services arrangement found
  # (reviewed 2026-10); each serves only its own municipality.
  "Delanco Twp PD",                      "Municipal",
  "Magnolia PD",                         "Municipal",
  "Belleville PD",                       "Municipal",
  "Robbinsville Twp PD",                 "Municipal"
)

registry <- registry %>%
  left_join(old_type, by = "agency_id") %>%
  left_join(type_overrides, by = "agency_name") %>%
  mutate(agency_type = factor(coalesce(agency_type, old_type), agency_type_levels))
stopifnot(!anyNA(registry$agency_type))

# ---- Municipalities --------------------------------------------------------------------------
# Census names as of 2025, keyed by the njmunicipalities stable ID (the year-2000 GEOID).
towns <- njmunicipalities::get_municipalities(2025, geoid_year = 2000,
                                               geoid_ref_as_ref_column = TRUE) %>%
  select(GEOID_Y2K = GEOID_ref, county, municipality)

# The home municipality of each municipal agency, by trying suffix variations of the
# agency name (the 1.x add_test_municipalities() cascade).
home <- registry %>%
  filter(agency_type %in% c("Municipal", "Multiple Municipalities")) %>%
  transmute(agency_id, county = as.character(agency_county),
            base = str_remove(agency_name, " PD$"), municipality = NA_character_)
candidates <- list(
  function(b) paste0(b, " city"), function(b) paste0(b, " town"),
  function(b) paste0(b, " village"), function(b) paste0(b, " borough"),
  function(b) paste0(b, " township"),
  function(b) str_replace(b, "City", "city"), function(b) str_replace(b, "Twp", "township"),
  function(b) str_replace(b, "Boro", "borough"), function(b) str_replace(b, "Town", "town"),
  function(b) str_replace(b, "Village", "village"), function(b) paste0(b, " City city")
)
for (candidate in candidates) {
  home <- home %>%
    mutate(test = candidate(base)) %>%
    left_join(towns %>% select(county, test = municipality), by = c("county", "test"),
              keep = TRUE, suffix = c("", ".town")) %>%
    mutate(municipality = coalesce(municipality, test.town)) %>%
    select(agency_id, county, base, municipality)
}
manual_home <- c(
  "Mt. Ephraim" = "Mount Ephraim borough",
  "Orange" = "City of Orange township",
  "South Orange" = "South Orange Village township",
  "Avon-By-The-Sea" = "Avon-by-the-Sea borough",
  "Bayhead Boro" = "Bay Head borough",
  "Oceangate Boro" = "Ocean Gate borough",
  "Peapack-Gladstone" = "Peapack and Gladstone borough",
  "Princeton" = "Princeton"
)
home <- home %>%
  mutate(municipality = coalesce(municipality, manual_home[base])) %>%
  mutate(note = "home municipality")
print(home %>% filter(is.na(municipality)), n = Inf)

# Additional municipalities served under shared-services agreements.
served <- tribble(
  ~agency_county,      ~agency_name,        ~county,             ~municipality,            ~note,
  "Morris County",     "Chester PD",        "Morris County",     "Chester township",       "A department of Chester Township; serves Chester Borough under a Police Services Agreement of 2016-12-20 (https://ecode360.com/11479397)",
  "Monmouth County",   "Belmar PD",         "Monmouth County",   "Lake Como borough",      "Lake Como disbanded its police department in 2016 and contracts with Belmar (https://en.wikipedia.org/wiki/Lake_Como,_New_Jersey)",
  "Gloucester County", "Woolwich Twp PD",   "Gloucester County", "Swedesboro borough",     "Interlocal agreement from 2009-06-01 (https://www.nj.gov/dca/affiliates/luarcc/pdf/interlocal%20_swedesboro_woolwich_police-(revised_5-4-09).pdf)",
  "Gloucester County", "Franklin Twp PD",   "Gloucester County", "Newfield borough",       "Interlocal agreement 2017, extended 2022 (https://www.franklintownshipnj.org/DocumentCenter/View/4772)",
  "Gloucester County", "Franklin Twp PD",   "Atlantic County",   "Buena borough",          "Department states it serves Franklin Twp, Newfield and Buena (https://www.policeapp.com/NJ-Franklin-Township-Gloucester-County-Police-Department/1148/)",
  "Cape May County",   "Cape May City PD",  "Cape May County",   "West Cape May borough",  "Department jurisdiction covers West Cape May and Cape May Point (https://www.policeapp.com/Cape-May-NJ-Police-Department/1061/)",
  "Cape May County",   "Cape May City PD",  "Cape May County",   "Cape May Point borough", "Department jurisdiction covers West Cape May and Cape May Point (https://www.policeapp.com/Cape-May-NJ-Police-Department/1061/)",
  "Morris County",     "Wharton Boro PD",   "Morris County",     "Mine Hill township",     "Service contract from 2002-05-01; still patrols Mine Hill per a 2026 job posting (https://minehill.com/wp-content/uploads/2012/10/WhartonPolicePresentation.pdf)",
  "Camden County",     "Haddon Twp PD",     "Camden County",     "Audubon Park borough",   "Department serves Haddon Township and Audubon Park (https://www.haddontwp.com/departmets/police-department/)",
  "Morris County",     "Washington Twp PD", "Hunterdon County",  "Califon borough",        "Interlocal agreement renewed for 2013-2015 (https://wtmorris.org/images/R-17-13_CALIFON_POLICING_1-21RM.pdf); Califon has no police department in the release"
) %>%
  inner_join(registry %>% transmute(agency_id, agency_name,
                                    agency_county = as.character(agency_county)),
             by = c("agency_county", "agency_name")) %>%
  select(agency_id, county, municipality, note)
stopifnot(nrow(served) == 10)

agency_municipality <- bind_rows(
  home %>% filter(!is.na(municipality)) %>% select(agency_id, county, municipality, note),
  served
) %>%
  left_join(towns, by = c("county", "municipality")) %>%
  left_join(registry %>% select(agency_id, first_year, final_year), by = "agency_id")
stopifnot(!anyNA(agency_municipality$GEOID_Y2K))

# ---- Write -----------------------------------------------------------------------------------
registry %>%
  transmute(agency_id, first_year, final_year, agency_county, agency_name, agency_type,
            ori = NA_character_) %>%
  readr::write_csv(file.path(extdata, "agency_registry.csv"), na = "")
alias %>%
  readr::write_csv(file.path(extdata, "agency_alias.csv"), na = "")
agency_municipality %>%
  transmute(agency_id, GEOID_Y2K, first_year, final_year, municipality, note) %>%
  arrange(agency_id, GEOID_Y2K) %>%
  readr::write_csv(file.path(extdata, "agency_municipality.csv"), na = "")
