#' Officers in the NJ OAG Law Enforcement Officer Diversity data set
#'
#' Officer records from the NJ OAG Law Enforcement Officer Diversity data set.
#'
#' The first three columns -- `year`, `agency_county` and `agency_name` -- serve
#' as foreign key to the `agency` table.
#' @format A dataframe with 6 columns
#' \describe{
#'  \item{year}{Year}
#'  \item{agency_county}{Agency county, or `NA` if statewide or regional}
#'  \item{agency_name}{Agency name, such as "Abescon City PD"}
#'  \item{officer_age}{Officer age}
#'  \item{officer_race}{Officer race}
#'  \item{officer_gender}{Officer gender}
#' }
#' @source \url{https://www.njoag.gov/policerecruiting/}
"officer"
