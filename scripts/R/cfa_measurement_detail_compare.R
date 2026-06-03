## ============================================================
## 측정모형 CFA 상세 비교: 방안 1 (4문항) vs 방안 2 (2문항)
## 박사학위논문 3.1. 확인적 요인분석 갱신용
##
## 출력:
##   1. 측정모형 적합도 (표 9)
##   2. 표준화 요인부하량 (그림 2 / 표 11)
##   3. 잠재변수 간 상관관계
##   4. AVE / CR / Cronbach's alpha
##
## 잠재변수:
##   efficacy  = 자원봉사 효능감 (B_05_1~B_05_10)
##   awareness = 자원봉사제도 인식 (B_06_1~B_06_8)
##   wellbeing = 주관적 안녕감
##     방안 1: C_01 + re_C_02 + re_C_03 + C_04 (4문항)
##     방안 2: C_01 + C_04 (2문항: 삶의 만족 + 행복)
## ============================================================

library(lavaan)
library(readxl)

df <- read_excel("data/260414_data_recoded.xlsx")

## 라벨 매핑
item_labels <- list(
  efficacy = "자원봉사 효능감",
  awareness = "자원봉사제도 인식",
  wellbeing = "주관적 안녕감",
  B_05_1="효능감1", B_05_2="효능감2", B_05_3="효능감3", B_05_4="효능감4", B_05_5="효능감5",
  B_05_6="효능감6", B_05_7="효능감7", B_05_8="효능감8", B_05_9="효능감9", B_05_10="효능감10",
  B_06_1="제도인식1", B_06_2="제도인식2", B_06_3="제도인식3", B_06_4="제도인식4",
  B_06_5="제도인식5", B_06_6="제도인식6", B_06_7="제도인식7", B_06_8="제도인식8",
  C_01="삶의만족", re_C_02="걱정(역)", re_C_03="우울(역)", C_04="행복"
)
lab <- function(x) if (x %in% names(item_labels)) item_labels[[x]] else x

## ============================================================
## 분석 함수
## ============================================================
analyze_cfa <- function(model, df, title) {
  cat("\n================================================================\n")
  cat(title, "\n")
  cat("================================================================\n")

  fit <- cfa(model, data = df, estimator = "ML")

  ## 1) 적합도
  fi <- fitMeasures(fit, c("chisq","df","pvalue","gfi","cfi","tli",
                            "rmsea","rmsea.ci.lower","rmsea.ci.upper","srmr"))
  cat("\n[1] 측정모형 적합도\n")
  cat(sprintf("  chi2(df) = %.3f(%.0f), p < .001\n", fi["chisq"], fi["df"]))
  cat(sprintf("  chi2/df  = %.3f\n", fi["chisq"]/fi["df"]))
  cat(sprintf("  GFI = %.3f | CFI = %.3f | TLI = %.3f\n", fi["gfi"], fi["cfi"], fi["tli"]))
  cat(sprintf("  RMSEA = %.3f [%.3f, %.3f] | SRMR = %.3f\n",
              fi["rmsea"], fi["rmsea.ci.lower"], fi["rmsea.ci.upper"], fi["srmr"]))

  ## 2) 표준화 요인부하량
  std <- standardizedSolution(fit)
  loadings <- std[std$op == "=~", ]
  cat("\n[2] 표준화 요인부하량 (lambda)\n")
  for (i in 1:nrow(loadings)) {
    sig <- ifelse(loadings$pvalue[i] < .001, "***",
           ifelse(loadings$pvalue[i] < .01, "**",
           ifelse(loadings$pvalue[i] < .05, "*", "n.s.")))
    cat(sprintf("  %s -> %s: lambda = %.3f %s\n",
                lab(loadings$lhs[i]), lab(loadings$rhs[i]),
                loadings$est.std[i], sig))
  }
  cat(sprintf("\n  요인부하량 범위: %.2f ~ %.2f\n",
              min(loadings$est.std), max(loadings$est.std)))

  ## 3) 잠재변수 간 상관
  cors <- std[std$op == "~~" & std$lhs != std$rhs &
              std$lhs %in% c("efficacy","awareness","wellbeing") &
              std$rhs %in% c("efficacy","awareness","wellbeing"), ]
  cat("\n[3] 잠재변수 간 상관관계\n")
  if (nrow(cors) > 0) {
    for (i in 1:nrow(cors)) {
      cat(sprintf("  %s <-> %s: r = %.3f (p %s)\n",
                  lab(cors$lhs[i]), lab(cors$rhs[i]), cors$est.std[i],
                  ifelse(cors$pvalue[i] < .001, "< .001", sprintf("= %.3f", cors$pvalue[i]))))
    }
  }

  ## 4) AVE / CR / alpha
  cat("\n[4] 집중타당도 (AVE, CR) 및 신뢰도\n")
  for (lv in c("efficacy", "awareness", "wellbeing")) {
    l <- loadings[loadings$lhs == lv, "est.std"]
    ave <- mean(l^2)
    cr <- sum(l)^2 / (sum(l)^2 + sum(1 - l^2))
    cat(sprintf("  %s: AVE = %.3f, CR = %.3f (문항 %d개)\n",
                lab(lv), ave, cr, length(l)))
  }

  ## 판별타당도 (AVE > r^2)
  cat("\n[5] 판별타당도 (Fornell-Larcker: AVE > 상관제곱)\n")
  ave_vals <- sapply(c("efficacy","awareness","wellbeing"), function(lv) {
    l <- loadings[loadings$lhs == lv, "est.std"]; mean(l^2)
  })
  if (nrow(cors) > 0) {
    for (i in 1:nrow(cors)) {
      r2 <- cors$est.std[i]^2
      min_ave <- min(ave_vals[cors$lhs[i]], ave_vals[cors$rhs[i]])
      verdict <- ifelse(min_ave > r2, "충족", "위반")
      cat(sprintf("  %s-%s: r^2 = %.3f vs min(AVE) = %.3f -> %s\n",
                  lab(cors$lhs[i]), lab(cors$rhs[i]), r2, min_ave, verdict))
    }
  }

  return(fit)
}

## ============================================================
## 방안 1: 4문항
## ============================================================
model_4 <- '
  efficacy  =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04
'
fit4 <- analyze_cfa(model_4, df, "[방안 1] 안녕감 4문항 (현재)")

## ============================================================
## 방안 2: 2문항
## ============================================================
model_2 <- '
  efficacy  =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + C_04
'
fit2 <- analyze_cfa(model_2, df, "[방안 2] 안녕감 2문항 (삶의 만족 + 행복)")

cat("\n\n================================================================\n")
cat("분석 완료\n")
cat("================================================================\n")
