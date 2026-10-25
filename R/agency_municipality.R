#' Municipalities served by each agency
#'
#' One row for each municipality an agency serves, with the years it served it. Municipal
#' agencies serve their own municipality; multiple-municipality agencies also serve
#' municipalities that contract with them for police services.
#'
#' Municipalities are identified by `GEOID_Y2K`, the stable municipality identifier of the
#' `njmunicipalities` package: the municipality's US Census GEOID as of 2000. To get the
#' name and GEOID in effect in a given year, join with
#' `njmunicipalities::get_municipalities(year, geoid_year = 2000, geoid_ref_as_ref_column = TRUE)`
#' by `GEOID_Y2K = "GEOID_ref"`.
#'
#' The columns `agency_id`, `GEOID_Y2K` and `first_year` serve as the primary key.
#' @format A dataframe with 4 columns
#' \describe{
#'  \item{agency_id}{Stable agency identifier, as in [agency]}
#'  \item{GEOID_Y2K}{Stable municipality identifier, as in `njmunicipalities`}
#'  \item{first_year}{First year the agency served the municipality, within the years
#'  covered by the data}
#'  \item{final_year}{Final year the agency served the municipality, within the years
#'  covered by the data}
#' }
"agency_municipality"
