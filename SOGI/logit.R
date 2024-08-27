
get_logit <- \(dsg) {
  fit <- svyglm(gay ~ county, design = dsg, family = "quasibinomial", data = dsg$variables)
  parms_fit <- predict(fit, newdata=dsg$variables, type="link")
  ci_fit <- unique(confint(parms_fit))
  parms_est <- unique(1/(1 + exp(-parms_fit)))
  ci_est <- unique(1/(1 + exp(-ci_fit)))
  logit_ci <- cbind(parms_est, ci_est)
  colnames(logit_ci)[1] <- "p"
  logit_ci
} 
