## ============================================================
## 방안 2: 주관적 안녕감 2문항 모형 (행복 + 삶의 만족)
## 박사학위논문 마지막 점검 - 지도교수님 권장 반영
##
## 변경사항: 우울(re_C_02), 걱정(re_C_03) 제외
##           안녕감 잠재변수 = C_01(만족) + C_04(행복) 2문항
## ============================================================

library(lavaan)
library(readxl)

df <- read_excel("data/260414_data_recoded.xlsx")

## ============================================================
## 1. CFA - 측정모형 검증
## ============================================================
cat("================================================================\n")
cat("[방안 2] CFA: 안녕감 2문항 모형\n")
cat("================================================================\n")

cfa_model <- '
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + C_04
'

fit_cfa <- cfa(cfa_model, data = df, estimator = "ML")
fi_cfa <- fitMeasures(fit_cfa,
                       c("chisq","df","pvalue","gfi","cfi","tli","rmsea",
                         "rmsea.ci.lower","rmsea.ci.upper","srmr"))
cat(sprintf("Chi-square = %.3f (df = %.0f, p = %.4f)\n",
            fi_cfa["chisq"], fi_cfa["df"], fi_cfa["pvalue"]))
cat(sprintf("Chi-square/df = %.3f\n", fi_cfa["chisq"] / fi_cfa["df"]))
cat(sprintf("GFI = %.3f\n", fi_cfa["gfi"]))
cat(sprintf("CFI = %.3f\n", fi_cfa["cfi"]))
cat(sprintf("TLI = %.3f\n", fi_cfa["tli"]))
cat(sprintf("RMSEA = %.3f [%.3f, %.3f]\n",
            fi_cfa["rmsea"], fi_cfa["rmsea.ci.lower"], fi_cfa["rmsea.ci.upper"]))
cat(sprintf("SRMR = %.3f\n", fi_cfa["srmr"]))

## AVE/CR 계산
std_load <- standardizedSolution(fit_cfa)
for (lv in c("efficacy", "awareness", "wellbeing")) {
  loadings <- std_load[std_load$op == "=~" & std_load$lhs == lv, "est.std"]
  ave <- mean(loadings^2)
  cr <- (sum(loadings))^2 / ((sum(loadings))^2 + sum(1 - loadings^2))
  cat(sprintf("\n%s: AVE = %.3f, CR = %.3f, 문항수 = %d\n",
              lv, ave, cr, length(loadings)))
}

## ============================================================
## 2. SEM - 구조모형 (MLR 추정)
## ============================================================
cat("\n================================================================\n")
cat("[방안 2] SEM 적합도 (MLR 추정)\n")
cat("================================================================\n")

sem_model <- '
  # 측정모형 (안녕감 2문항)
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + C_04

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

fit_sem <- sem(sem_model, data = df, estimator = "MLR")
fi_sem <- fitMeasures(fit_sem,
                       c("chisq.scaled","df.scaled","pvalue.scaled",
                         "gfi","cfi.robust","tli.robust",
                         "rmsea.robust","rmsea.ci.lower.robust","rmsea.ci.upper.robust",
                         "srmr"))
cat(sprintf("Chi-square (S-B) = %.3f (df = %.0f, p < .001)\n",
            fi_sem["chisq.scaled"], fi_sem["df.scaled"]))
cat(sprintf("Chi-square/df = %.3f\n", fi_sem["chisq.scaled"] / fi_sem["df.scaled"]))
cat(sprintf("GFI = %.3f\n", fi_sem["gfi"]))
cat(sprintf("CFI (robust) = %.3f\n", fi_sem["cfi.robust"]))
cat(sprintf("TLI (robust) = %.3f\n", fi_sem["tli.robust"]))
cat(sprintf("RMSEA (robust) = %.3f [%.3f, %.3f]\n",
            fi_sem["rmsea.robust"], fi_sem["rmsea.ci.lower.robust"], fi_sem["rmsea.ci.upper.robust"]))
cat(sprintf("SRMR = %.3f\n", fi_sem["srmr"]))

## 표준화 경로계수
cat("\n--- 주요 경로계수 (표준화) ---\n")
std_sol <- standardizedSolution(fit_sem)

path_labels <- list(
  "efficacy" = "효능감", "wellbeing" = "안녕감",
  "re_A_01_1" = "참여", "D_05" = "건강", "D_03" = "교육수준",
  "C_05" = "신뢰", "re_C_06" = "네트워크", "re_C_07" = "사회단체",
  "awareness" = "제도인식", "re_C_08" = "종교활동", "re_B_04" = "봉사교육",
  "re_SQ1" = "성별", "SQ2" = "연령", "D_04" = "혼인상태", "re_B_02" = "과거봉사"
)
get_label <- function(x) if (x %in% names(path_labels)) path_labels[[x]] else x

main_iv <- c("D_05","D_03","C_05","re_C_06","re_C_07","awareness","re_C_08","re_B_04")
iv_wb <- c("D_05","D_03","C_05","re_C_06","re_C_07","re_C_08")

for (dv in c("efficacy", "wellbeing", "re_A_01_1")) {
  cat(sprintf("\n[%s 대상 경로]\n", get_label(dv)))
  iv_list <- if (dv == "wellbeing") iv_wb else main_iv
  rows <- std_sol[std_sol$op == "~" & std_sol$lhs == dv & std_sol$rhs %in% iv_list, ]
  for (i in 1:nrow(rows)) {
    sig <- ifelse(rows$pvalue[i] < .001, "***",
           ifelse(rows$pvalue[i] < .01, "**",
           ifelse(rows$pvalue[i] < .05, "*", "n.s.")))
    cat(sprintf("  %s -> %s: beta=%.3f, p=%.4f %s\n",
      get_label(rows$rhs[i]), get_label(rows$lhs[i]),
      rows$est.std[i], rows$pvalue[i], sig))
  }
}

