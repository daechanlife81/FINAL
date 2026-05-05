## ============================================================
## WLSMV 추정법 재시도 - 학술적 재현성 확보용
## 박사학위논문 마지막 점검 (2026-04-26)
##
## 목적: 종속변수가 이분형(re_A_01_1: 0/1)인 점을 고려하여
##       WLSMV 추정의 적합성을 재확인하고 결과를 기록 보존함.
##
## 비교 대상:
##   1) WLSMV (이분형 종속변수 정식 추정법)
##   2) ML    (현재 채택 추정법)
##   3) MLR   (강건 표준오차 ML)
## ============================================================

library(lavaan)
library(readxl)

df <- read_excel("data/260414_data_recoded.xlsx")

## ===== 모형 정의 (현재 sem_analysis.R과 동일) =====
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

## ===== 1. WLSMV 추정 시도 =====
cat("================================================================\n")
cat("1. WLSMV 추정법 시도 (이분형 종속변수 정식 추정)\n")
cat("================================================================\n")

fit_wlsmv <- tryCatch({
  sem(sem_model, data = df,
      estimator = "WLSMV",
      ordered = "re_A_01_1")
}, warning = function(w) {
  cat("WARNING:", conditionMessage(w), "\n")
  sem(sem_model, data = df,
      estimator = "WLSMV",
      ordered = "re_A_01_1")
}, error = function(e) {
  cat("ERROR:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(fit_wlsmv)) {
  cat("\n--- WLSMV 적합도 ---\n")
  fi_w <- fitMeasures(fit_wlsmv,
                       c("chisq.scaled", "df.scaled", "pvalue.scaled",
                         "cfi.scaled", "tli.scaled",
                         "rmsea.scaled", "rmsea.ci.lower.scaled", "rmsea.ci.upper.scaled",
                         "srmr"))
  print(round(fi_w, 4))

  ## 분산 음수 진단
  cat("\n--- 분산 추정치 (음수 분산 진단) ---\n")
  param <- parameterEstimates(fit_wlsmv)
  variances <- param[param$op == "~~" & param$lhs == param$rhs, ]
  neg_var <- variances[variances$est < 0, ]
  if (nrow(neg_var) > 0) {
    cat("** 음수 분산 발견 (Heywood case 의심) **\n")
    print(neg_var[, c("lhs", "est", "se")])
  } else {
    cat("음수 분산 없음\n")
  }

  ## 표준화 추정치 절댓값 1.0 근접 확인
  cat("\n--- 표준화 적재량/경로 (|β| > 0.95 진단) ---\n")
  std_sol <- standardizedSolution(fit_wlsmv)
  high_load <- std_sol[abs(std_sol$est.std) > 0.95 & std_sol$op %in% c("=~", "~"), ]
  if (nrow(high_load) > 0) {
    cat("** |β| > 0.95 경로 발견 (다중공선성/Heywood case 의심) **\n")
    print(high_load[, c("lhs", "op", "rhs", "est.std", "se", "pvalue")])
  } else {
    cat("|β| > 0.95 경로 없음\n")
  }
} else {
  cat("WLSMV 추정 실패 (수렴 불가)\n")
}

## ===== 2. ML 추정 (현재 채택) =====
cat("\n================================================================\n")
cat("2. ML 추정법 (현재 채택 추정)\n")
cat("================================================================\n")

fit_ml <- sem(sem_model, data = df, estimator = "ML")
fi_ml <- fitMeasures(fit_ml,
                      c("chisq", "df", "pvalue",
                        "cfi", "tli",
                        "rmsea", "rmsea.ci.lower", "rmsea.ci.upper",
                        "srmr"))
cat("\n--- ML 적합도 ---\n")
print(round(fi_ml, 4))

## ===== 3. MLR 추정 (강건 표준오차) =====
cat("\n================================================================\n")
cat("3. MLR 추정법 (강건 표준오차)\n")
cat("================================================================\n")

fit_mlr <- sem(sem_model, data = df, estimator = "MLR")
fi_mlr <- fitMeasures(fit_mlr,
                       c("chisq.scaled", "df.scaled", "pvalue.scaled",
                         "cfi.robust", "tli.robust",
                         "rmsea.robust", "rmsea.ci.lower.robust", "rmsea.ci.upper.robust",
                         "srmr"))
cat("\n--- MLR 적합도 (Robust) ---\n")
print(round(fi_mlr, 4))

## ===== 4. 세 추정법 비교 요약 =====
cat("\n================================================================\n")
cat("4. 추정법 비교 요약\n")
cat("================================================================\n")

if (!is.null(fit_wlsmv)) {
  comp <- data.frame(
    Estimator = c("WLSMV", "ML", "MLR"),
    Chisq = c(round(fi_w["chisq.scaled"], 2),
              round(fi_ml["chisq"], 2),
              round(fi_mlr["chisq.scaled"], 2)),
    df = c(fi_w["df.scaled"], fi_ml["df"], fi_mlr["df.scaled"]),
    CFI = c(round(fi_w["cfi.scaled"], 3),
            round(fi_ml["cfi"], 3),
            round(fi_mlr["cfi.robust"], 3)),
    TLI = c(round(fi_w["tli.scaled"], 3),
            round(fi_ml["tli"], 3),
            round(fi_mlr["tli.robust"], 3)),
    RMSEA = c(round(fi_w["rmsea.scaled"], 3),
              round(fi_ml["rmsea"], 3),
              round(fi_mlr["rmsea.robust"], 3)),
    SRMR = c(round(fi_w["srmr"], 3),
             round(fi_ml["srmr"], 3),
             round(fi_mlr["srmr"], 3))
  )
  print(comp)

  ## 결과 저장
  write.csv(comp, "results/estimator_comparison.csv", row.names = FALSE)
  cat("\n결과 저장: results/estimator_comparison.csv\n")
}

cat("\n================================================================\n")
cat("재현성 보존: 본 스크립트 실행 결과를 박사논문 부록 또는\n")
cat("            방법론 검토 메모에 보존하여 reviewer 질문에 대비\n")
cat("================================================================\n")
