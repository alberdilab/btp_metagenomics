#!/usr/bin/env python3
"""Second full audit pass: fix verified numeric mismatches in btp_manuscript.docx.

Purple markup (RGB 163, 53, 158) for all changes in this pass.
"""

from __future__ import annotations

import shutil
from pathlib import Path

from docx import Document
from docx.shared import RGBColor

ROOT = Path(__file__).resolve().parents[2]
MANUSCRIPT = ROOT / "Manuscript" / "btp_manuscript.docx"
BACKUP = ROOT / "Manuscript" / "btp_manuscript_pre_audit_pass2.docx"

PURPLE = RGBColor(163, 53, 158)

REPLACEMENTS: list[tuple[object, str]] = [
    (
        lambda t: "Bacillota_A (60.7" in t and "Bacteroidota (16.1" in t,
        "The gut communities were clearly dominated by Bacillota_A (60.7% ± 17.8%), with "
        "Bacteroidota (15.3% ± 12.8%) and Bacillota (10.7% ± 15.1%) as the next most abundant "
        "phyla, while all remaining groups each contributed on average less than 3% of the "
        "community (Fig. 2). At the family level, the microbiome was dominated by Lachnospiraceae "
        "(28.2% ± 10.0%), followed by Bacteroidaceae (10.7% ± 11.1%), Oscillospiraceae "
        "(11.2% ± 8.2%), Borkfalkiaceae (7.4% ± 5.3%) and CAG-288 (8.6% ± 15.3%). The most "
        "abundant genera were Prevotella (9.1% ± 10.5%), Enterosoma (8.6% ± 15.3%), Coproplasma "
        "(6.8% ± 5.0%), RGIG6307 (5.3% ± 4.8%) and Onthomonas (4.4% ± 3.2%).",
    ),
    (
        lambda t: "Land-cover heterogeneity was a weak predictor" in t and "0.027" in t,
        lambda t: t.replace(
            "Land-cover heterogeneity was a weak predictor of taxonomic β-diversity (R² = 0.027–0.045)",
            "Land-cover heterogeneity was a weak predictor of taxonomic β-diversity (R² = 0.038–0.065)",
        ),
    ),
    (
        lambda t: t.startswith("This identified 16 FDR-significant GIFT elements (12 with positive"),
        "This identified 16 FDR-significant GIFT elements (Fig. 5D; 12 with positive and four with "
        "negative mean interaction β). Positive mean β was enriched for nitrogen-compound degradation "
        "(e.g. D0608, D0601, D0607, D0613), amino-acid degradation (D0512), vitamin biosynthesis "
        "(B0711), appendage traits (S0202) and cellular-structure traits (S0104, S0105), whereas "
        "negative mean β reflected higher capacity for lipid degradation (D0102), sugar degradation "
        "(D0302) and, in a smaller subset, vitamin biosynthesis (B0703) and nitrogen-compound "
        "degradation (D0604). Interpretation remains cautious because devil density and temperature "
        "co-vary geographically within Tasmania.",
    ),
    (
        lambda t: t.startswith("fig5) HMSC functional associations"),
        "Fig. 5. HMSC functional associations across four predictors. Four-panel volcano plots show "
        "GIFT-level functional contrasts for devil density (A), temperature (B), landscape diversity "
        "(C) and devil × temperature interaction (D), ordered left to right, top to bottom. Panels "
        "A–C compare mean GIFT abundance between genomes classified as positively versus negatively "
        "associated with each predictor; panel D shows mean genome-level HMSC interaction β across "
        "genomes carrying each GIFT element (one-sample test vs zero). Points are coloured by GIFT "
        "category and dashed lines indicate FDR = 0.05 and effect-size thresholds.",
    ),
    (
        lambda t: "but not functional β-diversity (R² = 0.005, p = 0.734" in t,
        lambda t: t.replace("p = 0.734", "p = 0.74"),
    ),
    (
        lambda t: t.startswith("The fitted devil × temperature interaction identified a further layer")
        and "102 of 119" not in t,
        lambda t: t.replace(
            "Because interaction-positive genomes largely overlapped devil-negative genomes,",
            "Because interaction-positive genomes were concentrated among devil-negative lineages "
            "(102 of 119) and largely overlapped devil-negative genomes,",
        ),
    ),
]


def find_paragraph(doc: Document, predicate) -> object:
    for para in doc.paragraphs:
        if predicate(para.text.strip()):
            return para
    raise ValueError("Paragraph not found")


def replace_text(para, text: str) -> None:
    para.clear()
    run = para.add_run(text)
    run.font.color.rgb = PURPLE


def main() -> None:
    shutil.copy2(MANUSCRIPT, BACKUP)
    doc = Document(str(MANUSCRIPT))
    n = 0
    for pred, new in REPLACEMENTS:
        para = find_paragraph(doc, pred)
        if callable(new):
            text = new(para.text)
        else:
            text = new
        replace_text(para, text)
        n += 1
    doc.save(str(MANUSCRIPT))
    print(f"Backup: {BACKUP}")
    print(f"Updated {n} paragraphs (purple).")


if __name__ == "__main__":
    main()
