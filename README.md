
<!-- README.md is generated from README.Rmd. Please edit that file -->

# njoagleod

<!-- badges: start -->

[![R-CMD-check](https://github.com/tor-gu/njoagleod/workflows/R-CMD-check/badge.svg)](https://github.com/tor-gu/njoagleod/actions)
<!-- badges: end -->

This is a cleaned-up version of the NJ OAG Law Enforcement Officer
Diversity database available from
<https://www.njoag.gov/policerecruiting/>

## Dataset Overview

This package is built from the 2025 NJ OAG release, which covers
officers for 2021–2025 and agencies and applicants for 2022–2025. It
contains six tables.

- `agency` One row per law enforcement agency (per name, if the agency
  is renamed). Each agency has a stable `agency_id`.
- `agency_alias` Every spelling of every agency’s name, in the NJ OAG
  releases and in the [`njoaguof`](https://github.com/tor-gu/njoaguof)
  package, mapped to its `agency_id`.
- `agency_municipality` The municipalities each agency serves,
  identified as in the
  [`njmunicipalities`](https://github.com/tor-gu/njmunicipalities)
  package.
- `agency_practice` Each agency’s hiring and promotion practices, by
  year.
- `officer` Counts of officers by year, agency, race, age range, gender
  and promotion.
- `applicant` Counts of applicants by year, agency, race, age range,
  gender, applicant type and outcome.

## Examples

``` r
library(njoagleod)
library(dplyr)
```

The `agency` table looks like this:

``` r
agency
#> # A tibble: 532 × 7
#>    agency_id first_year final_year agency_county   agency_name agency_type ori  
#>    <chr>          <int>      <int> <fct>           <chr>       <fct>       <chr>
#>  1 A0001           2021       2025 Atlantic County Absecon Ci… Municipal   <NA> 
#>  2 A0002           2021       2025 Atlantic County Atlantic C… Municipal   <NA> 
#>  3 A0003           2021       2025 Atlantic County Atlantic C… County      <NA> 
#>  4 A0004           2021       2025 Atlantic County Atlantic C… County      <NA> 
#>  5 A0005           2021       2025 Atlantic County Brigantine… Municipal   <NA> 
#>  6 A0006           2021       2025 Atlantic County Egg Harbor… Municipal   <NA> 
#>  7 A0007           2021       2025 Atlantic County Egg Harbor… Municipal   <NA> 
#>  8 A0008           2021       2025 Atlantic County Galloway T… Municipal   <NA> 
#>  9 A0009           2021       2025 Atlantic County Hamilton T… Municipal   <NA> 
#> 10 A0010           2021       2025 Atlantic County Hammonton … Municipal   <NA> 
#> # ℹ 522 more rows
```

The columns `agency_id` and `first_year` form the primary key. The other
tables refer to agencies by `agency_id` only.

The `officer` and `applicant` tables are count tables: each row is a
combination of characteristics, and `officer_count` (or
`applicant_count`) is the number of people who share it.

``` r
officer
#> # A tibble: 44,711 × 11
#>     year agency_id officer_race              officer_age_range officer_gender
#>    <int> <chr>     <fct>                     <ord>             <fct>         
#>  1  2021 A0001     Asian                     36-45             Female        
#>  2  2021 A0001     Black or African American 26-35             Male          
#>  3  2021 A0001     White                     25 or less        Male          
#>  4  2021 A0001     White                     26-35             Male          
#>  5  2021 A0001     White                     36-45             Male          
#>  6  2021 A0001     White                     46-55             Female        
#>  7  2021 A0001     White                     46-55             Male          
#>  8  2021 A0001     White                     56-65             Male          
#>  9  2021 A0002     Asian                     25 or less        Male          
#> 10  2021 A0002     Asian                     26-35             Male          
#> # ℹ 44,701 more rows
#> # ℹ 6 more variables: eligible_for_promotion <lgl>,
#> #   applied_for_promotion <lgl>, promoted <lgl>, old_rank <fct>,
#> #   new_rank <fct>, officer_count <int>
```

So count people with the count as a weight. Counting rows counts
combinations, not officers.

``` r
officer %>%
  filter(year == 2025) %>%
  count(officer_race, wt = officer_count, name = "officers")
#> # A tibble: 9 × 2
#>   officer_race                              officers
#>   <fct>                                        <int>
#> 1 American Indian or Alaska Native                32
#> 2 Asian                                          575
#> 3 Black or African American                     3092
#> 4 Hispanic                                      6360
#> 5 Native Hawaiian or other Pacific Islander       68
#> 6 Other                                          138
#> 7 Two or more races                              204
#> 8 White                                        20785
#> 9 <NA>                                           284
```

To attach agency names to a table, join `agency` on the `agency_id` and
the years each name was in use:

``` r
officer %>%
  count(year, agency_id, wt = officer_count, name = "officers") %>%
  left_join(agency, join_by(agency_id, between(year, first_year, final_year))) %>%
  select(year, agency_county, agency_name, officers) %>%
  arrange(desc(officers))
#> # A tibble: 2,630 × 4
#>     year agency_county agency_name             officers
#>    <int> <fct>         <chr>                      <int>
#>  1  2025 <NA>          New Jersey State Police     3351
#>  2  2024 <NA>          New Jersey State Police     3286
#>  3  2023 <NA>          New Jersey State Police     3264
#>  4  2022 <NA>          New Jersey State Police     3117
#>  5  2021 <NA>          New Jersey State Police     3073
#>  6  2022 Essex County  Newark PD                   1149
#>  7  2025 Essex County  Newark PD                   1105
#>  8  2024 Essex County  Newark PD                   1046
#>  9  2021 Essex County  Newark PD                   1034
#> 10  2023 Essex County  Newark PD                   1027
#> # ℹ 2,620 more rows
```

### Municipalities

`agency_municipality` identifies municipalities by `GEOID_Y2K`, the
stable municipality identifier of the `njmunicipalities` package. It
does not change when a municipality is renamed or assigned a new GEOID.
To get the name and GEOID in effect in a given year:

``` r
agency_municipality %>%
  left_join(
    njmunicipalities::get_municipalities(2025, geoid_year = 2000,
                                         geoid_ref_as_ref_column = TRUE),
    by = c("GEOID_Y2K" = "GEOID_ref")
  ) %>%
  left_join(agency %>% filter(first_year <= 2025, final_year >= 2025), by = "agency_id") %>%
  select(agency_name, GEOID, county, municipality)
#> # A tibble: 470 × 4
#>    agency_name        GEOID      county          municipality        
#>    <chr>              <chr>      <chr>           <chr>               
#>  1 Absecon City PD    3400100100 Atlantic County Absecon city        
#>  2 Atlantic City PD   3400102080 Atlantic County Atlantic City city  
#>  3 Brigantine PD      3400107810 Atlantic County Brigantine city     
#>  4 Egg Harbor City PD 3400120350 Atlantic County Egg Harbor City city
#>  5 Egg Harbor Twp PD  3400120290 Atlantic County Egg Harbor township 
#>  6 Galloway Twp PD    3400125560 Atlantic County Galloway township   
#>  7 Hamilton Twp PD    3400129280 Atlantic County Hamilton township   
#>  8 Hammonton PD       3400129430 Atlantic County Hammonton town      
#>  9 Linwood City PD    3400140530 Atlantic County Linwood city        
#> 10 Longport PD        3400141370 Atlantic County Longport borough    
#> # ℹ 460 more rows
```

Agencies that serve more than one municipality have one row for each:

``` r
agency %>%
  filter(agency_type == "Multiple Municipalities") %>%
  inner_join(agency_municipality, by = "agency_id") %>%
  left_join(
    njmunicipalities::get_municipalities(2025, geoid_year = 2000,
                                         geoid_ref_as_ref_column = TRUE),
    by = c("GEOID_Y2K" = "GEOID_ref")
  ) %>%
  select(agency_name, municipality)
#> # A tibble: 18 × 2
#>    agency_name       municipality          
#>    <chr>             <chr>                 
#>  1 Haddon Twp PD     Audubon Park borough  
#>  2 Haddon Twp PD     Haddon township       
#>  3 Cape May City PD  Cape May city         
#>  4 Cape May City PD  Cape May Point borough
#>  5 Cape May City PD  West Cape May borough 
#>  6 Franklin Twp PD   Buena borough         
#>  7 Franklin Twp PD   Franklin township     
#>  8 Franklin Twp PD   Newfield borough      
#>  9 Woolwich Twp PD   Swedesboro borough    
#> 10 Woolwich Twp PD   Woolwich township     
#> 11 Belmar PD         Belmar borough        
#> 12 Belmar PD         Lake Como borough     
#> 13 Chester PD        Chester borough       
#> 14 Chester PD        Chester township      
#> 15 Washington Twp PD Califon borough       
#> 16 Washington Twp PD Washington township   
#> 17 Wharton Boro PD   Mine Hill township    
#> 18 Wharton Boro PD   Wharton borough
```

### Use with `njoaguof`

`agency_alias` maps the agency names used by `njoaguof` to `agency_id`.
For example, here are the agencies with the most use-of-force incidents
per officer in 2024. (See the note below on incomplete agency reports.)

``` r
uof_agency <- agency_alias %>%
  filter(source == "njoaguof") %>%
  select(agency_county, agency_name, agency_id)

njoaguof::incident %>%
  filter(format(incident_date_1, "%Y") == "2024") %>%
  mutate(agency_county = as.character(agency_county)) %>%
  inner_join(uof_agency, by = c("agency_county", "agency_name")) %>%
  count(agency_id, name = "incidents") %>%
  inner_join(
    officer %>%
      filter(year == 2024) %>%
      count(agency_id, wt = officer_count, name = "officers"),
    by = "agency_id"
  ) %>%
  mutate(incidents_per_officer = incidents / officers) %>%
  left_join(agency %>% filter(first_year <= 2024, final_year >= 2024), by = "agency_id") %>%
  select(agency_name, incidents, officers, incidents_per_officer) %>%
  arrange(desc(incidents_per_officer))
#> # A tibble: 493 × 4
#>    agency_name                      incidents officers incidents_per_officer
#>    <chr>                                <int>    <int>                 <dbl>
#>  1 Seaside Heights PD                     212       28                  7.57
#>  2 Vineland PD                            413      146                  2.83
#>  3 Pleasantville PD                       141       52                  2.71
#>  4 Point Pleasant Beach PD                 58       25                  2.32
#>  5 Waterford Twp PD                        55       25                  2.2 
#>  6 Delaware River Port Authority PD       210       96                  2.19
#>  7 New Jersey Transit Police              661      308                  2.15
#>  8 Red Bank PD                             75       36                  2.08
#>  9 Wildwood PD                             95       47                  2.02
#> 10 Fair Lawn PD                            14        7                  2   
#> # ℹ 483 more rows
```

## Notes

These are the ways in which this package differs from the source data.

### Agency identifiers and names

The source identifies agencies by county and name only. This package
assigns each agency a stable `agency_id`, and records every spelling
seen in `agency_alias`. The `agency_name` in `agency` is the 2025
release’s spelling, except for these agencies, where it fixes a
truncation or follows the “Twp PD” naming of the other agencies:

``` r
agency_alias %>%
  filter(source == "njoag-leod-2025") %>%
  inner_join(agency, by = "agency_id", suffix = c("_source", "")) %>%
  filter(agency_name_source != agency_name) %>%
  select(source_name = agency_name_source, agency_name)
#> # A tibble: 7 × 2
#>   source_name                     agency_name                       
#>   <chr>                           <chr>                             
#> 1 Burlington County Sheriffs Off  Burlington Co Sheriffs Office     
#> 2 New Jersey Institute Of Technol New Jersey Institute Of Technology
#> 3 Robbinsville Township Police    Robbinsville Twp PD               
#> 4 Toms River Township             Toms River Twp PD                 
#> 5 Hardyston Twp Police Dept       Hardyston Twp PD                  
#> 6 Linden Police Department        Linden PD                         
#> 7 Park Police                     New Jersey State Park Police
```

Agencies that the source lists as “State or Other Agency” have
`agency_county` `NA`.

### Agency type and municipalities

The source no longer reports agency type. `agency_type` was assigned by
this package, starting from the 2021 release’s agency types, with some
corrections: for example, Chester PD serves both Chester borough and
Chester township, and the police departments of private universities
have type “Other”. The municipalities in `agency_municipality` were also
assigned by this package, including municipalities served under
shared-services agreements. The sources for these are recorded in
`inst/extdata/agency_municipality.csv`.

### Incomplete agency reports

The data is as reported by each agency, and some agency-years look
incomplete. For example, Lakewood PD reports 153 officers in 2021 but 20
in 2022 and 58 in 2025, and Saddle Brook PD reports about 30 officers
every year until 2025, when it reports 5. This package does not correct
these. Here are the agency-years with fewer than half the agency’s
median number of officers (among agencies with a median of at least 10).
This is only a rough screen: it misses agencies that report too few
officers in most years, such as Fair Lawn PD, which reports 7 to 17
officers in 2021–2024 and 56 in 2025.

``` r
officer %>%
  count(agency_id, year, wt = officer_count, name = "officers") %>%
  group_by(agency_id) %>%
  mutate(median_officers = median(officers)) %>%
  ungroup() %>%
  filter(median_officers >= 10, officers < median_officers / 2) %>%
  left_join(agency, join_by(agency_id, between(year, first_year, final_year))) %>%
  select(year, agency_county, agency_name, officers, median_officers) %>%
  arrange(year, agency_county, agency_name) %>%
  print(n = Inf)
#> # A tibble: 16 × 5
#>     year agency_county     agency_name                 officers median_officers
#>    <int> <fct>             <chr>                          <int>           <dbl>
#>  1  2022 Bergen County     Park Ridge PD                      3              21
#>  2  2022 Cape May County   Cape May Co Sheriffs Office       49             135
#>  3  2022 Ocean County      Lakewood PD                       20             153
#>  4  2023 Gloucester County Franklin Twp PD                   11              38
#>  5  2023 Monmouth County   Rumson PD                          2              19
#>  6  2024 Camden County     Hi-Nella PD                        2              10
#>  7  2025 Atlantic County   Linwood City PD                    9              21
#>  8  2025 Bergen County     Ramsey PD                         14              36
#>  9  2025 Bergen County     Saddle Brook PD                    5              32
#> 10  2025 Camden County     Hi-Nella PD                        3              10
#> 11  2025 Gloucester County Greenwich Twp PD                   8              19
#> 12  2025 Mercer County     Ewing Twp PD                      28              82
#> 13  2025 Morris County     Montville Twp PD                  11              40
#> 14  2025 Morris County     Mountain Lakes PD                  4              12
#> 15  2025 Ocean County      Lakewood PD                       58             153
#> 16  2025 Ocean County      Long Beach Twp PD                  8              35
```

### Recoded values

“Not Provided” and “Blank” are recoded as `NA`, and yes/no answers as
logicals. One value in the source has a trailing space (`"Other "` as
the reason for no appointment), which has been removed.

## Installation

You can install the latest version of njoagleod from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("tor-gu/njoagleod")
```
