# Description ----

# Asociaciones espacio longitudinales del Indice de Privacion (SEE)
# con el IMC pediatrico en visitas registradas en la Historia Clinica Elec
# trónica de Salud 2010-2023 20/02/2024


# Package Dependencies -----

## Installation and loading ----
if(require("pacman")){
  print("Loading package pacman")
} else {
  print("Installing package pacman")
  install.packages("pacman")
}

# Required packages
packages <- c("anthro", "anthroplus", "bit64", "data.table",
              "gganimate", "ggExtra", "gridExtra", "growthcleanr",
              "janitor", "kableExtra", "lattice", "leaflet",
              "leaflet.extras", "leafpop", "leafsync", "lubridate",
              "magick", "openxlsx", "plotly", "RColorBrewer",
              "readr", "scales", "stringi", "tidyverse", "writexl"
              )

# Install and load packages
pacman::p_load(char = packages)




# Working directory ----

wd <- paste0(getwd(), "/Data_collection_and_cleaning")




# Data loading ----

## Patient information ----
patients <- read.csv(paste0(wd, "/raw_data/PRISIB22008_PACIENT.txt"),
                 sep = "\t") %>% 
  select(CLAUPAX, SEXE, DATA_NAIXEMENT) %>% 
  mutate(
    DATA_NAIXEMENT = dmy(DATA_NAIXEMENT),
    SEXE = as.factor(SEXE)
    ) %>% 
  rename(subjid = CLAUPAX,
         sex = SEXE,
         date_of_birth = DATA_NAIXEMENT
         ) %>% 
  as_tibble() %>% 
  group_by(subjid) %>% 
  summarise_all(first) %>% 
  arrange(subjid)


## PSIA information out of protocol ----
out_PSIA_weight <- read.csv(paste0(wd, "/raw_data/PRISIB22008_GIS_PSIA Pesos fora protocol.tsv"),
                        sep = "\t",
                        dec = ",") %>% 
  select(CLAUPAX, VALOR, DATA_PES) %>% 
  mutate(
    DATA_PES = dmy(DATA_PES)
    ) %>% 
  rename(subjid = CLAUPAX,
         WEIGHTKG = VALOR,
         date_of_measurement = DATA_PES
         ) %>% 
  as_tibble() %>% 
  filter(!stri_isempty(subjid)) %>% 
  arrange(subjid, date_of_measurement)

out_PSIA_height <- read.csv(paste0(wd, "/raw_data/PRISIB22008_GIS_PSIA Talles fora protocol.tsv"),
                             sep = "\t",
                            dec = ",") %>% 
  select(CLAUPAX, VALOR, DATA_PES) %>% 
  mutate(
    DATA_PES = dmy(DATA_PES)
    ) %>% 
  rename(
    subjid = CLAUPAX,
    HEIGHTCM = VALOR,
    date_of_measurement = DATA_PES
  ) %>% 
  as_tibble() %>% 
  filter(!stri_isempty(subjid)) %>% 
  arrange(subjid, date_of_measurement)


## Load weight and sizes ----
Weight <- patients %>% 
  inner_join(out_PSIA_weight, by = "subjid") %>% 
  filter(year(date_of_measurement) >= 2010) %>% # Year of standardisation
  filter(year(date_of_measurement) < 2023) %>% # PSIA year
  mutate(
    agedays = as.numeric(round((date_of_measurement - date_of_birth))),
    sex = as.numeric(paste(fct_recode(sex, "1" = "FEMENI", "0" = "MASCULI"))),
    ) %>%
  select(subjid, sex, agedays, WEIGHTKG, date_of_measurement) %>%
  filter((agedays / 365.24) > 2) %>% 
  filter((agedays / 365.24) < 15) # Age between 2 and 14 years

Height <- patients %>% 
  inner_join(out_PSIA_height, by = "subjid") %>% 
  filter(year(date_of_measurement) >= 2010) %>% 
  filter(year(date_of_measurement) < 2023) %>% 
  mutate(
    agedays = as.numeric(round((date_of_measurement - date_of_birth))),
    sex = as.numeric(paste(fct_recode(sex, "1" = "FEMENI", "0" = "MASCULI")))
    ) %>% 
  select(subjid, sex, agedays, HEIGHTCM, date_of_measurement) %>% 
  filter((agedays / 365.24) > 2) %>% 
  filter((agedays / 365.24) < 15)


## PSIA in protocol ----
in_PSIA_weight <- read.csv(paste0(wd, "/raw_data/PRISIB22008_PES.txt"),
                        sep = "\t") %>% 
  select(CLAUPAX, VALOR, DATA, CODI) %>% 
  mutate(
    DATA = dmy(DATA),
    CODI = as.character(CODI)
    ) %>% 
  rename(
    subjid = CLAUPAX,
    WEIGHTKG = VALOR,
    date_of_measurement = DATA,
    visit_code = CODI
  ) %>% 
  filter(!stri_isempty(subjid)) %>% 
  as_tibble() %>% 
  arrange(subjid, date_of_measurement)

