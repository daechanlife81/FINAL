# 박사학위논문 최종 점검 세션 종합 정리

**작성일**: 2026-04-26
**목적**: 지도교수님 제출 전 마지막 점검 단계에서 진행한 분석 검증 및 논문 작성 검토 내용 종합

---

## 목차

1. [추가 분석 검증 (Robustness Checks)](#1-추가-분석-검증-robustness-checks)
2. [논문 작성 검토 사항](#2-논문-작성-검토-사항)
3. [인용 정확성 검토](#3-인용-정확성-검토)
4. [산출물 목록](#4-산출물-목록)

---

## 1. 추가 분석 검증 (Robustness Checks)

박사학위논문 마지막 점검 단계에서 학술적 엄밀성 확보를 위해 세 가지 추가 검증을 수행하였다.

### 1.1. 추정법 검증 (WLSMV vs ML vs MLR)

**배경**: 종속변수가 이분형(자원봉사 참여 0/1)인 점을 고려하여 WLSMV 적용을 검토하였으나 문제 발생.

**결과**:

| 추정법 | χ² | CFI | TLI | RMSEA | SRMR | 판정 |
|--------|-----:|-----:|-----:|------:|------:|------|
| WLSMV | 3702.17 | .768 | .869 | .074 | .120 | ❌ Heywood case |
| ML (기존) | 2165.32 | .881 | .865 | .054 | .074 | ✅ 안정 |
| **MLR (최종 채택)** | 2092.84 | .882 | .866 | .054 | .074 | ✅ **채택** |

**WLSMV 실패 원인**:
- 폴리코릭 상관 추정 시 re_A_01_1과 B_05_2 간 상관 1.0 근접
- re_A_01_1 분산 = -2.295 (음수 분산, Heywood case)
- CFI=.768, SRMR=.120으로 수용 기준 미달

**최종 결정**:
- **적합도 평가**: MLR (Satorra-Bentler 강건 표준오차) 적용
- **매개효과 검증**: ML + Bootstrap 5,000회 (MLR은 부트스트랩과 동시 적용 불가)
- **결과**: ML과 MLR 결과 거의 동일 → 추정법 견고성 확인 (14개 가설 판정 동일)

**관련 산출물**:
- `scripts/R/sem_wlsmv_check.R`
- `scripts/R/sem_analysis_mlr.R`
- `results/SEM_robustness_check.xlsx` (7개 시트)
- `results/estimator_comparison.csv`

### 1.2. 상관계수 견고성 검증 (Pearson vs Spearman vs Kendall)

**배경**: 본 연구 변수 중 이분형이 다수(7개)인 점을 고려하여 Pearson 상관의 적절성 검토.

**변수 유형 구성**:
- 이분형 7개: 성별, 자원봉사 참여경험, 과거 봉사경험, 봉사교육경험, 네트워크, 사회단체활동, 종교활동
- 서열형 3개: 주관적 건강, 교육수준, 일반적 신뢰
- 연속형 1개: 연령

**결과**:

| 비교 | 평균 절대 차이 | 판정 |
|------|--------------|------|
| Pearson vs Spearman | 0.0032 | 거의 동일 |
| Pearson vs Kendall | 0.0025 | 거의 동일 |

- 이분형 ↔ 이분형 상관: 세 방법 **완전 일치** (.365, .208 등)
- 서열형/연속형 포함 변수: 최대 차이 .015

**최종 결정**: **Pearson 유지**
- 근거 1: 이분형↔연속형 Pearson = Point-biserial 수학적 동일 (Cohen et al., 2003)
- 근거 2: 대표본(N=1,328) 조건에서 Pearson robustness 확보 (Hair et al., 2010)
- 근거 3: SEM 입력값(Pearson 공분산 행렬)과 동일 기반 유지
- 근거 4: 세 방법 결과 견고성 확인 (차이 .003 이하)

**관련 산출물**:
- `scripts/R/correlation_robustness.R`
- `results/Correlation_robustness_check.xlsx` (6개 시트)
- `results/correlation_pearson.csv`, `correlation_spearman.csv`, `correlation_kendall.csv`

### 1.3. GFI 산출 검증

**배경**: SEM 적합도 보고에서 GFI 누락 발견.

**결과** (모든 추정법에서 GFI 산출 가능):

| 분석 | GFI | 비고 |
|------|----:|------|
| CFA (ML) | .913 | 측정모형 |
| CFA (MLR) | .913 | 측정모형 |
| SEM (ML) | .872 | 구조모형 |
| SEM (MLR) | .872 | 구조모형 |

**최종 결정**: GFI 보고 추가 (한국 박사논문 관행)
- 측정모형: GFI = .913 (충족)
- 구조모형: GFI = .872 (.90 근접, Kenny & McCoach 2003 변수 수 효과로 정당화)
- 본문 위치: χ²/df 다음, CFI 앞 (절대적합지수 순서)
- GFI 출처: Jöreskog & Sörbom(1984) 별도 명시 (Hu & Bentler는 GFI 권장 X)

**관련 산출물**:
- `scripts/R/check_gfi.R`

### 1.4. 주관적 안녕감 측정 옵션 비교 (지도교수님 권고)

**배경**: 지도교수님께서 우울·걱정 문항 제외, 행복·삶의 만족만 사용 제안.

**3가지 방안 비교**:

| 방안 | 구성 | α | AVE | CR | SEM CFI | 비고 |
|------|------|---:|----:|----:|--------:|------|
| 방안 1 (현재) | 4문항 | .696 | .388 | .701 | .882 | Diener 3요소 |
| **방안 2 (교수님 권장)** | 2문항 | .767 | .649 | .784 | .919 | **권장** |
| 방안 3 (분리) | 양적+음적 | 양:.767 | 양:.633 | 양:.774 | .911 | 음수 분산 경고 |

**가설 검증 변동 (방안 1 → 방안 2)**:
- H5 (사회자본→안녕감): 부분채택(신뢰·네트워크) → 부분채택(신뢰만)
- H12 (안녕감→참여): β=.083* 유의 → β=.073, **p=.050 경계선**
- H14 (안녕감 매개): 3개 유의 → 2개 유의(건강·신뢰)

**방안 3 학술적 발견 (양적/음적 차별적 영향)**:

| 변수 | 양적 안녕감 (행복+만족) | 음적 안녕감 (걱정·우울 부재) |
|------|----------------------|---------------------------|
| 건강 | β=.208*** | β=.116** |
| 일반적 신뢰 | **β=.282*** | β=.045 n.s. |
| 네트워크 | β=.038 n.s. | **β=.156*** |
| 사회단체 | β=.000 n.s. | **β=.105*** |
| 종교활동 | β=-.010 n.s. | **β=-.071** |
| 효능감 | β=.309*** | β=.173*** |

→ 양적 안녕감은 신뢰·건강 중심, 음적 안녕감은 네트워크·사회단체 중심의 차별적 패턴
→ 단, 음수 분산 경고(부트스트랩 4,412회 nonadmissible)로 본 분석 채택 부적절

**최종 권고**:
- 본 분석: 방안 2 채택 (지도교수님 권장 + 학술 기준 충족)
- 부록: 방안 3을 보조 분석으로 활용 (양적/음적 차별 영향)
- 주의: H12 p=.050 경계선, H14 매개 결과 변동 정직하게 보고

**관련 산출물**:
- `scripts/R/wellbeing_2items_check.R`, `sem_option2_2items.R`, `sem_option3_split.R`
- `results/Wellbeing_Measurement_Options_Report.xlsx` (7개 시트)
- `results/Wellbeing_Options_Decision_Report.md` (상세 보고서)

---

## 2. 논문 작성 검토 사항

### 2.1. 서론 (연구의 필요성) 검토

**3단계 구조 평가** (Start Broad → Be Specific → Address the Gap):
- 전반적으로 3단계 구조 잘 따름 (★★★★)
- ① Start Broad가 6문단으로 다소 과다하나, 분량 유지 결정
- 권장 보완: ② Be Specific 시작에 "본 연구의 핵심 질문" 명시

**핵심 질문 명시 위치** (7번째 문단 첫 문장):
> "이러한 맥락에서 본 연구는 다음의 핵심 질문에 답하고자 한다. 개인이 보유한 인간자본·사회자본·문화자본은 자원봉사 참여에 어떻게 영향을 미치며, 그 과정에서 자원봉사 효능감과 주관적 안녕감은 어떠한 매개적 역할을 수행하는가?"

**학술적 공백 ↔ 본 연구 차별성 1:1 대응** (셋째 → 둘째 순서 변경):
- 차별성 순서를 모형 → 효능감(영역특수성) → 안녕감(선행위치)로 정렬
- 본 연구 매개변수 순서(효능감 → 안녕감)와 일치

**통합돌봄 단락 확대해석 수정**:
- "통합돌봄 정책의 지속가능성을 좌우" → 확대해석으로 판단
- 본 연구는 자원봉사 참여 영향요인 규명이 핵심, 통합돌봄은 배경 사례
- 수정: "자원봉사 활성화를 위한 학술적 기반"으로 위상 정확화
- 종속변수가 참여 여부(0/1)이므로 "지속적 참여·헌신·질적 기반" 표현 제거
- 서론에서 연구 한계 언급 부적절 → 5장 한계 절에서만 다룸

### 2.2. 측정도구 작성 검토

**자원봉사 제도인식 문항-전체 상관 추가**:
- 8개 문항 수정 ITC: .602 ~ .766 (모두 우수 기준 충족)
- Cronbach's α = .910

**성별 변수 표기 수정**:
- "남성 1, 여성 2 이분형 변수" → "남성을 준거집단(0)으로, 여성을 1로 더미코딩"
- 본 연구는 더미코딩(0/1) 사용 (남=0, 여=1)

### 2.3. 분석 방법 표 검토

**EFA 제거**:
- 본 연구는 EFA 실시하지 않음 (기존 타당화 척도 사용)
- 분석 방법 표에서 "탐색적 요인분석(EFA)" 삭제 필요

**MLR 추정법 명시**:
- WLSMV 검토 후 MLR 적용 흐름 명시
- 부트스트랩 5,000회 명시

**분석도구**:
- SPSS 26.0 (데이터 전처리 + 기술통계, 별도 사용 확인)
- R 4.5.2 (lavaan) (CFA, SEM, 매개효과)

### 2.4. 적합도 보고 검토

**측정모형 적합도 (GFI 추가)**:
| χ²(df) | χ²/df | GFI | CFI | TLI | RMSEA [90% CI] | SRMR |
|-------:|------:|----:|----:|----:|---------------:|-----:|
| 1353.408(206) | 6.570 | .913 | .913 | .903 | .065 [.062, .068] | .051 |

**구조모형 적합도 (ML → MLR 수정 필요)**:
- 본문에 ML 값(2165.325) 작성됨 → MLR 값(2092.837)로 수정 필요
- 방법론에서 MLR 명시했으므로 결과도 MLR로 통일

---

## 3. 인용 정확성 검토

### 3.1. 수정이 필요한 인용

| 인용 | 문제 | 수정 권장 |
|------|------|----------|
| Anderson & Gerbing(1988) - EFA 생략 근거 | "2차자료 EFA 생략" 직접 근거 아님 | + Brown(2015) 보강 |
| Nunnally(1978) - α .70 기준 | 1994판이 더 정확 | Nunnally & Bernstein(1994) |
| Hair et al.(2010) - α .60 수용 | "탐색적 연구" 기준 (본 연구는 확인적) | Cortina(1993) 짧은 척도 |

### 3.2. 신뢰도 정당화 수정안

**Before**: "Nunnally(1978)가 제시한 기준 .70에 미치지 못하였으나, 4문항 짧은 척도에서 .60 이상이면 수용 가능(Hair et al., 2010)"

**After**: "일반적으로 권장되는 .70 기준(Nunnally & Bernstein, 1994)에는 다소 미치지 못하였으나, Cortina(1993)가 지적한 바와 같이 Cronbach's α는 척도의 문항 수에 영향을 받으며 짧은 척도일수록 낮게 산출되는 경향이 있다."

### 3.3. CSSES 정의 인용 (Reeb et al., 1998)

- 정의: "봉사를 통해 지역사회에 의미 있는 기여를 할 수 있다는 개인의 자신감"
- 원문: "the student's confidence in his or her own ability to make clinically significant contributions to the community through service"
- 위치: Purpose 단락 (p. 49 추정, 원문 PDF 직접 확인 권장)
- 학술지: Michigan Journal of Community Service Learning, 5(1), 48-57

### 3.4. 추가 참고문헌

```
Anderson, J. C., & Gerbing, D. W. (1988). Structural equation modeling
   in practice: A review and recommended two-step approach.
   Psychological Bulletin, 103(3), 411-423.
Brown, T. A. (2015). Confirmatory factor analysis for applied research
   (2nd ed.). New York, NY: Guilford Press.
Kline, R. B. (2015). Principles and practice of structural equation
   modeling (4th ed.). New York, NY: Guilford Press.
Nunnally, J. C., & Bernstein, I. H. (1994). Psychometric theory
   (3rd ed.). New York, NY: McGraw-Hill.
Cortina, J. M. (1993). What is coefficient alpha? An examination
   of theory and applications. Journal of Applied Psychology, 78(1), 98-104.
Jöreskog, K. G., & Sörbom, D. (1984). LISREL VI user's guide
   (3rd ed.). Mooresville, IN: Scientific Software.
Cohen, J., Cohen, P., West, S. G., & Aiken, L. S. (2003). Applied
   multiple regression/correlation analysis for the behavioral sciences
   (3rd ed.). Mahwah, NJ: Erlbaum.
```

---

## 4. 산출물 목록

### 4.1. 분석 스크립트 (scripts/R/)

| 파일 | 내용 |
|------|------|
| sem_wlsmv_check.R | WLSMV 재시도 검증 (Heywood case 진단) |
| sem_analysis_mlr.R | MLR 본 분석 |
| item_total_correlation.R | 자원봉사제도 인식 문항-전체 상관 |
| correlation_robustness.R | Pearson vs Spearman vs Kendall 비교 |
| check_gfi.R | GFI 산출 가능성 검증 |
| wellbeing_2items_check.R | 안녕감 측정 3방안 사전 검토 |
| sem_option2_2items.R | 방안 2 (2문항) 전체 분석 |
| sem_option3_split.R | 방안 3 (양적/음적 분리) 전체 분석 |

### 4.2. 분석 결과 (results/)

| 파일 | 내용 |
|------|------|
| SEM_robustness_check.xlsx | 추정법 비교 (7개 시트) |
| Correlation_robustness_check.xlsx | 상관계수 견고성 (6개 시트) |
| Wellbeing_Measurement_Options_Report.xlsx | 안녕감 옵션 비교 (7개 시트) |
| Wellbeing_Options_Decision_Report.md | 안녕감 옵션 의사결정 보고서 |
| estimator_comparison.csv / log.txt | 추정법 비교 로그 |
| correlation_pearson/spearman/kendall.csv | 상관 행렬 |
| sem_option2_2items_log.txt / sem_option3_split_log.txt | 방안별 분석 로그 |

### 4.3. Python 생성기 (scripts/python/)

| 파일 | 내용 |
|------|------|
| create_robustness_check_excel.py | 추정법 비교 엑셀 생성 |
| create_correlation_robustness_excel.py | 상관 견고성 엑셀 생성 |
| create_wellbeing_options_report.py | 안녕감 옵션 보고서 생성 |

---

## 5. 우선 결정 필요 사항 (지도교수님 협의)

| 우선순위 | 결정 사항 | 권장 |
|---------|----------|------|
| ★★★★★ | 주관적 안녕감 측정 방안 (1/2/3) | 방안 2 + 방안 3 부록 |
| ★★★★★ | 본문 χ²(df) ML → MLR 수정 | MLR(2092.837)로 통일 |
| ★★★★ | 안녕감 측정 변경 시 본문 전면 갱신 | 방안 2 확정 시 진행 |
| ★★★★ | GFI 보고 추가 | 측정모형·구조모형 모두 추가 |
| ★★★ | 인용 출처 수정 | Nunnally&Bernstein, Cortina, Brown |
| ★★★ | EFA 분석 방법 표에서 삭제 | 삭제 |

---

**작성**: 박사학위논문 연구 분석 세션
**다음 단계**: 지도교수님 협의 후 안녕감 측정 방안 확정 → 본문 갱신
