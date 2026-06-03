"""
2026 SWVR 보고서에서 자원봉사 제도인식 = 문화자본 근거 검색
"""
import pypdf
import re

path = "reference/2026 State of the World's Volunteersim Report.pdf"
reader = pypdf.PdfReader(path)

print(f"총 페이지: {len(reader.pages)}")
print("=" * 70)

# 키워드 (문화자본 / 제도 / 인식 관련)
keywords = [
    "cultural capital", "cultural", "institution", "institutional",
    "enabling environment", "awareness", "knowledge", "perception",
    "Bourdieu", "social capital", "human capital", "capital",
    "norm", "value", "infrastructure", "policy", "legal", "legislation",
    "recognition", "literacy", "framework"
]

# 페이지별 전체 텍스트 추출
all_text = {}
for i, page in enumerate(reader.pages):
    try:
        txt = page.extract_text()
        all_text[i] = txt
    except Exception as e:
        all_text[i] = ""
        print(f"페이지 {i+1} 추출 실패: {e}")

# 키워드별 등장 페이지 카운트
print("\n[키워드별 등장 빈도]")
for kw in keywords:
    count = 0
    pages_found = []
    for i, txt in all_text.items():
        c = len(re.findall(re.escape(kw), txt, re.IGNORECASE))
        if c > 0:
            count += c
            pages_found.append(i + 1)
    if count > 0:
        print(f"  '{kw}': {count}회 (페이지: {pages_found[:15]})")

# "cultural capital" 문맥 추출 (가장 중요)
print("\n" + "=" * 70)
print("[★ 'cultural capital' 문맥 발췌]")
print("=" * 70)
for i, txt in all_text.items():
    for m in re.finditer(r"cultural capital", txt, re.IGNORECASE):
        start = max(0, m.start() - 300)
        end = min(len(txt), m.end() + 300)
        print(f"\n--- 페이지 {i+1} ---")
        print(txt[start:end].replace("\n", " "))