in_PSIA_height <- read.csv(paste0(wd, "/raw_data/PRISIB22008_TALLA.txt"),
                        sep = "\t") %>% 
  select(CLAUPAX, VALOR, DATA, CODI) %>% 
  mutate(
    DATA = dmy(DATA),
    CODI = as.character(CODI)
    ) %>% 
  rename(
    subjid = CLAUPAX,
    HEIGHTCM = VALOR,
    date_of_measurement = DATA,
    visit_code = CODI
  ) %>% 
  as_tibble() %>% 
  filter(!stri_isempty(subjid)) %>% 
  arrange(subjid, date_of_measurement)


## Load PSIA's weight and sizes ----
PSIA_weight <- patients %>% 
  inner_join(in_PSIA_weight, by = "subjid") %>% 
  filter(year(date_of_measurement) >= 2010) %>% 
  filter(year(date_of_measurement) < 2023) %>% 
  mutate(
    agedays = as.numeric(round((date_of_measurement - date_of_birth))),
    sex = as.numeric(paste(fct_recode(sex, "1" = "FEMENI", "0" = "MASCULI")))
    ) %>% 
  select(subjid, sex, agedays, WEIGHTKG, date_of_measurement) %>% 
  filter((agedays / 365.24) > 2) %>% 
  filter((agedays / 365.24) < 15)

PSIA_height <- patients %>% 
  inner_join(in_PSIA_height, by = "subjid") %>% 
  filter(year(date_of_measurement) >= 2018) %>% 
  filter(year(date_of_measurement) < 2023) %>% 
  mutate(
    agedays = as.numeric(round((date_of_measurement - date_of_birth))),
    sex = as.numeric(paste(fct_recode(sex, "1" = "FEMENI", "0" = "MASCULI"))),
    ) %>% 
  select(subjid, sex, agedays, HEIGHTCM, date_of_measurement) %>% 
  filter((agedays / 365.24) > 2) %>% 
  filter((agedays / 365.24) < 15)


## Bind data frames by category ----
Weight <- bind_rows(Weight, PSIA_weight)
Height <- bind_rows(Height, PSIA_height)




# Data processing for Growthcleanr----

## Convert to data.table and format ----
Weight_long <- melt(as.data.table(Weight),
                    id.vars = c("subjid",
                                "sex",
                                "agedays",
                                "date_of_measurement"),
                     measure.vars = c("WEIGHTKG"),
                     variable.name = "param",
                     value.name = "measurement"
                    )

Height_long <- melt(as.data.table(Height),
                    id.vars = c("subjid",
                                "sex",
                                "agedays",
                                "date_of_measurement"),
                    measure.vars = c( "HEIGHTCM"),
                    variable.name = "param",
                    value.name = "measurement"
                    )


## Join data ----
Full_data <- full_join(Height_long, Weight_long)


## Store data ----

### Folders to store data ----
processed_data_path <- paste0(wd, "/processed_data")
csv_path <- paste0(processed_data_path, "/csv_files")
RDS_path <- paste0(processed_data_path, "/RDS_files")

# Check if folders exists and creates them if needed
if(!dir.exists(processed_data_path)){
  dir.create(processed_data_path)
}

if(!dir.exists(csv_path)){
  dir.create(csv_path)
}

if(!dir.exists(RDS_path)){
  dir.create(RDS_path)
}

### Save data ----
write_csv(Full_data, paste0(csv_path, "/Full_data.csv"))
save(Full_data, file = paste0(RDS_path, "/Full_data.RData"))




## Clean memory ----
rm(list=ls()[!ls() %in% c("wd",
                          "Full_data",
                          "processed_data_path",
                          "csv_path",
                          "RDS_path")])
gc()




# Growthcleanr ----

# Set key for better indexing
setkey(Full_data, subjid, param, agedays, sex)

# WARNING: very slow process
cleaned_data <- Full_data[, gcr_result := cleangrowth(subjid,
                                                      param,
                                                      agedays,
                                                      sex,
                                                      measurement)]

# Summarize results by result type
kbl(cleaned_data %>% 
      group_by(gcr_result, param) %>% 
      tally(sort = TRUE)) %>% 
  kable_paper() %>% 
  scroll_box(width = "100%", height = "400px")


## Filter included data ----
# Age: 2-15 years; Time period: 2011-2017; Plausible growth values
included_data <- cleaned_data %>% 
  filter(gcr_result == "Include") %>% 
  filter(date_of_measurement < as.Date("2018-01-01") & 
           date_of_measurement > as.Date("2010-12-31"))

