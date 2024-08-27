
get_table <- \(dsg) {
  lapply(levels(dsg$variables$sexual_orientation), \(x) {
    fo <- sprintf("~ I(sexual_orientation == %s)", x) |> as.formula()
    fit <- svyby(formula=fo, design=dsg, by=~county, 
                 FUN=svyciprop, vartype="ci", method="xlogit")
    names(fit)[2] <- "mean"
    fit$sexual_orientation <- x
    fit
  }) |> do.call(what= "rbind") |> arrange(county)
}
