#!/usr/bin/env python3
"""Second-pass consistency revision for btp_manuscript.docx.

Checks key numbers against analysis caches and fixes Results/Discussion alignment.
New/changed text is coloured purple (RGB 163, 53, 158).
"""

from __future__ import annotations

import shutil
from pathlib import Path

from docx import Document
from docx.oxml import OxmlElement
from docx.shared import RGBColor
from docx.text.paragraph import Paragraph

ROOT = Path(__file__).resolve().parents[2]
MANUSCRIPT = ROOT / "Manuscript" / "btp_manuscript.docx"
BACKUP = ROOT / "Manuscript" / "btp_manuscript_pre_consistency_pass.docx"

PURPLE = RGBColor(163, 53, 158)


def find_paragraph(doc: Document, predicate, *, optional: bool = False) -> Paragraph | None:
    for para in doc.paragraphs:
        if predicate(para.text.strip()):
            return para
    if optional:
        return None
    raise ValueError("Paragraph not found")


def replace_paragraph_text(para: Paragraph, text: str) -> None:
    para.clear()
    run = para.add_run(text)
    run.font.color.rgb = PURPLE


def insert_after(anchor: Paragraph, text: str, *, style: str = "normal") -> Paragraph:
    new_p = OxmlElement("w:p")
    anchor._element.addnext(new_p)
    para = Paragraph(new_p, anchor._parent)
    if style:
        para.style = style
    if text:
        run = para.add_run(text)
        run.font.color.rgb = PURPLE
    return para


