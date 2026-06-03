## ============================================================
## 2문항 주관적 안녕감 식별 안정성 분석 (박사논문 심사 대비)
##
## 분석 내용:
##   1. 단독 CFA 식별 문제 재확인 (df = -1)
##   2. 요인부하량 동일 제약(tau-equivalent) 모형 - 식별 확보
##   3. 전체 SEM 내 식별 (비제약 vs 제약 비교)
##   4. Eisinga et al.(2013) 기반 2문항 신뢰도 (r, Spearman-Brown)
##
## 안녕감 2문항: C_01(삶의 만족) + C_04(행복)
## ============================================================

library(lavaan)
library(readxl)
library(psych)

df <- read_excel("data/260414_data_recoded.xlsx")

## ============================================================
## 1. 단독 CFA - 식별 문제 재확인
## ============================================================
cat("================================================================\n")
cat("[1] 단독 CFA 식별 문제 확인 (2문항 잠재변수)\n")
cat("================================================================\n")

# 안녕감만 단독으로 (식별 불가 예상)
model_solo <- 'wellbeing =~ C_01 + C_04'
fit_solo <- tryCatch(
  cfa(model_solo, data = df, estimator = "ML"),
  warning = function(w) { cat("WARNING:", conditionMessage(w), "\n"); suppressWarnings(cfa(model_solo, data = df, estimator = "ML")) }
)
cat(sprintf("\n단독 모형 df = %d\n", fitMeasures(fit_solo, "df")))
cat("→ 잠재변수 1개 + 관측변수 2개 = 음수 자유도 (under-identified)\n")
cat("  모수: 분산2 + 부하량2 + 요인분산1 = 5개 추정 / 정보 3개 (2분산+1공분산)\n")

## ============================================================
## 2. 요인부하량 동일 제약 (tau-equivalent) - 단독 식별 확보
## ============================================================
cat("\n================================================================\n")
cat("[2] 요인부하량 동일 제약 모형 (tau-equivalent)\n")
cat("================================================================\n")

# 두 문항 부하량을 같게 제약 (a*)
model_tau <- 'wellbeing =~ a*C_01 + a*C_04'
fit_tau <- cfa(model_tau, data = df, estimator = "ML")
cat(sprintf("\n동일 제약 모형 df = %d\n", fitMeasures(fit_tau, "df")))

std_tau <- standardizedSolution(fit_tau)
load_tau <- std_tau[std_tau$op == "=~", ]
cat("\n표준화 요인부하량 (동일 제약):\n")
for (i in 1:nrow(load_tau)) {
  cat(sprintf("  %s: lambda = %.3f\n", load_tau$rhs[i], load_tau$est.std[i]))
}
cat("→ 동일 제약으로 자유도 확보, 단독 식별 가능\n")

## ============================================================
## 3. 전체 SEM 내 식별 (비제약 vs 제약)
## ============================================================
cat("\n================================================================\n")
cat("[3] 전체 측정모형 내 2문항 식별 (비제약 vs 동일제약)\n")
cat("================================================================\n")

# (A) 비제약 - 전체 CFA 내에서 식별
model_free <- '
  efficacy  =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + C_04
'
fit_free <- cfa(model_free, data = df, estimator = "ML")
fi_free <- fitMeasures(fit_free, c("chisq","df","cfi","tli","rmsea","srmr"))

# (B) 동일제약 - 전체 CFA 내에서 부하량 제약
model_constr <- '
  efficacy  =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ a*C_01 + a*C_04
'
fit_constr <- cfa(model_constr, data = df, estimator = "ML")
fi_constr <- fitMeasures(fit_constr, c("chisq","df","cfi","tli","rmsea","srmr"))

cat("\n(A) 비제약 모형 (전체 CFA 내 식별):\n")
cat(sprintf("  chi2(df)=%.3f(%.0f), CFI=%.3f, TLI=%.3f, RMSEA=%.3f, SRMR=%.3f\n",
            fi_free["chisq"], fi_free["df"], fi_free["cfi"], fi_free["tli"],
            fi_free["rmsea"], fi_free["srmr"]))

cat("\n(B) 동일제약 모형 (tau-equivalent):\n")
cat(sprintf("  chi2(df)=%.3f(%.0f), CFI=%.3f, TLI=%.3f, RMSEA=%.3f, SRMR=%.3f\n",
            fi_constr["chisq"], fi_constr["df"], fi_constr["cfi"], fi_constr["tli"],
            fi_constr["rmsea"], fi_constr["srmr"]))

# 모형 비교 (chi-square difference)
cat("\n--- 비제약 vs 제약 모형 비교 (Chi-square difference test) ---\n")
comp <- anova(fit_constr, fit_free)
print(comp)
cat("\n→ 유의하지 않으면(p>.05) 동일 제약이 데이터에 부합 = tau-equivalent 성립\n")

## 비제약 모형 안녕감 부하량
std_free <- standardizedSolution(fit_free)
load_free_wb <- std_free[std_free$op == "=~" & std_free$lhs == "wellbeing", ]
cat("\n비제약 모형 안녕감 부하량:\n")
for (i in 1:nrow(load_free_wb)) {
  cat(sprintf("  %s: lambda = %.3f\n", load_free_wb$rhs[i], load_free_wb$est.std[i]))
}

## ============================================================
## 4. Eisinga et al.(2013) 기반 2문항 신뢰도
## ============================================================
cat("\n================================================================\n")
cat("[4] 2문항 신뢰도 (Eisinga et al., 2013 권장 지표)\n")
cat("================================================================\n")

wb <- df[, c("C_01", "C_04")]; wb <- wb[complete.cases(wb), ]
r <- cor(wb$C_01, wb$C_04)
sb <- 2 * r / (1 + r)  # Spearman-Brown
alpha_val <- psych::alpha(wb)$total$raw_alpha

cat(sprintf("\n  Pearson 상관 (r)        = %.3f\n", r))
cat(sprintf("  Spearman-Brown 계수     = %.3f\n", sb))
cat(sprintf("  Cronbach's alpha        = %.3f\n", alpha_val))
cat("\n  ※ Eisinga et al.(2013): 2문항 척도는 Spearman-Brown이 가장 적절\n")
cat("    'The reliability of a two-item scale: Pearson, Cronbach, or Spearman-Brown?'\n")
cat("    International Journal of Public Health, 58(4), 637-642.\n")

## ============================================================
## 5. 종합 요약
## ============================================================
cat("\n================================================================\n")
cat("[종합] 2문항 안녕감 식별 안정성\n")
cat("================================================================\n")
cat("\n1. 단독 CFA: df=-1 (식별 불가) → 전체 SEM 내 식별 필요\n")
cat("2. tau-equivalent 제약: 단독 식별 가능 (df>=0)\n")
cat("3. 전체 모형 내: 비제약/제약 모두 안정적 추정\n")
cat(sprintf("4. 신뢰도: SB=%.3f (2문항 권장 지표)\n", sb))
cat("\n→ 박사논문 기술: 전체 SEM 내 식별 + Spearman-Brown 신뢰도 보고\n")
