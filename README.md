
<!-- README.md is generated from README.Rmd. Please edit that file -->

# njoagleod

<!-- badges: start -->

[![R-CMD-check](https://github.com/tor-gu/njoaguof/workflows/R-CMD-check/badge.svg)](https://github.com/tor-gu/njoagleod/actions)<!-- badges: end -->

This is a cleaned-up version of the NJ OAG Law Enforcment Officer
Diversity database available from
<https://www.njoag.gov/policerecruiting/>

## Dataset Overview

This dataset contains two tables.

-   `agency` Has one row for each law enforcement agency, for each year
-   `officer` Has one row for each officer, for each year.

Currently 2021 is the only year represented.

## Examples

The `agency` table looks like this:

``` r
library(tidyverse)
library(njoagleod)
agency
#> # A tibble: 527 × 5
#>     year agency_county   agency_name                agency_type hiring_governed…
#>    <dbl> <fct>           <chr>                      <fct>       <lgl>           
#>  1  2021 Atlantic County Absecon City PD            Municipal   FALSE           
#>  2  2021 Atlantic County Atlantic City PD           Municipal   TRUE            
#>  3  2021 Atlantic County Atlantic Co Sheriffs Offi… County      TRUE            
#>  4  2021 Atlantic County Atlantic County Prosecuto… County      FALSE           
#>  5  2021 Atlantic County Brigantine PD              Municipal   FALSE           
#>  6  2021 Atlantic County Egg Harbor City PD         Municipal   TRUE            
#>  7  2021 Atlantic County Egg Harbor Twp PD          Municipal   FALSE           
#>  8  2021 Atlantic County Galloway Twp PD            Municipal   FALSE           
#>  9  2021 Atlantic County Hamilton Twp PD            Municipal   FALSE           
#> 10  2021 Atlantic County Hammonton PD               Municipal   TRUE            
#> # … with 517 more rows
```

The columns `year`, `agency_county` and `agency_name` form the primary
key.

The `officer` table looks like this.

``` r
officer
#> # A tibble: 30,453 × 6
#>     year agency_county   agency_name     officer_age officer_race officer_gender
#>    <dbl> <fct>           <chr>                 <dbl> <fct>        <fct>         
#>  1  2021 Atlantic County Absecon City PD          20 White        Male          
#>  2  2021 Atlantic County Absecon City PD          22 White        Male          
#>  3  2021 Atlantic County Absecon City PD          26 Black        Male          
#>  4  2021 Atlantic County Absecon City PD          27 White        Male          
#>  5  2021 Atlantic County Absecon City PD          29 White        Male          
#>  6  2021 Atlantic County Absecon City PD          29 White        Male          
#>  7  2021 Atlantic County Absecon City PD          30 White        Male          
#>  8  2021 Atlantic County Absecon City PD          32 White        Male          
#>  9  2021 Atlantic County Absecon City PD          34 White        Male          
#> 10  2021 Atlantic County Absecon City PD          35 White        Male          
#> # … with 30,443 more rows
```

The columns `year`, `agency_county` and `agency_name` act as a foreign
key to the `agency` table.

The `agency_name` and `agency_county` columns are consistent with the
columns of the same name in the associated
[`njoaguof`](https://github.com/tor-gu/njoaguof) package. Here are the
agencies with the highest number of use-of-force incidents per officer.

``` r
officer %>% 
  group_by(year, agency_county, agency_name) %>%
  summarize(officer_count = n(), .groups = "drop") %>%
  left_join(njoaguof::incident, by=c("agency_county", "agency_name")) %>%
  filter(lubridate::year(incident_date_1)==year) %>%
  group_by(year, agency_county, agency_name, officer_count) %>%
  summarize(incident_count = n(), .groups="drop") %>%
  mutate(incidents_per_officer = incident_count / officer_count) %>%
  arrange(desc(incidents_per_officer))
#> # A tibble: 467 × 6
#>     year agency_county agency_name officer_count incident_count incidents_per_o…
#>    <dbl> <fct>         <chr>               <int>          <int>            <dbl>
#>  1  2021 Cape May Cou… North Wild…            27             68             2.52
#>  2  2021 Ocean County  Seaside He…            25             56             2.24
#>  3  2021 Cape May Cou… Wildwood PD            44             97             2.20
#>  4  2021 Middlesex Co… South Rive…            32             65             2.03
#>  5  2021 Burlington C… Willingbor…            62            124             2   
#>  6  2021 Cumberland C… Millville …            80            154             1.92
#>  7  2021 <NA>          New Jersey…           301            536             1.78
#>  8  2021 Ocean County  Tuckerton …            13             22             1.69
#>  9  2021 Camden County Stratford …            19             31             1.63
#> 10  2021 Cape May Cou… Middle Twp…            54             88             1.63
#> # … with 457 more rows
```

## Notes

### Duplicates entries removed

In the source data, The Delaware River and Bay Authority Police
Department and its officers appear twice, once associated to Salem
County and once associated to Cape May County.

In this package, we have removed the duplicate entries and assigned the
county to `NA`. As a result, the source data has `30505` officers across
`528` agencies, while this package contains `30443` officers and `527`
agencies.

## Installation

You can install the latest version of njoaguof from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("tor-gu/njoagleod")
```
