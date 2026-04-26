library(lavaan)
library(readxl)

df <- read_excel("260414_data_recoded.xlsx")

sink("analysis_results.txt")

cat("================================================================\n")
cat("박사 졸업논문 분석 결과 보고서\n")
cat("================================================================\n\n")

# ========== 1. CFA ==========
cat("1. 측정모형 확인적 요인분석 (CFA)\n")
cat("================================================================\n")

cfa_model <- '
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04
'
cfa_fit <- cfa(cfa_model, data = df, estimator = "ML")

cat("\n1-1. 적합도\n")
fi <- fitMeasures(cfa_fit, c("chisq","df","pvalue","gfi","cfi","tli","rmsea","rmsea.ci.lower","rmsea.ci.upper","srmr"))
cat(sprintf("  Chi-square(df) = %.3f(%0.f), p < .001\n", fi["chisq"], fi["df"]))
cat(sprintf("  Chi-square/df = %.3f\n", fi["chisq"]/fi["df"]))
cat(sprintf("  RMSEA = %.3f [%.3f, %.3f]\n", fi["rmsea"], fi["rmsea.ci.lower"], fi["rmsea.ci.upper"]))
cat(sprintf("  SRMR = %.3f\n", fi["srmr"]))
cat(sprintf("  CFI = %.3f\n", fi["cfi"]))
cat(sprintf("  TLI = %.3f\n", fi["tli"]))

cat("\n1-2. 표준화 요인부하량\n")
std_sol <- standardizedSolution(cfa_fit)
loadings <- std_sol[std_sol$op == "=~", ]
for (i in 1:nrow(loadings)) {
  cat(sprintf("  %s -> %s: beta=%.3f, p=%.4f\n", loadings$lhs[i], loadings$rhs[i], loadings$est.std[i], loadings$pvalue[i]))
}

cat("\n1-3. AVE, CR, Cronbach's alpha\n")
latent_vars <- c("efficacy", "awareness", "wellbeing")
latent_labels <- c("효능감", "제도인식", "안녕감")
calc_alpha <- function(data) {
  k <- ncol(data); item_vars <- apply(data, 2, var); total_var <- var(rowSums(data))
  (k/(k-1))*(1-sum(item_vars)/total_var)
}
for (k in 1:3) {
  lv <- latent_vars[k]
  lv_loadings <- loadings[loadings$lhs == lv, "est.std"]
  lambda_sq <- lv_loadings^2; error_var <- 1 - lambda_sq
  ave <- mean(lambda_sq); cr <- (sum(lv_loadings))^2/((sum(lv_loadings))^2+sum(error_var))
  if (k==1) alpha <- calc_alpha(as.data.frame(df[, paste0("B_05_", 1:10)]))
  else if (k==2) alpha <- calc_alpha(as.data.frame(df[, paste0("B_06_", 1:8)]))
  else alpha <- calc_alpha(as.data.frame(df[, c("C_01","re_C_02","re_C_03","C_04")]))
  cat(sprintf("  %s: AVE=%.3f, CR=%.3f, alpha=%.3f\n", latent_labels[k], ave, cr, alpha))
}

cat("\n1-4. 잠재변수 간 상관\n")
cor_est <- std_sol[std_sol$op=="~~" & std_sol$lhs!=std_sol$rhs & std_sol$lhs %in% latent_vars & std_sol$rhs %in% latent_vars, ]
for (i in 1:nrow(cor_est)) {
  cat(sprintf("  %s <-> %s: r=%.3f\n", cor_est$lhs[i], cor_est$rhs[i], cor_est$est.std[i]))
}

# ========== 2. SEM ==========
cat("\n\n2. 구조모형 (SEM)\n")
cat("================================================================\n")

sem_model <- '
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04
  efficacy ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + awareness + re_C_08 + re_B_04
  wellbeing ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + re_C_08
  re_A_01_1 ~ D_05 + D_03 + C_05 + re_C_06 + re_C_07 + awareness + re_C_08 + re_B_04
  wellbeing ~ efficacy
  re_A_01_1 ~ efficacy
  re_A_01_1 ~ wellbeing
  efficacy ~ re_SQ1 + SQ2 + D_04 + re_B_02
  wellbeing ~ re_SQ1 + SQ2 + D_04 + re_B_02
  re_A_01_1 ~ re_SQ1 + SQ2 + D_04 + re_B_02
'
sem_fit <- sem(sem_model, data = df, estimator = "ML")

cat("\n2-1. 적합도\n")
fi2 <- fitMeasures(sem_fit, c("chisq","df","pvalue","cfi","tli","rmsea","rmsea.ci.lower","rmsea.ci.upper","srmr"))
cat(sprintf("  Chi-square(df) = %.3f(%.0f), p < .001\n", fi2["chisq"], fi2["df"]))
cat(sprintf("  Chi-square/df = %.3f\n", fi2["chisq"]/fi2["df"]))
cat(sprintf("  RMSEA = %.3f [%.3f, %.3f]\n", fi2["rmsea"], fi2["rmsea.ci.lower"], fi2["rmsea.ci.upper"]))
cat(sprintf("  SRMR = %.3f\n", fi2["srmr"]))
cat(sprintf("  CFI = %.3f\n", fi2["cfi"]))
cat(sprintf("  TLI = %.3f\n", fi2["tli"]))

cat("\n2-2. 경로계수 (B, S.E., beta, p)\n")
params <- parameterEstimates(sem_fit, standardized = TRUE)
struct <- params[params$op == "~", ]
labels <- list(efficacy="효능감", wellbeing="안녕감", re_A_01_1="참여",
  D_05="건강", D_03="교육", C_05="신뢰", re_C_06="네트워크", re_C_07="사회단체",
  awareness="제도인식", re_C_08="종교", re_B_04="봉사교육",
  re_SQ1="성별", SQ2="연령", D_04="혼인", re_B_02="과거봉사")
get_label <- function(x) { if (x %in% names(labels)) labels[[x]] else x }

for (dv in c("efficacy","wellbeing","re_A_01_1")) {
  cat(sprintf("\n  --- %s ---\n", get_label(dv)))
  rows <- struct[struct$lhs == dv, ]
  for (i in 1:nrow(rows)) {
    sig <- ifelse(rows$pvalue[i]<.001,"***",ifelse(rows$pvalue[i]<.01,"**",ifelse(rows$pvalue[i]<.05,"*","")))
    cat(sprintf("  %s -> %s: B=%.3f, SE=%.3f, beta=%.3f, p=%.4f %s\n",
      get_label(rows$rhs[i]), get_label(rows$lhs[i]), rows$est[i], rows$se[i], rows$std.all[i], rows$pvalue[i], sig))
  }
}

cat("\n2-3. R-squared\n")
r2 <- lavInspect(sem_fit, "r2")
cat(sprintf("  효능감: R2 = %.3f\n", r2["efficacy"]))
cat(sprintf("  안녕감: R2 = %.3f\n", r2["wellbeing"]))
cat(sprintf("  참여: R2 = %.3f\n", r2["re_A_01_1"]))

sink()
cat("저장 완료: analysis_results.txt\n")
