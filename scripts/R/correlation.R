library(lavaan)
library(readxl)
library(openxlsx)

df <- read_excel("260414_data_recoded.xlsx")

# 잠재변수는 관측변수의 평균으로 산출
df$efficacy_mean <- rowMeans(df[, paste0("B_05_", 1:10)])
df$awareness_mean <- rowMeans(df[, paste0("B_06_", 1:8)])
df$wellbeing_mean <- rowMeans(df[, c("C_01", "re_C_02", "re_C_03", "C_04")])

# 분석 변수 목록 (연구모형 투입 순서)
var_cols <- c(
  "re_SQ1",        # 1. 성별
  "SQ2",           # 2. 연령
  "D_04",          # 3. 혼인상태
  "re_B_02",       # 4. 과거 자원봉사경험
  "D_05",          # 5. 주관적 건강
  "D_03",          # 6. 교육수준
  "C_05",          # 7. 일반적 신뢰
  "re_C_06",       # 8. 네트워크
  "re_C_07",       # 9. 사회단체활동
  "awareness_mean",# 10. 자원봉사제도 인식
  "re_C_08",       # 11. 종교활동
  "re_B_04",       # 12. 자원봉사교육 경험
  "efficacy_mean", # 13. 자원봉사 효능감
  "wellbeing_mean",# 14. 주관적 안녕감
  "re_A_01_1"      # 15. 자원봉사 참여경험
)

var_labels <- c(
  "1.성별", "2.연령", "3.혼인상태", "4.과거봉사경험",
  "5.주관적건강", "6.교육수준", "7.일반적신뢰", "8.네트워크",
  "9.사회단체활동", "10.제도인식", "11.종교활동", "12.봉사교육경험",
  "13.봉사효능감", "14.주관적안녕감", "15.봉사참여경험"
)

data_sub <- df[, var_cols]

# Pearson 상관행렬
cor_matrix <- cor(data_sub, use = "complete.obs")

# p-value 행렬
n <- nrow(data_sub)
p_matrix <- matrix(NA, ncol = length(var_cols), nrow = length(var_cols))
for (i in 1:length(var_cols)) {
  for (j in 1:length(var_cols)) {
    if (i != j) {
      test <- cor.test(data_sub[[i]], data_sub[[j]])
      p_matrix[i, j] <- test$p.value
    }
  }
}

# 콘솔 출력: 하삼각 상관행렬 + 유의도 표시
cat("================================================================\n")
cat("주요 변수 간 상관관계 분석 (N=1,328)\n")
cat("================================================================\n\n")

# M, SD 출력
cat(sprintf("%-20s %8s %8s\n", "변수", "M", "SD"))
cat("----------------------------------------\n")
for (i in 1:length(var_cols)) {
  cat(sprintf("%-20s %8.3f %8.3f\n", var_labels[i], mean(data_sub[[i]]), sd(data_sub[[i]])))
}
cat("\n")

# 하삼각 상관행렬
cat("상관행렬 (하삼각):\n")
cat(sprintf("%22s", ""))
for (j in 1:(length(var_cols)-1)) {
  cat(sprintf("%8s", paste0("[", j, "]")))
}
cat("\n")

for (i in 2:length(var_cols)) {
  cat(sprintf("%-22s", var_labels[i]))
  for (j in 1:(i-1)) {
    r <- cor_matrix[i, j]
    p <- p_matrix[i, j]
    stars <- ""
    if (!is.na(p)) {
      if (p < .001) stars <- "***"
      else if (p < .01) stars <- "** "
      else if (p < .05) stars <- "*  "
      else stars <- "   "
    }
    cat(sprintf("%6.3f%s", r, stars))
  }
  cat("\n")
}
cat("\n*p<.05, **p<.01, ***p<.001\n")

# 종속변수(봉사참여경험)와의 상관 요약
cat("\n================================================================\n")
cat("종속변수(자원봉사 참여경험)와의 상관관계 요약\n")
cat("================================================================\n")
dep_idx <- which(var_cols == "re_A_01_1")
for (i in 1:(length(var_cols)-1)) {
  r <- cor_matrix[dep_idx, i]
  p <- p_matrix[dep_idx, i]
  sig <- ifelse(p < .001, "***", ifelse(p < .01, "**", ifelse(p < .05, "*", "n.s.")))
  cat(sprintf("  %-20s r = %6.3f (%s)\n", var_labels[i], r, sig))
}

# 엑셀 저장
wb <- createWorkbook()
addWorksheet(wb, "상관관계분석")

# 제목
writeData(wb, 1, "주요 변수 간 상관관계 분석 결과 (N=1,328)", startRow = 1, startCol = 1)

# 헤더: 변수, M, SD, [1]~[14]
header <- c("변수", "M", "SD", paste0("[", 1:(length(var_cols)-1), "]"))
writeData(wb, 1, t(header), startRow = 3, startCol = 1, colNames = FALSE)

# 데이터 행
for (i in 1:length(var_cols)) {
  row_data <- c(var_labels[i],
    sprintf("%.3f", mean(data_sub[[i]])),
    sprintf("%.3f", sd(data_sub[[i]])))

  if (i >= 2) {
    for (j in 1:(i-1)) {
      r <- cor_matrix[i, j]
      p <- p_matrix[i, j]
      stars <- ""
      if (!is.na(p)) {
        if (p < .001) stars <- "***"
        else if (p < .01) stars <- "**"
        else if (p < .05) stars <- "*"
      }
      row_data <- c(row_data, sprintf("%.3f%s", r, stars))
    }
  }
  writeData(wb, 1, t(row_data), startRow = 3 + i, startCol = 1, colNames = FALSE)
}

# 주석
note_row <- 3 + length(var_cols) + 1
writeData(wb, 1, "*p<.05, **p<.01, ***p<.001", startRow = note_row, startCol = 1)

# 열 너비
setColWidths(wb, 1, cols = 1, widths = 22)
setColWidths(wb, 1, cols = 2:3, widths = 10)
setColWidths(wb, 1, cols = 4:(3+length(var_cols)-1), widths = 12)

# 헤더 스타일
headerStyle <- createStyle(fontName = "Times New Roman", fontSize = 11, halign = "center",
  textDecoration = "bold", border = "TopBottom", borderStyle = "medium")
addStyle(wb, 1, headerStyle, rows = 3, cols = 1:(3+length(var_cols)-1), gridExpand = TRUE)

# 본문 스타일
bodyStyle <- createStyle(fontName = "Times New Roman", fontSize = 11, halign = "center")
addStyle(wb, 1, bodyStyle, rows = 4:(3+length(var_cols)),
  cols = 1:(3+length(var_cols)-1), gridExpand = TRUE)

# 제목 스타일
titleStyle <- createStyle(fontName = "Times New Roman", fontSize = 13, textDecoration = "bold", halign = "center")
mergeCells(wb, 1, cols = 1:(3+length(var_cols)-1), rows = 1)
addStyle(wb, 1, titleStyle, rows = 1, cols = 1)

# 하단 테두리
bottomStyle <- createStyle(fontName = "Times New Roman", fontSize = 11, halign = "center",
  border = "bottom", borderStyle = "medium")
addStyle(wb, 1, bottomStyle, rows = 3+length(var_cols),
  cols = 1:(3+length(var_cols)-1), gridExpand = TRUE)

saveWorkbook(wb, "상관관계분석.xlsx", overwrite = TRUE)
cat("\n저장 완료: 상관관계분석.xlsx\n")
