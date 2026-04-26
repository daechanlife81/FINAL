library(lavaan)
library(readxl)

df <- read_excel("260414_data_recoded.xlsx")

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

fit <- sem(sem_model, data = df, estimator = "ML")

# 비표준화 + 표준화 계수 함께 추출
params <- parameterEstimates(fit, standardized = TRUE)
struct <- params[params$op == "~", ]

labels <- list(
  efficacy="효능감", wellbeing="안녕감", re_A_01_1="참여",
  D_05="주관적건강", D_03="교육수준", C_05="일반적신뢰",
  re_C_06="네트워크", re_C_07="사회단체활동", awareness="제도인식",
  re_C_08="종교활동", re_B_04="봉사교육경험",
  re_SQ1="성별", SQ2="연령", D_04="혼인상태", re_B_02="과거봉사경험"
)

get_label <- function(x) { if (x %in% names(labels)) labels[[x]] else x }

cat("구조경로계수 (비표준화 B + 표준화 beta)\n")
cat("================================================================\n")
cat(sprintf("%-20s %-14s %8s %8s %8s %8s\n", "경로", "", "B", "S.E.", "beta", "p"))
cat("----------------------------------------------------------------\n")

for (dv in c("efficacy", "wellbeing", "re_A_01_1")) {
  rows <- struct[struct$lhs == dv, ]
  for (i in 1:nrow(rows)) {
    path <- sprintf("%s -> %s", get_label(rows$rhs[i]), get_label(rows$lhs[i]))
    cat(sprintf("%-34s %8.3f %8.3f %8.3f %8.4f\n",
      path, rows$est[i], rows$se[i], rows$std.all[i], rows$pvalue[i]))
  }
  cat("\n")
}
