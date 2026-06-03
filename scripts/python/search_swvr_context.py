"""
SWVR 보고서 - cultural / institution / enabling environment 문맥 발췌
"""
import pypdf
import re

path = "reference/2026 State of the World's Volunteersim Report.pdf"
reader = pypdf.PdfReader(path)

all_text = {}
for i, page in enumerate(reader.pages):
    try:
        all_text[i] = page.extract_text()
    except Exception:
        all_text[i] = ""

def show_context(keyword, window=400, max_hits=30):
    print("\n" + "=" * 72)
    print(f"[ '{keyword}' 문맥 ]")
    print("=" * 72)
    hits = 0
    for i, txt in all_text.items():
        for m in re.finditer(re.escape(keyword), txt, re.IGNORECASE):
            if hits >= max_hits:
                return
            start = max(0, m.start() - window)
            end = min(len(txt), m.end() + window)
            snippet = txt[start:end].replace("\n", " ")
            snippet = re.sub(r"\s+", " ", snippet)
            print(f"\n--- p.{i+1} ---")
            print(snippet)
            hits += 1

# 핵심 키워드 문맥
show_context("cultural", window=350, max_hits=35)
