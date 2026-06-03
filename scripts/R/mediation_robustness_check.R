## ============================================================
## 매개구조 복원 민감도 분석 (심사위원 robustness 요구 대응)
##
## 심사위원 지적: 이분 종속변수(참여 10%대), 불균형, 복잡 모형에서
##                매개구조가 추정법을 바꿔도 복원되는지 검증 필요
##
## 검증 내용:
##   1. 종속변수 불균형 구조 확인
##   2. 추정법별 매개구조 복원 (ML, MLR, ULS, GLS)
##   3. 핵심 매개경로(효능감→안녕감→참여) 일관성 비교
##
## 본 분석 = 1차 심사본 기준 (안녕감 4문항)
## ============================================================

library(lavaan)
library(readxl)

df <- read_excel("data/260414_data_recoded.xlsx")

## ============================================================
## 1. 종속변수 불균형 구조 확인
## ============================================================
cat("================================================================\n")
cat("[1] 종속변수(자원봉사 참여) 불균형 구조\n")
cat("================================================================\n")
tab <- table(df$re_A_01_1)
prop <- prop.table(tab)
cat(sprintf("  미참여(0): %d명 (%.1f%%)\n", tab["0"], prop["0"]*100))
cat(sprintf("  참여(1):   %d명 (%.1f%%)\n", tab["1"], prop["1"]*100))
cat(sprintf("  참여율: %.1f%% → 불균형 구조 확인\n", prop["1"]*100))

## ============================================================
## 공통 모형 정의 (매개경로 라벨 포함)
## ============================================================
sem_model <- '
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04

  efficacy ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + awareness + re_C_08 + re_B_04
  wellbeing ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + re_C_08
  re_A_01_1 ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + awareness + re_C_08 + re_B_04

  wellbeing ~ b1*efficacy
  re_A_01_1 ~ b2*efficacy
  re_A_01_1 ~ b3*wellbeing

  efficacy ~ re_SQ1 + SQ2 + D_04 + re_B_02
  wellbeing ~ re_SQ1 + SQ2 + D_04 + re_B_02
  re_A_01_1 ~ re_SQ1 + SQ2 + D_04 + re_B_02
'

## ============================================================
## 2. 추정법별 분석
## ============================================================
estimators <- c("ML", "MLR", "GLS", "ULS")
results <- list()

for (est in estimators) {
  cat(sprintf("\n----------------------------------------------------------------\n"))
  cat(sprintf("[추정법: %s]\n", est))
  cat(sprintf("----------------------------------------------------------------\n"))

  fit <- tryCatch(
    sem(sem_model, data = df, estimator = est),
    error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NULL }
  )

  if (!is.null(fit)) {
    # 적합도
    if (est == "MLR") {
      fi <- fitMeasures(fit, c("cfi.robust","tli.robust","rmsea.robust","srmr"))
      names(fi) <- c("cfi","tli","rmsea","srmr")
    } else if (est == "ULS") {
      fi <- fitMeasures(fit, c("cfi","tli","rmsea","srmr"))
    } else {
      fi <- fitMeasures(fit, c("cfi","tli","rmsea","srmr"))
    }
    cat(sprintf("  적합도: CFI=%.3f, TLI=%.3f, RMSEA=%.3f, SRMR=%.3f\n",
                fi["cfi"], fi["tli"], fi["rmsea"], fi["srmr"]))

    # 핵심 매개경로 (표준화)
    std <- standardizedSolution(fit)
    b1 <- std[std$lhs=="wellbeing" & std$rhs=="efficacy" & std$op=="~", ]
    b2 <- std[std$lhs=="re_A_01_1" & std$rhs=="efficacy" & std$op=="~", ]
    b3 <- std[std$lhs=="re_A_01_1" & std$rhs=="wellbeing" & std$op=="~", ]

    sig <- function(p) ifelse(p<.001,"***",ifelse(p<.01,"**",ifelse(p<.05,"*","n.s.")))
    cat("\n  핵심 매개경로 (표준화):\n")
    cat(sprintf("    효능감 -> 안녕감 (b1): beta=%.3f %s\n", b1$est.std, sig(b1$pvalue)))
    cat(sprintf("    효능감 -> 참여   (b2): beta=%.3f %s\n", b2$est.std, sig(b2$pvalue)))
    cat(sprintf("    안녕감 -> 참여   (b3): beta=%.3f %s\n", b3$est.std, sig(b3$pvalue)))

    results[[est]] <- data.frame(
      estimator = est,
      CFI = round(fi["cfi"],3), TLI = round(fi["tli"],3),
      RMSEA = round(fi["rmsea"],3), SRMR = round(fi["srmr"],3),
      b1_eff_wb = round(b1$est.std,3), b1_p = round(b1$pvalue,4),
      b2_eff_par = round(b2$est.std,3), b2_p = round(b2$pvalue,4),
      b3_wb_par = round(b3$est.std,3), b3_p = round(b3$pvalue,4)
    )
  }
}

## ============================================================
## 3. 종합 비교표
## ============================================================
cat("\n================================================================\n")
cat("[3] 추정법별 매개구조 복원 종합 비교\n")
cat("================================================================\n")
comp <- do.call(rbind, results)
rownames(comp) <- NULL
print(comp, row.names = FALSE)

write.csv(comp, "results/mediation_robustness_comparison.csv", row.names = FALSE)
cat("\n결과 저장: results/mediation_robustness_comparison.csv\n")

cat("\n[해석]\n")
cat("- 핵심 매개구조: 효능감->안녕감(b1) 정적 유의, 안녕감->참여(b3) 정적,\n")
cat("  효능감->참여(b2) 직접효과 비유의 = 완전매개 구조\n")
cat("- 추정법을 달리해도 이 구조가 일관되게 복원되면 강건성 입증\n")
