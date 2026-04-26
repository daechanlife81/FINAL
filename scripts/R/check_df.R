library(lavaan)
library(readxl)

df <- read_excel("260414_data_recoded.xlsx")

sem_model <- '
  # 측정모형
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04

  # 구조모형
  efficacy ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + awareness + re_C_08 + re_B_04
  wellbeing ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + re_C_08
  re_A_01_1 ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + awareness + re_C_08 + re_B_04
  wellbeing ~ efficacy
  re_A_01_1 ~ efficacy
  re_A_01_1 ~ wellbeing

  # 통제변수
  efficacy ~ re_SQ1 + SQ2 + D_04 + re_B_02
  wellbeing ~ re_SQ1 + SQ2 + D_04 + re_B_02
  re_A_01_1 ~ re_SQ1 + SQ2 + D_04 + re_B_02
'

fit <- sem(sem_model, data = df, estimator = "ML")

# 적합도
fi <- fitMeasures(fit, c("chisq", "df", "npar", "pvalue"))
cat(sprintf("Chi-square = %.3f\n", fi["chisq"]))
cat(sprintf("df = %.0f\n", fi["df"]))
cat(sprintf("추정 모수 수 (npar) = %.0f\n", fi["npar"]))

# 관측변수 수 확인
obs_vars <- lavNames(fit, type = "ov")
cat(sprintf("\n관측변수 수 = %d\n", length(obs_vars)))
cat("관측변수 목록:\n")
cat(paste(obs_vars, collapse = ", "))

# df 산출 과정
p <- length(obs_vars)
known <- p * (p + 1) / 2
npar <- fi["npar"]
cat(sprintf("\n\n=== df 산출 과정 ===\n"))
cat(sprintf("관측변수 수 (p) = %d\n", p))
cat(sprintf("알려진 정보 수 = p(p+1)/2 = %d x %d / 2 = %.0f\n", p, p+1, known))
cat(sprintf("추정할 모수 수 = %.0f\n", npar))
cat(sprintf("df = 알려진 정보 - 추정 모수 = %.0f - %.0f = %.0f\n", known, npar, known - npar))
