library(lavaan)
library(readxl)

df <- read_excel("260414_data_recoded.xlsx")

# ========================================
# 구조방정식 모형 정의
# ========================================
sem_model <- '
  # ========== 측정모형 ==========
  # 잠재변수 1: 자원봉사 효능감
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10

  # 잠재변수 2: 자원봉사제도 인식
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8

  # 잠재변수 3: 주관적 안녕감
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04

  # ========== 구조모형 ==========
  # 연구문제 1: 독립변수 -> 자원봉사 효능감 (8개 경로)
  efficacy ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + awareness + re_C_08 + re_B_04

  # 연구문제 2: 독립변수 -> 주관적 안녕감 (6개 경로, 제도인식/교육경험 제외)
  wellbeing ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + re_C_08

  # 연구문제 3: 독립변수 -> 자원봉사 참여 (8개 경로)
  re_A_01_1 ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + awareness + re_C_08 + re_B_04

  # 연구문제 4: 매개변수 경로
  wellbeing ~ efficacy          # 효능감 -> 안녕감
  re_A_01_1 ~ efficacy          # 효능감 -> 참여
  re_A_01_1 ~ wellbeing         # 안녕감 -> 참여

  # 통제변수
  efficacy ~ re_SQ1 + SQ2 + D_04 + re_B_02
  wellbeing ~ re_SQ1 + SQ2 + D_04 + re_B_02
  re_A_01_1 ~ re_SQ1 + SQ2 + D_04 + re_B_02
'

# ========================================
# 모형 추정 (ML + Bootstrap 5000회)
# ========================================
cat("모형 추정 중 (Bootstrap 5000회)...\n")
fit <- sem(sem_model, data = df, estimator = "ML",
           se = "bootstrap", bootstrap = 5000)

# ========================================
# 1. 구조모형 적합도
# ========================================
cat("\n================================================================\n")
cat("1. 구조모형 적합도\n")
cat("================================================================\n")
fi <- fitMeasures(fit, c("chisq", "df", "pvalue", "gfi", "cfi", "tli", "rmsea", "rmsea.ci.lower", "rmsea.ci.upper", "srmr"))
cat(sprintf("Chi-square = %.3f (df = %.0f, p < .001)\n", fi["chisq"], fi["df"]))
cat(sprintf("Chi-square/df = %.3f\n", fi["chisq"] / fi["df"]))
cat(sprintf("GFI = %.3f\n", fi["gfi"]))
cat(sprintf("CFI = %.3f\n", fi["cfi"]))
cat(sprintf("TLI = %.3f\n", fi["tli"]))
cat(sprintf("RMSEA = %.3f [%.3f, %.3f]\n", fi["rmsea"], fi["rmsea.ci.lower"], fi["rmsea.ci.upper"]))
cat(sprintf("SRMR = %.3f\n", fi["srmr"]))

# ========================================
# 2. 구조경로 계수 (표준화)
# ========================================
cat("\n================================================================\n")
cat("2. 구조경로 계수 (표준화)\n")
cat("================================================================\n")

std_sol <- standardizedSolution(fit)
struct <- std_sol[std_sol$op == "~", ]

# 경로별 라벨
path_labels <- list(
  "efficacy" = "자원봉사 효능감",
  "wellbeing" = "주관적 안녕감",
  "re_A_01_1" = "자원봉사 참여",
  "D_05" = "주관적 건강",
  "D_03" = "교육수준",
  "C_05" = "일반적 신뢰",
  "re_C_06" = "네트워크",
  "re_C_07" = "사회단체활동",
  "awareness" = "제도인식",
  "re_C_08" = "종교활동",
  "re_B_04" = "봉사교육경험",
  "re_SQ1" = "성별",
  "SQ2" = "연령",
  "D_04" = "혼인상태",
  "re_B_02" = "과거봉사경험"
)

get_label <- function(x) {
  if (x %in% names(path_labels)) return(path_labels[[x]])
  return(x)
}

# 연구문제별 출력
cat("\n--- 연구문제 1: 독립변수 -> 효능감 ---\n")
rq1 <- struct[struct$lhs == "efficacy" & struct$rhs %in% c("D_05","D_03","C_05","re_C_06","re_C_07","awareness","re_C_08","re_B_04"), ]
for (i in 1:nrow(rq1)) {
  sig <- ifelse(rq1$pvalue[i] < .001, "***", ifelse(rq1$pvalue[i] < .01, "**", ifelse(rq1$pvalue[i] < .05, "*", "n.s.")))
  cat(sprintf("  %s -> %s: beta=%.3f, SE=%.3f, p=%.4f %s\n",
    get_label(rq1$rhs[i]), get_label(rq1$lhs[i]), rq1$est.std[i], rq1$se[i], rq1$pvalue[i], sig))
}

