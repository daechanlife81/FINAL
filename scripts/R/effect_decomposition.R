library(lavaan)
library(readxl)

df <- read_excel("260414_data_recoded.xlsx")

sem_med <- '
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04

  # 독립 -> 효능감
  efficacy ~ a1*D_05 + a2*D_03 + a3*C_05 + a4*re_C_06 + a5*re_C_07 + a6*awareness + a7*re_C_08 + a8*re_B_04

  # 독립 -> 안녕감
  wellbeing ~ c1*D_05 + c2*D_03 + c3*C_05 + c4*re_C_06 + c5*re_C_07 + c6*re_C_08

  # 독립 -> 참여
  re_A_01_1 ~ d1*D_05 + d2*D_03 + d3*C_05 + d4*re_C_06 + d5*re_C_07 + d6*awareness + d7*re_C_08 + d8*re_B_04

  # 매개경로
  wellbeing ~ b1*efficacy
  re_A_01_1 ~ b2*efficacy
  re_A_01_1 ~ b3*wellbeing

  # 통제변수
  efficacy ~ re_SQ1 + SQ2 + D_04 + re_B_02
  wellbeing ~ re_SQ1 + SQ2 + D_04 + re_B_02
  re_A_01_1 ~ re_SQ1 + SQ2 + D_04 + re_B_02

  # 간접효과 (a) X->효능감->참여
  ind_a1 := a1*b2
  ind_a2 := a2*b2
  ind_a3 := a3*b2
  ind_a4 := a4*b2
  ind_a5 := a5*b2
  ind_a6 := a6*b2
  ind_a7 := a7*b2
  ind_a8 := a8*b2

  # 간접효과 (b) X->안녕감->참여
  ind_b1 := c1*b3
  ind_b2 := c2*b3
  ind_b3 := c3*b3
  ind_b4 := c4*b3
  ind_b5 := c5*b3
  ind_b6 := c6*b3

  # 간접효과 (c) X->효능감->안녕감->참여
  ind_c1 := a1*b1*b3
  ind_c2 := a2*b1*b3
  ind_c3 := a3*b1*b3
  ind_c4 := a4*b1*b3
  ind_c5 := a5*b1*b3
  ind_c6 := a6*b1*b3
  ind_c7 := a7*b1*b3
  ind_c8 := a8*b1*b3

  # 총간접효과
  total_ind1 := a1*b2 + c1*b3 + a1*b1*b3
  total_ind2 := a2*b2 + c2*b3 + a2*b1*b3
  total_ind3 := a3*b2 + c3*b3 + a3*b1*b3
  total_ind4 := a4*b2 + c4*b3 + a4*b1*b3
  total_ind5 := a5*b2 + c5*b3 + a5*b1*b3
  total_ind6 := a6*b2 + a6*b1*b3
  total_ind7 := a7*b2 + c6*b3 + a7*b1*b3
  total_ind8 := a8*b2 + a8*b1*b3

  # 총효과
  total1 := d1 + a1*b2 + c1*b3 + a1*b1*b3
  total2 := d2 + a2*b2 + c2*b3 + a2*b1*b3
  total3 := d3 + a3*b2 + c3*b3 + a3*b1*b3
  total4 := d4 + a4*b2 + c4*b3 + a4*b1*b3
  total5 := d5 + a5*b2 + c5*b3 + a5*b1*b3
  total6 := d6 + a6*b2 + a6*b1*b3
  total7 := d7 + a7*b2 + c6*b3 + a7*b1*b3
  total8 := d8 + a8*b2 + a8*b1*b3
'

cat("Bootstrap 5000회 실행 중...\n")
fit <- sem(sem_med, data = df, estimator = "ML", se = "bootstrap", bootstrap = 5000)

params <- parameterEstimates(fit, boot.ci.type = "perc", level = 0.95, standardized = TRUE)
defined <- params[params$op == ":=", ]

iv_labels <- c("주관적건강", "교육수준", "일반적신뢰", "네트워크", "사회단체활동", "제도인식", "종교활동", "봉사교육경험")

# 직접효과
struct <- params[params$op == "~" & params$lhs == "re_A_01_1", ]

cat("\n================================================================\n")
cat("효과분해 결과 (표준화 계수)\n")
cat("================================================================\n")
cat(sprintf("%-14s %8s %8s %8s %8s %8s %10s %10s\n",
  "변수", "직접", "(a)", "(b)", "(c)", "총간접", "총효과", ""))
cat("----------------------------------------------------------------\n")

