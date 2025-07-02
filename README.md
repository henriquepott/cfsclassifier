# cfsclassifier <img src="man/figures/logo.PNG" align="right" height="138" />

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
  My_Dressing_Var = c(1, 0, 0, 0, 0, 0),
  My_Eating_Var = c(1, 0, 0, 0, 0, 0),
  My_Walking_Var = c(1, 0, 0, 0, 0, 0),
  My_Bed_Transfer_Var = c(0, 1, 0, 0, 0, 0),
  My_Showering_Var = c(0, 1, 0, 0, 0, 0),
  My_Phone_Use_Var = c(0, 1, 1, 0, 0, 0),
  My_Shopping_Var = c(0, 1, 1, 0, 0, 0),
  My_Cooking_Var = c(0, 1, 1, 0, 0, 0),
  My_Meds_Var = c(0, 1, 1, 0, 0, 0),
  My_Money_Var = c(0, 1, 1, 0, 0, 0),
  My_Housekeeping_Var = c(0, 0, 0, 0, 0, 0),
  My_Heart_Disease_Var = c(0, 0, 0, 1, 0, 0),
  My_COPD_Var = c(0, 0, 0, 1, 0, 0),
  My_Hypertension_Var = c(0, 0, 0, 1, 0, 0),
  My_Diabetes_Var = c(0, 0, 0, 1, 0, 0),
  My_Cognition_Score = c(0, 0, 0, 3, 0, 0), # Values 0-5
  My_Mobility_Score = c(1, 1, 1, 4, 1, 2),  # Values 1-4
  My_Energy_Level = c(1, 1, 1, 4, 4, 1)     # Values 1-4
)

# Option 1: Run interactively (recommended for first-time use)
# This will prompt you in the R console to map your column names.
# classified_data_interactive <- classify_cfs(dummy_data)

# Option 2: Run with a pre-defined map (recommended for automated scripts)
# This map explicitly tells the function which of your columns correspond to the standard CFS variables.
# Use NA for variables not present in your dataset.
my_variable_map <- list(
  p40 = "My_Dressing_Var", p46 = "My_Eating_Var", p37 = "My_Walking_Var",
  p49 = "My_Bed_Transfer_Var", p43 = "My_Showering_Var",
  p28 = "My_Phone_Use_Var", p26 = "My_Shopping_Var", p20 = "My_Cooking_Var",
  p30 = "My_Meds_Var", p22 = "My_Money_Var", p33 = "My_Housekeeping_Var",
  n55 = "My_COPD_Var", n54 = "My_Asthma_Var", n28 = "My_Hypertension_Var",
  n35 = "My_Diabetes_Var", n50 = NA, n46 = NA, # Example of unmapped/missing diseases
  n60 = NA, n63_2 = NA, n62 = NA, n63 = NA, n58 = NA, n56 = NA,
  n57 = NA, n52 = NA, n61 = NA,
  n1 = "My_Cognition_Score", n73 = "My_Mobility_Score", l2 = "My_Energy_Level"
)

classified_data_mapped <- classify_cfs(dummy_data, variable_map = my_variable_map)

