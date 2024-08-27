
get_randyear <- \(dsg) {
  fit <- glmer(gay ~ year + (1|county), family = binomial, data = dsg,
               control = glmerControl(optimizer = "bobyqa"))
  new_data <- dsg[which(dsg$year == max(dsg$year)), ]
  preds <- unique(predict(fit, new_data, type = "response"))
  data.frame(cbind(county=levels(dsg$county), preds))
} 