cat("\n--- 연구문제 2: 독립변수 -> 안녕감 ---\n")
rq2 <- struct[struct$lhs == "wellbeing" & struct$rhs %in% c("D_05","D_03","C_05","re_C_06","re_C_07","re_C_08"), ]
for (i in 1:nrow(rq2)) {
  sig <- ifelse(rq2$pvalue[i] < .001, "***", ifelse(rq2$pvalue[i] < .01, "**", ifelse(rq2$pvalue[i] < .05, "*", "n.s.")))
  cat(sprintf("  %s -> %s: beta=%.3f, SE=%.3f, p=%.4f %s\n",
    get_label(rq2$rhs[i]), get_label(rq2$lhs[i]), rq2$est.std[i], rq2$se[i], rq2$pvalue[i], sig))
}

cat("\n--- 연구문제 3: 독립변수 -> 참여 ---\n")
rq3 <- struct[struct$lhs == "re_A_01_1" & struct$rhs %in% c("D_05","D_03","C_05","re_C_06","re_C_07","awareness","re_C_08","re_B_04"), ]
for (i in 1:nrow(rq3)) {
  sig <- ifelse(rq3$pvalue[i] < .001, "***", ifelse(rq3$pvalue[i] < .01, "**", ifelse(rq3$pvalue[i] < .05, "*", "n.s.")))
  cat(sprintf("  %s -> %s: beta=%.3f, SE=%.3f, p=%.4f %s\n",
    get_label(rq3$rhs[i]), get_label(rq3$lhs[i]), rq3$est.std[i], rq3$se[i], rq3$pvalue[i], sig))
}

cat("\n--- 연구문제 4: 매개변수 경로 ---\n")
rq4_paths <- list(
  c("wellbeing", "efficacy"),
  c("re_A_01_1", "efficacy"),
  c("re_A_01_1", "wellbeing")
)
for (p in rq4_paths) {
  row <- struct[struct$lhs == p[1] & struct$rhs == p[2], ]
  if (nrow(row) > 0) {
    sig <- ifelse(row$pvalue[1] < .001, "***", ifelse(row$pvalue[1] < .01, "**", ifelse(row$pvalue[1] < .05, "*", "n.s.")))
    cat(sprintf("  %s -> %s: beta=%.3f, SE=%.3f, p=%.4f %s\n",
      get_label(row$rhs[1]), get_label(row$lhs[1]), row$est.std[1], row$se[1], row$pvalue[1], sig))
  }
}

cat("\n--- 통제변수 ---\n")
ctrl_vars <- c("re_SQ1", "SQ2", "D_04", "re_B_02")
for (dv in c("efficacy", "wellbeing", "re_A_01_1")) {
  ctrl <- struct[struct$lhs == dv & struct$rhs %in% ctrl_vars, ]
  for (i in 1:nrow(ctrl)) {
    sig <- ifelse(ctrl$pvalue[i] < .001, "***", ifelse(ctrl$pvalue[i] < .01, "**", ifelse(ctrl$pvalue[i] < .05, "*", "n.s.")))
    cat(sprintf("  %s -> %s: beta=%.3f, p=%.4f %s\n",
      get_label(ctrl$rhs[i]), get_label(ctrl$lhs[i]), ctrl$est.std[i], ctrl$pvalue[i], sig))
  }
}

# ========================================
# 3. R-squared
# ========================================
cat("\n================================================================\n")
cat("3. 설명력 (R-squared)\n")
cat("================================================================\n")
r2 <- lavInspect(fit, "r2")
cat(sprintf("  자원봉사 효능감: R2 = %.3f\n", r2["efficacy"]))
cat(sprintf("  주관적 안녕감: R2 = %.3f\n", r2["wellbeing"]))
cat(sprintf("  자원봉사 참여: R2 = %.3f\n", r2["re_A_01_1"]))

# ========================================
# 4. 매개효과 검증 (연구문제 5)
# ========================================
cat("\n================================================================\n")
cat("4. 매개효과 검증 (Bootstrap 95% CI)\n")
cat("================================================================\n")