for (i in 1:8) {
  # 직접효과
  d_var <- c("D_05","D_03","C_05","re_C_06","re_C_07","awareness","re_C_08","re_B_04")[i]
  d_row <- struct[struct$rhs == d_var, ]
  direct <- d_row$std.all

  # 간접효과 (a)
  a_row <- defined[defined$lhs == paste0("ind_a", i), ]
  ind_a <- a_row$std.all
  a_lo <- a_row$ci.lower
  a_hi <- a_row$ci.upper
  a_sig <- ifelse(a_lo > 0 | a_hi < 0, "*", "")

  # 간접효과 (b) - 제도인식, 봉사교육은 안녕감 직접경로 없음
  if (i <= 5) {
    b_row <- defined[defined$lhs == paste0("ind_b", i), ]
    ind_b <- b_row$std.all
    b_lo <- b_row$ci.lower
    b_hi <- b_row$ci.upper
    b_sig <- ifelse(b_lo > 0 | b_hi < 0, "*", "")
  } else if (i == 7) {
    b_row <- defined[defined$lhs == "ind_b6", ]
    ind_b <- b_row$std.all
    b_lo <- b_row$ci.lower
    b_hi <- b_row$ci.upper
    b_sig <- ifelse(b_lo > 0 | b_hi < 0, "*", "")
  } else {
    ind_b <- NA
    b_sig <- "-"
  }

  # 간접효과 (c)
  c_row <- defined[defined$lhs == paste0("ind_c", i), ]
  ind_c <- c_row$std.all
  c_lo <- c_row$ci.lower
  c_hi <- c_row$ci.upper
  c_sig <- ifelse(c_lo > 0 | c_hi < 0, "*", "")

  # 총간접효과
  ti_row <- defined[defined$lhs == paste0("total_ind", i), ]
  total_ind <- ti_row$std.all
  ti_lo <- ti_row$ci.lower
  ti_hi <- ti_row$ci.upper
  ti_sig <- ifelse(ti_lo > 0 | ti_hi < 0, "*", "")

  # 총효과
  t_row <- defined[defined$lhs == paste0("total", i), ]
  total_eff <- t_row$std.all

  if (is.na(ind_b)) {
    cat(sprintf("%-14s %8.3f %8.3f%s %8s %8.3f%s %8.3f%s %8.3f\n",
      iv_labels[i], direct, ind_a, a_sig, paste0("-"), ind_c, c_sig, total_ind, ti_sig, total_eff))
  } else {
    cat(sprintf("%-14s %8.3f %8.3f%s %8.3f%s %8.3f%s %8.3f%s %8.3f\n",
      iv_labels[i], direct, ind_a, a_sig, ind_b, b_sig, ind_c, c_sig, total_ind, ti_sig, total_eff))
  }
}

# CI 상세
cat("\n================================================================\n")
cat("간접효과 95% CI 상세\n")
cat("================================================================\n")
for (i in 1:8) {
  cat(sprintf("\n--- %s ---\n", iv_labels[i]))

  a_row <- defined[defined$lhs == paste0("ind_a", i), ]
  cat(sprintf("  (a) beta=%.4f, CI[%.4f, %.4f]\n", a_row$std.all, a_row$ci.lower, a_row$ci.upper))

  if (i <= 5) {
    b_row <- defined[defined$lhs == paste0("ind_b", i), ]
    cat(sprintf("  (b) beta=%.4f, CI[%.4f, %.4f]\n", b_row$std.all, b_row$ci.lower, b_row$ci.upper))
  } else if (i == 7) {
    b_row <- defined[defined$lhs == "ind_b6", ]
    cat(sprintf("  (b) beta=%.4f, CI[%.4f, %.4f]\n", b_row$std.all, b_row$ci.lower, b_row$ci.upper))
  } else {
    cat("  (b) - (경로 미설정)\n")
  }

  c_row <- defined[defined$lhs == paste0("ind_c", i), ]
  cat(sprintf("  (c) beta=%.4f, CI[%.4f, %.4f]\n", c_row$std.all, c_row$ci.lower, c_row$ci.upper))

  ti_row <- defined[defined$lhs == paste0("total_ind", i), ]
  cat(sprintf("  총간접: beta=%.4f, CI[%.4f, %.4f]\n", ti_row$std.all, ti_row$ci.lower, ti_row$ci.upper))

  t_row <- defined[defined$lhs == paste0("total", i), ]
  cat(sprintf("  총효과: beta=%.4f\n", t_row$std.all))
}
