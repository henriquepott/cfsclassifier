#' @importFrom magrittr %>%
#' @importFrom stats setNames
NULL

# Define variáveis globais para evitar notas no R CMD check
utils::globalVariables(
  c(".", "gh", "e", "p", "term", "cfs_score", "balds_count",
    "ialds_count", "diseases_count", "expected_cfs", "setNames")
)
