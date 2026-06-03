## ============================================================
## 2문항 안녕감 식별 방법 4가지 비교 (박사논문 심사 대비 v2)
##
## ① tau-equivalent (요인부하량 동일) - 앞서 부적합 확인
## ② 오차분산 동일 제약 (Error Variance Constraint)
## ③ 외부 식별 (External identification - 다른 잠재변수 활용)
## ④ 종합 비교
##
## 안녕감 2문항: C_01(삶의 만족) + C_04(행복)
## ============================================================

library(lavaan)
library(readxl)

df <- read_excel("data/260414_data_recoded.xlsx")

cat("================================================================\n")
cat("2문항 안녕감 식별 방법 비교\n")
cat("================================================================\n")

## ============================================================
## 방법 ②: 오차분산 동일 제약 (단독 모형)
## ============================================================
cat("\n----------------------------------------------------------------\n")
cat("[방법 2] 오차분산 동일 제약 - 단독 CFA\n")
cat("----------------------------------------------------------------\n")
cat("부하량은 자유 추정, 측정오차 분산을 동일하게 고정\n\n")

model_ev_solo <- '
  wellbeing =~ C_01 + C_04
  C_01 ~~ ev*C_01
  C_04 ~~ ev*C_04
'
fit_ev_solo <- tryCatch(
  cfa(model_ev_solo, data = df, estimator = "ML"),
  warning = function(w) { cat("WARNING:", conditionMessage(w), "\n")
                          suppressWarnings(cfa(model_ev_solo, data = df, estimator = "ML")) }
)
cat(sprintf("단독 오차분산 제약 모형 df = %d\n", fitMeasures(fit_ev_solo, "df")))

std_ev <- standardizedSolution(fit_ev_solo)
load_ev <- std_ev[std_ev$op == "=~", ]
cat("\n표준화 요인부하량 (오차분산 동일 제약):\n")
for (i in 1:nrow(load_ev)) {
  cat(sprintf("  %s: lambda = %.3f\n", load_ev$rhs[i], load_ev$est.std[i]))
}
cat("→ 부하량은 서로 다르게 추정되면서, 오차분산 제약으로 식별 확보\n")

## ============================================================
## 방법 ③: 외부 식별 (전체 측정모형 - 제약 없음)
## ============================================================
cat("\n----------------------------------------------------------------\n")
cat("[방법 3] 외부 식별 - 전체 측정모형 내 (제약 없음)\n")
cat("----------------------------------------------------------------\n")
cat("안녕감이 다른 잠재변수(효능감·제도인식)와 상관 → 자동 식별\n\n")

model_external <- '
  efficacy  =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + C_04
'
fit_ext <- cfa(model_external, data = df, estimator = "ML")
fi_ext <- fitMeasures(fit_ext, c("chisq","df","cfi","tli","rmsea","srmr"))
cat(sprintf("전체 모형 df = %.0f (식별됨)\n", fi_ext["df"]))
cat(sprintf("적합도: CFI=%.3f, TLI=%.3f, RMSEA=%.3f, SRMR=%.3f\n",
            fi_ext["cfi"], fi_ext["tli"], fi_ext["rmsea"], fi_ext["srmr"]))

std_ext <- standardizedSolution(fit_ext)
load_ext <- std_ext[std_ext$op == "=~" & std_ext$lhs == "wellbeing", ]
cat("\n안녕감 부하량 (자유 추정):\n")
for (i in 1:nrow(load_ext)) {
  cat(sprintf("  %s: lambda = %.3f\n", load_ext$rhs[i], load_ext$est.std[i]))
}

# 잠재변수 간 상관 (외부 식별의 근거)
cors <- std_ext[std_ext$op == "~~" & std_ext$lhs != std_ext$rhs &
                std_ext$lhs %in% c("efficacy","awareness","wellbeing") &
                std_ext$rhs %in% c("efficacy","awareness","wellbeing"), ]
cat("\n안녕감과 다른 잠재변수 상관 (외부 식별 근거):\n")
for (i in 1:nrow(cors)) {
  if (cors$lhs[i] == "wellbeing" | cors$rhs[i] == "wellbeing") {
    other <- ifelse(cors$lhs[i] == "wellbeing", cors$rhs[i], cors$lhs[i])
    cat(sprintf("  wellbeing <-> %s: r = %.3f (p %s)\n",
                other, cors$est.std[i],
                ifelse(cors$pvalue[i] < .001, "< .001", sprintf("= %.3f", cors$pvalue[i]))))
  }
}

## ============================================================
## 방법 ②-전체: 오차분산 동일 제약 (전체 모형 내)
## ============================================================
cat("\n----------------------------------------------------------------\n")
cat("[방법 2-전체] 오차분산 동일 제약 - 전체 측정모형 내\n")
cat("----------------------------------------------------------------\n")

model_ev_full <- '
  efficacy  =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + C_04
  C_01 ~~ ev*C_01
  C_04 ~~ ev*C_04
'
fit_ev_full <- cfa(model_ev_full, data = df, estimator = "ML")
fi_ev_full <- fitMeasures(fit_ev_full, c("chisq","df","cfi","tli","rmsea","srmr"))
cat(sprintf("전체 오차분산 제약 모형 df = %.0f\n", fi_ev_full["df"]))
cat(sprintf("적합도: CFI=%.3f, TLI=%.3f, RMSEA=%.3f, SRMR=%.3f\n",
            fi_ev_full["cfi"], fi_ev_full["tli"], fi_ev_full["rmsea"], fi_ev_full["srmr"]))

## 외부식별(비제약) vs 오차분산제약 모형 비교
cat("\n--- 외부식별(비제약) vs 오차분산제약 비교 ---\n")
comp_ev <- anova(fit_ev_full, fit_ext)
print(comp_ev)
cat("\n→ 유의(p<.05)하면 오차분산이 서로 다름 = 비제약(외부식별)이 더 적합\n")

## ============================================================
## 종합 비교
## ============================================================
cat("\n================================================================\n")
cat("[종합] 2문항 안녕감 식별 방법 비교\n")
cat("================================================================\n")
cat(sprintf("\n%-30s %6s %8s %8s\n", "방법", "df", "CFI", "RMSEA"))
cat(strrep("-", 56), "\n")
cat(sprintf("%-30s %6.0f %8.3f %8.3f\n",
            "① 외부식별 (비제약)", fi_ext["df"], fi_ext["cfi"], fi_ext["rmsea"]))
cat(sprintf("%-30s %6.0f %8.3f %8.3f\n",
            "② 오차분산 동일제약 (전체)", fi_ev_full["df"], fi_ev_full["cfi"], fi_ev_full["rmsea"]))
cat("\n참고: ③ tau-equivalent는 부적합 확인됨 (앞 분석: Δχ²=8.09, p=.004)\n")

cat("\n[결론]\n")
cat("- 단독 식별 필요 시: 오차분산 동일 제약 (df 확보, 부하량 자유)\n")
cat("- 전체 모형: 외부 식별 (제약 불필요, 다른 잠재변수와 상관으로 자동 식별)\n")
cat("- 본 연구는 SEM이므로 [외부 식별]이 가장 자연스럽고 권장됨\n")
