
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
contains three tables.

- `agency_practice` Each agency’s hiring and promotion practices, by
  year.
- `officer` Counts of officers by year, agency, race, age range, gender
  and promotion.
- `applicant` Counts of applicants by year, agency, race, age range,
  gender, applicant type and outcome.

The tables identify agencies by `agency_id`, a stable identifier from
the [`njlea`](https://github.com/tor-gu/njlea) registry of NJ law
enforcement agencies. This package re-exports njlea’s functions for
looking agencies up:

- `get_agencies(year)` The agencies in a year, with their names as of
  that year, county, level and function.
- `get_agency_municipalities(year)` The municipalities each agency
  serves, identified as in the
  [`njmunicipalities`](https://github.com/tor-gu/njmunicipalities)
  package.
- `find_agency(pattern)` Search agency names and every source spelling.

njlea’s tables (`njlea::agency`, `njlea::agency_alias` and the others)
have the full registry.

## Examples

``` r
library(njoagleod)
library(dplyr)
```

The agencies in 2025:

``` r
get_agencies(2025)
#> # A tibble: 543 × 6
#>    agency_id agency_name     county agency_level agency_function multi_municipal
#>    <chr>     <chr>           <chr>  <fct>        <fct>           <lgl>          
#>  1 NJLEA0001 Absecon Police… Atlan… Municipal    Police          FALSE          
#>  2 NJLEA0002 Atlantic City … Atlan… Municipal    Police          FALSE          
#>  3 NJLEA0003 Atlantic Count… Atlan… County       Corrections     FALSE          
#>  4 NJLEA0004 Atlantic Count… Atlan… County       Prosecutor      FALSE          
#>  5 NJLEA0005 Atlantic Count… Atlan… County       Sheriff         FALSE          
#>  6 NJLEA0006 Brigantine Pol… Atlan… Municipal    Police          FALSE          
#>  7 NJLEA0007 Egg Harbor Cit… Atlan… Municipal    Police          FALSE          
#>  8 NJLEA0008 Egg Harbor Tow… Atlan… Municipal    Police          FALSE          
#>  9 NJLEA0009 Galloway Towns… Atlan… Municipal    Police          FALSE          
#> 10 NJLEA0010 Hamilton Towns… Atlan… Municipal    Police          FALSE          
#> # ℹ 533 more rows
```

The `officer` and `applicant` tables are count tables: each row is a
combination of characteristics, and `officer_count` (or
`applicant_count`) is the number of people who share it.

``` r
officer
#> # A tibble: 44,711 × 11
#>     year agency_id officer_race              officer_age_range officer_gender
#>    <int> <chr>     <fct>                     <ord>             <fct>         
#>  1  2021 NJLEA0001 Asian                     36-45             Female        
#>  2  2021 NJLEA0001 Black or African American 26-35             Male          
#>  3  2021 NJLEA0001 White                     25 or less        Male          
#>  4  2021 NJLEA0001 White                     26-35             Male          
#>  5  2021 NJLEA0001 White                     36-45             Male          
#>  6  2021 NJLEA0001 White                     46-55             Female        
#>  7  2021 NJLEA0001 White                     46-55             Male          
#>  8  2021 NJLEA0001 White                     56-65             Male          
#>  9  2021 NJLEA0002 Asian                     25 or less        Male          
#> 10  2021 NJLEA0002 Asian                     26-35             Male          
#> # ℹ 44,701 more rows
#> # ℹ 6 more variables: eligible_for_promotion <lgl>,
#> #   applied_for_promotion <lgl>, promoted <lgl>, old_rank <fct>,
#> #   new_rank <fct>, officer_count <int>
```

So count people with the count as a weight. Counting rows counts
combinations, not officers.

``` r
officer |>
  filter(year == 2025) |>
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

An agency’s name can change from year to year, so to attach names to a
table that covers several years, get each year’s agencies and join on
`agency_id` and `year`:

``` r
agency_names <- function(years) {
  bind_rows(lapply(years, function(y) mutate(get_agencies(y), year = y)))
}

officer |>
  count(year, agency_id, wt = officer_count, name = "officers") |>
  left_join(agency_names(2021:2025), by = c("agency_id", "year")) |>
  select(year, county, agency_name, officers) |>
  arrange(desc(officers))
#> # A tibble: 2,630 × 4
#>     year county       agency_name              officers
#>    <int> <chr>        <chr>                       <int>
#>  1  2025 <NA>         New Jersey State Police      3351
#>  2  2024 <NA>         New Jersey State Police      3286
#>  3  2023 <NA>         New Jersey State Police      3264
#>  4  2022 <NA>         New Jersey State Police      3117
#>  5  2021 <NA>         New Jersey State Police      3073
#>  6  2022 Essex County Newark Police Department     1149
#>  7  2025 Essex County Newark Police Department     1105
#>  8  2024 Essex County Newark Police Department     1046
#>  9  2021 Essex County Newark Police Department     1034
#> 10  2023 Essex County Newark Police Department     1027
#> # ℹ 2,620 more rows
```

### Municipalities

`get_agency_municipalities()` lists the municipalities each agency
serves, with their names and GEOIDs as of the year asked for:

``` r
get_agency_municipalities(2025) |>
  left_join(get_agencies(2025) |> select(agency_id, agency_name), by = "agency_id") |>
  select(agency_name, GEOID, county, municipality, link_type)
#> # A tibble: 471 × 5
#>    agency_name                           GEOID     county municipality link_type
#>    <chr>                                 <chr>     <chr>  <chr>        <fct>    
#>  1 Absecon Police Department             34001001… Atlan… Absecon city Home     
#>  2 Atlantic City Police Department       34001020… Atlan… Atlantic Ci… Home     
#>  3 Brigantine Police Department          34001078… Atlan… Brigantine … Home     
#>  4 Egg Harbor City Police Department     34001203… Atlan… Egg Harbor … Home     
#>  5 Egg Harbor Township Police Department 34001202… Atlan… Egg Harbor … Home     
#>  6 Galloway Township Police Department   34001255… Atlan… Galloway to… Home     
#>  7 Hamilton Township Police Department   34001292… Atlan… Hamilton to… Home     
#>  8 Hammonton Police Department           34001294… Atlan… Hammonton t… Home     
#>  9 Linwood Police Department             34001405… Atlan… Linwood city Home     
#> 10 Longport Police Department            34001413… Atlan… Longport bo… Home     
#> # ℹ 461 more rows
```

Agencies that serve more than one municipality have one row for each:

``` r
get_agencies(2025) |>
  filter(multi_municipal) |>
  inner_join(get_agency_municipalities(2025), by = "agency_id",
             suffix = c("_agency", "")) |>
  select(agency_name, municipality, link_type)
#> # A tibble: 22 × 3
#>    agency_name                         municipality           link_type
#>    <chr>                               <chr>                  <fct>    
#>  1 Camden County Police Department     Camden city            Service  
#>  2 Camden County Police Department     Woodlynne borough      Service  
#>  3 Haddon Township Police Department   Haddon township        Home     
#>  4 Haddon Township Police Department   Audubon Park borough   Service  
#>  5 Cape May Police Department          Cape May city          Home     
#>  6 Cape May Police Department          Cape May Point borough Service  
#>  7 Cape May Police Department          West Cape May borough  Service  
#>  8 Franklin Township Police Department Franklin township      Home     
#>  9 Franklin Township Police Department Buena borough          Service  
#> 10 Franklin Township Police Department Newfield borough       Service  
#> # ℹ 12 more rows
```

### Use with `njoaguof`

The [`njoaguof`](https://github.com/tor-gu/njoaguof) use-of-force
package uses the same `agency_id`, so use-of-force incidents can be set
against what this package knows about each agency: its officers and its
hiring practices. Here we count 2024 incidents per agency.

``` r
incidents_2024 <- njoaguof::incident |>
  filter(format(incident_date_1, "%Y") == "2024") |>
  count(agency_id, name = "incidents")
```

From the `officer` table, the size of each agency’s force and its share
of female officers and of officers aged 35 or under; from
`agency_practice`, whether hiring is governed by Civil Service.

``` r
officers_2024 <- officer |>
  filter(year == 2024) |>
  group_by(agency_id) |>
  summarize(
    officers = sum(officer_count),
    pct_female = 100 * sum(officer_count[officer_gender %in% "Female"]) / officers,
    pct_35_or_under =
      100 * sum(officer_count[officer_age_range %in% c("25 or less", "26-35")]) / officers
  )

agency_2024 <- officers_2024 |>
  left_join(incidents_2024, by = "agency_id") |>
  mutate(incidents = coalesce(incidents, 0L),
         incidents_per_100_officers = 100 * incidents / officers) |>
  left_join(agency_practice |> filter(year == 2024) |>
              select(agency_id, hiring_civil_service),
            by = "agency_id") |>
  left_join(get_agencies(2024) |> select(agency_id, agency_name, agency_level),
            by = "agency_id")
```

The ten agencies with at least 50 officers and the most incidents per
officer:

``` r
agency_2024 |>
  filter(officers >= 50) |>
  arrange(desc(incidents_per_100_officers)) |>
  select(agency_name, officers, pct_female, pct_35_or_under, hiring_civil_service,
         incidents_per_100_officers) |>
  head(10) |>
  knitr::kable(digits = 0)
```

| agency_name                                     | officers | pct_female | pct_35_or_under | hiring_civil_service | incidents_per_100_officers |
|:------------------------------------------------|---------:|-----------:|----------------:|:---------------------|---------------------------:|
| Vineland Police Department                      |      146 |         12 |              52 | TRUE                 |                        283 |
| Pleasantville Police Department                 |       52 |         15 |              58 | TRUE                 |                        271 |
| Delaware River Port Authority Police Department |       96 |          7 |              47 | FALSE                |                        219 |
| New Jersey Transit Police Department            |      308 |          8 |              45 | FALSE                |                        215 |
| Neptune Township Police Department              |       86 |          8 |              41 | FALSE                |                        193 |
| Pennsauken Township Police Department           |       88 |         16 |              55 | TRUE                 |                        189 |
| Hoboken Police Department                       |      140 |         11 |              53 | TRUE                 |                        181 |
| Glassboro Police Department                     |       52 |         12 |              50 | FALSE                |                        181 |
| Trenton Police Department                       |      236 |         18 |              43 | TRUE                 |                        177 |
| Asbury Park Police Department                   |       87 |          8 |              33 | TRUE                 |                        176 |

And, for municipal agencies, incidents per 100 officers by Civil Service
hiring and by the share of officers aged 35 or under:

``` r
agency_2024 |>
  filter(agency_level == "Municipal") |>
  mutate(pct_35_or_under = cut(pct_35_or_under, c(0, 30, 45, 60, 100),
                               include.lowest = TRUE)) |>
  group_by(hiring_civil_service, pct_35_or_under) |>
  summarize(agencies = n(),
            incidents_per_100_officers = 100 * sum(incidents) / sum(officers),
            .groups = "drop")
#> # A tibble: 8 × 4
#>   hiring_civil_service pct_35_or_under agencies incidents_per_100_officers
#>   <lgl>                <fct>              <int>                      <dbl>
#> 1 FALSE                [0,30]                23                       48.2
#> 2 FALSE                (30,45]               91                       57.7
#> 3 FALSE                (45,60]              125                       51.3
#> 4 FALSE                (60,100]              44                       56.2
#> 5 TRUE                 [0,30]                15                       50.3
#> 6 TRUE                 (30,45]               69                       79.7
#> 7 TRUE                 (45,60]               66                       96.7
#> 8 TRUE                 (60,100]              23                      109.
```

These are descriptive only: incident rates depend heavily on what each
agency polices, and some agencies’ officer counts are incomplete (see
the note below).

## Notes

These are the ways in which this package differs from the source data.

### Agencies

The source identifies agencies by county and name only. The `agency_id`,
the agency names, levels and functions, and the municipalities served
all come from [`njlea`](https://github.com/tor-gu/njlea), not from the
source. njlea uses its own canonical names (such as “Absecon Police
Department” for the source’s “Absecon City PD”), records every source
spelling in `njlea::agency_alias` (source `"njoag-leod-2025"`), and
documents its corrections to the source, such as the municipalities
served under shared-services agreements. `find_agency()` searches the
names and the source spellings. The source’s “Chester PD”, for instance,
is Chester Township’s department:

``` r
find_agency("^Chester PD$")
#> # A tibble: 3 × 5
#>   agency_id agency_name                        county    matched_on matched_text
#>   <chr>     <chr>                              <chr>     <chr>      <chr>       
#> 1 NJLEA0355 Chester Township Police Department Morris C… njoag-leo… Chester PD  
#> 2 NJLEA0355 Chester Township Police Department Morris C… njoag-leo… Chester PD  
#> 3 NJLEA0355 Chester Township Police Department Morris C… njoaguof   Chester PD
```

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
officer |>
  count(agency_id, year, wt = officer_count, name = "officers") |>
  group_by(agency_id) |>
  mutate(median_officers = median(officers)) |>
  ungroup() |>
  filter(median_officers >= 10, officers < median_officers / 2) |>
  left_join(agency_names(2021:2025), by = c("agency_id", "year")) |>
  select(year, county, agency_name, officers, median_officers) |>
  arrange(year, county, agency_name) |>
  print(n = Inf)
#> # A tibble: 16 × 5
#>     year county            agency_name                  officers median_officers
#>    <int> <chr>             <chr>                           <int>           <dbl>
#>  1  2022 Bergen County     Park Ridge Police Department        3              21
#>  2  2022 Cape May County   Cape May County Sheriff's O…       49             135
#>  3  2022 Ocean County      Lakewood Township Police De…       20             153
#>  4  2023 Gloucester County Franklin Township Police De…       11              38
#>  5  2023 Monmouth County   Rumson Police Department            2              19
#>  6  2024 Camden County     Hi-Nella Police Department          2              10
#>  7  2025 Atlantic County   Linwood Police Department           9              21
#>  8  2025 Bergen County     Ramsey Police Department           14              36
#>  9  2025 Bergen County     Saddle Brook Township Polic…        5              32
#> 10  2025 Camden County     Hi-Nella Police Department          3              10
#> 11  2025 Gloucester County Greenwich Township Police D…        8              19
#> 12  2025 Mercer County     Ewing Township Police Depar…       28              82
#> 13  2025 Morris County     Montville Township Police D…       11              40
#> 14  2025 Morris County     Mountain Lakes Police Depar…        4              12
#> 15  2025 Ocean County      Lakewood Township Police De…       58             153
#> 16  2025 Ocean County      Long Beach Township Police …        8              35
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
