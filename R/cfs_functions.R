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
classify_cfs <- function(data, variable_map = NULL, min_comorbidities = 5) {

  processed_df <- as.data.frame(data)

  # --- Standard CFS variable definitions (for mapping) ---
  cfs_var_definitions <- list(
    p40 = "Dressing: Do you have difficulty with DRESSING UP? (0=No, 1=Yes)",
    p46 = "Eating: Do you have difficulty with EATING? (0=No, 1=Yes)",
    p37 = "Walking: Do you have difficulty with GETTING ACROSS A ROOM? (0=No, 1=Yes)",
    p49 = "Bed Transfer: Do you have difficulty with GETTING IN OR OUT OF BED? (0=No, 1=Yes)",
    p43 = "Showering: Do you have difficulty with SHOWERING? (0=No, 1=Yes)",
    p28 = "Telephone Use: Do you have difficulty with USING TELEPHONE? (0=No, 1=Yes)",
    p26 = "Shopping: Do you have difficulty with DOING SHOPPING? (0=No, 1=Yes)",
    p20 = "Meal Prep: Do you have difficulty with preparing A HOT MEAL? (0=No, 1=Yes)",
    p30 = "Medication Management: Do you have difficulty with TAKING/MANAGING YOUR MEDS? (0=No, 1=Yes)",
    p22 = "Financial Management: Do you have difficulty with MANAGING YOUR MONEY? (0=No, 1=Yes)",
    p33 = "Light Housekeeping: Do you have difficulty with LIGHT HOUSEKEEPING? (0=No, 1=Yes)",
    n55 = "COPD (0=No, 1=Yes)",
    n54 = "Asthma (0=No, 1=Yes)",
    n28 = "Hypertension (0=No, 1=Yes)",
    n35 = "Diabetes (0=No, 1=Yes)",
    n50 = "Heart Failure (0=No, 1=Yes)",
    n46 = "Heart Attack (0=No, 1=Yes)",
    n60 = "Cancer (0=No, 1=Yes)",
    n63_2 = "Memory/Dementia (non-Alzheimer's) (0=No, 1=Yes)",
    n62 = "Parkinson's (0=No, 1=Yes)",
    n63 = "Alzheimer's (0=No, 1=Yes)",
    n58 = "Chronic Column Problem (0=No, 1=Yes)",
    n56 = "Arthritis/Rheumatism (0=No, 1=Yes)",
    n57 = "Osteoporosis (0=No, 1=Yes)",
    n52 = "Stroke (0=No, 1=Yes)",
    n61 = "Chronic Renal Failure (0=No, 1=Yes)",
    n1 = "General Health: 0=Excellent, 1=Very good, 2=Good, 3=Fair, 4=Bad, 5=Very bad",
    n73 = "Daily Activities Effort: 1=Never/rarely, 2=Very few times, 3=Sometimes, 4=Most of the time",
    l2 = "Physical Activity: 1=More than once a week, 2=Once a week, 3=1-3 times/month, 4=Rarely/never"
  )

  # --- Mapping variables (manual or provided) ---
  if (is.null(variable_map)) {
    variable_map <- list()
    message("\n--- Variable Mapping Required ---")
    for (std_var in names(cfs_var_definitions)) {
      description <- cfs_var_definitions[[std_var]]
      prompt_text <- paste0("Standard CFS Variable: '", std_var, "'\nDescription: ", description, "\nEnter column name: ")
      user_input <- readline(prompt = prompt_text)
      variable_map[[std_var]] <- ifelse(trimws(user_input) != "", trimws(user_input), NA_character_)
    }
  }

  # --- Helper to get mapped column name ---
  get_mapped_name <- function(std_var_name) {
    mapped_name <- variable_map[[std_var_name]]
    if (is.null(mapped_name) || is.na(mapped_name) || mapped_name == "") return(NA_character_)
    return(mapped_name)
  }

  # --- Define groups of variables ---
  balds_vars <- na.omit(c(get_mapped_name("p40"), get_mapped_name("p46"), get_mapped_name("p37"), get_mapped_name("p49"), get_mapped_name("p43")))
  ialds_vars <- na.omit(c(get_mapped_name("p28"), get_mapped_name("p26"), get_mapped_name("p20"), get_mapped_name("p30"), get_mapped_name("p22"), get_mapped_name("p33")))
  diseases_vars <- na.omit(c(get_mapped_name("n55"), get_mapped_name("n54"), get_mapped_name("n28"), get_mapped_name("n35"),
                             get_mapped_name("n50"), get_mapped_name("n46"), get_mapped_name("n60"), get_mapped_name("n63_2"),
                             get_mapped_name("n62"), get_mapped_name("n63"), get_mapped_name("n58"), get_mapped_name("n56"),
                             get_mapped_name("n57"), get_mapped_name("n52"), get_mapped_name("n61")))
  n1_mapped <- get_mapped_name('n1')
  n73_mapped <- get_mapped_name('n73')
  l2_mapped <- get_mapped_name('l2')

  # --- Clean variables ---
  if (length(balds_vars) > 0) processed_df <- clean_cfs_variables(processed_df, balds_vars, c(0,1))
  if (length(ialds_vars) > 0) processed_df <- clean_cfs_variables(processed_df, ialds_vars, c(0,1))
  if (!is.na(n1_mapped)) processed_df <- clean_cfs_variables(processed_df, n1_mapped, 0:5)
  if (length(diseases_vars) > 0) processed_df <- clean_cfs_variables(processed_df, diseases_vars, c(0,1))
  if (!is.na(n73_mapped)) processed_df <- clean_cfs_variables(processed_df, n73_mapped, 1:4)
  if (!is.na(l2_mapped)) processed_df <- clean_cfs_variables(processed_df, l2_mapped, 1:4)

  # --- Compute counts ---
  processed_df$balds_count <- if(length(balds_vars)>0) rowSums(processed_df[, balds_vars, drop=FALSE]==1, na.rm=TRUE) else 0
  processed_df$ialds_count <- if(length(ialds_vars)>0) rowSums(processed_df[, ialds_vars, drop=FALSE]==1, na.rm=TRUE) else 0
  processed_df$diseases_count <- if(length(diseases_vars)>0) rowSums(processed_df[, diseases_vars, drop=FALSE]==1, na.rm=TRUE) else 0

  processed_df$cfs_score <- NA_character_

  # --- Rule 0: insufficient comorbidities ---
  insufficient_comorbidity <- which(processed_df$diseases_count < min_comorbidities)
  processed_df$cfs_score[insufficient_comorbidity] <- NA
  eligible <- which(processed_df$diseases_count >= min_comorbidities | length(diseases_vars) == 0)

  # --- Rule 1: BALDS >=3 => CFS 7 ---
  idx <- which(processed_df$balds_count >=3 & is.na(processed_df$cfs_score) & eligible)
  # Rule 1: BALDS >=3
  processed_df$cfs_score[idx] <- "7"

  # --- Rule 2 (part 1): BALDS 1-2 => CFS 6 ---
  idx <- which(processed_df$balds_count %in% c(1,2) & is.na(processed_df$cfs_score) & eligible)
  processed_df$cfs_score[idx] <- "6"

  # --- Rule 2 (part 2): BALDS 0 AND IALDS >=5 => CFS 6 ---
  idx <- which(processed_df$balds_count == 0 & processed_df$ialds_count >=5 & is.na(processed_df$cfs_score) & eligible)
  processed_df$cfs_score[idx] <- "6"

  # --- Rule 3: BALDS 0 AND IALDS 1-4 => CFS 5 ---
  idx <- which(processed_df$balds_count == 0 & processed_df$ialds_count %in% 1:4 & is.na(processed_df$cfs_score) & eligible)
  processed_df$cfs_score[idx] <- "5"

  # --- Rule 4a: BALDS 0 AND IALDS 0 AND DISEASES >=10 => CFS 4 ---
  idx <- which(processed_df$balds_count == 0 & processed_df$ialds_count == 0 & processed_df$diseases_count >= 10 & is.na(processed_df$cfs_score) & eligible)
  processed_df$cfs_score[idx] <- "4"

  # --- Additional rules with n1, n73, l2 can be inserted here ---
  # Example:
  # Rule 4b: BALDS 0 AND IALDS 0 AND DISEASES <=9 AND n1=0 AND n73=1 AND l2=4 => CFS 4
  # idx <- which(processed_df$balds_count==0 & processed_df$ialds_count==0 & processed_df$diseases_count <=9 &
  #              processed_df[[n1_mapped]]==0 & processed_df[[n73_mapped]]==1 & processed_df[[l2_mapped]]==4)
  # processed_df$cfs_score[idx] <- "4"

  return(processed_df)
}
