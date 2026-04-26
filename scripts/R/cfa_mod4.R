library(lavaan)
library(readxl)

df <- read_excel("260414_data_recoded.xlsx")

model_mod4 <- '
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04

  # 잔차공분산 4개
  re_C_02 ~~ re_C_03   # 1. 부정정서 공유 (MI=403.0)
  C_01 ~~ C_04         # 2. 긍정평가 공유 (MI=137.7)
  B_06_1 ~~ B_06_2     # 3. 행정적 인프라 (MI=80.3)
  B_06_4 ~~ B_06_5     # 6. 경제적 인센티브 (MI=41.2)
'

fit_orig <- cfa('
  efficacy =~ B_05_1 + B_05_2 + B_05_3 + B_05_4 + B_05_5 + B_05_6 + B_05_7 + B_05_8 + B_05_9 + B_05_10
  awareness =~ B_06_1 + B_06_2 + B_06_3 + B_06_4 + B_06_5 + B_06_6 + B_06_7 + B_06_8
  wellbeing =~ C_01 + re_C_02 + re_C_03 + C_04
', data = df, estimator = "ML")

fit_mod4 <- cfa(model_mod4, data = df, estimator = "ML")

# 적합도 비교
cat("================================================================\n")
cat("적합도 비교: 원래 vs 수정(잔차공분산 4개)\n")
cat("================================================================\n")
indices <- c("chisq", "df", "pvalue", "gfi", "cfi", "tli", "rmsea", "rmsea.ci.lower", "rmsea.ci.upper", "srmr")
fi_o <- fitMeasures(fit_orig, indices)
fi_m <- fitMeasures(fit_mod4, indices)

cat(sprintf("%-20s %12s %12s\n", "", "원래 모형", "수정 모형"))
cat("----------------------------------------------------------------\n")
cat(sprintf("%-20s %12.3f %12.3f\n", "Chi-square", fi_o["chisq"], fi_m["chisq"]))
cat(sprintf("%-20s %12.0f %12.0f\n", "df", fi_o["df"], fi_m["df"]))
cat(sprintf("%-20s %12.3f %12.3f\n", "Chi-square/df", fi_o["chisq"]/fi_o["df"], fi_m["chisq"]/fi_m["df"]))
cat(sprintf("%-20s %12.3f %12.3f\n", "GFI", fi_o["gfi"], fi_m["gfi"]))
cat(sprintf("%-20s %12.3f %12.3f\n", "CFI", fi_o["cfi"], fi_m["cfi"]))
cat(sprintf("%-20s %12.3f %12.3f\n", "TLI", fi_o["tli"], fi_m["tli"]))
cat(sprintf("%-20s %12.3f %12.3f\n", "RMSEA", fi_o["rmsea"], fi_m["rmsea"]))
cat(sprintf("%-20s %s %s\n", "RMSEA 90% CI",
  sprintf("[%.3f,%.3f]", fi_o["rmsea.ci.lower"], fi_o["rmsea.ci.upper"]),
  sprintf("[%.3f,%.3f]", fi_m["rmsea.ci.lower"], fi_m["rmsea.ci.upper"])))
cat(sprintf("%-20s %12.3f %12.3f\n", "SRMR", fi_o["srmr"], fi_m["srmr"]))
cat("\n")

# 카이제곱 차이 검정
delta_chi <- fi_o["chisq"] - fi_m["chisq"]
delta_df <- fi_o["df"] - fi_m["df"]
p_val <- pchisq(delta_chi, delta_df, lower.tail = FALSE)
cat(sprintf("Delta Chi-sq = %.3f, Delta df = %.0f, p = %.6f\n", delta_chi, delta_df, p_val))
cat("\n")

# 요인부하량
cat("================================================================\n")
cat("수정 모형 표준화 요인부하량\n")
cat("================================================================\n")
std_mod <- standardizedSolution(fit_mod4)
loadings <- std_mod[std_mod$op == "=~", ]
for (i in 1:nrow(loadings)) {
  flag <- ifelse(abs(loadings$est.std[i]) < 0.5, " **미달**", "")
  cat(sprintf("  %s -> %s: %.3f%s\n", loadings$lhs[i], loadings$rhs[i], loadings$est.std[i], flag))
}
cat("\n")

# AVE, CR
cat("================================================================\n")
cat("수정 모형 AVE, CR\n")
cat("================================================================\n")
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

# 판별타당도
cat("================================================================\n")
cat("수정 모형 판별타당도\n")
cat("================================================================\n")
cor_mod <- std_mod[std_mod$op == "~~" & std_mod$lhs != std_mod$rhs & std_mod$lhs %in% latent_vars & std_mod$rhs %in% latent_vars, ]
for (i in 1:nrow(cor_mod)) {
  lhs_idx <- which(latent_vars == cor_mod$lhs[i])
  rhs_idx <- which(latent_vars == cor_mod$rhs[i])
  r <- cor_mod$est.std[i]
  r_sq <- r^2
  discriminant <- ifelse(ave_vals[lhs_idx] > r_sq & ave_vals[rhs_idx] > r_sq, "충족", "미충족")
  cat(sprintf("  %s <-> %s: r=%.3f, r2=%.3f -> %s\n",
    latent_labels[lhs_idx], latent_labels[rhs_idx], r, r_sq, discriminant))
}
cat("\n")

# 잔차공분산 추정치
cat("================================================================\n")
cat("잔차공분산 추정치\n")
cat("================================================================\n")
resid_cov <- std_mod[std_mod$op == "~~" & std_mod$lhs != std_mod$rhs & !(std_mod$lhs %in% latent_vars), ]
for (i in 1:nrow(resid_cov)) {
  cat(sprintf("  %s ~~ %s: std=%.3f, p=%.6f\n",
    resid_cov$lhs[i], resid_cov$rhs[i], resid_cov$est.std[i], resid_cov$pvalue[i]))
}
