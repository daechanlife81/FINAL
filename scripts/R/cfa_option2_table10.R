## ============================================================
## 방안 2 (안녕감 2문항) - 표 10 작성용 전체 모수 추출
## B(비표준화), SE, C.R., 표준화 요인부하량, AVE, CR, alpha
## ============================================================

library(lavaan)
library(readxl)
library(psych)

df <- read_excel("data/260414_data_recoded.xlsx")

model_2 <- '
  efficacy  =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + C_04
'

fit <- cfa(model_2, data = df, estimator = "ML")

## 비표준화 + 표준화 추정치 결합
unstd <- parameterEstimates(fit)
std <- standardizedSolution(fit)

cat("================================================================\n")
cat("표 10 작성용 모수 (방안 2: 안녕감 2문항)\n")
cat("================================================================\n\n")

loadings_unstd <- unstd[unstd$op == "=~", ]
loadings_std <- std[std$op == "=~", ]

cat(sprintf("%-12s %-12s %8s %8s %8s %8s\n",
            "잠재변수", "관측변수", "B", "SE", "C.R.", "lambda"))
cat(strrep("-", 64), "\n")
for (i in 1:nrow(loadings_unstd)) {
  cr_val <- if (loadings_unstd$se[i] == 0) NA else loadings_unstd$z[i]
  cat(sprintf("%-12s %-12s %8.3f %8s %8s %7.3f***\n",
              loadings_unstd$lhs[i], loadings_unstd$rhs[i],
              loadings_unstd$est[i],
              ifelse(loadings_unstd$se[i] == 0, "(고정)", sprintf("%.3f", loadings_unstd$se[i])),
              ifelse(is.na(cr_val), "-", sprintf("%.3f", cr_val)),
              loadings_std$est.std[i]))
}

## AVE / CR / alpha
cat("\n--- AVE / CR / Cronbach's alpha ---\n")
for (lv in c("efficacy", "awareness", "wellbeing")) {
  l <- loadings_std[loadings_std$lhs == lv, "est.std"]
  ave <- mean(l^2)
  cr <- sum(l)^2 / (sum(l)^2 + sum(1 - l^2))

  if (lv == "efficacy") items <- paste0("B_05_", 1:10)
  if (lv == "awareness") items <- paste0("B_06_", 1:8)
  if (lv == "wellbeing") items <- c("C_01", "C_04")
  sub <- df[, items]; sub <- sub[complete.cases(sub), ]
  alpha_val <- psych::alpha(sub)$total$raw_alpha

  cat(sprintf("  %s: AVE = %.3f, CR = %.3f, alpha = %.3f\n",
              lv, ave, cr, alpha_val))
}

## 안녕감 합산 점수 신뢰도 (참고)
cat("\n--- 안녕감 2문항 상관 (참고) ---\n")
wb <- df[, c("C_01", "C_04")]; wb <- wb[complete.cases(wb), ]
cat(sprintf("  C_01-C_04 Pearson r = %.3f\n", cor(wb$C_01, wb$C_04)))
