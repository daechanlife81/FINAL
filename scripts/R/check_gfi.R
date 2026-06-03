## ============================================================
## GFI 산출 가능성 확인
## - ML 추정에서는 GFI 산출 가능
## - MLR 추정에서는 GFI 산출 불가 (lavaan 기본값)
## ============================================================

library(lavaan)
library(readxl)

df <- read_excel("data/260414_data_recoded.xlsx")

## ===== 측정모형 (CFA) =====
cfa_model <- '
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04
'

cat("================================================================\n")
cat("1. CFA - ML 추정 (GFI 포함)\n")
cat("================================================================\n")
fit_cfa_ml <- cfa(cfa_model, data = df, estimator = "ML")
fi_cfa_ml <- fitMeasures(fit_cfa_ml, c("chisq","df","gfi","cfi","tli","rmsea","srmr"))
print(round(fi_cfa_ml, 4))

cat("\n================================================================\n")
cat("2. CFA - MLR 추정 (GFI 산출 시도)\n")
cat("================================================================\n")
fit_cfa_mlr <- cfa(cfa_model, data = df, estimator = "MLR")
fi_cfa_mlr <- fitMeasures(fit_cfa_mlr,
                           c("chisq.scaled","df.scaled","gfi",
                             "cfi.robust","tli.robust","rmsea.robust","srmr"))
print(round(fi_cfa_mlr, 4))

## ===== 구조모형 (SEM) =====
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

  efficacy ~ re_SQ1 + SQ2 + D_04 + re_B_02
  wellbeing ~ re_SQ1 + SQ2 + D_04 + re_B_02
  re_A_01_1 ~ re_SQ1 + SQ2 + D_04 + re_B_02
'

cat("\n================================================================\n")
cat("3. SEM - ML 추정 (GFI 산출)\n")
cat("================================================================\n")
fit_sem_ml <- sem(sem_model, data = df, estimator = "ML")
fi_sem_ml <- fitMeasures(fit_sem_ml, c("chisq","df","gfi","cfi","tli","rmsea","srmr"))
print(round(fi_sem_ml, 4))

cat("\n================================================================\n")
cat("4. SEM - MLR 추정 (GFI 산출 시도)\n")
cat("================================================================\n")
fit_sem_mlr <- sem(sem_model, data = df, estimator = "MLR")
fi_sem_mlr <- fitMeasures(fit_sem_mlr,
                           c("chisq.scaled","df.scaled","gfi",
                             "cfi.robust","tli.robust","rmsea.robust","srmr"))
print(round(fi_sem_mlr, 4))

## ===== GFI 가용성 진단 =====
cat("\n================================================================\n")
cat("5. GFI 가용성 진단\n")
cat("================================================================\n")

cat("\nCFA - ML:  GFI =", round(fi_cfa_ml["gfi"], 4),
    ifelse(is.na(fi_cfa_ml["gfi"]), "(NA - 산출 불가)", "(산출 가능)"), "\n")
cat("CFA - MLR: GFI =", round(fi_cfa_mlr["gfi"], 4),
    ifelse(is.na(fi_cfa_mlr["gfi"]), "(NA - 산출 불가)", "(산출 가능)"), "\n")
cat("SEM - ML:  GFI =", round(fi_sem_ml["gfi"], 4),
    ifelse(is.na(fi_sem_ml["gfi"]), "(NA - 산출 불가)", "(산출 가능)"), "\n")
cat("SEM - MLR: GFI =", round(fi_sem_mlr["gfi"], 4),
    ifelse(is.na(fi_sem_mlr["gfi"]), "(NA - 산출 불가)", "(산출 가능)"), "\n")
