pacman::p_load(dplyr, tidyr, tibble)

#' @title Clean Clinical Frailty Scale Variables
#' @description Cleans specified variables in a data frame, replacing invalid values and '9' with NA.
#' @param df A data frame.
#' @param variables A character vector of column names to be cleaned.
#' @param allowed_values A vector of valid values for the variables.
#' @return The data frame with the specified variables cleaned.
clean_cfs_variables <- function(df, variables, allowed_values) {

  vars_to_clean <- intersect(variables, names(df))

  if (length(vars_to_clean) == 0) {
    warning("None of the specified variables were found in the data frame.")
    return(df)
  }

  df <- df %>%
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::all_of(vars_to_clean),
        .fns = ~ dplyr::case_when(
          . %in% allowed_values ~ as.numeric(.),
          . == 9 ~ NA_real_,
          TRUE ~ NA_real_
        )
      )
    )

  vars_not_found <- setdiff(variables, names(df))
  if(length(vars_not_found) > 0) {
    warning(paste0("Variables not found in the data frame: ", paste(vars_not_found, collapse = ", "), ". They were skipped."))
  }

  return(df)
}

#' @title Classify Clinical Frailty Scale (CFS)
#' @description Classifies the CFS based on specified variables, applying precise rules for CFS 1–9.
#' @param data A data frame containing the necessary variables for CFS classification.
#' @param variable_map Optional named list mapping standard CFS variable names to your dataset's columns.
#' @param min_comorbidities Minimum number of comorbidities required to assign CFS score (default 10).
#' @return The input data frame with 'balds_count', 'ialds_count', 'diseases_count', and 'cfs_score' added.
#' @export
classify_cfs <- function(data, variable_map = NULL, min_comorbidities = 10) {

  df <- tibble::as_tibble(data)

  safe_column_access <- function(df, var_name) {
    if (is.null(var_name) || !var_name %in% names(df)) {
      return(rep(NA_real_, nrow(df)))
    } else {
      return(df[[var_name]])
    }
  }

  std_vars <- c(
    "bald_dressing","bald_eating","bald_walking","bald_bed_transfer","bald_showering",
    "iald_phone_use","iald_shopping","iald_meal_prep","iald_med_management","iald_finance","iald_housekeeping",
    "disease_copd","disease_asthma","disease_hypertension","disease_diabetes","disease_heart_fail",
    "disease_heart_attack","disease_cancer","disease_dementia","disease_parkinson","disease_alzheimer",
    "disease_spine","disease_arthritis","disease_osteoporosis","disease_stroke","disease_renal",
    "general_health","daily_effort","physical_activity","terminally_ill"
  )

  if(is.null(variable_map)) variable_map <- setNames(std_vars, std_vars)
  get_var <- function(var) variable_map[[var]] %||% var

  gh_var <- get_var("general_health")
  effort_var <- get_var("daily_effort")
  phys_var <- get_var("physical_activity")
  term_var <- get_var("terminally_ill")

  balds_keys <- c("bald_dressing","bald_eating","bald_walking","bald_bed_transfer","bald_showering")
  ialds_keys <- c("iald_phone_use","iald_shopping","iald_meal_prep","iald_med_management","iald_finance","iald_housekeeping")
  diseases_keys <- grep("^disease_", names(variable_map), value = TRUE)

  balds_vars_raw <- intersect(unlist(variable_map[balds_keys]), names(df))
  ialds_vars_raw <- intersect(unlist(variable_map[ialds_keys]), names(df))
  diseases_vars_raw <- intersect(unlist(variable_map[diseases_keys]), names(df))

  df <- df %>%
    dplyr::mutate(
      balds_count = if(length(balds_vars_raw) > 0) rowSums(dplyr::select(., dplyr::all_of(balds_vars_raw)) == 1, na.rm = TRUE) else 0,
      ialds_count = if(length(ialds_vars_raw) > 0) rowSums(dplyr::select(., dplyr::all_of(ialds_vars_raw)) == 1, na.rm = TRUE) else 0,
      diseases_count = if(length(diseases_vars_raw) > 0) rowSums(dplyr::select(., dplyr::all_of(diseases_vars_raw)) == 1, na.rm = TRUE) else 0
    )

  # --- VECTORIZED CLASSIFICATION using case_when ---
  df <- df %>%
    dplyr::mutate(
      # Safe access to mapped columns
      gh = safe_column_access(., gh_var),
      e = safe_column_access(., effort_var),
      p = safe_column_access(., phys_var),
      term = safe_column_access(., term_var),

      cfs_score = dplyr::case_when(
        # Terminal Rules (CFS 8–9)
        term == 1 ~ dplyr::if_else(balds_count <= 2, "9", "8"),

        # CFS 7
        balds_count >= 3 ~ "7",

        # CFS 6
        balds_count %in% 1:2 | (balds_count == 0 & ialds_count >= 5) ~ "6",

        # CFS 5
        balds_count == 0 & ialds_count %in% 1:4 ~ "5",

        # CFS 4
        balds_count == 0 & ialds_count == 0 & (diseases_count >= min_comorbidities | gh %in% 4:5 | e == 5) ~ "4",

        # CFS 3
        balds_count == 0 & ialds_count == 0 & diseases_count < min_comorbidities &
          (
            (gh == 1 & e %in% 3:4 & p == 0) |
              (gh %in% 2:3 & e %in% 1:4 & p == 0)
          ) ~ "3",

        # CFS 2
        balds_count == 0 & ialds_count == 0 & diseases_count < min_comorbidities &
          (
            (gh == 1 & e %in% 3:4 & p == 1) |
              (gh %in% 2:3 & e %in% 1:4 & p == 1) |
              (gh == 1 & e %in% 1:2 & p == 0) # ADICIONADO: GH Exc, E Mínimo, Sem Ativ (CFS 2 por regra textual)
          ) ~ "2",

        # CFS 1
        balds_count == 0 & ialds_count == 0 & diseases_count < min_comorbidities & gh == 1 & e %in% 1:2 & p == 1 ~ "1",

        # Contingency Fallback: If data is complete but doesn't fit in 1, 2, 4-7, classify as 3.
        .default = "3"
      )
    ) %>%
    # Final NA assignment: Overwrite CFS score with NA if any key health variable is missing.
    dplyr::mutate(
      cfs_score = dplyr::if_else(
        is.na(gh) | is.na(e) | is.na(p) | is.na(term),
        NA_character_,
        cfs_score
      )
    )

  return(df)
}


