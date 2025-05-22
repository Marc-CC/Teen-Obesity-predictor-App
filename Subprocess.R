# Subprocess for streamlit app ----
suppressWarnings({

packages <- c("growthcleanr", "anthro", "anthroplus")
for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg)
  }
  library(pkg, character.only = TRUE)
}
require(jsonlite, quietly = TRUE)
require(dplyr, quietly = TRUE)
require(tidyr, quietly = TRUE)

# Load inputs ----
input <- fromJSON("child_data.json")

# Re-check and convert types ----
input$Sex = as.character(input$Sex)
input$Age = as.numeric(input$Age)
input$Height_cm = as.numeric(input$Height_cm)
input$Weight_kg = as.numeric(input$Weight_kg)

# Processing ----

## Growthcleanr ----

### Prepare for growthcleanr ----

# Split into two dfs
height_data <- input[, !colnames(input) %in% "Weight_kg"]
weight_data <- input[, !colnames(input) %in% "Height_cm"]

height_data$param <- rep("HEIGHTCM", dim(height_data)[1])
weight_data$param <- rep("WEIGHTKG", dim(weight_data)[1])

colnames(height_data) <- c("Sex", "Age", "measurement", "param")
colnames(weight_data) <- c("Sex", "Age", "measurement", "param")

# Re-fuse dfs and finish preparing data
growthclean <- rbind(height_data, weight_data)
growthclean$Age <- growthclean$Age * 365.25
growthclean$Sex <- ifelse(growthclean$Sex == "Female", "F", "M")
growthclean$subjid <- rep("subjid", dim(growthclean)[1])

### Call cleangrowth
gcr_result <- cleangrowth(subjid = growthclean$subjid,
                          param = growthclean$param,
                          agedays = growthclean$Age,
                          sex = growthclean$Sex,
                          measurement = growthclean$measurement)
growthclean <- cbind(growthclean, gcr_result)

# Zbmi calculation ----

## Data preparation ----
growthclean <- growthclean[growthclean$gcr_result == "Include", ]
growthclean <- growthclean[, !colnames(growthclean) %in% "gcr_result"]

growthclean <- growthclean %>%
  pivot_wider(names_from = param, values_from = measurement) %>%
  filter(!is.na(HEIGHTCM) & !is.na(WEIGHTKG))

# Split by anthro and anthroplus ages
anthro <- growthclean[growthclean$Age < (5 * 365.25), ]
anthroplus <- growthclean[growthclean$Age >= (5 * 365.25), ]
original_age_anthroplus <- anthroplus$Age
anthroplus$Age <- anthroplus$Age / 30.4375

anthro[["zbmi"]] <- with(
  anthro,
  anthro_zscores(
    sex = Sex, age = Age,
    weight = WEIGHTKG, lenhei = HEIGHTCM)
  ) %>% pull(zbmi)

anthroplus[["zbmi"]] <- with(
  anthroplus,
  anthroplus_zscores(
    sex = Sex, age = Age,
    weight_in_kg = WEIGHTKG, height_in_cm = HEIGHTCM)
) %>% pull(zbfa)

anthroplus$Age <- original_age_anthroplus

# Merge all data ----
All <- bind_rows(anthro, anthroplus) %>% 
  select(Sex, Age, zbmi) %>%
  mutate(Age = Age / 365.25)

All$Sex <- ifelse(All$Sex == "F", 1, 0)

# Prepare for model ----
All <- pivot_wider(All, names_from = Age,
                   values_from = zbmi,
                   names_glue = "zbmi_{Age}")

ages <- seq(2, 13, 1)
zbmi_cols <- paste0("zbmi_", ages)
other_cols <- setdiff(names(All), zbmi_cols)

for (col in zbmi_cols) {
  if (!col %in% names(All)) {
    All[[col]] <- NA
  }
}

All <- All[, c(zbmi_cols, other_cols)]

All$sex_Female <- ifelse(All$Sex == 1, 1.0, 0.0)
All$sex_Male <- ifelse(All$Sex == 1, 0.0, 1.0)
All$Sex <- NULL

All$stratify <- 0

# Export ----
write(toJSON(All, auto_unbox = TRUE, na = "null"), "child_data_processed.json")

})