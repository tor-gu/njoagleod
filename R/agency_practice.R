#' Agency hiring and promotion practices
#'
#' Each agency's answers to the NJ OAG questions about how it hires and promotes officers,
#' one row per agency per year, for 2022 onward. All answers are `TRUE` (yes), `FALSE` (no)
#' or `NA` (not answered).
#'
#' The columns `year` and `agency_id` serve as the primary key.
#' @format A dataframe with 26 columns
#' \describe{
#'  \item{year}{Year}
#'  \item{agency_id}{Stable agency identifier, as in [agency]}
#'  \item{applications_received}{Did the agency receive any applications for employment?}
#'  \item{hiring_civil_service}{Is hiring governed by Civil Service?}
#'  \item{hire_method_civil_service_list}{Hires from a Civil Service exam list}
#'  \item{hire_method_non_civil_service_list}{Hires from a non-Civil Service exam list}
#'  \item{hire_method_intergovernmental_transfer}{Hires by inter-governmental transfer}
#'  \item{hire_method_waiver}{Hires by training waiver}
#'  \item{hire_method_bcpo_direct}{Hires graduates of the Basic Course for Police Officers
#'  (BCPO) directly}
#'  \item{hire_element_return_the_card}{Application uses "return the card"}
#'  \item{hire_element_formal_application}{Application uses a formal application}
#'  \item{hire_element_interview_board}{Application uses an interview board}
#'  \item{hire_element_written_exam}{Application uses a written exam}
#'  \item{hire_element_local_preference}{Preference for local or county applicants}
#'  \item{hire_element_veteran_preference}{Preference for veteran applicants}
#'  \item{hire_element_drug_test}{Application uses drug testing}
#'  \item{hire_element_medical_exam}{Application uses a medical exam}
#'  \item{hire_element_psychiatric_exam}{Application uses a psychiatric exam}
#'  \item{appointed_before_academy}{Officers are appointed before entering the academy}
#'  \item{appointed_after_academy}{Officers are appointed after completing the academy}
#'  \item{promotion_applications_received}{Did the agency receive any applications for
#'  promotion?}
#'  \item{promotion_civil_service}{Are promotions governed by Civil Service regulations?}
#'  \item{promotion_civil_service_all_ranks}{Are promotions governed by Civil Service
#'  regulations for all ranks?}
#'  \item{promotion_practice_civil_service_list}{Promotes from a Civil Service exam list}
#'  \item{promotion_practice_non_civil_service_list}{Promotes from a non-Civil Service exam
#'  list}
#'  \item{promotion_practice_interview}{Promotion uses an interview}
#' }
#' @source \url{https://www.njoag.gov/policerecruiting/}
"agency_practice"
