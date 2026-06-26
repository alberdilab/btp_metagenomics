#!/usr/bin/env python3
"""Merge key points from Manuscript/4 | Discussion.docx into btp_manuscript.docx.

Writes merged discussion with new/changed text in green (RGB 0, 128, 64).
"""

from __future__ import annotations

import shutil
from pathlib import Path

from docx import Document
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import RGBColor
from docx.text.paragraph import Paragraph

ROOT = Path(__file__).resolve().parents[2]
MANUSCRIPT = ROOT / "Manuscript" / "btp_manuscript.docx"
BACKUP = ROOT / "Manuscript" / "btp_manuscript_pre_discussion_merge.docx"

GREEN = RGBColor(0, 128, 64)


def find_paragraph_index(doc: Document, predicate) -> int:
    for i, para in enumerate(doc.paragraphs):
        if predicate(para.text.strip()):
            return i
    raise ValueError("Paragraph not found")


def remove_paragraph(para: Paragraph) -> None:
    para._element.getparent().remove(para._element)


def insert_paragraph_after(anchor: Paragraph, text: str, *, style: str = "normal") -> Paragraph:
    new_p = OxmlElement("w:p")
    anchor._element.addnext(new_p)
    para = Paragraph(new_p, anchor._parent)
    if style:
        para.style = style
    if text:
        run = para.add_run(text)
        run.font.color.rgb = GREEN
    return para


