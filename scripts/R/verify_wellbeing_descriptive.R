## 예전 안녕감 기술통계 검증: 4문항 평균 vs 2문항 평균
library(readxl)
library(psych)

df <- read_excel("data/260414_data_recoded.xlsx")

# 4문항 평균 (예전 방식: C_01 + re_C_02 + re_C_03 + C_04)
wb4 <- rowMeans(df[, c("C_01", "re_C_02", "re_C_03", "C_04")], na.rm = TRUE)
cat("=== 4문항 평균 (예전 방식) ===\n")
cat(sprintf("M = %.2f, SD = %.2f, 왜도 = %.2f, 첨도(excess) = %.2f\n\n",
            mean(wb4), sd(wb4), skew(wb4), kurtosi(wb4)))

# 2문항 평균 (방안 2: C_01 + C_04)
wb2 <- rowMeans(df[, c("C_01", "C_04")], na.rm = TRUE)
cat("=== 2문항 평균 (삶의 만족 + 행복, 방안 2) ===\n")
cat(sprintf("M = %.2f, SD = %.2f, 왜도 = %.2f, 첨도(excess) = %.2f\n",
            mean(wb2), sd(wb2), skew(wb2), kurtosi(wb2)))
