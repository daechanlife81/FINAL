## ============================================================
## 주관적 안녕감 측정 옵션 비교
## 옵션 1: 4문항 (행복, 삶의 만족, 우울역, 걱정역) - 현재
## 옵션 2: 2문항 (행복, 삶의 만족) - 지도교수님 권장
##
## 박사학위논문 최종 점검 (2026-04-26)
## ============================================================

library(lavaan)
library(readxl)

df <- read_excel("data/260414_data_recoded.xlsx")

## ============================================================
## 1. 옵션 1: 4문항 (현재 본 연구)
## ============================================================
cat("================================================================\n")
cat("[옵션 1] 4문항: 행복 + 삶의 만족 + 우울(역) + 걱정(역)\n")
cat("================================================================\n")

cfa_4items <- '
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04
'

fit_4 <- cfa(cfa_4items, data = df, estimator = "ML")
fi_4 <- fitMeasures(fit_4,
                     c("chisq","df","pvalue","gfi","cfi","tli","rmsea","srmr"))
cat("\n--- 4문항 모형 적합도 ---\n")
print(round(fi_4, 4))

## 신뢰도 계산
items_4 <- df[, c("C_01", "re_C_02", "re_C_03", "C_04")]
items_4 <- items_4[complete.cases(items_4), ]
alpha_4 <- psych::alpha(items_4)$total$raw_alpha

cat(sprintf("\nCronbach's alpha (4문항) = %.3f\n", alpha_4))

## AVE/CR 계산
std_load_4 <- standardizedSolution(fit_4)
loadings_4 <- std_load_4[std_load_4$op == "=~", "est.std"]
ave_4 <- mean(loadings_4^2)
cr_4 <- (sum(loadings_4))^2 / ((sum(loadings_4))^2 + sum(1 - loadings_4^2))

cat(sprintf("AVE (4문항) = %.3f\n", ave_4))
cat(sprintf("CR (4문항) = %.3f\n", cr_4))

## ============================================================
## 2. 옵션 2: 2문항 (행복 + 삶의 만족)
## ============================================================
cat("\n================================================================\n")
cat("[옵션 2] 2문항: 행복 + 삶의 만족 (지도교수님 권장)\n")
cat("================================================================\n")

cfa_2items <- '
  wellbeing =~ C_01 + C_04
'

fit_2 <- tryCatch({
  cfa(cfa_2items, data = df, estimator = "ML")
}, error = function(e) {
  cat("ERROR: 2문항 모형은 잠재변수당 최소 3문항 필요 (식별 불가)\n")
  NULL
})

if (!is.null(fit_2)) {
  fi_2 <- fitMeasures(fit_2,
                       c("chisq","df","pvalue","gfi","cfi","tli","rmsea","srmr"))
  cat("\n--- 2문항 모형 적합도 ---\n")
  print(round(fi_2, 4))
}

## 신뢰도 계산
items_2 <- df[, c("C_01", "C_04")]
items_2 <- items_2[complete.cases(items_2), ]
alpha_2 <- psych::alpha(items_2)$total$raw_alpha

cat(sprintf("\nCronbach's alpha (2문항) = %.3f\n", alpha_2))

## 상관계수
cor_2items <- cor(items_2$C_01, items_2$C_04)
cat(sprintf("C_01과 C_04 상관계수 = %.3f\n", cor_2items))

## Spearman-Brown 공식 (2문항 신뢰도)
sb_2 <- 2 * cor_2items / (1 + cor_2items)
cat(sprintf("Spearman-Brown 신뢰도 (2문항) = %.3f\n", sb_2))

## ============================================================
## 3. 옵션 3: 양적 안녕감 + 음적 안녕감 분리 (2개 잠재변수)
## ============================================================
cat("\n================================================================\n")
cat("[옵션 3] 양적 안녕감 + 음적 안녕감 분리 (2개 잠재변수)\n")
cat("================================================================\n")

cfa_split <- '
  pos_wb =~ C_01 + C_04
  neg_wb =~ re_C_02 + re_C_03
'

fit_split <- tryCatch({
  cfa(cfa_split, data = df, estimator = "ML")
}, error = function(e) {
  cat("ERROR:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(fit_split)) {
  fi_split <- fitMeasures(fit_split,
                           c("chisq","df","pvalue","gfi","cfi","tli","rmsea","srmr"))
  cat("\n--- 양적/음적 분리 모형 적합도 ---\n")
  print(round(fi_split, 4))
}

## ============================================================
## 4. 종합 비교
## ============================================================
cat("\n================================================================\n")
cat("4. 종합 비교\n")
cat("================================================================\n")

cat(sprintf("\n[4문항] alpha = %.3f, AVE = %.3f, CR = %.3f\n",
            alpha_4, ave_4, cr_4))
cat(sprintf("[2문항] alpha = %.3f, Spearman-Brown = %.3f\n",
            alpha_2, sb_2))

cat("\n주의사항:\n")
cat("  - 2문항 모형은 단독 CFA 식별 불가 (df < 0)\n")
cat("  - SEM 모형 내 잠재변수로 투입 시 다른 변수와 결합으로 식별 가능\n")
cat("  - 2문항 잠재변수는 학술적 권장사항이 아님\n")
