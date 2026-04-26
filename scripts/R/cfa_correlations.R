library(lavaan)
library(readxl)

df <- read_excel("260414_data_recoded.xlsx")

model <- '
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04
'

fit <- cfa(model, data = df, estimator = "ML")

std_sol <- standardizedSolution(fit)
cor_est <- std_sol[std_sol$op == "~~" & std_sol$lhs != std_sol$rhs &
  std_sol$lhs %in% c("efficacy","awareness","wellbeing") &
  std_sol$rhs %in% c("efficacy","awareness","wellbeing"), ]

cat("잠재변수 간 상관계수 (CFA 원래 모형)\n")
cat("==========================================\n")
labels <- c(efficacy="자원봉사 효능감", awareness="자원봉사제도 인식", wellbeing="주관적 안녕감")
for (i in 1:nrow(cor_est)) {
  cat(sprintf("  %s <-> %s: r = %.3f (p = %.6f)\n",
    labels[cor_est$lhs[i]], labels[cor_est$rhs[i]], cor_est$est.std[i], cor_est$pvalue[i]))
}
