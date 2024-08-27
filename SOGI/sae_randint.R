
get_randint <- \(dsg) {
  fit <- glmer(gay ~ 1|county, family = binomial, data = dsg,
               control = glmerControl(optimizer = "bobyqa"), nAGQ = 10)
  sae_probs <- 1/(1 + exp(-(fixef(fit) + unname(unlist(ranef(fit))))))
  data.frame(cbind(county=levels(dsg$county), sae_probs))
} 