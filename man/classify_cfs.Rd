\name{classify_cfs}
\alias{classify_cfs}
\title{Classify Clinical Frailty Scale (CFS)}
\description{
Classifies the Clinical Frailty Scale (CFS) for individuals based on a set of standardized variables.
The function supports both interactive mapping of variable names from the user's dataset and pre-defined mappings.
}
\usage{
classify_cfs(data, variable_map = NULL)
}
\arguments{
\item{data}{A data frame containing the necessary variables for CFS classification. Column names should match either the standard CFS variable names or those specified in \code{variable_map}.}
\item{variable_map}{An optional named list mapping standard CFS variable names (e.g., 'p40', 'n1') to actual column names in \code{data}. If \code{NULL}, an interactive console prompt will guide the user to define this mapping.
Example: \code{list(p40 = "user_p40_name", n1 = "user_n1_name")}. Variables not present in the map or explicitly set to \code{NA} will be treated as missing.}
}
\details{
The Clinical Frailty Scale (CFS) is a 9-point scale used to categorize an individual's level of frailty.
This function implements a rule-based classification algorithm. The classification rules are applied in a specific order, from most to least severe.
Invalid variable values (e.g., '9' or values outside the expected range) are replaced with \code{NA} before classification.

\strong{Key Variable Groups and Their Standard Names (with descriptions):}
\itemize{
  \item \strong{BALDS} (Basic Activities of Daily Living): Variables indicating difficulty with fundamental self-care tasks.
    \itemize{
      \item \code{p40}: Dressing: Difficulty dressing (0=No, 1=Yes)
      \item \code{p46}: Eating: Difficulty eating from a dish (0=No, 1=Yes)
      \item \code{p37}: Walking: Difficulty getting across a room (0=No, 1=Yes)
      \item \code{p49}: Bed Transfer: Difficulty getting in/out of bed (0=No, 1=Yes)
      \item \code{p43}: Showering: Difficulty with showering (0=No, 1=Yes)
    }
  \item \strong{IALDS} (Instrumental Activities of Daily Living): Variables indicating difficulty with tasks necessary for independent living.
    \itemize{
      \item \code{p28}: Telephone Use: Difficulty using telephone (0=No, 1=Yes)
      \item \code{p26}: Shopping: Difficulty doing shopping (0=No, 1=Yes)
      \item \code{p20}: Meal Prep: Difficulty preparing a hot meal (0=No, 1=Yes)
      \item \code{p30}: Medication Management: Difficulty managing medications (0=No, 1=Yes)
      \item \code{p22}: Financial Management: Difficulty managing money (0=No, 1=Yes)
      \item \code{p33}: Light Housekeeping: Difficulty performing light housekeeping (0=No, 1=Yes)
    }
  \item \strong{DISEASES} (Health Conditions): Variables indicating the presence of specific diagnosed health conditions.
    \itemize{
      \item \code{n55}: COPD (0=No, 1=Yes)
      \item \code{n54}: Asthma (0=No, 1=Yes)
      \item \code{n28}: Hypertension (0=No, 1=Yes)
      \item \code{n35}: Diabetes (0=No, 1=Yes)
      \item \code{n50}: Heart Failure (0=No, 1=Yes)
      \item \code{n46}: Heart Attack (0=No, 1=Yes)
      \item \code{n60}: Cancer (0=No, 1=Yes)
      \item \code{n63_2}: Memory/Dementia (non-Alzheimer's) (0=No, 1=Yes)
      \item \code{n62}: Parkinson's Disease (0=No, 1=Yes)
      \item \code{n63}: Alzheimer's Disease (0=No, 1=Yes)
      \item \code{n58}: Chronic Column Problem (0=No, 1=Yes)
      \item \code{n56}: Arthritis/Rheumatism (0=No, 1=Yes)
      \item \code{n57}: Osteoporosis (0=No, 1=Yes)
      \item \code{n52}: Stroke (0=No, 1=Yes)
      \item \code{n61}: Chronic Renal Failure (0=No, 1=Yes)
    }
  \item \strong{Other Important Variables}:
    \itemize{
      \item \code{n1}: General Health (0=Excellent to 5=Very bad)
      \item \code{n73}: Daily Activities Effort (1=Never/rarely to 4=Most of the time)
      \item \code{l2}: Physical Activity (1=More than once/week to 4=Rarely/never)
    }
}

The function adds three count columns (\code{balds_count}, \code{ialds_count}, \code{diseases_count})
and the final \code{cfs_score} column to the input data frame.
}
\value{
A data frame identical to the input \code{data}, but with the following new columns added:
\itemize{
  \item \code{balds_count}: Number of reported difficulties in Basic Activities of Daily Living.
  \item \code{ialds_count}: Number of reported difficulties in Instrumental Activities of Daily Living.
  \item \code{diseases_count}: Number of reported diagnosed health conditions.
  \item \code{cfs_score}: The calculated Clinical Frailty Scale score (1-7) as a character variable. \code{NA} if classification is not possible.
}
}
\examples{
# Create dummy data for demonstration (replace with your actual data)
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

# Option 1: Run interactively (variable_map = NULL)
# This will prompt for input in the R console.
# classified_data_interactive <- classify_cfs(dummy_data)

# Option 2: Run with a pre-defined map (non-interactive)
my_map <- list(
  p40 = "My_Dressing_Var", p46 = "My_Eating_Var", p37 = "My_Walking_Var",
  p49 = "My_Bed_Transfer_Var", p43 = "My_Showering_Var",
  p28 = "My_Phone_Use_Var", p26 = "My_Shopping_Var", p20 = "My_Cooking_Var",
  p30 = "My_Meds_Var", p22 = "My_Money_Var", p33 = "My_Housekeeping_Var",
  n55 = "My_Heart_Disease_Var", n54 = "My_COPD_Var", n28 = "My_Hypertension_Var",
  n35 = "My_Diabetes_Var", n50 = NA, n46 = NA, # Example of unmapped/missing diseases
  n60 = NA, n63_2 = NA, n62 = NA, n63 = NA, n58 = NA, n56 = NA,
  n57 = NA, n52 = NA, n61 = NA,
  n1 = "My_Cognition_Score", n73 = "My_Mobility_Score", l2 = "My_Energy_Level"
)
classified_data_mapped <- classify_cfs(dummy_data, variable_map = my_map)
print(classified_data_mapped)
}
\author{
[Henrique Pott / Geriatric Medicine Research - Dalhousie University]
}
\references{
Rockwood, K., Song, X., MacKnight, C., Bergman, H., Hogan, D. B., McDowell, I., & Mitnitski, A. (2005). A global clinical measure of fitness and frailty in elderly people. \emph{CMAJ}, \emph{173}(5), 489-495.
\cr
More information on the Clinical Frailty Scale can be found at \url{https://www.dal.ca/sites/gmr/our-tools/clinical-frailty-scale.html}
}
\seealso{
\code{\link{clean_cfs_variables}}
}