RESULTS_REPLACEMENTS: list[tuple[object, str]] = [
    (
        lambda t: t.startswith("Across predictors, most genomes were neutral"),
        "Across predictors, most genomes were neutral and only subsets responded positively or "
        "negatively: devil density (130 positive, 105 negative, 341 neutral), temperature "
        "(139 positive, 134 negative, 303 neutral) and landscape diversity (133 positive, "
        "109 negative, 334 neutral). The devil × temperature interaction was estimable "
        "(119 positive, 102 negative, 355 neutral), although geographic confounding limits "
        "inference about synergistic effects; 207 genomes showed congruent devil and "
        "temperature responses.",
    ),
    (
        lambda t: t.startswith("Using the HMSC-derived posterior estimates, we then contrasted"),
        "Using HMSC-derived posterior estimates, we contrasted functional potential between MAGs "
        "positively versus negatively associated with devil density. Devil-positive genomes were "
        "enriched in biosynthetic traits, including amino acid (B02), nucleic acid (B01), vitamin "
        "(B07), organic anion (B06) and aromatic compound (B08) biosynthesis, and in degradative "
        "capacities including polysaccharide (D02), amino acid (D05), nitrogen compound (D06) and "
        "antibiotic (D09) degradation. Volcano contrasts identified 60 FDR-significant GIFT "
        "elements (FDR < 0.05): 52 enriched among devil-positive genomes and eight among "
        "devil-negative genomes (Fig. 5A), consistent with a broader metabolic repertoire under "
        "higher devil density.",
    ),
    (
        lambda t: t.startswith("Functional modelling identified 61 FDR-significant GIFT elements differing between temperature-positiv"),
        "Functional modelling identified 61 FDR-significant GIFT elements (FDR < 0.05): 55 were "
        "enriched among temperature-positive genomes and six among temperature-negative genomes. "
        "Temperature-positive genomes were enriched in biosynthetic and degradative traits "
        "(Fig. 5B).",
    ),
    (
        lambda t: t.startswith("The fitted devil × temperature interaction term identified genome-specific responses")
        and "Fig. 5c" in t,
        "The fitted devil × temperature interaction term identified genome-specific responses that "
        "were not reducible to the main effects alone: 119 genomes (21%) carried a positive "
        "interaction coefficient, 102 (18%) a negative coefficient and 355 (62%) were neutral. "
        "Unlike panels A–C (Fig. 5), the interaction functional volcano (Fig. 5D) does not contrast "
        "mean GIFT abundance between interaction-positive and interaction-negative genomes. "
        "Interaction-positive MAGs largely overlapped devil-negative MAGs, so an abundance contrast "
        "would largely recapitulate the devil-density panel; instead, for each GIFT element we "
        "tested whether genomes carrying that trait show a mean HMSC interaction β significantly "
        "different from zero (FDR < 0.05, |β| ≥ 0.05).",
    ),
    (
        lambda t: t.startswith("Landscape diversity as a predictor showed a similar magnitude"),
        "Landscape diversity showed a parallel magnitude of genome-level response (133 positive, "
        "109 negative). Diversity-positive genomes were dominated by Bacillota_A (n = 108), "
        "including CAG-508 (n = 36), Lachnospiraceae (n = 32) and Borkfalkiaceae (n = 24). "
        "Volcano contrasts identified 69 FDR-significant GIFT elements (FDR < 0.05; Fig. 5C), "
        "with a strongly asymmetric distribution: only three elements were enriched among "
        "diversity-positive genomes—spore formation (S0301), acetate biosynthesis (B0401) and "
        "cellular structure (S0104)—whereas 66 elements showed higher capacity in "
        "diversity-negative genomes, spanning amino-acid, aromatic and vitamin biosynthesis and "
        "multiple degradation pathways including antibiotic (D09) and amino-acid (D05) degradation. "
        "Higher landscape diversity was thus associated with genome subsets carrying somewhat "
        "leaner biosynthetic and degradative pathway completeness.",
    ),
    (
        lambda t: t.startswith("Across all samples, possum gut microbiomes harboured on average"),
        "Across all samples, possum gut microbiomes harboured on average 307 ± 138 MAGs, with "
        "abundance-weighted diversity of 115 ± 69, phylogenetic diversity of 7.4 ± 1.4, and "
        "functional diversity of 1.44 ± 0.05. Linear mixed-effects models with broad environment as "
        "a fixed effect and region as a random intercept indicated significant environment effects on "
        "richness (F₄,₅₂ = 2.74, p = 0.038) and phylogenetic diversity (F₄,₅₂ = 3.77, p = 0.009), "
        "but not on abundance-weighted diversity (F₄,₅₂ = 1.48, p = 0.22) or functional diversity "
        "(F₄,₅₂ = 0.38, p = 0.82; Fig. 3). PERMANOVA showed that broad environment significantly "
        "structured richness-based (R² = 0.135, p = 0.001), abundance-weighted (R² = 0.150, "
        "p = 0.001), and phylogenetic β-diversity (R² = 0.183, p = 0.001), but not functional "
        "β-diversity (R² = 0.005, p = 0.734; Fig. 3) of microbial communities. Island additionally "
        "structured taxonomic β-diversity (R² ≈ 0.13–0.15, p = 0.001) without a corresponding "
        "effect on α-diversity. Compositional turnover therefore occurred primarily in taxonomic and "
        "phylogenetic space, with functional potential largely conserved across environments. "
        "Land-cover heterogeneity was a weak predictor of taxonomic β-diversity (R² = 0.027–0.045) "
        "and unrelated to functional turnover. NMDS ordinations mirrored these patterns, with "
        "environmental groups partially separating in richness, neutral and phylogenetic "
        "distances—including clear separation of an Australian outgroup—but showing substantial "
        "overlap in functional space (Fig. 3).",
    ),
]