# 매개경로
cat("\n--- 매개변수 경로 ---\n")
med_paths <- list(c("wellbeing","efficacy"), c("re_A_01_1","efficacy"), c("re_A_01_1","wellbeing"))
for (p in med_paths) {
  row <- std_sol[std_sol$op == "~" & std_sol$lhs == p[1] & std_sol$rhs == p[2], ]
  sig <- ifelse(row$pvalue[1] < .001, "***",
         ifelse(row$pvalue[1] < .01, "**",
         ifelse(row$pvalue[1] < .05, "*", "n.s.")))
  cat(sprintf("  %s -> %s: beta=%.3f, p=%.4f %s\n",
    get_label(row$rhs[1]), get_label(row$lhs[1]),
    row$est.std[1], row$pvalue[1], sig))
}

## R-squared
cat("\n--- R-squared ---\n")
r2 <- lavInspect(fit_sem, "r2")
cat(sprintf("효능감: R2 = %.3f\n", r2["efficacy"]))
cat(sprintf("안녕감: R2 = %.3f\n", r2["wellbeing"]))
cat(sprintf("참여: R2 = %.3f\n", r2["re_A_01_1"]))

## ============================================================
## 3. 매개효과 (ML + Bootstrap 5,000회)
## ============================================================
cat("\n================================================================\n")
cat("[방안 2] 매개효과 (ML + Bootstrap 5,000회)\n")
cat("================================================================\n")

sem_mediation <- '
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + C_04

  efficacy ~ a1*D_05 + a2*D_03 + a3*C_05 + a4*re_C_06 + a5*re_C_07 + a6*awareness + a7*re_C_08 + a8*re_B_04
  wellbeing ~ c1*D_05 + c2*D_03 + c3*C_05 + c4*re_C_06 + c5*re_C_07 + c6*re_C_08
  re_A_01_1 ~ d1*D_05 + d2*D_03 + d3*C_05 + d4*re_C_06 + d5*re_C_07 + d6*awareness + d7*re_C_08 + d8*re_B_04
  wellbeing ~ b1*efficacy
  re_A_01_1 ~ b2*efficacy
  re_A_01_1 ~ b3*wellbeing

  efficacy ~ re_SQ1 + SQ2 + D_04 + re_B_02
  wellbeing ~ re_SQ1 + SQ2 + D_04 + re_B_02
  re_A_01_1 ~ re_SQ1 + SQ2 + D_04 + re_B_02

  ind_eff1 := a1*b2; ind_eff2 := a2*b2; ind_eff3 := a3*b2; ind_eff4 := a4*b2
  ind_eff5 := a5*b2; ind_eff6 := a6*b2; ind_eff7 := a7*b2; ind_eff8 := a8*b2
  ind_wb1 := c1*b3; ind_wb2 := c2*b3; ind_wb3 := c3*b3
  ind_wb4 := c4*b3; ind_wb5 := c5*b3; ind_wb6 := c6*b3
  serial1 := a1*b1*b3; serial2 := a2*b1*b3; serial3 := a3*b1*b3; serial4 := a4*b1*b3
  serial5 := a5*b1*b3; serial6 := a6*b1*b3; serial7 := a7*b1*b3; serial8 := a8*b1*b3
'

cat("매개효과 부트스트랩 중...\n")
fit_med <- sem(sem_mediation, data = df, estimator = "ML",
               se = "bootstrap", bootstrap = 5000)

med_params <- parameterEstimates(fit_med, boot.ci.type = "perc",
                                  level = 0.95, standardized = TRUE)
defined <- med_params[med_params$op == ":=", ]

iv_labels <- c("주관적건강","교육수준","일반적신뢰","네트워크",
               "사회단체활동","제도인식","종교활동","봉사교육경험")
iv_wb_labels <- c("주관적건강","교육수준","일반적신뢰","네트워크","사회단체활동","종교활동")

cat("\n--- 단순매개: 효능감 ---\n")
for (i in 1:8) {
  row <- defined[defined$lhs == paste0("ind_eff", i), ]
  sig <- ifelse(row$ci.lower > 0 | row$ci.upper < 0, "유의", "비유의")
  cat(sprintf("  %s: beta=%.4f, 95%%CI[%.4f, %.4f] %s\n",
    iv_labels[i], row$std.all, row$ci.lower, row$ci.upper, sig))
}

cat("\n--- 단순매개: 안녕감 ---\n")
for (i in 1:6) {
  row <- defined[defined$lhs == paste0("ind_wb", i), ]
  sig <- ifelse(row$ci.lower > 0 | row$ci.upper < 0, "유의", "비유의")
  cat(sprintf("  %s: beta=%.4f, 95%%CI[%.4f, %.4f] %s\n",
    iv_wb_labels[i], row$std.all, row$ci.lower, row$ci.upper, sig))
}

cat("\n--- 순차매개 ---\n")
for (i in 1:8) {
  row <- defined[defined$lhs == paste0("serial", i), ]
  sig <- ifelse(row$ci.lower > 0 | row$ci.upper < 0, "유의", "비유의")
  cat(sprintf("  %s: beta=%.4f, 95%%CI[%.4f, %.4f] %s\n",
    iv_labels[i], row$std.all, row$ci.lower, row$ci.upper, sig))
}

cat("\n================================================================\n")
cat("[방안 2] 분석 완료\n")
cat("================================================================\n")
