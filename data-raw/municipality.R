# This requires a census API key
library(tidyverse)
library(tidycensus)

# Get a list of the counties of NJ
counties <- get_estimates(geography = "county",
                        product = "population",
                        state = "New Jersey",
                        year=2019) %>%
  separate(NAME, sep=", ", into=c("county", "state")) %>%
  pull(county) %>%
  unique() %>%
  sort()


# Get municipalities for each county
municipality <- counties %>%
  purrr::map_df(
    ~ tidycensus::get_estimates(geography="county subdivision",
                                state="NJ",
                                county=.,
                                year=2019,
                                variables="POP") %>%
      separate(NAME, sep=", ", into=c("municipality","county","state")) %>%
      select(county, municipality, GEOID)
  )

# Save the data
usethis::use_data(municipality, overwrite = TRUE)
