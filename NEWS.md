# njoagleod 2.0.0
Breaking changes: the package is rebuilt from the 2025 NJ OAG release, and every table has a
new structure.

* New source data: the 2025 NJ OAG release, covering officers for 2021-2025 and agencies and
  applicants for 2022-2025. The 2021 release is no longer used.
* Agencies are identified by a stable `agency_id` from the
  [njlea](https://github.com/tor-gu/njlea) registry of NJ law enforcement agencies, such as
  `"NJLEA0001"`. The tables refer to agencies by `agency_id` only.
* Removed the `agency` table. Agency names, levels and functions, municipalities served and
  source spellings come from njlea. This package re-exports `get_agencies()`,
  `get_agency_municipalities()` and `find_agency()`; njlea's own tables have the rest.
* New and changed tables:
  - `agency_practice` (new): agency hiring and promotion practices, 2022 onward.
  - `officer`: now a count table (`officer_count`), with age range in place of age and new
    promotion columns.
  - `applicant` (new): counts of applicants, 2022 onward.
* Removed the `municipality` table; use `get_agency_municipalities()` or the
  `njmunicipalities` package instead.
* Race, gender and other factor levels now follow the source rather than `njoaguof`.
* Corrected errors in the source data:
  - Trailing space removed from the reason for no appointment `"Other "`.
  - Corrections to agency types and municipalities (such as Chester PD's) are now made, and
    documented, in njlea.

# njoagleod 1.1.3
* Corrected error in the source data:
  - Chester PD `agency_type` corrected: `Municipal` --> `Multiple Municipality`.
* Corected two errors I introduced:
  - Boonton PD `municipality`:  "Boonton township" --> "Boonton town"
  - Shrewsbury PD `municipality`:  "Shrewsbury township" --> "Shrewsbury borough"
  
# njoagleod 1.1.2
* Changed three agency names for consistency

  - "Toms River Township" --> "Toms River Twp PD"
  - "Hardyston Twp Police Dept" --> "Hardyston Twp PD"
  - "Linden Police Department" --> "Linden PD"

* Added `municipality` table.

* Added `municipality` column to `agency` table.

# njoagleod 1.1.1

* Updated consistency checks with njoaguof. No data changes.

# njoagleod 1.1.0

* Added a `NEWS.md` file to track changes to the package.

* Updated with NJ OAG data dump of 2022.05.11:
  - Added Washington Park PD (Warren County)
  - Added New Jersey State Park Police
  - Updated Clark PD (Union County) officer list

# njoagleod 1.0.0

  * Initial version.
