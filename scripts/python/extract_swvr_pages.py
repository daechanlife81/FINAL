"""SWVR 보고서 특정 페이지 전체 텍스트 추출"""
import pypdf
import sys

path = "reference/2026 State of the World's Volunteersim Report.pdf"
reader = pypdf.PdfReader(path)

# 추출할 페이지 (1-indexed로 입력받아 0-indexed 변환)
pages = [35, 36, 37, 95, 96, 97]
for p in pages:
    print("\n" + "#" * 72)
    print(f"# PAGE {p}")
    print("#" * 72)
    txt = reader.pages[p-1].extract_text()
    print(txt)
