#MAG Catalouge

# Generate the phylum color heatmap
phylum_heatmap <- read_tsv("https://raw.githubusercontent.com/earthhologenome/EHI_taxonomy_colour/main/ehi_phylum_colors.tsv") %>%
  right_join(genome_metadata, by=join_by(phylum == phylum)) %>%
  arrange(match(genome, genome_tree$tip.label)) %>%
  select(genome,phylum) %>%
  mutate(phylum = factor(phylum, levels = unique(phylum))) %>%
  column_to_rownames(var = "genome")

# Generate  basal tree
circular_tree <- force.ultrametric(genome_tree, method="extend") %>% # extend to ultrametric for the sake of visualisation
  ggtree(., layout="fan", open.angle=10, size=0.5)

# Add phylum ring
circular_tree <- gheatmap(circular_tree, phylum_heatmap, offset=0.55, width=0.1, colnames=FALSE) +
  scale_fill_manual(values=phylum_colors) +
  geom_tiplab2(size=1, hjust=-0.1) +
  theme(legend.position = "none", plot.margin = margin(0, 0, 0, 0), panel.margin = margin(0, 0, 0, 0))

# Flush color scale to enable a new color scheme in the next ring
circular_tree <- circular_tree + new_scale_fill()

# Add completeness ring
circular_tree <- circular_tree +
  new_scale_fill() +
  scale_fill_gradient(low = "#d1f4ba", high = "#f4baba") +
  geom_fruit(
    data=genome_metadata,
    geom=geom_bar,
    mapping = aes(x=completeness, y=genome, fill=contamination),
    offset = 0.55,
    orientation="y",
    stat="identity")

# Add genome-size ring
circular_tree <-  circular_tree +
  new_scale_fill() +
  scale_fill_manual(values = "#cccccc") +
  geom_fruit(
    data=genome_metadata,
    geom=geom_bar,
    mapping = aes(x=length, y=genome),
    offset = 0.05,
    orientation="y",
    stat="identity")


# Add text
#Doesnt look good so maybe add afterwards via Gimp or the likes
circular_tree <- circular_tree +
  annotate('text', x=3.4, y=0, label='Phylum', size=3) +
  annotate('text', x=4.25, y=0, label='Genome quality', size=3) +
  annotate('text', x=4.85, y=0, label='Genome size', size=3)


ggsave("clean_circular_tree_large.png", plot=circular_tree, dpi=300, width=50, height=50, limitsize = FALSE)

pdf("clean_circular_tree_large.pdf", width=50, height=50)
print(circular_tree)
dev.off()

  