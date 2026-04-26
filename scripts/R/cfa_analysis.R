library(lavaan)
library(readxl)

df <- read_excel("260414_data_recoded.xlsx")

# 측정모형 정의
model <- '
  # 잠재변수 1: 자원봉사 효능감
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10

  # 잠재변수 2: 자원봉사제도 인식
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8

  # 잠재변수 3: 주관적 안녕감
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04
'

# CFA 실행 (ML 추정)
fit <- cfa(model, data = df, estimator = "ML")

# 1. 모형 적합도
cat("========================================\n")
cat("1. 측정모형 적합도 지수\n")
cat("========================================\n")
fi <- fitMeasures(fit, c("chisq", "df", "pvalue", "chisq.scaled", "gfi", "cfi", "tli", "rmsea", "rmsea.ci.lower", "rmsea.ci.upper", "srmr"))
cat(sprintf("Chi-square = %.3f\n", fi["chisq"]))
cat(sprintf("df = %.0f\n", fi["df"]))
cat(sprintf("p-value = %.6f\n", fi["pvalue"]))
cat(sprintf("Chi-square/df = %.3f\n", fi["chisq"] / fi["df"]))
cat(sprintf("GFI = %.3f\n", fi["gfi"]))
cat(sprintf("CFI = %.3f\n", fi["cfi"]))
cat(sprintf("TLI = %.3f\n", fi["tli"]))
cat(sprintf("RMSEA = %.3f [%.3f, %.3f]\n", fi["rmsea"], fi["rmsea.ci.lower"], fi["rmsea.ci.upper"]))
cat(sprintf("SRMR = %.3f\n", fi["srmr"]))
cat("\n")

# 적합도 판단
cat("적합도 기준 판단:\n")
cat(sprintf("  CFI >= .90: %s (%.3f)\n", ifelse(fi["cfi"] >= .90, "충족", "미충족"), fi["cfi"]))
cat(sprintf("  TLI >= .90: %s (%.3f)\n", ifelse(fi["tli"] >= .90, "충족", "미충족"), fi["tli"]))
cat(sprintf("  RMSEA <= .08: %s (%.3f)\n", ifelse(fi["rmsea"] <= .08, "충족", "미충족"), fi["rmsea"]))
cat(sprintf("  SRMR <= .08: %s (%.3f)\n", ifelse(fi["srmr"] <= .08, "충족", "미충족"), fi["srmr"]))
cat("\n")

# 2. 표준화 요인부하량
cat("========================================\n")
cat("2. 표준화 요인부하량\n")
cat("========================================\n")
std_est <- standardizedSolution(fit)
loadings <- std_est[std_est$op == "=~", ]
for (i in 1:nrow(loadings)) {
  cat(sprintf("  %s -> %s: lambda=%.3f, SE=%.3f, z=%.3f, p=%.6f\n",
    loadings$lhs[i], loadings$rhs[i], loadings$est.std[i], loadings$se[i], loadings$z[i], loadings$pvalue[i]))
}
cat("\n")

# 기준 미달 문항 확인
low_loading <- loadings[abs(loadings$est.std) < 0.5, ]
if (nrow(low_loading) > 0) {
  cat("!! 요인부하량 < .50 문항:\n")
  for (i in 1:nrow(low_loading)) {
    cat(sprintf("   %s -> %s: %.3f\n", low_loading$lhs[i], low_loading$rhs[i], low_loading$est.std[i]))
  }
} else {
  cat("모든 문항의 요인부하량 >= .50\n")
}
cat("\n")

# 3. AVE, CR 계산
cat("========================================\n")
cat("3. 집중타당도: AVE, CR\n")
cat("========================================\n")
latent_vars <- c("efficacy", "awareness", "wellbeing")
latent_labels <- c("자원봉사 효능감", "자원봉사제도 인식", "주관적 안녕감")

ave_vals <- c()
cr_vals <- c()

for (k in 1:length(latent_vars)) {
  lv <- latent_vars[k]
  lv_loadings <- loadings[loadings$lhs == lv, "est.std"]
  lambda_sq <- lv_loadings^2
  error_var <- 1 - lambda_sq
  
  ave <- mean(lambda_sq)
  cr <- (sum(lv_loadings))^2 / ((sum(lv_loadings))^2 + sum(error_var))
  
  ave_vals <- c(ave_vals, ave)
  cr_vals <- c(cr_vals, cr)
  
  cat(sprintf("  %s: AVE=%.3f (%s), CR=%.3f (%s)\n",
    latent_labels[k], ave, ifelse(ave >= .50, "충족", "미충족"), cr, ifelse(cr >= .70, "충족", "미충족")))
}
cat("\n")

# 4. 판별타당도 (Fornell-Larcker)
cat("========================================\n")
cat("4. 판별타당도 (Fornell-Larcker 기준)\n")
cat("========================================\n")
cor_est <- std_est[std_est$op == "~~" & std_est$lhs != std_est$rhs & std_est$lhs %in% latent_vars & std_est$rhs %in% latent_vars, ]

cat("잠재변수 간 상관 및 상관제곱:\n")
for (i in 1:nrow(cor_est)) {
  lhs_idx <- which(latent_vars == cor_est$lhs[i])
  rhs_idx <- which(latent_vars == cor_est$rhs[i])
  r <- cor_est$est.std[i]
  r_sq <- r^2
  ave_lhs <- ave_vals[lhs_idx]
  ave_rhs <- ave_vals[rhs_idx]
  discriminant <- ifelse(ave_lhs > r_sq & ave_rhs > r_sq, "충족", "미충족")
  cat(sprintf("  %s <-> %s: r=%.3f, r^2=%.3f, AVE(%s)=%.3f, AVE(%s)=%.3f -> %s\n",
    latent_labels[lhs_idx], latent_labels[rhs_idx], r, r_sq,
    latent_labels[lhs_idx], ave_lhs, latent_labels[rhs_idx], ave_rhs, discriminant))
}
cat("\n")

# 5. Cronbach's alpha
cat("========================================\n")
cat("5. 신뢰도: Cronbach's Alpha\n")
cat("========================================\n")

calc_alpha <- function(data) {
  k <- ncol(data)
  item_vars <- apply(data, 2, var)
  total_var <- var(rowSums(data))
  alpha <- (k / (k - 1)) * (1 - sum(item_vars) / total_var)
  return(alpha)
}

eff_items <- df[, paste0("B_05_", 1:10)]
awa_items <- df[, paste0("B_06_", 1:8)]
wb_items <- df[, c("C_01", "re_C_02", "re_C_03", "C_04")]

alpha_eff <- calc_alpha(as.data.frame(eff_items))
alpha_awa <- calc_alpha(as.data.frame(awa_items))
alpha_wb <- calc_alpha(as.data.frame(wb_items))

cat(sprintf("  자원봉사 효능감 (10문항): alpha = %.3f (%s)\n", alpha_eff, ifelse(alpha_eff >= .70, "충족", "미충족")))
cat(sprintf("  자원봉사제도 인식 (8문항): alpha = %.3f (%s)\n", alpha_awa, ifelse(alpha_awa >= .70, "충족", "미충족")))
cat(sprintf("  주관적 안녕감 (4문항): alpha = %.3f (%s)\n", alpha_wb, ifelse(alpha_wb >= .70, "충족", "미충족")))
cat("\n")

# 6. 수정지수 상위 10개
cat("========================================\n")
cat("6. 수정지수 상위 10개 (참고용)\n")
cat("========================================\n")
mi <- modificationIndices(fit, sort. = TRUE)
print(head(mi, 10))
