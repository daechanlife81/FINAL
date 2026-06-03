## ============================================================
## 샘플 부트스트랩 민감도 분석 (심사위원 핵심 robustness 요구)
##
## 심사위원 지적: 결과변수 이분(참여 17.4%)·불균형 구조에서
##                샘플을 재구성해도 매개구조가 복원되는지 검증
##
## 검증 방법:
##   1. 70% 서브샘플링 반복 (불균형 구조 유지, 무작위)
##   2. 오버샘플링 (참여자 비율 상향 보정)
##   3. 핵심 매개경로 복원율 산출
##
## 본 분석 = 1차 심사본 기준 (안녕감 4문항)
## 재현성: set.seed 고정
## ============================================================

library(lavaan)
library(readxl)

df <- read_excel("data/260414_data_recoded.xlsx")
df <- as.data.frame(df)

## 공통 모형 (매개경로 라벨)
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

## 핵심 경로 추출 함수
extract_paths <- function(fit) {
  std <- standardizedSolution(fit)
  b1 <- std[std$lhs=="wellbeing" & std$rhs=="efficacy" & std$op=="~", ]
  b3 <- std[std$lhs=="re_A_01_1" & std$rhs=="wellbeing" & std$op=="~", ]
  c(b1_est = b1$est.std, b1_p = b1$pvalue,
    b3_est = b3$est.std, b3_p = b3$pvalue)
}

## ============================================================
## 1. 70% 서브샘플링 반복 (200회)
## ============================================================
cat("================================================================\n")
cat("[1] 70% 서브샘플링 반복 (n=200, 불균형 구조 유지)\n")
cat("================================================================\n")

set.seed(20260603)
n_rep <- 200
n_sub <- round(nrow(df) * 0.7)

sub_results <- data.frame()
fail_count <- 0

for (i in 1:n_rep) {
  idx <- sample(1:nrow(df), n_sub, replace = FALSE)
  d_sub <- df[idx, ]

  fit <- tryCatch(
    sem(sem_model, data = d_sub, estimator = "ML", warn = FALSE),
    error = function(e) NULL,
    warning = function(w) suppressWarnings(sem(sem_model, data = d_sub, estimator = "ML"))
  )

  if (!is.null(fit) && lavInspect(fit, "converged")) {
    p <- extract_paths(fit)
    sub_results <- rbind(sub_results, as.data.frame(as.list(p)))
  } else {
    fail_count <- fail_count + 1
  }
}

cat(sprintf("\n수렴 성공: %d/%d회 (실패 %d회)\n",
            nrow(sub_results), n_rep, fail_count))
cat("\n--- 효능감 -> 안녕감 (b1) ---\n")
cat(sprintf("  평균 beta = %.3f (SD = %.3f)\n",
            mean(sub_results$b1_est), sd(sub_results$b1_est)))
cat(sprintf("  유의(p<.05) 비율 = %.1f%%\n",
            mean(sub_results$b1_p < .05) * 100))
cat(sprintf("  beta 범위 = [%.3f, %.3f]\n",
            min(sub_results$b1_est), max(sub_results$b1_est)))

cat("\n--- 안녕감 -> 참여 (b3) ---\n")
cat(sprintf("  평균 beta = %.3f (SD = %.3f)\n",
            mean(sub_results$b3_est), sd(sub_results$b3_est)))
cat(sprintf("  유의(p<.05) 비율 = %.1f%%\n",
            mean(sub_results$b3_p < .05) * 100))
cat(sprintf("  beta 범위 = [%.3f, %.3f]\n",
            min(sub_results$b3_est), max(sub_results$b3_est)))

## ============================================================
## 2. 오버샘플링 (참여자 비율 상향: 17.4% -> 약 40%)
## ============================================================
cat("\n================================================================\n")
cat("[2] 오버샘플링 (참여자 비율 상향 보정)\n")
cat("================================================================\n")

set.seed(20260603)
participants <- df[df$re_A_01_1 == 1, ]
nonparticipants <- df[df$re_A_01_1 == 0, ]