#' @title Validate Clinical Frailty Scale (CFS) Classification
#' @description Checks whether the CFS classification in a data frame matches expected values
#'    based on the counts of BADLs, IADLs, comorbidities, and other health variables.
#' @param df A data frame returned from `classify_cfs`.
#' @param min_comorbidities Minimum number of comorbidities required to assign CFS score (default 10).
#' @return A list containing:
#'    - df: the input data frame with additional columns 'expected_cfs' and 'check_pass'.
#'    - summary_pass: a table summarizing TRUE/FALSE for check_pass.
#'    - failed_cases: subset of df where the classification did not match expected.
#' @export
validate_cfs <- function(df, min_comorbidities = 10) {

  df <- df %>%
    dplyr::mutate(
      b = balds_count,
      iald = ialds_count,
      d = diseases_count,

      expected_cfs = dplyr::case_when(
        # Terminal Rules (CFS 8–9)
        terminally_ill == 1 ~ dplyr::if_else(b <= 2, "9", "8"),

        # CFS 7
        b >= 3 ~ "7",

        # CFS 6
        b %in% 1:2 | (b == 0 & iald >= 5) ~ "6",

        # CFS 5
        b == 0 & iald %in% 1:4 ~ "5",

        # CFS 4
        b == 0 & iald == 0 & (d >= min_comorbidities | general_health %in% 4:5 | daily_effort == 5) ~ "4",

        # CFS 3
        b == 0 & iald == 0 & d < min_comorbidities &
          (
            (general_health == 1 & daily_effort %in% 3:4 & physical_activity == 0) |
              (general_health %in% 2:3 & daily_effort %in% 1:4 & physical_activity == 0)
          ) ~ "3",

        # CFS 2
        b == 0 & iald == 0 & d < min_comorbidities &
          (
            (general_health == 1 & daily_effort %in% 3:4 & physical_activity == 1) |
              (general_health %in% 2:3 & daily_effort %in% 1:4 & physical_activity == 1) |
              (general_health == 1 & daily_effort %in% 1:2 & physical_activity == 0) # ADICIONADO
          ) ~ "2",

        # CFS 1
        b == 0 & iald == 0 & d < min_comorbidities & general_health == 1 & daily_effort %in% 1:2 & physical_activity == 1 ~ "1",

        .default = NA_character_
      ),

      check_pass = as.logical(cfs_score == expected_cfs)
    )

  summary_pass <- table(df$check_pass, useNA = "ifany")
  failed_cases <- df[df$check_pass == FALSE & !is.na(df$check_pass), ]

  return(list(df = df, summary_pass = summary_pass, failed_cases = failed_cases))
}

#' @title Convert numeric CFS scores to descriptive labels
#' @param cfs A numeric vector of CFS scores (1-9).
#' @return A factor vector with descriptive labels.
cfs_label <- function(cfs) {

  labels <- c(
    "Very Fit",
    "Fit",
    "Managing Well",
    "Living with Very Mild Frailty",
    "Living with Mild Frailty",
    "Living with Moderate Frailty",
    "Living with Severe Frailty",
    "Living with Very Severe Frailty",
    "Terminally Ill"
  )

  cfs <- suppressWarnings(as.numeric(cfs))
  if (any(!cfs %in% 1:9, na.rm = TRUE)) {
    warning("CFS scores must be integers between 1 and 9. Invalid values set to NA.")
    cfs[!cfs %in% 1:9] <- NA
  }

  factor(labels[cfs],
         levels = labels,
         ordered = TRUE)
}

#' @title Group CFS scores into frailty categories
#' @param cfs A numeric vector of CFS scores (1-9).
#' @param scheme A character string specifying the grouping scheme ("2group" or "3group").
#' @return A factor vector with frailty group labels.
cfs_group <- function(cfs, scheme = c("2group", "3group")) {

  scheme <- match.arg(scheme)
  cfs <- suppressWarnings(as.numeric(cfs))
  cfs[!cfs %in% 1:9] <- NA

  if (scheme == "2group") {
    group <- ifelse(cfs <= 4, "Non-frail",
                    ifelse(cfs >= 5, "Frail", NA))
    group <- factor(group, levels = c("Non-frail", "Frail"), ordered = TRUE)
  } else {
    group <- cut(cfs,
                 breaks = c(0, 3, 5, 9),
                 labels = c("Non-frail", "Pre-frail", "Frail"),
                 right = TRUE)
  }
  return(group)
}