# View the result
print(classified_data_mapped)
```

---

## Variable Mapping Explained

The `classify_cfs` function needs to know which columns in your dataset correspond to the specific variables used in the Clinical Frailty Scale calculation.

* **Interactive Mapping (Default):** If you call `classify_cfs(your_data)` without the `variable_map` argument, the function will guide you through the process via console prompts. For each standard CFS variable, it will display a description and ask you to type in the exact name of the corresponding column in your `your_data` data frame. If a variable is not available in your data, simply press Enter without typing anything.
* **Pre-defined Mapping (`variable_map`):** For scripting or repeated use, you can provide a named list (`variable_map`) where the names are the standard CFS variable IDs (e.g., `p40`, `n1`) and the values are the actual column names in your data (e.g., `"My_Dressing_Var"`). Use `NA` for variables that are not present in your dataset.

---


## Required Variables and Expected Values

Below is a list of the standard CFS variables that the `cfsclassifier` function expects, along with their descriptions and allowed values. Your input columns should contain data compatible with these types and ranges. Values outside the allowed range or `9` (commonly used for "unknown" or "missing") will be converted to `NA`.

### Basic Activities of Daily Living (BALDS) - Expected values: `0` (No difficulty), `1` (Yes, difficulty)
* **`p40`**: Dressing: Do you have any difficulty with DRESSING UP?
* **`p46`**: Eating: Do you have any difficulty with EATING from a dish that was placed in front of you?
* **`p37`**: Walking: Do you have any difficulty with GETTING ACROSS A ROOM OR WALKING FROM ONE ROOM TO ANOTHER on the same floor?
* **`p49`**: Bed Transfer: Do you have any difficulty with GETTING IN OR OUT OF BED?
* **`p43`**: Showering: Do you have any difficulty with SHOWERING?

### Instrumental Activities of Daily Living (IALDS) - Expected values: `0` (No difficulty), `1` (Yes, difficulty)
* **`p28`**: Telephone Use: Do you have any difficulty with USING TELEPHONE (LANDLINE OR CELLULAR)?
* **`p26`**: Shopping: Do you have any difficulty with DOING SHOPPING?
* **`p20`**: Meal Prep: Do you have any difficulty with preparing A HOT MEAL?
* **`p30`**: Medication Management: Do you have any difficulty with TAKING/MANAGING YOUR OWN MEDICATIONS?
* **`p22`**: Financial Management: Do you have any difficulty with MANAGING YOUR OWN MONEY?
* **`p33`**: Light Housekeeping: Do you have any difficulty with PERFORMING LIGHT HOUSEKEEPING?

### Health Conditions (DISEASES) - Expected values: `0` (No), `1` (Yes)
* **`n55`**: COPD
* **`n54`**: Asthma
* **`n28`**: Hypertension (high blood pressure)
* **`n35`**: Diabetes ('high blood sugar')
* **`n50`**: Heart Failure
* **`n46`**: Heart Attack
* **`n60`**: Cancer
* **`n63_2`**: Memory/Dementia (non-Alzheimer's)
* **`n62`**: Parkinson’s Disease
* **`n63`**: Alzheimer’s Disease
* **`n58`**: Chronic Column Problem (e.g., back pain, sciatica)
* **`n56`**: Arthritis or Rheumatism
* **`n57`**: Osteoporosis
* **`n52`**: Cerebral Vascular Accident (stroke)
* **`n61`**: Chronic Renal Failure

### Other Important Variables
* **`n1`**: General Health: `0`=Excellent, `1`=Very good, `2`=Good, `3`=Fair, `4`=Bad, `5`=Very bad
* **`n73`**: Daily Activities Effort: `1`=Never/rarely, `2`=Very few times, `3`=Sometimes, `4`=Most of the time
* **`l2`**: Physical Activity: `1`=More than once a week, `2`=Once a week, `3`=1 to 3 times a month, `4`=Rarely or never

---

## CFS Classification Logic

The `classify_cfs` function implements a rule-based algorithm to assign a CFS score from 1 to 7. The rules are applied hierarchically, from severe frailty (CFS 7) down to very fit (CFS 1). If a rule matches, the CFS score is assigned, and subsequent rules are not evaluated for that individual. Individuals with insufficient data for any classification will have an `NA` for `cfs_score`.

---

## References

* Rockwood, K., Song, X., MacKnight, C., Bergman, H., Hogan, D. B., McDowell, I., & Mitnitski, A. (2005). A global clinical measure of fitness and frailty in elderly people. \emph{CMAJ}, \emph{173}(5), 489-495.
* More information on the Clinical Frailty Scale can be found at: [https://www.dal.ca/sites/healthy-aging/cfs.html](https://www.dal.ca/sites/healthy-aging/cfs.html)

---

## License

This package is licensed under the MIT License. See the `LICENSE` file for details.

---

## Contributing

Contributions to `cfsclassifier` are welcome! If you find a bug or have a feature request, please open an issue on the [GitHub repository](https://github.com/YOUR_GITHUB_USERNAME/cfsclassifier/issues).

---