DISCUSSION_REPLACEMENTS: list[tuple[object, str]] = [
    (
        lambda t: t.startswith("Among devil-positive genomes, 60 GIFT elements differed significantly"),
        "Volcano contrasts identified 60 FDR-significant GIFT elements for devil density (52 "
        "enriched among devil-positive genomes, eight among devil-negative genomes). Devil-positive "
        "genomes showed enrichment of biosynthetic pathways (amino acids, nucleic acids, vitamins, "
        "organic anions) and multiple degradative categories. Higher devil density was thus "
        "associated with a metagenomic signature of internal nutrient provisioning and elevated "
        "xenobiotic and plant secondary metabolite degradation capacity—plausibly reflecting "
        "predator-induced behavioural constraints that limit access to diverse, high-quality forage "
        "and increase reliance on chemically defended foliage. These patterns are correlative but "
        "align with landscape-of-fear theory; direct dietary measurements from the same individuals "
        "would be needed to confirm mechanistic links.",
    ),
    (
        lambda t: t.startswith("Temperature gradients offered a complementary abiotic axis"),
        "Temperature gradients offered a complementary abiotic axis. Comparable minorities were "
        "temperature-positive (139; 24%) or temperature-negative (134; 23%). Temperature-positive "
        "genomes were predominantly Bacillota_A (128 of 139; 92%), especially Oscillospiraceae, "
        "whereas cooler-associated genomes were taxonomically more diverse (Cyanobacteriota, "
        "Thermoplasmatota, Bacteroidota). Functional contrasts identified 61 FDR-significant GIFT "
        "elements (55 enriched among temperature-positive genomes, six among temperature-negative "
        "genomes), predominantly biosynthetic and degradative categories—rather than a broader "
        "metabolic portfolio in cool-associated genomes.",
    ),
    (
        lambda t: t.startswith("Interpretation must remain cautious: devil density and temperature are spatially structured"),
        "Interpretation must remain cautious: devil density and temperature are spatially structured "
        "across Tasmania (r ≈ −0.19 among 55 HMSC samples), and devils occur only on the island. "
        "The evidence supports directional consistency rather than confirmation of synergistic "
        "effects; targeted sampling across warm/dry versus cool/wet regions with contrasting devil "
        "densities—and paired diet or stress biomarkers—would be needed for causal tests.",
    ),
    (
        lambda t: t.startswith("Several limitations apply."),
        "Several limitations apply. Environmental variables—land cover, climate layers and modelled "
        "devil density—are coarse proxies for individual experience; diet, microhabitat use and "
        "physiological stress markers would help disentangle dietary from stress-mediated mechanisms. "
        "Sampling was regionally imbalanced (55 Tasmania versus 17 mainland samples for broader "
        "analyses; HMSC restricted to 55 Tasmania samples and 576 genomes whereas α/β-diversity used "
        "72 analysed samples). Devil density and temperature are partially confounded geographically, "
        "limiting robust inference on their interaction. Functional volcano plots additionally "
        "highlight elements meeting effect-size thresholds (|mean abundance difference| ≥ 0.2 for "
        "main-effect panels; |mean interaction β| ≥ 0.05 for panel D), whereas headline "
        "FDR-significant element counts refer to FDR < 0.05 unless stated otherwise. The "
        "cross-sectional design cannot resolve seasonal turnover or reconfiguration rates. HMSC "
        "identifies associations, not causation. Finally, unmapped metagenomic reads likely contain "
        "diversity and function not represented in the MAG catalogue.",
    ),
]

DIVERSITY_DISCUSSION_HEADING = "4.4.2. Landscape diversity and asymmetric functional filtering"
DIVERSITY_DISCUSSION_BODY = (
    "Landscape diversity (land-cover heterogeneity) showed parallel genome-level filtering "
    "(133 positive, 109 negative) concentrated within Bacillota_A, including CAG-508, "
    "Lachnospiraceae and Borkfalkiaceae. Functional contrasts were strongly asymmetric: 69 "
    "FDR-significant GIFT elements, but only three enriched among diversity-positive genomes "
    "(S0301, B0401, S0104) versus 66 enriched among diversity-negative genomes. This pattern "
    "suggests that higher landscape heterogeneity is associated with reweighting toward genome "
    "subsets carrying leaner biosynthetic and degradative pathway completeness, rather than a "
    "broad expansion of metabolic repertoire at genome resolution—again illustrating how "
    "community-level functional homeostasis can mask directional genome-specific shifts."
)


def main() -> None:
    if not MANUSCRIPT.exists():
        raise SystemExit(f"Missing manuscript: {MANUSCRIPT}")

    shutil.copy2(MANUSCRIPT, BACKUP)
    doc = Document(str(MANUSCRIPT))

    replaced = 0
    for pred, text in RESULTS_REPLACEMENTS + DISCUSSION_REPLACEMENTS:
        para = find_paragraph(doc, pred)
        assert para is not None
        replace_paragraph_text(para, text)
        replaced += 1

    if find_paragraph(doc, lambda t: t.startswith("4.4.2. Landscape diversity"), optional=True) is None:
        trap_last = find_paragraph(
            doc,
            lambda t: t.startswith(
                "Interpretation must remain cautious: devil density and temperature are spatially structured"
            ),
        )
        assert trap_last is not None
        heading = insert_after(trap_last, "", style="normal")
        heading = insert_after(heading, DIVERSITY_DISCUSSION_HEADING, style="Heading 3")
        insert_after(heading, DIVERSITY_DISCUSSION_BODY, style="normal")
        replaced += 2

    doc.save(str(MANUSCRIPT))
    print(f"Backup: {BACKUP}")
    print(f"Updated: {MANUSCRIPT}")
    print(f"Replaced/inserted {replaced} blocks (purple markup).")


if __name__ == "__main__":
    main()
