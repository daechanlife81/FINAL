## ============================================================
## 상관계수 robustness 검증
## Pearson vs Spearman vs Kendall 비교
##
## 목적: 본 연구의 변수 유형(이분형/서열형 다수)을 고려하여
##       Pearson 상관의 적절성을 다른 상관계수와 비교 검증
## ============================================================

library(readxl)
library(dplyr)

df <- read_excel("data/260414_data_recoded.xlsx")

## ===== 주요 변수 선택 =====
vars <- c("re_A_01_1",  # 자원봉사 참여경험 (이분형)
          "re_B_02",    # 과거 봉사경험 (이분형)
          "re_B_04",    # 봉사교육경험 (이분형)
          "re_C_06",    # 네트워크 (이분형)
          "re_C_07",    # 사회단체활동 (이분형)
          "re_C_08",    # 종교활동 (이분형)
          "re_SQ1",     # 성별 (이분형)
          "D_05",       # 주관적 건강 (서열형 1-5)
          "D_03",       # 교육수준 (서열형 1-5)
          "C_05",       # 일반적 신뢰 (서열형 1-4)
          "SQ2")        # 연령 (연속형)

df_sub <- df %>% select(all_of(vars)) %>% na.omit()

## ===== 변수 유형 분류 =====
cat("================================================================\n")
cat("변수 유형 분류\n")
cat("================================================================\n")
var_types <- data.frame(
  Variable = vars,
  Type = c("Binary", "Binary", "Binary", "Binary", "Binary", "Binary", "Binary",
           "Ordinal", "Ordinal", "Ordinal", "Continuous"),
  Levels = sapply(df_sub, function(x) length(unique(x)))
)
print(var_types)

## ===== Pearson 상관 =====
cat("\n================================================================\n")
cat("1. Pearson 상관계수\n")
cat("================================================================\n")
cor_pearson <- cor(df_sub, method = "pearson")
print(round(cor_pearson, 3))

## ===== Spearman 상관 =====
cat("\n================================================================\n")
cat("2. Spearman 순위상관계수\n")
cat("================================================================\n")
cor_spearman <- cor(df_sub, method = "spearman")
print(round(cor_spearman, 3))

## ===== Kendall 상관 =====
cat("\n================================================================\n")
cat("3. Kendall tau 상관계수\n")
cat("================================================================\n")
cor_kendall <- cor(df_sub, method = "kendall")
print(round(cor_kendall, 3))

## ===== 세 상관계수 차이 비교 (종속변수와의 상관) =====
cat("\n================================================================\n")
cat("4. 종속변수(자원봉사 참여)와의 상관 - 세 방법 비교\n")
cat("================================================================\n")

dv_cor <- data.frame(
  Variable = vars[-1],
  Pearson = round(cor_pearson["re_A_01_1", -1], 3),
  Spearman = round(cor_spearman["re_A_01_1", -1], 3),
  Kendall = round(cor_kendall["re_A_01_1", -1], 3)
)
dv_cor$Pearson_vs_Spearman_Diff <- round(abs(dv_cor$Pearson - dv_cor$Spearman), 3)
dv_cor$Pearson_vs_Kendall_Diff <- round(abs(dv_cor$Pearson - dv_cor$Kendall), 3)
print(dv_cor)

## ===== 평균 절대 차이 =====
cat("\n--- 세 방법 간 차이 요약 ---\n")
cat(sprintf("Pearson vs Spearman 평균 절대 차이: %.4f\n",
            mean(dv_cor$Pearson_vs_Spearman_Diff)))
cat(sprintf("Pearson vs Kendall 평균 절대 차이: %.4f\n",
            mean(dv_cor$Pearson_vs_Kendall_Diff)))

## ===== 결과 저장 =====
write.csv(round(cor_pearson, 3),
          "results/correlation_pearson.csv", row.names = TRUE)
write.csv(round(cor_spearman, 3),
          "results/correlation_spearman.csv", row.names = TRUE)
write.csv(round(cor_kendall, 3),
          "results/correlation_kendall.csv", row.names = TRUE)
write.csv(dv_cor,
          "results/correlation_comparison_dv.csv", row.names = FALSE)

cat("\n================================================================\n")
cat("결과 저장 완료:\n")
cat("  results/correlation_pearson.csv\n")
cat("  results/correlation_spearman.csv\n")
cat("  results/correlation_kendall.csv\n")
cat("  results/correlation_comparison_dv.csv\n")
cat("================================================================\n")