# 매개효과 모형 (라벨 추가)
sem_mediation <- '
  # 측정모형
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04

  # 독립변수 -> 효능감
  efficacy ~ a1*D_05 + a2*D_03 + a3*C_05 + a4*re_C_06 + a5*re_C_07 + a6*awareness + a7*re_C_08 + a8*re_B_04

  # 독립변수 -> 안녕감
  wellbeing ~ c1*D_05 + c2*D_03 + c3*C_05 + c4*re_C_06 + c5*re_C_07 + c6*re_C_08

  # 독립변수 -> 참여
  re_A_01_1 ~ d1*D_05 + d2*D_03 + d3*C_05 + d4*re_C_06 + d5*re_C_07 + d6*awareness + d7*re_C_08 + d8*re_B_04

  # 매개경로
  wellbeing ~ b1*efficacy
  re_A_01_1 ~ b2*efficacy
  re_A_01_1 ~ b3*wellbeing

  # 통제변수
  efficacy ~ re_SQ1 + SQ2 + D_04 + re_B_02
  wellbeing ~ re_SQ1 + SQ2 + D_04 + re_B_02
  re_A_01_1 ~ re_SQ1 + SQ2 + D_04 + re_B_02

  # ===== 간접효과 정의 =====
  # 단순매개: 독립 -> 효능감 -> 참여
  ind_eff1 := a1*b2   # 건강 -> 효능감 -> 참여
  ind_eff2 := a2*b2   # 교육 -> 효능감 -> 참여
  ind_eff3 := a3*b2   # 신뢰 -> 효능감 -> 참여
  ind_eff4 := a4*b2   # 네트워크 -> 효능감 -> 참여
  ind_eff5 := a5*b2   # 사회단체 -> 효능감 -> 참여
  ind_eff6 := a6*b2   # 제도인식 -> 효능감 -> 참여
  ind_eff7 := a7*b2   # 종교 -> 효능감 -> 참여
  ind_eff8 := a8*b2   # 교육경험 -> 효능감 -> 참여

  # 단순매개: 독립 -> 안녕감 -> 참여
  ind_wb1 := c1*b3    # 건강 -> 안녕감 -> 참여
  ind_wb2 := c2*b3    # 교육 -> 안녕감 -> 참여
  ind_wb3 := c3*b3    # 신뢰 -> 안녕감 -> 참여
  ind_wb4 := c4*b3    # 네트워크 -> 안녕감 -> 참여
  ind_wb5 := c5*b3    # 사회단체 -> 안녕감 -> 참여
  ind_wb6 := c6*b3    # 종교 -> 안녕감 -> 참여

  # 순차매개: 독립 -> 효능감 -> 안녕감 -> 참여
  serial1 := a1*b1*b3  # 건강
  serial2 := a2*b1*b3  # 교육
  serial3 := a3*b1*b3  # 신뢰
  serial4 := a4*b1*b3  # 네트워크
  serial5 := a5*b1*b3  # 사회단체
  serial6 := a6*b1*b3  # 제도인식
  serial7 := a7*b1*b3  # 종교
  serial8 := a8*b1*b3  # 교육경험
'

cat("매개효과 모형 추정 중 (Bootstrap 5000회)...\n")
fit_med <- sem(sem_mediation, data = df, estimator = "ML",
               se = "bootstrap", bootstrap = 5000)

# 간접효과 결과 추출
med_params <- parameterEstimates(fit_med, boot.ci.type = "perc", level = 0.95, standardized = TRUE)
defined <- med_params[med_params$op == ":=", ]

iv_labels <- c("주관적건강", "교육수준", "일반적신뢰", "네트워크", "사회단체활동", "제도인식", "종교활동", "봉사교육경험")

cat("\n--- 단순매개: 독립 -> 효능감 -> 참여 ---\n")
for (i in 1:8) {
  row <- defined[defined$lhs == paste0("ind_eff", i), ]
  sig <- ifelse(row$ci.lower > 0 | row$ci.upper < 0, "유의", "비유의")
  cat(sprintf("  %s: B=%.4f, beta=%.4f, 95%%CI[%.4f, %.4f] %s\n",
    iv_labels[i], row$est, row$std.all, row$ci.lower, row$ci.upper, sig))
}

cat("\n--- 단순매개: 독립 -> 안녕감 -> 참여 ---\n")
for (i in 1:6) {
  row <- defined[defined$lhs == paste0("ind_wb", i), ]
  sig <- ifelse(row$ci.lower > 0 | row$ci.upper < 0, "유의", "비유의")
  cat(sprintf("  %s: B=%.4f, beta=%.4f, 95%%CI[%.4f, %.4f] %s\n",
    iv_labels[i], row$est, row$std.all, row$ci.lower, row$ci.upper, sig))
}

cat("\n--- 순차매개: 독립 -> 효능감 -> 안녕감 -> 참여 ---\n")
for (i in 1:8) {
  row <- defined[defined$lhs == paste0("serial", i), ]
  sig <- ifelse(row$ci.lower > 0 | row$ci.upper < 0, "유의", "비유의")
  cat(sprintf("  %s: B=%.4f, beta=%.4f, 95%%CI[%.4f, %.4f] %s\n",
    iv_labels[i], row$est, row$std.all, row$ci.lower, row$ci.upper, sig))
}
