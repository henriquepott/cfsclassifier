#' @title Clean Clinical Frailty Scale Variables
#' @description Cleans specified variables in a data frame, replacing invalid values and '9' with NA.
#' @param df A data frame.
#' @param variables A character vector of column names to be cleaned.
#' @param allowed_values A vector of valid values for the variables.
#' @return The data frame with the specified variables cleaned.
#' @examples
#' # df_example <- data.frame(v1 = c(0, 1, 9, 2), v2 = c(1, 0, 0, 9))
#' # clean_cfs_variables(df_example, c("v1", "v2"), c(0, 1))
clean_cfs_variables <- function(df, variables, allowed_values) {
  for (var in variables) {
    if (var %in% names(df)) {
      column <- df[[var]]
      # Replace values not in allowed_values or equal to 9 with NA
      column[! (column %in% allowed_values)] <- NA
      column[column == 9] <- NA
      df[[var]] <- column
    } else {
      warning(paste0("Variable '", var, "' not found in the data frame. Skipping cleaning for this variable."))
    }
  }
  return(df)
}

#' @title Classify Clinical Frailty Scale (CFS)
#' @description Classifies the Clinical Frailty Scale (CFS) based on specified variables,
#'              allowing for interactive or pre-defined mapping of variable names.
#' @param data A data frame containing the necessary variables for CFS classification.
#' @param variable_map An optional named list mapping standard CFS variable names to
#'                     actual column names in `data`. If `NULL`, an interactive
#'                     prompt will guide the user to define this mapping.
#'                     Example: `list(p40 = "user_p40_name", n1 = "user_n1_name")`
#' @return The input data frame with 'balds_count', 'ialds_count', 'diseases_count'
#'         and 'cfs_score' columns added.
#' @details
#' The CFS classification rules are applied in a specific order, from most to least severe.
#' Variable groups:
#' \itemize{
#'   \item **BALDS**: Basic Activities of Daily Living (p40, p46, p37, p49, p43)
#'   \item **IALDS**: Instrumental Activities of Daily Living (p28, p26, p20, p30, p22, p33)
#'   \item **DISEASES**: Health Conditions (n55, n54, n28, n35, n50, n46, n60, n63_2, n62, n63, n58, n56, n57, n52, n61)
#' }
#' Other key variables: n1 (Cognition), n73 (Mobility), l2 (Energy).
#' Invalid variable values (including '9') are replaced with NA before classification.
#' @examples
#' # Create dummy data for demonstration (replace with your actual data)
#' dummy_data <- data.frame(
#'   # Example with custom names, mimicking a user's dataset
#'   My_Dressing_Var = c(1, 0, 0, 0),
#'   My_Eating_Var = c(1, 0, 0, 0),
#'   My_Walking_Var = c(1, 0, 0, 0),
#'   My_Bed_Transfer_Var = c(0, 1, 0, 0),
#'   My_Showering_Var = c(0, 1, 0, 0),
#'   My_Phone_Use_Var = c(0, 1, 1, 0),
#'   My_Shopping_Var = c(0, 1, 1, 0),
#'   My_Cooking_Var = c(0, 1, 1, 0),
#'   My_Meds_Var = c(0, 1, 1, 0),
#'   My_Money_Var = c(0, 1, 1, 0),
#'   My_Housekeeping_Var = c(0, 0, 0, 0),
#'   My_Heart_Disease_Var = c(0, 0, 0, 1),
#'   My_COPD_Var = c(0, 0, 0, 1),
#'   My_Hypertension_Var = c(0, 0, 0, 1),
#'   My_Diabetes_Var = c(0, 0, 0, 1),
#'   My_Cognition_Score = c(0, 0, 0, 3), # Values 0-5
#'   My_Mobility_Score = c(1, 1, 1, 4),  # Values 1-4
#'   My_Energy_Level = c(1, 1, 1, 4)     # Values 1-4
#' )
#'
#' # Option 1: Run interactively (variable_map = NULL)
#' # This will prompt for input in the R console.
#' # classified_data_interactive <- classify_cfs(dummy_data)
#'
#' # Option 2: Run with a pre-defined map (non-interactive)
#' # my_map <- list(
#' #   p40 = "My_Dressing_Var", p46 = "My_Eating_Var", p37 = "My_Walking_Var",
#' #   p49 = "My_Bed_Transfer_Var", p43 = "My_Showering_Var",
#' #   p28 = "My_Phone_Use_Var", p26 = "My_Shopping_Var", p20 = "My_Cooking_Var",
#' #   p30 = "My_Meds_Var", p22 = "My_Money_Var", p33 = "My_Housekeeping_Var",
#' #   n55 = "My_Heart_Disease_Var", n54 = "My_COPD_Var", n28 = "My_Hypertension_Var",
#' #   n35 = "My_Diabetes_Var", n50 = NA, n46 = NA,
#' #   n60 = NA, n63_2 = NA, n62 = NA, n63 = NA, n58 = NA, n56 = NA,
#' #   n57 = NA, n52 = NA, n61 = NA,
#' #   n1 = "My_Cognition_Score", n73 = "My_Mobility_Score", l2 = "My_Energy_Level"
#' # )
#' # classified_data_mapped <- classify_cfs(dummy_data, variable_map = my_map)
classify_cfs <- function(data, variable_map = NULL) {

  processed_df <- as.data.frame(data)

  # Define standard CFS variables with comprehensive descriptions
  cfs_var_definitions <- list(
    # Basic Activities of Daily Living (BALDS)
    p40 = "Dressing: Do you have any difficulty with DRESSING UP? (0=No, 1=Yes)",
    p46 = "Eating: Do you have any difficulty with EATING from a dish that was placed in front of you? (0=No, 1=Yes)",
    p37 = "Walking: Do you have any difficulty with GETTING ACROSS A ROOM OR WALKING FROM ONE ROOM TO ANOTHER on the same floor? (0=No, 1=Yes)",
    p49 = "Bed Transfer: Do you have any difficulty with GETTING IN OR OUT OF BED? (0=No, 1=Yes)",
    p43 = "Showering: Do you have any difficulty with SHOWERING? (0=No, 1=Yes)",

    # Instrumental Activities of Daily Living (IALDS)
    p28 = "Telephone Use: Do you have any difficulty with USING TELEPHONE (LANDLINE OR CELLULAR)? (0=No, 1=Yes)",
    p26 = "Shopping: Do you have any difficulty with DOING SHOPPING? (0=No, 1=Yes)",
    p20 = "Meal Prep: Do you have any difficulty with preparing A HOT MEAL? (0=No, 1=Yes)",
    p30 = "Medication Management: Do you have any difficulty with TAKING/MANAGING YOUR OWN MEDICATIONS? (0=No, 1=Yes)",
    p22 = "Financial Management: Do you have any difficulty with MANAGING YOUR OWN MONEY? (0=No, 1=Yes)",
    p33 = "Light Housekeeping: Do you have any difficulty with PERFORMING LIGHT HOUSEKEEPING (making your own bed, removing dust, taking care of the garbage etc.)? (0=No, 1=Yes)",

    # Health Conditions (DISEASES)
    n55 = "COPD: Has a doctor ever told you that you have emphysema, chronic bronchitis or chronic obstructive pulmonary disease (COPD)? (0=No, 1=Yes)",
    n54 = "Asthma: Has a doctor ever told you that you have asthma? (0=No, 1=Yes)",
    n28 = "Hypertension: Has any doctor ever told you that you have arterial hypertension (high blood pressure)? (0=No, 1=Yes)",
    n35 = "Diabetes: Has any doctor ever told you that you have diabetes ('high blood sugar')? (0=No, 1=Yes)",
    n50 = "Heart Failure: Has any doctor ever told you that you have a heart failure? (0=No, 1=Yes)",
    n46 = "Heart Attack: Has any doctor ever told you that you had a heart attack? (0=No, 1=Yes)",
    n60 = "Cancer: Has a doctor ever told you that you have or had cancer? (0=No, 1=Yes)",
    n63_2 = "Memory/Dementia (non-Alzheimer's): Has a doctor ever told you that you have a serious memory problem or dementia? (excludes Alzheimer's disease) (0=No, 1=Yes)",
    n62 = "Parkinson's: Has a doctor ever told you that you have Parkinson’s disease? (0=No, 1=Yes)",
    n63 = "Alzheimer's: Has a doctor ever told you that you have Alzheimer’s disease? (0=No, 1=Yes)",
    n58 = "Chronic Column Problem: Has a doctor ever told you that you have chronic column problem, such as back pain, neck pain, low back pain, sciatica pain, issues in vertebrae or disc? (0=No, 1=Yes)",
    n56 = "Arthritis/Rheumatism: Has a doctor ever told you that you have arthritis or rheumatism? (0=No, 1=Yes)",
    n57 = "Osteoporosis: Has a doctor ever told you that you have osteoporosis? (0=No, 1=Yes)",
    n52 = "Stroke: Has a doctor ever told you that you had a cerebral vascular accident (stroke)? (0=No, 1=Yes)",
    n61 = "Chronic Renal Failure: Has a doctor ever told you that you have chronic renal failure? (0=No, 1=Yes)",

    # Other Important Variables
    n1 = "General Health: In general, how would you evaluate your health? (0=Excellent, 1=Very good, 2=Good, 3=Fair, 4=Bad, 5=Very bad)",
    n73 = "Daily Activities Effort: In the LAST WEEK, how often have your daily activities required a big effort from you to be performed? (1=Never/rarely (less than 1 day), 2=Very few times (1-2 days), 3=Sometimes (3-4 days), 4=Most of the time)",
    l2 = "Physical Activity: How often do you do moderate physical activities, such as gardening, washing the car, walking at moderate speed, dancing, or doing stretching exercises? (1=More than once a week, 2=Once a week, 3=1 to 3 times a month, 4=Rarely or never)"
  )

  # Validate or create variable_map
  if (is.null(variable_map)) {
    variable_map <- list()
    message("\n--- Variable Mapping Required ---")
    message("Please provide the column name from your dataset that corresponds to each standard CFS variable.")
    message("If a variable is NOT present in your data or you do not have the information, simply leave the input blank and press Enter (it will be treated as missing/NA).\n")

    for (std_var in names(cfs_var_definitions)) {
      description <- cfs_var_definitions[[std_var]]
      prompt_text <- paste0("Standard CFS Variable: '", std_var, "'\n",
                            "Description: ", description, "\n",
                            "Enter the column name from your dataset for '", std_var, "': ")

      user_input <- readline(prompt = prompt_text)
      user_input <- trimws(user_input)

      if (user_input != "") {
        if (!(user_input %in% names(processed_df))) {
          stop(paste0("Error: Column '", user_input, "' not found in your dataset. Please check the entered name and try again."))
        }
        variable_map[[std_var]] <- user_input
      } else {
        variable_map[[std_var]] <- NA_character_
        message(paste0("  Standard variable '", std_var, "' will be treated as missing/NA (no column name provided)."))
      }
      message("") # Blank line for readability
    }
    message("--- Variable Mapping Complete ---\n")
  } else {
    if (!is.list(variable_map) || is.null(names(variable_map))) {
      stop("`variable_map` must be a named list (e.g., list(p40 = 'user_column_name')).")
    }
    # Validate provided map entries against data and warn for missing standard variables
    for (std_var in names(cfs_var_definitions)) {
      mapped_name <- variable_map[[std_var]]
      if (is.null(mapped_name) || is.na(mapped_name) || mapped_name == "") {
        warning(paste0("Warning: Standard CFS variable '", std_var, "' (", cfs_var_definitions[[std_var]], ") is not present in the provided `variable_map` or was left blank. It will be treated as missing/NA."))
        variable_map[[std_var]] <- NA_character_
      } else if (!(mapped_name %in% names(processed_df))) {
        stop(paste0("Error: The column '", mapped_name, "' mapped for '", std_var, "' was NOT found in your input dataset. Please correct your `variable_map`."))
      }
    }
  }

  # Helper to get mapped name, returning NA if not found or blank
  get_mapped_name <- function(std_var_name) {
    mapped_name <- variable_map[[std_var_name]]
    if (is.null(mapped_name) || is.na(mapped_name) || mapped_name == "") {
      return(NA_character_)
    }
    return(mapped_name)
  }

  # Define variable groups using mapped names, filtering out NAs
  balds_vars <- c(
    get_mapped_name("p40"), get_mapped_name("p46"), get_mapped_name("p37"),
    get_mapped_name("p49"), get_mapped_name("p43")
  )
  balds_vars <- balds_vars[!is.na(balds_vars)]

  ialds_vars <- c(
    get_mapped_name("p28"), get_mapped_name("p26"), get_mapped_name("p20"),
    get_mapped_name("p30"), get_mapped_name("p22"), get_mapped_name("p33")
  )
  ialds_vars <- ialds_vars[!is.na(ialds_vars)]

  diseases_vars <- c(
    get_mapped_name("n55"), get_mapped_name("n54"), get_mapped_name("n28"),
    get_mapped_name("n35"), get_mapped_name("n50"), get_mapped_name("n46"),
    get_mapped_name("n60"), get_mapped_name("n63_2"), get_mapped_name("n62"),
    get_mapped_name("n63"), get_mapped_name("n58"), get_mapped_name("n56"),
    get_mapped_name("n57"), get_mapped_name("n52"), get_mapped_name("n61")
  )
  diseases_vars <- diseases_vars[!is.na(diseases_vars)]

  # Map individual specific variables
  n1_mapped <- get_mapped_name('n1')
  n73_mapped <- get_mapped_name('n73')
  l2_mapped <- get_mapped_name('l2')

  # Clean variables
  if (length(balds_vars) > 0) {
    processed_df <- clean_cfs_variables(processed_df, balds_vars, c(0, 1))
  }
  if (length(ialds_vars) > 0) {
    processed_df <- clean_cfs_variables(processed_df, ialds_vars, c(0, 1))
  }
  if (!is.na(n1_mapped) && n1_mapped %in% names(processed_df)) { # Only clean if mapped variable exists
    processed_df <- clean_cfs_variables(processed_df, n1_mapped, c(0, 1, 2, 3, 4, 5))
  }
  if (length(diseases_vars) > 0) {
    processed_df <- clean_cfs_variables(processed_df, diseases_vars, c(0, 1))
  }
  if (!is.na(n73_mapped) && n73_mapped %in% names(processed_df)) { # Only clean if mapped variable exists
    processed_df <- clean_cfs_variables(processed_df, n73_mapped, c(1, 2, 3, 4))
  }
  if (!is.na(l2_mapped) && l2_mapped %in% names(processed_df)) { # Only clean if mapped variable exists
    processed_df <- clean_cfs_variables(processed_df, l2_mapped, c(1, 2, 3, 4))
  }

  # Calculate counts for available variables
  processed_df$balds_count <- if (length(balds_vars) > 0) {
    rowSums(processed_df[, balds_vars, drop = FALSE] == 1, na.rm = TRUE)
  } else {
    0
  }

  processed_df$ialds_count <- if (length(ialds_vars) > 0) {
    rowSums(processed_df[, ialds_vars, drop = FALSE] == 1, na.rm = TRUE)
  } else {
    0
  }

  processed_df$diseases_count <- if (length(diseases_vars) > 0) {
    rowSums(processed_df[, diseases_vars, drop = FALSE] == 1, na.rm = TRUE)
  } else {
    0
  }

  # Initialize CFS score
  processed_df$cfs_score <- NA_character_

  # --- Apply CFS Classification Rules ---
  # Rules are applied sequentially. Later rules only apply if cfs_score is still NA.

  # Rule 7: BALDS >= 3
  idx <- which(processed_df$balds_count >= 3 & is.na(processed_df$cfs_score))
  if (length(idx) > 0) processed_df$cfs_score[idx] <- "7"

  # Rule 6: (BALDS 1-2) OR (BALDS 0 AND IALDS >= 5)
  idx_6a <- which(processed_df$balds_count %in% c(1, 2) & is.na(processed_df$cfs_score))
  if (length(idx_6a) > 0) processed_df$cfs_score[idx_6a] <- "6"

  idx_6b <- which(processed_df$balds_count == 0 & processed_df$ialds_count >= 5 & is.na(processed_df$cfs_score))
  if (length(idx_6b) > 0) processed_df$cfs_score[idx_6b] <- "6"

  # Rule 5: BALDS 0 AND IALDS 1-4
  idx <- which(processed_df$balds_count == 0 & processed_df$ialds_count %in% c(1, 2, 3, 4) & is.na(processed_df$cfs_score))
  if (length(idx) > 0) processed_df$cfs_score[idx] <- "5"

  # Rule 4 (part 1): BALDS 0 AND IALDS 0 AND DISEASES >= 10
  idx_4a <- which(processed_df$balds_count == 0 & processed_df$ialds_count == 0 & processed_df$diseases_count >= 10 & is.na(processed_df$cfs_score))
  if (length(idx_4a) > 0) processed_df$cfs_score[idx_4a] <- "4"

  # Rule 4 (part 2): BALDS 0 AND IALDS 0 AND DISEASES <= 9 AND n1=0 AND n73=4
  idx_4b <- integer(0)
  if (!is.na(n1_mapped) && n1_mapped %in% names(processed_df) &&
      !is.na(n73_mapped) && n73_mapped %in% names(processed_df)) {
    idx_4b <- which(
      processed_df$balds_count == 0 & processed_df$ialds_count == 0 & processed_df$diseases_count <= 9 &
        processed_df[[n1_mapped]] == 0 & processed_df[[n73_mapped]] == 4 & is.na(processed_df$cfs_score)
    )
  }
  if (length(idx_4b) > 0) processed_df$cfs_score[idx_4b] <- "4"

  # Rule 1: BALDS 0 AND IALDS 0 AND DISEASES <= 9 AND n1=0 AND n73=1 AND l2=1-3
  idx_1 <- integer(0)
  if (!is.na(n1_mapped) && n1_mapped %in% names(processed_df) &&
      !is.na(n73_mapped) && n73_mapped %in% names(processed_df) &&
      !is.na(l2_mapped) && l2_mapped %in% names(processed_df)) {
    idx_1 <- which(
      processed_df$balds_count == 0 & processed_df$ialds_count == 0 & processed_df$diseases_count <= 9 &
        processed_df[[n1_mapped]] == 0 & processed_df[[n73_mapped]] == 1 &
        processed_df[[l2_mapped]] %in% c(1, 2, 3) & is.na(processed_df$cfs_score)
    )
  }
  if (length(idx_1) > 0) processed_df$cfs_score[idx_1] <- "1"

  # Rule 2 (part 1): BALDS 0 AND IALDS 0 AND DISEASES <= 9 AND n1=0 AND n73=1 AND l2=4
  idx_2a <- integer(0)
  if (!is.na(n1_mapped) && n1_mapped %in% names(processed_df) &&
      !is.na(n73_mapped) && n73_mapped %in% names(processed_df) &&
      !is.na(l2_mapped) && l2_mapped %in% names(processed_df)) {
    idx_2a <- which(
      processed_df$balds_count == 0 & processed_df$ialds_count == 0 & processed_df$diseases_count <= 9 &
        processed_df[[n1_mapped]] == 0 & processed_df[[n73_mapped]] == 1 &
        processed_df[[l2_mapped]] == 4 & is.na(processed_df$cfs_score)
    )
  }
  if (length(idx_2a) > 0) processed_df$cfs_score[idx_2a] <- "2"

  # Rule 2 (part 2): BALDS 0 AND IALDS 0 AND DISEASES <= 9 AND n1=0 AND n73=2-3 AND l2=1-3
  idx_2b <- integer(0)
  if (!is.na(n1_mapped) && n1_mapped %in% names(processed_df) &&
      !is.na(n73_mapped) && n73_mapped %in% names(processed_df) &&
      !is.na(l2_mapped) && l2_mapped %in% names(processed_df)) {
    idx_2b <- which(
      processed_df$balds_count == 0 & processed_df$ialds_count == 0 & processed_df$diseases_count <= 9 &
        processed_df[[n1_mapped]] == 0 & processed_df[[n73_mapped]] %in% c(2, 3) &
        processed_df[[l2_mapped]] %in% c(1, 2, 3) & is.na(processed_df$cfs_score)
    )
  }
  if (length(idx_2b) > 0) processed_df$cfs_score[idx_2b] <- "2"

  # Rule 3 (part 1): BALDS 0 AND IALDS 0 AND DISEASES <= 9 AND n1=0 AND n73=2-3 AND l2=4
  idx_3a <- integer(0)
  if (!is.na(n1_mapped) && n1_mapped %in% names(processed_df) &&
      !is.na(n73_mapped) && n73_mapped %in% names(processed_df) &&
      !is.na(l2_mapped) && l2_mapped %in% names(processed_df)) {
    idx_3a <- which(
      processed_df$balds_count == 0 & processed_df$ialds_count == 0 & processed_df$diseases_count <= 9 &
        processed_df[[n1_mapped]] == 0 & processed_df[[n73_mapped]] %in% c(2, 3) &
        processed_df[[l2_mapped]] == 4 & is.na(processed_df$cfs_score)
    )
  }
  if (length(idx_3a) > 0) processed_df$cfs_score[idx_3a] <- "3"

  # Rule 2 (part 3): BALDS 0 AND IALDS 0 AND DISEASES <= 9 AND n1=1-2 AND n73=1 AND l2=1-3
  idx_2c <- integer(0)
  if (!is.na(n1_mapped) && n1_mapped %in% names(processed_df) &&
      !is.na(n73_mapped) && n73_mapped %in% names(processed_df) &&
      !is.na(l2_mapped) && l2_mapped %in% names(processed_df)) {
    idx_2c <- which(
      processed_df$balds_count == 0 & processed_df$ialds_count == 0 & processed_df$diseases_count <= 9 &
        processed_df[[n1_mapped]] %in% c(1, 2) & processed_df[[n73_mapped]] == 1 &
        processed_df[[l2_mapped]] %in% c(1, 2, 3) & is.na(processed_df$cfs_score)
    )
  }
  if (length(idx_2c) > 0) processed_df$cfs_score[idx_2c] <- "2"

  # Rule 3 (part 2): BALDS 0 AND IALDS 0 AND DISEASES <= 9 AND n1=1-2 AND n73=1 AND l2=4
  idx_3b <- integer(0)
  if (!is.na(n1_mapped) && n1_mapped %in% names(processed_df) &&
      !is.na(n73_mapped) && n73_mapped %in% names(processed_df) &&
      !is.na(l2_mapped) && l2_mapped %in% names(processed_df)) {
    idx_3b <- which(
      processed_df$balds_count == 0 & processed_df$ialds_count == 0 & processed_df$diseases_count <= 9 &
        processed_df[[n1_mapped]] %in% c(1, 2) & processed_df[[n73_mapped]] == 1 &
        processed_df[[l2_mapped]] == 4 & is.na(processed_df$cfs_score)
    )
  }
  if (length(idx_3b) > 0) processed_df$cfs_score[idx_3b] <- "3"

  # Rule 2 (part 4): BALDS 0 AND IALDS 0 AND DISEASES <= 9 AND n1=1-2 AND n73=2-3 AND l2=1-3
  idx_2d <- integer(0)
  if (!is.na(n1_mapped) && n1_mapped %in% names(processed_df) &&
      !is.na(n73_mapped) && n73_mapped %in% names(processed_df) &&
      !is.na(l2_mapped) && l2_mapped %in% names(processed_df)) {
    idx_2d <- which(
      processed_df$balds_count == 0 & processed_df$ialds_count == 0 & processed_df$diseases_count <= 9 &
        processed_df[[n1_mapped]] %in% c(1, 2) & processed_df[[n73_mapped]] %in% c(2, 3) &
        processed_df[[l2_mapped]] %in% c(1, 2, 3) & is.na(processed_df$cfs_score)
    )
  }
  if (length(idx_2d) > 0) processed_df$cfs_score[idx_2d] <- "2"

  # Rule 3 (part 3): BALDS 0 AND IALDS 0 AND DISEASES <= 9 AND n1=1-2 AND n73=2-3 AND l2=4
  idx_3c <- integer(0)
  if (!is.na(n1_mapped) && n1_mapped %in% names(processed_df) &&
      !is.na(n73_mapped) && n73_mapped %in% names(processed_df) &&
      !is.na(l2_mapped) && l2_mapped %in% names(processed_df)) {
    idx_3c <- which(
      processed_df$balds_count == 0 & processed_df$ialds_count == 0 & processed_df$diseases_count <= 9 &
        processed_df[[n1_mapped]] %in% c(1, 2) & processed_df[[n73_mapped]] %in% c(2, 3) &
        processed_df[[l2_mapped]] == 4 & is.na(processed_df$cfs_score)
    )
  }
  if (length(idx_3c) > 0) processed_df$cfs_score[idx_3c] <- "3"

  # Rule 4 (part 3): BALDS 0 AND IALDS 0 AND DISEASES <= 9 AND n1=3-5
  idx_4c <- integer(0)
  if (!is.na(n1_mapped) && n1_mapped %in% names(processed_df)) {
    idx_4c <- which(
      processed_df$balds_count == 0 & processed_df$ialds_count == 0 & processed_df$diseases_count <= 9 &
        processed_df[[n1_mapped]] %in% c(3, 4, 5) & is.na(processed_df$cfs_score)
    )
  }
  if (length(idx_4c) > 0) processed_df$cfs_score[idx_4c] <- "4"

  return(processed_df)
}
