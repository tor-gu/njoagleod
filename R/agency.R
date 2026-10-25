#' Agencies in the NJ OAG Law Enforcement Officer Diversity data set
#'
#' One row per agency per name. `agency_id` is a stable identifier assigned by this
#' package; it does not change when an agency is renamed or re-spelled. If an agency is
#' renamed, it has one row for each name, with the years each name was in use.
#'
#' To attach the name in effect in a given year to a table with `agency_id` and `year`:
#' `dplyr::left_join(officer, agency, dplyr::join_by(agency_id, between(year, first_year, final_year)))`.
#'
#' `agency_county` and `agency_name` can also be used to join with the `njoaguof` package,
#' through the aliases in [agency_alias].
#'
#' The columns `agency_id` and `first_year` serve as the primary key.
#' @format A dataframe with 7 columns
#' \describe{
#'  \item{agency_id}{Stable agency identifier, such as "A0001"}
#'  \item{first_year}{First year of this name, within the years covered by the data}
#'  \item{final_year}{Final year of this name, within the years covered by the data}
#'  \item{agency_county}{Agency county, such as "Atlantic County", or `NA` if statewide or
#'  regional}
#'  \item{agency_name}{Agency name, such as "Absecon City PD"}
#'  \item{agency_type}{Agency type. Levels are "State-wide", "County", "Municipal",
#'  "Multiple Municipalities" and "Other". Assigned by this package; the source no
#'  longer reports it.}
#'  \item{ori}{FBI Originating Agency Identifier, where known. Currently always `NA`.}
#' }
#' @source \url{https://www.njoag.gov/policerecruiting/}
"agency"
