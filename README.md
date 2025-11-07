# cfsclassifier <img src="man/figures/logo.png" align="right" height="138" />

**Tools for Clinical Frailty Scale (CFS) Classification in R**

[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

---

## Overview

The `cfsclassifier` package provides a robust and easy-to-use set of functions for classifying individuals based on the **Clinical Frailty Scale (CFS)** within an R environment. It is designed to streamline the process of assessing frailty by handling variable mapping, data cleaning, and the application of established CFS classification rules.

## Features

* **Automated CFS Classification:** Applies the defined CFS algorithm to your dataset.
* **Flexible Variable Mapping:** Supports both interactive console-based mapping and pre-defined `variable_map` lists to match your dataset's column names with standard CFS variables.
* **Data Cleaning:** Automatically cleans relevant variables, converting invalid entries (e.g., `9` for unknown/missing, or out-of-range values) to `NA`.
* **Detailed Output:** Appends `balds_count`, `ialds_count`, `diseases_count`, and the final `cfs_score` to your input data frame.
* **Utility Functions:** Includes helpers for labeling (`cfs_label`), grouping (`cfs_group`), and validation (`validate_cfs`) of CFS scores.

---

## Version History

### v2.0 – 2025-09-19
- **Major Update:** Adjusted CFS classification logic to include **CFS scores 8 and 9 (Terminally Ill)** and implement the minimum comorbidities rule (default 10).
- Updated `cfs_functions.R` to v2.
- Preserved previous version as `R/old_versions/cfs_functions_v1.R`.
- Tagged release in GitHub as `v2.0`.

### v1.0
- Initial implementation of CFS functions.
- Rule-based CFS classification with hierarchical scoring from 1 to 7.
- Supports interactive and pre-defined variable mapping.

---

## Installation

You can install the `cfsclassifier` package directly from GitHub using `devtools`. If you don't have `devtools` installed, you'll need to install it first.

```R
# Install devtools if you haven't already
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install cfsclassifier from GitHub
devtools::install_github("henriquepott/cfsclassifier")
```

---

## Basic Usage

The primary function in this package is classify_cfs(). Here's a quick example using dummy data.

```R
# Load the package
library(cfsclassifier)

# Create example dummy data (replace with your actual dataset)
# Ensure your column names and values align with the descriptions below.
dummy_data <- data.frame(
  # Example with custom names, mimicking a user's dataset
  My_Dressing_Var = c(1, 0, 0, 0, 0, 0), My_Eating_Var = c(1, 0, 0, 0, 0, 0),
  My_Walking_Var = c(1, 0, 0, 0, 0, 0), My_Bed_Transfer_Var = c(0, 1, 0, 0, 0, 0),
  My_Showering_Var = c(0, 1, 0, 0, 0, 0), My_Phone_Use_Var = c(0, 1, 1, 0, 0, 0),
  My_Shopping_Var = c(0, 1, 1, 0, 0, 0), My_Cooking_Var = c(0, 1, 1, 0, 0, 0),
  My_Meds_Var = c(0, 1, 1, 0, 0, 0), My_Money_Var = c(0, 1, 1, 0, 0, 0),
  My_Housekeeping_Var = c(0, 0, 0, 0, 0, 0), My_Heart_Disease_Var = c(0, 0, 0, 1, 0, 0),
  My_COPD_Var = c(0, 0, 0, 1, 0, 0), My_Hypertension_Var = c(0, 0, 0, 1, 0, 0),
  My_Diabetes_Var = c(0, 0, 0, 1, 0, 0), My_Cognition_Score = c(0, 0, 0, 3, 0, 0),
  My_Mobility_Score = c(1, 1, 1, 4, 1, 2), My_Energy_Level = c(1, 1, 1, 4, 4, 1),
  My_Terminally_Ill_Var = c(0, 0, 0, 0, 0, 0) # Adicionado para CFS 8/9
)

# Option 2: Run with a pre-defined map (recommended for automated scripts)
# The names on the left are the standard variables expected by the package.
my_variable_map <- list(
  # BALDS
  bald_dressing = "My_Dressing_Var", bald_eating = "My_Eating_Var", bald_walking = "My_Walking_Var",
  bald_bed_transfer = "My_Bed_Transfer_Var", bald_showering = "My_Showering_Var",
  # IALDS
  iald_phone_use = "My_Phone_Use_Var", iald_shopping = "My_Shopping_Var", iald_meal_prep = "My_Cooking_Var",
  iald_med_management = "My_Meds_Var", iald_finance = "My_Money_Var", iald_housekeeping = "My_Housekeeping_Var",
  # DISEASES
  disease_copd = "My_COPD_Var", disease_asthma = "My_Asthma_Var", disease_hypertension = "My_Hypertension_Var",
  disease_diabetes = "My_Diabetes_Var", disease_heart_fail = NA, disease_heart_attack = NA,
  disease_cancer = NA, disease_dementia = NA, disease_parkinson = NA, disease_alzheimer = NA,
  disease_spine = NA, disease_arthritis = NA, disease_osteoporosis = NA, disease_stroke = NA, disease_renal = NA,
  # OTHER KEY VARIABLES
  general_health = "My_Cognition_Score", daily_effort = "My_Mobility_Score", physical_activity = "My_Energy_Level",
  terminally_ill = "My_Terminally_Ill_Var"
)

classified_data_mapped <- classify_cfs(dummy_data, variable_map = my_variable_map, min_comorbidities = 10)

# View the result
print(classified_data_mapped)
```
---

## Utility Functions
Beyond the main classification, the package provides helpers to label and group CFS scores:
```R
# Assuming 'classified_data_mapped' is the output from classify_cfs()

# 1. Convert numeric CFS score to descriptive labels (e.g., "7" to "Living with Severe Frailty")
classified_data_mapped$cfs_label <- cfs_label(classified_data_mapped$cfs_score)

# 2. Group CFS scores into standard categories
# 2.1. Two-group classification (Non-frail: CFS 1-4, Frail: CFS 5-9)
classified_data_mapped$cfs_group_2 <- cfs_group(classified_data_mapped$cfs_score, scheme = "2group")

# 2.2. Three-group classification (Non-frail: 1-3, Pre-frail: 4-5, Frail: 6-9)
classified_data_mapped$cfs_group_3 <- cfs_group(classified_data_mapped$cfs_score, scheme = "3group")

# View the result with new labels
print(classified_data_mapped)
```
---

## Variable Mapping Explained

The `classify_cfs` function needs to know which columns in your dataset correspond to the specific variables used in the Clinical Frailty Scale calculation.

* **Interactive Mapping (Default):** If you call classify_cfs(your_data) without the variable_map argument, the function will guide you through the process via console prompts. For each standard package variable (e.g., bald_dressing), it will display a description and ask you to type in the exact name of the corresponding column in your data frame.
* **Pre-defined Mapping (`variable_map`):** For scripting or repeated use, you must provide a named list (variable_map) where the names are the standard variables expected by the package (as listed below) and the values are your actual column names.

---

## Required Variables and Expected Values

Below is the list of standard package variable names that should be used in the variable_map, along with their descriptions and allowed values.

### Basic Activities of Daily Living (BALDS) - Expected values: `0` (No difficulty), `1` (Yes, difficulty)
* **`bald_dressing`**: Dressing: Do you have any difficulty with DRESSING UP?
* **`bald_eating`**: Eating: Do you have any difficulty with EATING from a dish that was placed in front of you?
* **`bald_walking`**: Walking: Do you have any difficulty with GETTING ACROSS A ROOM OR WALKING FROM ONE ROOM TO ANOTHER on the same floor?
* **`bald_bed_transfer`**: Bed Transfer: Do you have any difficulty with GETTING IN OR OUT OF BED?
* **`bald_showering`**: Showering: Do you have any difficulty with SHOWERING?

### Instrumental Activities of Daily Living (IALDS) - Expected values: `0` (No difficulty), `1` (Yes, difficulty)
* **`iald_phone_use`**: Telephone Use: Do you have any difficulty with USING TELEPHONE (LANDLINE OR CELLULAR)?
* **`iald_shopping`**: Shopping: Do you have any difficulty with DOING SHOPPING?
* **`iald_meal_prep`**: Meal Prep: Do you have any difficulty with preparing A HOT MEAL?
* **`iald_med_management`**: Medication Management: Do you have any difficulty with TAKING/MANAGING YOUR OWN MEDICATIONS?
* **`iald_finance`**: Financial Management: Do you have any difficulty with MANAGING YOUR OWN MONEY?
* **`iald_housekeeping`**: Light Housekeeping: Do you have any difficulty with PERFORMING LIGHT HOUSEKEEPING?

### Health Conditions (DISEASES) - Expected values: `0` (No), `1` (Yes)
* **`disease_copd`**: COPD
* **`disease_asthma`**: Asthma
* **`disease_hypertension`**: Hypertension (high blood pressure)
* **`disease_diabetes`**: Diabetes ('high blood sugar')
* **`disease_heart_fail`**: Heart Failure
* **`disease_heart_attack`**: Heart Attack
* **`disease_cancer`**: Cancer
* **`disease_dementia`**: Memory/Dementia (non-Alzheimer's)
* **`disease_parkinson`**: Parkinson’s Disease
* **`disease_alzheimer`**: Alzheimer’s Disease
* **`disease_spine`**: Chronic Column Problem (e.g., back pain, sciatica)
* **`disease_arthritis`**: Arthritis or Rheumatism
* **`disease_osteoporosis`**: Osteoporosis
* **`disease_stroke`**: Cerebral Vascular Accident (stroke)
* **`disease_renal`**: Chronic Renal Failure

### Other Important Variables
* **`general_health`**: General Health: `0`=Excellent, `1`=Very good, `2`=Good, `3`=Fair, `4`=Bad, `5`=Very bad
* **`daily_effort`**: Daily Activities Effort: `1`=Never/rarely, `2`=Very few times, `3`=Sometimes, `4`=Most of the time
* **`physical_activity`**: Physical Activity: `1`=More than once a week, `2`=Once a week, `3`=1 to 3 times a month, `4`=Rarely or never
* **`terminally_ill`**: Terminally Ill status: `0`=(No), `1`=(Yes)

---

## CFS Classification Logic

The `classify_cfs` function implements a rule-based algorithm to assign a CFS score from **1 to 9**. The rules are applied hierarchically, from the most severe frailty (CFS 9) down to very fit (CFS 1). Individuals with insufficient data for any classification will have an an `NA` for `cfs_score`.

---

## References

* Theou O, Pérez-Zepeda MU, van der Valk AM, Searle SD, Howlett SE, Rockwood K. A classification tree to assist with routine scoring of the Clinical Frailty Scale. Age Ageing. 2021 Jun 28;50(4):1406-1411. doi: 10.1093/ageing/afab006. PMID: 33605412; PMCID: PMC7929455.
* Rockwood K, Theou O. Using the Clinical Frailty Scale in Allocating Scarce Health Care Resources. Can Geriatr J. 2020 Sep 1;23(3):210-215. doi: 10.5770/cgj.23.463. PMID: 32904824; PMCID: PMC7458601.
* More information on the Clinical Frailty Scale can be found at: [https://academic.oup.com/ageing/article/50/4/1406/6144822](https://academic.oup.com/ageing/article/50/4/1406/6144822) and [https://cgjonline.ca/index.php/cgj/article/view/463](https://cgjonline.ca/index.php/cgj/article/view/463)

---

## License

This package is licensed under the MIT License. See the `LICENSE` file for details.

---

## Contributing

Contributions to `cfsclassifier` are welcome! If you find a bug or have a feature request, please open an issue on the [GitHub repository](https://github.com/YOUR_GITHUB_USERNAME/cfsclassifier/issues).

---
