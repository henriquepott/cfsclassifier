\name{clean_cfs_variables}
\alias{clean_cfs_variables}
\title{Clean Clinical Frailty Scale Variables}
\description{
Cleans specified variables in a data frame, replacing invalid values (typically '9' for missing/unknown) and values outside of a defined allowed range with \code{NA}. This is a helper function primarily used internally by \code{\link{classify_cfs}}.
}
\usage{
clean_cfs_variables(df, variables, allowed_values)
}
\arguments{
\item{df}{A data frame.}
\item{variables}{A character vector of column names within \code{df} to be cleaned. These columns are expected to contain numeric or factor data that can be coerced to numeric for comparison.}
\item{allowed_values}{A vector of valid values for the specified variables. Any value in the \code{variables} columns that is not in \code{allowed_values} or is equal to '9' will be converted to \code{NA}.}
}
\value{
The input data frame \code{df} with the specified variables cleaned (invalid values replaced by \code{NA}).
}
\examples{
df_example <- data.frame(
  v1 = c(0, 1, 9, 2, NA),
  v2 = c(1, 0, 0, 9, 1),
  v3 = c(5, 6, 7, 8, 9)
)
print("Original DataFrame:")
print(df_example)

# Clean v1 and v2, expecting values 0 or 1
cleaned_df <- clean_cfs_variables(df_example, c("v1", "v2"), c(0, 1))
print("Cleaned DataFrame (v1, v2 for 0/1):")
print(cleaned_df)

# Clean v3, expecting values 5, 6, 7
cleaned_df_v3 <- clean_cfs_variables(df_example, "v3", c(5, 6, 7))
print("Cleaned DataFrame (v3 for 5/6/7):")
print(cleaned_df_v3)
}
\author{
[Seu Nome/Nome da Equipe de Desenvolvimento]
}
\seealso{
\code{\link{classify_cfs}}
}