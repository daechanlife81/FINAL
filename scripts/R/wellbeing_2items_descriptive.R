## ============================================================
## 주관적 안녕감 2문항(삶의 만족 + 행복) 기술통계 및 정규성 검토
## 박사학위논문 - 측정변수 기술통계표 갱신용 (방안 2)
##
## 변수:
##   C_01 = 삶의 만족 (Life Satisfaction)
##   C_04 = 행복 (Happiness)
## ============================================================

library(readxl)
library(psych)  # describe: skew, kurtosis (excess) 제공

df <- read_excel("data/260414_data_recoded.xlsx")

## psych::skew, psych::kurtosi 사용 (kurtosi는 excess kurtosis)
skewness <- function(x) psych::skew(x)
kurtosis <- function(x) psych::kurtosi(x) + 3  # 일반 첨도로 환산 (코드 호환용)

## ===== 2문항 추출 =====
items <- c("C_01", "C_04")
labels <- c("삶의 만족 (C_01)", "행복 (C_04)")

cat("================================================================\n")
cat("주관적 안녕감 2문항 기술통계 및 정규성\n")
cat("================================================================\n\n")

result <- data.frame(
  변수 = character(),
  N = integer(),
  최솟값 = numeric(),
  최댓값 = numeric(),
  평균 = numeric(),
  표준편차 = numeric(),
  왜도 = numeric(),
  첨도 = numeric(),
  stringsAsFactors = FALSE
)

for (i in seq_along(items)) {
  x <- df[[items[i]]]
  x <- x[!is.na(x)]
  result <- rbind(result, data.frame(
    변수 = labels[i],
    N = length(x),
    최솟값 = min(x),
    최댓값 = max(x),
    평균 = round(mean(x), 3),
    표준편차 = round(sd(x), 3),
    왜도 = round(skewness(x), 3),
    첨도 = round(kurtosis(x) - 3, 3)  # excess kurtosis (정규분포=0)
  ))
}

print(result, row.names = FALSE)

cat("\n주. 첨도는 excess kurtosis (정규분포 = 0 기준)\n")
cat("    정규성 기준: 왜도 |3| 미만, 첨도 |10| 미만 (Kline, 2016)\n")

## ===== 정규성 판정 =====
cat("\n--- 정규성 판정 (Kline, 2016) ---\n")
for (i in 1:nrow(result)) {
  sk_ok <- abs(result$왜도[i]) < 3
  ku_ok <- abs(result$첨도[i]) < 10
  cat(sprintf("  %s: 왜도=%.3f (%s), 첨도=%.3f (%s) -> %s\n",
              result$변수[i],
              result$왜도[i], ifelse(sk_ok, "충족", "위반"),
              result$첨도[i], ifelse(ku_ok, "충족", "위반"),
              ifelse(sk_ok & ku_ok, "정규성 충족", "정규성 위반")))
}

## ===== 안녕감 합산점수(2문항 평균)도 산출 =====
cat("\n================================================================\n")
cat("참고: 안녕감 2문항 합산(평균) 점수 기술통계\n")
cat("================================================================\n")
wb_sub <- df[, items]
wb_sub <- wb_sub[complete.cases(wb_sub), ]
wb_mean <- rowMeans(wb_sub)

cat(sprintf("  N = %d\n", length(wb_mean)))
cat(sprintf("  평균 = %.3f\n", mean(wb_mean)))
cat(sprintf("  표준편차 = %.3f\n", sd(wb_mean)))
cat(sprintf("  최솟값 = %.3f, 최댓값 = %.3f\n", min(wb_mean), max(wb_mean)))
cat(sprintf("  왜도 = %.3f\n", skewness(wb_mean)))
cat(sprintf("  첨도(excess) = %.3f\n", kurtosis(wb_mean) - 3))

## ===== 두 문항 상관 =====
cat(sprintf("\n  C_01과 C_04 상관계수 (Pearson) = %.3f\n",
            cor(wb_sub$C_01, wb_sub$C_04)))

## ===== CSV 저장 =====
write.csv(result, "results/wellbeing_2items_descriptive.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
cat("\n결과 저장: results/wellbeing_2items_descriptive.csv\n")
