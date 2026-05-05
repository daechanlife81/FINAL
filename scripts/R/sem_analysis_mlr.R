## ============================================================
## 본 SEM 분석 - MLR 추정법 적용 (박사학위논문 최종)
## 2026-04-26 갱신
##
## 변경사항:
##   - 추정법: ML → MLR (Satorra-Bentler 강건 표준오차)
##   - 간접효과: ML + Bootstrap 5,000회 (MLR은 부트스트랩 불가)
##   - WLSMV 사전 검토: Heywood case 발생으로 채택 불가 (별도 기록)
## ============================================================

library(lavaan)
library(readxl)

df <- read_excel("data/260414_data_recoded.xlsx")

## ===== 모형 정의 =====
sem_model <- '
  # 측정모형
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04

  # 구조모형
  efficacy ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + awareness + re_C_08 + re_B_04
  wellbeing ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + re_C_08
  re_A_01_1 ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + awareness + re_C_08 + re_B_04
  wellbeing ~ efficacy
  re_A_01_1 ~ efficacy
  re_A_01_1 ~ wellbeing

  # 통제변수
  efficacy ~ re_SQ1 + SQ2 + D_04 + re_B_02
  wellbeing ~ re_SQ1 + SQ2 + D_04 + re_B_02
  re_A_01_1 ~ re_SQ1 + SQ2 + D_04 + re_B_02
'

## ============================================================
## 1. 적합도 평가 - MLR 추정
## ============================================================
cat("================================================================\n")
cat("1. 구조모형 적합도 (MLR 추정 - Satorra-Bentler Robust)\n")
cat("================================================================\n")

fit_mlr <- sem(sem_model, data = df, estimator = "MLR")

fi <- fitMeasures(fit_mlr,
                   c("chisq.scaled", "df.scaled", "pvalue.scaled",
                     "cfi.robust", "tli.robust",
                     "rmsea.robust", "rmsea.ci.lower.robust", "rmsea.ci.upper.robust",
                     "srmr"))

cat(sprintf("Chi-square (Satorra-Bentler) = %.3f (df = %.0f, p < .001)\n",
            fi["chisq.scaled"], fi["df.scaled"]))
cat(sprintf("Chi-square/df = %.3f\n", fi["chisq.scaled"] / fi["df.scaled"]))
cat(sprintf("CFI (robust) = %.3f\n", fi["cfi.robust"]))
cat(sprintf("TLI (robust) = %.3f\n", fi["tli.robust"]))
cat(sprintf("RMSEA (robust) = %.3f [%.3f, %.3f]\n",
            fi["rmsea.robust"], fi["rmsea.ci.lower.robust"], fi["rmsea.ci.upper.robust"]))
cat(sprintf("SRMR = %.3f\n", fi["srmr"]))

## ============================================================
## 2. 표준화 경로계수 (MLR 표준오차 기반)
## ============================================================
cat("\n================================================================\n")
cat("2. 구조경로 계수 (MLR 강건 표준오차)\n")
cat("================================================================\n")

std_sol <- standardizedSolution(fit_mlr)
struct <- std_sol[std_sol$op == "~", ]

path_labels <- list(
  "efficacy" = "자원봉사 효능감",
  "wellbeing" = "주관적 안녕감",
  "re_A_01_1" = "자원봉사 참여",
  "D_05" = "주관적 건강", "D_03" = "교육수준",
  "C_05" = "일반적 신뢰", "re_C_06" = "네트워크",
  "re_C_07" = "사회단체활동", "awareness" = "제도인식",
  "re_C_08" = "종교활동", "re_B_04" = "봉사교육경험",
  "re_SQ1" = "성별", "SQ2" = "연령",
  "D_04" = "혼인상태", "re_B_02" = "과거봉사경험"
)
get_label <- function(x) if (x %in% names(path_labels)) path_labels[[x]] else x

print_paths <- function(rows, title) {
  cat(sprintf("\n--- %s ---\n", title))
  for (i in 1:nrow(rows)) {
    sig <- ifelse(rows$pvalue[i] < .001, "***",
           ifelse(rows$pvalue[i] < .01, "**",
           ifelse(rows$pvalue[i] < .05, "*", "n.s.")))
    cat(sprintf("  %s -> %s: beta=%.3f, SE=%.3f, p=%.4f %s\n",
      get_label(rows$rhs[i]), get_label(rows$lhs[i]),
      rows$est.std[i], rows$se[i], rows$pvalue[i], sig))
  }
}

iv_main <- c("D_05","D_03","C_05","re_C_06","re_C_07","awareness","re_C_08","re_B_04")
iv_wb <- c("D_05","D_03","C_05","re_C_06","re_C_07","re_C_08")
ctrl_vars <- c("re_SQ1", "SQ2", "D_04", "re_B_02")

print_paths(struct[struct$lhs == "efficacy" & struct$rhs %in% iv_main, ],
            "연구문제 1: 독립변수 -> 효능감")
print_paths(struct[struct$lhs == "wellbeing" & struct$rhs %in% iv_wb, ],
            "연구문제 2: 독립변수 -> 안녕감")
print_paths(struct[struct$lhs == "re_A_01_1" & struct$rhs %in% iv_main, ],
            "연구문제 3: 독립변수 -> 참여")
print_paths(struct[struct$lhs %in% c("wellbeing", "re_A_01_1") &
                   struct$rhs %in% c("efficacy", "wellbeing"), ],
            "연구문제 4: 매개변수 경로")

