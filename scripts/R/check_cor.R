library(readxl)
df <- read_excel("260414_data_recoded.xlsx")

df$efficacy_mean <- rowMeans(df[, paste0("B_05_", 1:10)])
df$awareness_mean <- rowMeans(df[, paste0("B_06_", 1:8)])
df$wellbeing_mean <- rowMeans(df[, c("C_01", "re_C_02", "re_C_03", "C_04")])

vars <- c("D_05","D_03","C_05","re_C_06","re_C_07","awareness_mean","re_C_08","re_B_04")
labels <- c("주관적건강","교육수준","일반적신뢰","네트워크","사회단체활동","제도인식","종교활동","봉사교육경험")

cat("독립변수와 매개/종속변수 간 상관관계\n")
cat("================================================================\n")
cat(sprintf("%-16s %10s %10s %10s\n", "독립변수", "효능감", "안녕감", "참여경험"))
cat("----------------------------------------------------------------\n")

for (i in 1:length(vars)) {
  r_eff <- cor(df[[vars[i]]], df$efficacy_mean)
  r_wb <- cor(df[[vars[i]]], df$wellbeing_mean)
  r_vol <- cor(df[[vars[i]]], df$re_A_01_1)
  p_eff <- cor.test(df[[vars[i]]], df$efficacy_mean)$p.value
  p_wb <- cor.test(df[[vars[i]]], df$wellbeing_mean)$p.value
  p_vol <- cor.test(df[[vars[i]]], df$re_A_01_1)$p.value

  sig <- function(p) ifelse(p<.001,"***",ifelse(p<.01,"** ",ifelse(p<.05,"*  ","   ")))

  cat(sprintf("%-16s %6.3f%s %6.3f%s %6.3f%s\n",
    labels[i], r_eff, sig(p_eff), r_wb, sig(p_wb), r_vol, sig(p_vol)))
}

cat("\n================================================================\n")
cat("상관이 낮은 경로 검토 (|r| < .05 또는 비유의)\n")
cat("================================================================\n")
for (i in 1:length(vars)) {
  r_eff <- cor(df[[vars[i]]], df$efficacy_mean)
  r_wb <- cor(df[[vars[i]]], df$wellbeing_mean)
  r_vol <- cor(df[[vars[i]]], df$re_A_01_1)
  p_eff <- cor.test(df[[vars[i]]], df$efficacy_mean)$p.value
  p_wb <- cor.test(df[[vars[i]]], df$wellbeing_mean)$p.value
  p_vol <- cor.test(df[[vars[i]]], df$re_A_01_1)$p.value

  if (p_eff >= .05 || abs(r_eff) < .05) cat(sprintf("  %s -> 효능감: r=%.3f (p=%.4f)\n", labels[i], r_eff, p_eff))
  if (p_wb >= .05 || abs(r_wb) < .05) cat(sprintf("  %s -> 안녕감: r=%.3f (p=%.4f)\n", labels[i], r_wb, p_wb))
  if (p_vol >= .05 || abs(r_vol) < .05) cat(sprintf("  %s -> 참여: r=%.3f (p=%.4f)\n", labels[i], r_vol, p_vol))
}
