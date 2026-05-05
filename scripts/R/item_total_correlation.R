## 자원봉사제도 인식 문항-전체 상관계수 (Item-Total Correlation)
## B_06_1 ~ B_06_8 (8개 문항, 1~4 척도)
## 수정된 문항-전체 상관(Corrected Item-Total Correlation): 해당 문항을 제외한
## 나머지 문항들의 합과 해당 문항 간 Pearson 상관계수

library(readxl)
library(openxlsx)

## 데이터 로드
data <- read_excel("data/260414_data_recoded.xlsx")

## 자원봉사제도 인식 문항 추출
items <- paste0("B_06_", 1:8)
inst <- data[, items]

## 결측 제거
inst <- na.omit(inst)
n_obs <- nrow(inst)
cat("분석 대상 사례 수:", n_obs, "\n\n")

## 1. 기술통계
desc <- data.frame(
  Item = items,
  N = sapply(inst, function(x) sum(!is.na(x))),
  Mean = round(sapply(inst, mean), 3),
  SD = round(sapply(inst, sd), 3),
  Min = sapply(inst, min),
  Max = sapply(inst, max)
)

cat("=== 1. 문항별 기술통계 ===\n")
print(desc)
cat("\n")

## 2. 문항-전체 상관 (Item-Total Correlation)
##  - 단순 문항-전체 상관: 해당 문항 포함한 전체 합과의 상관 (과대추정)
##  - 수정된 문항-전체 상관(Corrected): 해당 문항 제외한 합과의 상관 (권장)

total_score <- rowSums(inst)

itc_uncorrected <- numeric(length(items))
itc_corrected <- numeric(length(items))
alpha_if_deleted <- numeric(length(items))

## Cronbach's alpha 함수
cronbach_alpha <- function(x) {
  k <- ncol(x)
  var_total <- var(rowSums(x))
  var_items <- sum(apply(x, 2, var))
  alpha <- (k / (k - 1)) * (1 - var_items / var_total)
  return(alpha)
}

## 전체 척도의 Cronbach's alpha
overall_alpha <- cronbach_alpha(inst)

for (i in seq_along(items)) {
  ## 단순 문항-전체 상관
  itc_uncorrected[i] <- cor(inst[[i]], total_score)

  ## 수정된 문항-전체 상관 (해당 문항 제외)
  rest_score <- total_score - inst[[i]]
  itc_corrected[i] <- cor(inst[[i]], rest_score)

  ## 해당 문항 제거 시 Cronbach's alpha
  alpha_if_deleted[i] <- cronbach_alpha(inst[, -i])
}

result <- data.frame(
  Item = items,
  Mean = round(sapply(inst, mean), 3),
  SD = round(sapply(inst, sd), 3),
  ITC_Uncorrected = round(itc_uncorrected, 3),
  ITC_Corrected = round(itc_corrected, 3),
  Alpha_if_Deleted = round(alpha_if_deleted, 3)
)

cat("=== 2. 문항-전체 상관계수 (Item-Total Correlation) ===\n")
cat("전체 척도 Cronbach's alpha:", round(overall_alpha, 3), "\n\n")
print(result)
cat("\n")

cat("=== 판단 기준 ===\n")
cat("- 수정된 문항-전체 상관 >= .30: 양호 (Nunnally & Bernstein, 1994)\n")
cat("- 수정된 문항-전체 상관 >= .50: 우수\n")
cat("- 수정된 문항-전체 상관 < .30: 척도에서 제거 검토\n")
cat("- Alpha if Deleted < 전체 alpha: 해당 문항 유지 권장\n\n")

## 3. 문항 간 상관행렬
cat("=== 3. 문항 간 상관행렬 ===\n")
cor_matrix <- round(cor(inst), 3)
print(cor_matrix)
cat("\n")

## 4. 결과 엑셀로 저장
wb <- createWorkbook()

addWorksheet(wb, "기술통계")
writeData(wb, "기술통계", desc)

addWorksheet(wb, "문항-전체 상관")
writeData(wb, "문항-전체 상관", result)
writeData(wb, "문항-전체 상관",
          data.frame(Note = paste0("전체 척도 Cronbach's alpha = ", round(overall_alpha, 3),
                                   " (N = ", n_obs, ")")),
          startRow = nrow(result) + 3, colNames = FALSE)

addWorksheet(wb, "문항 간 상관")
writeData(wb, "문항 간 상관", cor_matrix, rowNames = TRUE)

saveWorkbook(wb, "results/item_total_correlation.xlsx", overwrite = TRUE)
cat("결과 저장 완료: results/item_total_correlation.xlsx\n")