DISCUSSION_BLOCKS: list[tuple[str, str]] = [
    (
        "normal",
        "Genome-resolved metagenomics and hierarchical modelling of species communities (HMSC) "
        "show that the common brushtail possum (Trichosurus vulpecula) gut microbiome is "
        "taxonomically responsive yet functionally robust at community scale. Environmental "
        "gradients, island context and habitat jointly restructure lineage composition—especially "
        "within Bacillota_A—while genome-level inference reveals parallel devil- and "
        "temperature-associated compensation that is directionally consistent with, but does not "
        "confirm, compounded physiological stress when predation recovery and warming coincide.",
    ),
    ("normal", ""),
    ("Heading 2", "4.1. Metagenomic plasticity in a generalist marsupial"),
    (
        "normal",
        "T. vulpecula is best understood as a holobiont whose ecological flexibility is mediated, "
        "in part, by gut microbial metabolism. Across habitats and regions, taxonomic composition "
        "and phylogenetic breadth shifted significantly, whereas aggregate functional potential "
        "remained comparatively stable. This decoupling—high taxonomic turnover against a conserved "
        "functional backdrop—represents metagenomic plasticity that likely underpins persistence "
        "across heterogeneous landscapes. While the host genome is fixed on ecological timescales, "
        "the microbial extended genotype can reorganise rapidly to track environmental variation.",
    ),
    (
        "normal",
        "A major empirical contribution is a genome-resolved catalogue of 1,817 metagenome-assembled "
        "genomes (MAGs) that captures a substantial fraction of microbial biomass in faecal "
        "metagenomes and links lineage identity to functional potential more directly than amplicon "
        "profiling. Most genomes lacked species-level resolution, underscoring how much marsupial "
        "gut diversity remains uncharacterised. Communities were consistently dominated by Bacillota_A, "
        "especially Lachnospiraceae and Oscillospiraceae—lineages central to plant polysaccharide "
        "fermentation and short-chain fatty acid production. Given the folivorous baseline diet and "
        "chemical recalcitrance of Eucalyptus foliage, this dominance is biologically coherent and "
        "suggests a non-negotiable functional core for fibre and plant secondary metabolite processing.",
    ),
    ("normal", ""),
    ("Heading 2", "4.2. Environmental context shapes taxonomy more than functional potential"),
    (
        "normal",
        "Broad environment categories explained variation in taxonomic alpha diversity, whereas island "
        "of origin (Tasmania versus mainland Australia) and habitat jointly structured taxonomic beta "
        "diversity. Conversely, functional beta diversity based on Genome-Inferred Functional Trait "
        "(GIFT) profiles overlapped extensively among habitats and islands; PERMANOVA on functional "
        "distances yielded very small effect sizes and non-significant results. The parsimonious "
        "interpretation is functional redundancy: distinct, often phylogenetically related genomes "
        "encode overlapping metabolic capabilities.",
    ),
    (
        "normal",
        "Using Hill numbers, phylogenetic and neutral diversities fluctuated across habitats while the "
        "functional toolkit remained homeostatic. Environmental filtering therefore appears to operate "
        "primarily on community membership within functional guilds rather than on the presence or "
        "absence of broad functional categories. This redundancy acts as ecological insurance, "
        "maintaining stable biochemical output despite taxonomic turnover. Functional stability at "
        "community scale does not imply ecological equivalence of all taxa—GIFT summarises genomic "
        "potential rather than realised activity—but it does indicate that contrasting habitats "
        "converge on broadly similar repertoires detectable at genome-inferred resolution. "
        "Community-level homeostasis can nonetheless coexist with genome-specific compensation along "
        "stress gradients, to which we turn next.",
    ),
    ("normal", ""),
    ("Heading 2", "4.3. Predator landscapes and microbiome signatures of risk"),
    (
        "normal",
        "Predation pressure from the Tasmanian devil (Sarcophilus harrisii) was associated with "
        "genome-level microbiome restructuring consistent with the nutritional compensation "
        "hypothesis. Among 576 MAGs modelled across 55 Tasmania samples, comparable minorities were "
        "devil-positive (130; 23%) or devil-negative (105; 18%), with most neutral (341; 59%). "
        "Responses concentrated within Bacillota_A core families—notably Lachnospiraceae and "
        "Oscillospiraceae—indicating reweighting within the dominant guild rather than wholesale "
        "turnover.",
    ),
    (
        "normal",
        "Among devil-positive genomes, 60 GIFT elements differed significantly from devil-negative "
        "genomes (FDR < 0.05), with enrichment of biosynthetic pathways (amino acids, nucleic acids, "
        "vitamins, organic anions) and multiple degradative categories. Higher devil density was thus "
        "associated with a metagenomic signature of internal nutrient provisioning and elevated "
        "xenobiotic and plant secondary metabolite degradation capacity—plausibly reflecting "
        "predator-induced behavioural constraints that limit access to diverse, high-quality forage "
        "and increase reliance on chemically defended foliage. These patterns are correlative but align "
        "with landscape-of-fear theory; direct dietary measurements from the same individuals would be "
        "needed to confirm mechanistic links.",
    ),
    ("normal", ""),
    ("Heading 2", "4.4. Temperature, Firmicutes, and genome-resolved thermal filtering"),
    (
        "normal",
        "Temperature gradients offered a complementary abiotic axis. Comparable minorities were "
        "temperature-positive (139; 24%) or temperature-negative (134; 23%). Temperature-positive "
        "genomes were predominantly Bacillota_A (128 of 139; 92%), especially Oscillospiraceae, "
        "whereas cooler-associated genomes were taxonomically more diverse (Cyanobacteriota, "
        "Thermoplasmatota, Bacteroidota). Functional contrasts identified 61 FDR-significant GIFT "
        "elements enriched among temperature-positive genomes, predominantly biosynthetic and "
        "degradative categories—rather than a broader metabolic portfolio in cool-associated genomes.",
    ),
    (
        "normal",
        "The shift toward Bacillota_A at higher temperatures is consistent with diet-induced "
        "thermogenesis logic: as possums may reduce protein intake in the heat to limit internal "
        "overheating, the microbiome may pivot toward Firmicutes lineages efficient at carbohydrate "
        "fermentation. A broad spore-formation signal was weak (one marginal S-element), so "
        "transmission-survival hypotheses remain plausible but are not strongly supported here. "
        "Independent devil and temperature associations raise the concern that compounding constraints "
        "in landscapes where both pressures coincide may exceed what community-level redundancy alone "
        "can buffer.",
    ),
    ("Heading 3", "4.4.1. Devil density × temperature: evidence consistent with a physiological trap"),
    (
        "normal",
        "To evaluate whether warming and predator recovery jointly constrain possums, we fitted "
        "devil density, temperature and their interaction in the final HMSC model. A physiological "
        "trap could emerge when predators restrict behavioural thermoregulation and foraging while "
        "heat stress alters dietary requirements and detoxification demand. Both main effects showed "
        "strong genome-level associations directionally consistent with compensatory logic.",
    ),
    (
        "normal",
        "Among 207 genomes with non-neutral responses to both devil density and temperature, all "
        "were directionally congruent (112 devil-positive and temperature-positive; 95 "
        "devil-negative and temperature-negative; no discordant pairs), indicating parallel filtering "
        "of a shared stress-responsive core within Bacillota_A rather than independent turnover "
        "along orthogonal axes.",
    ),
    (
        "normal",
        "The fitted devil × temperature interaction identified a further layer of non-additivity: "
        "119 genomes (21%) showed a positive interaction coefficient and 102 (18%) a negative "
        "interaction. Because interaction-positive genomes largely overlapped devil-negative "
        "genomes, functional testing used mean HMSC interaction β across genomes carrying each GIFT "
        "element rather than abundance contrasts between interaction-positive and interaction-negative "
        "MAGs. Sixteen GIFT elements met FDR < 0.05 (|mean β| ≥ 0.05): positive mean β was enriched "
        "for nitrogen-compound degradation, amino-acid degradation and vitamin biosynthesis, whereas "
        "negative mean β reflected lipid and sugar degradation. Interaction-negative genomes were "
        "predominantly devil-positive and temperature-positive—lineages recruited under both main "
        "gradients whose joint responses fell short of additive expectation. Together, congruent main "
        "effects and antagonistic interaction coefficients are compatible with compensatory reweighting "
        "that may approach limits when both stressors intensify together.",
    ),
    (
        "normal",
        "Interpretation must remain cautious: devil density and temperature are spatially structured "
        "across Tasmania, and devils occur only on the island. The evidence supports directional "
        "consistency rather than confirmation of synergistic effects; targeted sampling across "
        "warm/dry versus cool/wet regions with contrasting devil densities—and paired diet or stress "
        "biomarkers—would be needed for causal tests.",
    ),
    ("normal", ""),
    ("Heading 2", "4.5. HMSC, ordination, and technical validation"),
    (
        "normal",
        "Ecological signals were detectable with ordination and PERMANOVA, but HMSC provided a deeper "
        "genome-resolved perspective—simultaneous evaluation of community covariance with multiple "
        "predictors while accounting for study design and shared evolutionary history. Phylogenetic "
        "signal in genome responses suggests environmental sensitivities are conserved within clades "
        "rather than randomly distributed, so gradient shifts reflect structured reweighting of "
        "phylogenetically coherent groups with correlated trait repertoires. Joint modelling thus "
        "complements beta-diversity metrics by enabling mechanistic hypotheses at genome and trait-bundle "
        "resolution.",
    ),
    (
        "normal",
        "Technical validation was supported by SingleM microbial-fraction estimation for lineages "
        "missing from reference databases, reinforcing that functional inferences rest on a "
        "genome-resolved metagenomic landscape.",
    ),
    ("normal", ""),
    ("Heading 2", "4.6. Broader applicability across taxa and systems"),
    (
        "normal",
        "Although grounded in a single marsupial host, the functional principles are likely not "
        "system-specific. Microbiome-mediated functional homeostasis despite extensive taxonomic "
        "turnover provides a scalable framework for other generalist vertebrates facing rapid "
        "environmental perturbation. Analogous taxonomic–functional decouplings have been reported "
        "from marine fish to soil-dwelling mammals. Thermal gradients, predation-induced behavioural "
        "restriction and dietary compression are increasingly common under anthropogenic change, "
        "positioning the metagenome as an axis of phenotypic plasticity that complements—and may "
        "sometimes exceed—host genomic adaptive capacity.",
    ),
    (
        "normal",
        "The present results only partially support the view that the microbiome can buffer host "
        "viability under rapid environmental change. The gut microbiome is more accurately "
        "characterised as a rapidly responding axis of phenotypic flexibility that extends, but does "
        "not replace, the adaptive repertoire of the host. Testing whether specific functional "
        "enrichments recur under equivalent selective pressures in other taxa would advance the "
        "generalisability of the holobiont framework for conservation biology.",
    ),
    ("normal", ""),
    ("Heading 2", "4.7. Limitations and caveats"),
    (
        "normal",
        "Several limitations apply. Environmental variables—land cover, climate layers and modelled "
        "devil density—are coarse proxies for individual experience; diet, microhabitat use and "
        "physiological stress markers would help disentangle dietary from stress-mediated mechanisms. "
        "Sampling was regionally imbalanced (55 Tasmania versus 17 mainland samples for broader "
        "analyses; HMSC restricted to 55 Tasmania samples and 576 genomes whereas α/β-diversity used "
        "72 analysed samples). Devil density and temperature are partially confounded geographically, "
        "limiting robust inference on their interaction. The cross-sectional design cannot resolve "
        "seasonal turnover or reconfiguration rates. HMSC identifies associations, not causation. "
        "Finally, unmapped metagenomic reads likely contain diversity and function not represented in "
        "the MAG catalogue.",
    ),
    ("normal", ""),
    ("Heading 2", "4.8. Implications for holobiont resilience and conservation"),
    (
        "normal",
        "Core functional stability supports redundancy, but targeted genome-level shifts along devil "
        "and temperature gradients—biosynthesis, degradation and detoxification—are consistent with "
        "compensatory roles that may become limiting when both stressors coincide. If predator recovery "
        "and climatic warming intensify together, persistence may depend on whether populations carry "
        "microbiome configurations capable of biosynthetic and detoxification compensation—a "
        "hologenomic extension of translocation risk assessment. Experimental validation (diet "
        "metabarcoding, stress biomarkers, microbiota manipulations) should precede management "
        "interventions such as probiotics or bioaugmentation.",
    ),
    (
        "normal",
        "Future priorities include (1) plant DNA metabarcoding to link behavioural shifts to realised "
        "dietary chemistry; (2) targeted sampling across Tasmania contrasting warm/dry versus cool/wet "
        "regions with varying devil densities to test interaction predictions; and (3) experimental "
        "manipulations or microbiota transplants to establish causal roles for microbiome-mediated "
        "buffering. Despite these limitations, T. vulpecula hosts a gut microbiome that is "
        "taxonomically responsive yet functionally robust at community scale, with genome-resolved "
        "evidence for parallel stress-associated compensation that informs how holobiont frameworks "
        "can be applied to wildlife under global change.",
    ),
]


def main() -> None:
    if not MANUSCRIPT.exists():
        raise SystemExit(f"Missing manuscript: {MANUSCRIPT}")

    if not BACKUP.exists():
        shutil.copy2(MANUSCRIPT, BACKUP)

    doc = Document(str(MANUSCRIPT))

    disc_idx = find_paragraph_index(doc, lambda t: t == "4 | Discussion")
    outlook_idx = find_paragraph_index(doc, lambda t: t == "5 | Outlook")

    # Remove everything between the Discussion heading and Outlook (back to front).
    for para in list(doc.paragraphs[disc_idx + 1 : outlook_idx]):
        remove_paragraph(para)

    anchor = doc.paragraphs[disc_idx]
    for style, text in DISCUSSION_BLOCKS:
        anchor = insert_paragraph_after(anchor, text, style=style)

    doc.save(str(MANUSCRIPT))
    print(f"Backup: {BACKUP}")
    print(f"Updated: {MANUSCRIPT}")
    print(f"Inserted {len(DISCUSSION_BLOCKS)} discussion blocks (green markup).")


if __name__ == "__main__":
    main()