# At least two visits with the same day recorded height and weight
included_data <- included_data %>% 
  pivot_wider(names_from = param,
              values_from = measurement
              ) %>% 
  filter(!is.na(HEIGHTCM) & !is.na(WEIGHTKG)) %>% 
  group_by(subjid) %>% 
  filter(n() > 1) %>% 
  ungroup() %>% 
  select(!gcr_result)


## Save cleaned and included data ----
# Cleaned data
write_csv(cleaned_data, paste0(csv_path, "/Cleaned_full_data.csv"))
save(cleaned_data, file = paste0(RDS_path, "/Cleaned_full_data.RData"))

# Included data
write_csv(included_data, paste0(csv_path, "/Cleaned_included_data.csv"))
save(included_data, file = paste0(RDS_path, "/Cleaned_included_data.RData"))


## Clean memory ----
rm(list=ls()[!ls() %in% c("wd",
                          "cleaned_data",
                          "included_data",
                          "processed_data_path",
                          "csv_path",
                          "RDS_path")])
gc()




# WHO Zscores ----

# Change sex codification: Female = 2, Male = 1
included_data <- included_data %>% 
  mutate(
    sex = case_when(
      sex == 1 ~ 2,
      sex == 0 ~ 1
    )
  )

## Anthro (age under 5 years) ----
# Temporarily adjust agedays
cleaned_zscores_anthro <- included_data %>% 
  mutate(
    original_age = agedays,
    agedays = ifelse(trunc(agedays / 30.4375) == 60,
                     (agedays - 30.4375),
                     agedays
                     )
    ) %>% 
  filter((agedays / 30.4375) < 60)

anthro <- with(
  cleaned_zscores_anthro,
  anthro_zscores(
    sex = sex,
    age = agedays,
    is_age_in_month = FALSE,
    weight = WEIGHTKG,
    lenhei = HEIGHTCM
    )
  ) %>% 
  select(c("csex", "cbmi", "zbmi", "fbmi"))

# Restore agedays
cleaned_zscores_anthro <- cleaned_zscores_anthro %>% 
  mutate(
    agedays = original_age,
    original_age = NULL
  )

## Anthroplus (5 years or older) ----
cleaned_zscores_anthroplus <- included_data %>% 
  filter((agedays / 30.4375) >= 61)

anthroplus <- with(
  cleaned_zscores_anthroplus,
  anthroplus_zscores(
    sex = sex,
    age_in_months = (agedays / 30.4375),
    weight_in_kg = WEIGHTKG, 
    height_in_cm = HEIGHTCM
    )
  ) %>% 
  rename(
    zbmi=zbfa,
    fbmi=fbfa
    ) %>% 
  select(c("csex", "cbmi", "zbmi", "fbmi"))

anthro <- bind_cols(list(cleaned_zscores_anthro, anthro)) 
anthroplus <- bind_cols(list(cleaned_zscores_anthroplus, anthroplus)) 
who_zscores <- bind_rows(anthro, anthroplus)


## Label data ----
processed_included_data <- who_zscores %>% 
  mutate(
    age_years = agedays / 365.2425,
    csex = NULL
    ) %>% 
  group_by((agedays / 30.4375) < 61) %>% 
  mutate(
    zbmi_type = case_when(
      zbmi < -2.0 ~ "Underweight",
      zbmi >= -2.0 & zbmi <= 2.0 ~ "Normal_weight",
      zbmi > 2.0 & zbmi <= 3.0 ~ "Overweight",
      zbmi > 3.0 ~ "Obese"
      )
    ) %>% 
  ungroup() %>% 
  group_by((agedays / 30.4375) >= 61) %>% 
  mutate(
    zbmi_type = case_when(
      zbmi < -2.0 ~ "Underweight",
      zbmi >= -2.0 & zbmi <= 1.0 ~ "Normal_weight",
      zbmi > 1.0 & zbmi <= 2.0 ~ "Overweight",
      zbmi > 2.0 ~ "Obese"
      )
    ) %>% 
  ungroup() %>% 
  select(where(~ !is.logical(.))) %>% 
  relocate(age_years, .before = date_of_measurement)

processed_included_data$zbmi_type <- factor(processed_included_data$zbmi_type,
                                            levels = c("Underweight",
                                                       "Normal_weight",
                                                       "Overweight",
                                                       "Obese"),
                                            ordered = TRUE)

### Rename columns and arrange ----
processed_included_data <- processed_included_data %>% 
  mutate(
    sex = case_when(
      sex == 2 ~ "Female",
      sex == 1 ~ "Male"
    ),
    fbmi = NULL
  ) %>% 
  rename(
    age_days = agedays,
    height_cm = HEIGHTCM,
    weight_kg = WEIGHTKG,
    bmi = cbmi
  ) %>% 
  arrange(subjid, date_of_measurement)


## Save processed data ----
write_csv(processed_included_data, paste0(csv_path, "/Processed_data.csv"))
save(processed_included_data, file = paste0(RDS_path, "/Processed_data.RData"))
