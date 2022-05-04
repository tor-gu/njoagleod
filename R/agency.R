#' Agencies in the NJ OAG Law Enforcement Officer Diversity data set
#'
#' Agency records from the NJ OAG Law Enforcement Officer Diversity data set.
#'
#' The first three columns -- `year`, `agency_county` and `agency_name` -- serve
#' as the primary key.
#' @format A dataframe with 5 columns
#' \describe{
#'  \item{year}{Year}
#'  \item{agency_county}{Agency county, or `NA` if statewide or regional}
#'  \item{agency_name}{Agency name, such as "Abescon City PD"}
#'  \item{agency_type}{Agency type. Levels are "State-wide", "County",
#'  "Municipal", "Multiple Municipalities" and "Not Provided"}
#'  \item{hiring_governed_by_civil_service}{A boolean field. `NA` if not provided.}
#' }
#' @source \url{https://www.njoag.gov/policerecruiting/}
"agency"
