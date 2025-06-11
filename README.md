
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