cat("\n--- 통제변수 ---\n")
for (dv in c("efficacy", "wellbeing", "re_A_01_1")) {
  ctrl <- struct[struct$lhs == dv & struct$rhs %in% ctrl_vars, ]
  for (i in 1:nrow(ctrl)) {
    sig <- ifelse(ctrl$pvalue[i] < .001, "***",
           ifelse(ctrl$pvalue[i] < .01, "**",
           ifelse(ctrl$pvalue[i] < .05, "*", "n.s.")))
    cat(sprintf("  %s -> %s: beta=%.3f, p=%.4f %s\n",
      get_label(ctrl$rhs[i]), get_label(ctrl$lhs[i]),
      ctrl$est.std[i], ctrl$pvalue[i], sig))
  }
}

## ============================================================
## 3. R-squared
## ============================================================
cat("\n================================================================\n")
cat("3. 설명력 (R-squared)\n")
cat("================================================================\n")
r2 <- lavInspect(fit_mlr, "r2")
cat(sprintf("  자원봉사 효능감: R2 = %.3f\n", r2["efficacy"]))
cat(sprintf("  주관적 안녕감: R2 = %.3f\n", r2["wellbeing"]))
cat(sprintf("  자원봉사 참여: R2 = %.3f\n", r2["re_A_01_1"]))

## ============================================================
## 4. 매개효과 검증 (ML + Bootstrap 5,000회)
##    참고: lavaan에서 MLR 추정은 부트스트랩과 동시 사용 불가
##           따라서 매개효과만 ML + Bootstrap으로 별도 검증
## ============================================================
cat("\n================================================================\n")
cat("4. 매개효과 검증 (ML + Bootstrap 5,000회 백분위 95% CI)\n")
cat("================================================================\n")

sem_mediation <- '
  # 측정모형
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04

  efficacy ~ a1*D_05 + a2*D_03 + a3*C_05 + a4*re_C_06 + a5*re_C_07 + a6*awareness + a7*re_C_08 + a8*re_B_04
  wellbeing ~ c1*D_05 + c2*D_03 + c3*C_05 + c4*re_C_06 + c5*re_C_07 + c6*re_C_08
  re_A_01_1 ~ d1*D_05 + d2*D_03 + d3*C_05 + d4*re_C_06 + d5*re_C_07 + d6*awareness + d7*re_C_08 + d8*re_B_04
  wellbeing ~ b1*efficacy
  re_A_01_1 ~ b2*efficacy
  re_A_01_1 ~ b3*wellbeing

  efficacy ~ re_SQ1 + SQ2 + D_04 + re_B_02
  wellbeing ~ re_SQ1 + SQ2 + D_04 + re_B_02
  re_A_01_1 ~ re_SQ1 + SQ2 + D_04 + re_B_02

  # 단순매개: 독립 -> 효능감 -> 참여
  ind_eff1 := a1*b2; ind_eff2 := a2*b2; ind_eff3 := a3*b2; ind_eff4 := a4*b2
  ind_eff5 := a5*b2; ind_eff6 := a6*b2; ind_eff7 := a7*b2; ind_eff8 := a8*b2

  # 단순매개: 독립 -> 안녕감 -> 참여
  ind_wb1 := c1*b3; ind_wb2 := c2*b3; ind_wb3 := c3*b3
  ind_wb4 := c4*b3; ind_wb5 := c5*b3; ind_wb6 := c6*b3

  # 순차매개: 독립 -> 효능감 -> 안녕감 -> 참여
  serial1 := a1*b1*b3; serial2 := a2*b1*b3; serial3 := a3*b1*b3; serial4 := a4*b1*b3
  serial5 := a5*b1*b3; serial6 := a6*b1*b3; serial7 := a7*b1*b3; serial8 := a8*b1*b3
'

cat("매개효과 모형 추정 중 (ML + Bootstrap 5000회)...\n")
fit_med <- sem(sem_mediation, data = df, estimator = "ML",
               se = "bootstrap", bootstrap = 5000)

med_params <- parameterEstimates(fit_med, boot.ci.type = "perc",
                                  level = 0.95, standardized = TRUE)
defined <- med_params[med_params$op == ":=", ]

iv_labels <- c("주관적건강", "교육수준", "일반적신뢰", "네트워크",
               "사회단체활동", "제도인식", "종교활동", "봉사교육경험")

print_indirect <- function(prefix, n, labels, title) {
  cat(sprintf("\n--- %s ---\n", title))
  for (i in 1:n) {
    row <- defined[defined$lhs == paste0(prefix, i), ]
    sig <- ifelse(row$ci.lower > 0 | row$ci.upper < 0, "유의", "비유의")
    cat(sprintf("  %s: B=%.4f, beta=%.4f, 95%%CI[%.4f, %.4f] %s\n",
      labels[i], row$est, row$std.all, row$ci.lower, row$ci.upper, sig))
  }
}

print_indirect("ind_eff", 8, iv_labels,
               "단순매개: 독립 -> 효능감 -> 참여")
print_indirect("ind_wb", 6, iv_labels[c(1,2,3,4,5,7)],
               "단순매개: 독립 -> 안녕감 -> 참여")
print_indirect("serial", 8, iv_labels,
               "순차매개: 독립 -> 효능감 -> 안녕감 -> 참여")

cat("\n================================================================\n")
cat("분석 완료: MLR(적합도) + ML+Bootstrap(매개효과)\n")
cat("================================================================\n")
