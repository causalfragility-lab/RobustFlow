# Suppress R CMD check notes for variables used in ggplot2::aes() and
# other non-standard evaluation contexts.
utils::globalVariables(c(
  # ggplot2 aesthetics in app_server.R
  "time", "prevalence", "DII", "path", "n", "rate", "group",
  "gap", "perturbation", "adjusted_effect", "From", "To", "Count",
  "AbsGap",
  # internal column created in compute_group_gaps
  "._event_"
))
