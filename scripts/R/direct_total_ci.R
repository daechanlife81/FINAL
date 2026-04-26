library(lavaan)
library(readxl)

df <- read_excel("260414_data_recoded.xlsx")

sem_med <- '
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04

  efficacy ~ a1*D_05 + a2*D_03 + a3*C_05 + a4*re_C_06 + a5*re_C_07 + a6*awareness + a7*re_C_08 + a8*re_B_04
  wellbeing ~ c1*D_05 + c2*D_03 + c3*C_05 + c4*re_C_06 + c5*re_C_07 + c6*re_C_08
  re_A_01_1 ~ d1*D_05 + d2*D_03 + d3*C_05 + d4*re_C_06 + d5*re_C_07 + d6*awareness + d7*re_C_08 + d8*re_B_04

  wellbeing ~ b1*efficacy
  re_A_01_1 ~ b2*efficacy
  re_A_01_1 ~ b3*wellbeing

  efficacy ~ re_SQ1 + SQ2 + D_04 + re_B_02
  wellbeing ~ re_SQ1 + SQ2 + D_04 + re_B_02
  re_A_01_1 ~ re_SQ1 + SQ2 + D_04 + re_B_02

  # 총효과
  total1 := d1 + a1*b2 + c1*b3 + a1*b1*b3
  total2 := d2 + a2*b2 + c2*b3 + a2*b1*b3
  total3 := d3 + a3*b2 + c3*b3 + a3*b1*b3
  total4 := d4 + a4*b2 + c4*b3 + a4*b1*b3
  total5 := d5 + a5*b2 + c5*b3 + a5*b1*b3
  total6 := d6 + a6*b2 + a6*b1*b3
  total7 := d7 + a7*b2 + c6*b3 + a7*b1*b3
  total8 := d8 + a8*b2 + a8*b1*b3
'

cat("Bootstrap 5000회 실행 중...\n")
fit <- sem(sem_med, data = df, estimator = "ML", se = "bootstrap", bootstrap = 5000)

params <- parameterEstimates(fit, boot.ci.type = "perc", level = 0.95, standardized = TRUE)

# 직접효과 CI
struct <- params[params$op == "~" & params$lhs == "re_A_01_1", ]
iv_vars <- c("D_05","D_03","C_05","re_C_06","re_C_07","awareness","re_C_08","re_B_04")
iv_labels <- c("주관적건강","교육수준","일반적신뢰","네트워크","사회단체활동","제도인식","종교활동","봉사교육경험")

cat("\n직접효과 + 95% CI\n")
cat("================================================================\n")
for (i in 1:8) {
  row <- struct[struct$rhs == iv_vars[i], ]
  sig <- ifelse(row$ci.lower > 0 | row$ci.upper < 0, "*", "")
  cat(sprintf("  %s: beta=%.3f, CI[%.4f, %.4f] %s\n",
    iv_labels[i], row$std.all, row$ci.lower, row$ci.upper, sig))
}

# 총효과 CI
defined <- params[params$op == ":=", ]
cat("\n총효과 + 95% CI\n")
cat("================================================================\n")
for (i in 1:8) {
  row <- defined[defined$lhs == paste0("total", i), ]
  sig <- ifelse(row$ci.lower > 0 | row$ci.upper < 0, "*", "")
  cat(sprintf("  %s: beta=%.3f, CI[%.4f, %.4f] %s\n",
    iv_labels[i], row$std.all, row$ci.lower, row$ci.upper, sig))
}