cat(sprintf("원자료: 참여 %d명(17.4%%), 미참여 %d명\n",
            nrow(participants), nrow(nonparticipants)))

# 참여자를 복원추출로 증대 (참여:미참여 약 40:60)
target_part <- round(nrow(nonparticipants) * 40 / 60)
over_idx <- sample(1:nrow(participants), target_part, replace = TRUE)
df_over <- rbind(nonparticipants, participants[over_idx, ])

cat(sprintf("오버샘플링 후: 참여 %d명(%.1f%%), 미참여 %d명\n",
            target_part, target_part/(target_part+nrow(nonparticipants))*100,
            nrow(nonparticipants)))

fit_over <- tryCatch(
  sem(sem_model, data = df_over, estimator = "MLR"),
  error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NULL }
)

if (!is.null(fit_over)) {
  fi <- fitMeasures(fit_over, c("cfi.robust","tli.robust","rmsea.robust","srmr"))
  cat(sprintf("\n적합도: CFI=%.3f, TLI=%.3f, RMSEA=%.3f, SRMR=%.3f\n",
              fi["cfi.robust"], fi["tli.robust"], fi["rmsea.robust"], fi["srmr"]))
  std <- standardizedSolution(fit_over)
  b1 <- std[std$lhs=="wellbeing" & std$rhs=="efficacy" & std$op=="~", ]
  b2 <- std[std$lhs=="re_A_01_1" & std$rhs=="efficacy" & std$op=="~", ]
  b3 <- std[std$lhs=="re_A_01_1" & std$rhs=="wellbeing" & std$op=="~", ]
  sig <- function(p) ifelse(p<.001,"***",ifelse(p<.01,"**",ifelse(p<.05,"*","n.s.")))
  cat("\n핵심 매개경로 (오버샘플링):\n")
  cat(sprintf("  효능감 -> 안녕감 (b1): beta=%.3f %s\n", b1$est.std, sig(b1$pvalue)))
  cat(sprintf("  효능감 -> 참여   (b2): beta=%.3f %s\n", b2$est.std, sig(b2$pvalue)))
  cat(sprintf("  안녕감 -> 참여   (b3): beta=%.3f %s\n", b3$est.std, sig(b3$pvalue)))
}

## ============================================================
## 3. 종합 비교 (원자료 vs 서브샘플링 vs 오버샘플링)
## ============================================================
cat("\n================================================================\n")
cat("[3] 종합 비교: 원자료 vs 서브샘플링 vs 오버샘플링\n")
cat("================================================================\n")

# 원자료 기준값
fit_orig <- sem(sem_model, data = df, estimator = "ML")
p_orig <- extract_paths(fit_orig)

summary_tab <- data.frame(
  분석 = c("원자료 (N=1328)", "70% 서브샘플 평균", "오버샘플링 (40%)"),
  b1_효능감_안녕감 = c(round(p_orig["b1_est"],3),
                       round(mean(sub_results$b1_est),3),
                       ifelse(!is.null(fit_over), round(b1$est.std,3), NA)),
  b3_안녕감_참여 = c(round(p_orig["b3_est"],3),
                     round(mean(sub_results$b3_est),3),
                     ifelse(!is.null(fit_over), round(b3$est.std,3), NA))
)
print(summary_tab, row.names = FALSE)

write.csv(summary_tab, "results/sample_robustness_summary.csv", row.names = FALSE)
write.csv(sub_results, "results/sample_robustness_subsample.csv", row.names = FALSE)
cat("\n결과 저장:\n")
cat("  results/sample_robustness_summary.csv\n")
cat("  results/sample_robustness_subsample.csv\n")

cat("\n[해석]\n")
cat("- 서브샘플링: 핵심 매개경로가 높은 비율로 유의하게 복원되면 강건\n")
cat("- 오버샘플링: 불균형 보정 후에도 매개구조 유지되면 강건\n")
cat("- 세 조건에서 일관된 결과 = 강건성 입증, 불균형 우려 해소\n")
