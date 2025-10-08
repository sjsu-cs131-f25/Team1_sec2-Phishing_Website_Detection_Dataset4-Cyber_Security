INPUT="/mnt/scratch/CS131_jelenag/projects/team01_sec2/dataset4.csv"
OUTDIR="Team1_sec2-Phishing_Website_Detection_Dataset4-Cyber_Security/data/output3"

# Allow overrides: N=50 ./proj3.sh, TOPK=20 ./proj3.sh, CAP=100 ./proj3.sh
N="${N:-50}"          # Step 2 threshold (min edges per Domain)
TOPK="${TOPK:-20}"    # Step 5: number of top domains to visualize
CAP="${CAP:-100}"     # Step 5

chmod -R g+rX "$INPUT" || true

# Create output dir
mkdir -p "$OUTDIR"


echo "SETUP"
echo "------------------------------------------------------------------------------"
echo "Started:        $(date -Iseconds)"
echo "Input:          ${INPUT}"
echo "Output dir:     ${OUTDIR}"
echo "Top-N (N):      ${N}"
echo "TOPK domains:   ${TOPK}"
echo "CAP per domain: ${CAP}"
echo "Working dir:    $(pwd)"
echo "------------------------------------------------------------------------------"
[ -s "$INPUT" ] && echo "Input check:    OK (file exists & non-empty)" || { echo "Input check:    FAIL"; exit 1; }
echo


# ========================= STEP 1: Build edges.tsv ============================
echo "===== STEP 1: Building edges.tsv (Domain, URL) ====="
# Normalize Domain (col 4) to hostname: lowercase, strip scheme/path, drop leading 'www.'
{
  echo -e "Domain\tURL"
  awk -F',' '
    NR==1 { next } # skip header
    {
      raw=$4; u=$2
      host=tolower(raw)
      sub(/^[a-z]+:\/\//, "", host)  # strip scheme
      sub(/\/.*/, "", host)          # drop path/query
      sub(/^www\./, "", host)        # drop leading www.
      gsub(/[[:space:]]+$/, "", host)
      gsub(/[[:space:]]+$/, "", u)
      if (host != "" && u != "") print host "\t" u
    }' "$INPUT" \
  | sort -t $'\t' -k1,1 -k2,2 | uniq
} > "$OUTDIR/edges.tsv"

echo "edges.tsv -> $OUTDIR/edges.tsv"
echo


# ==================== STEP 2: entity_counts + threshold =======================
echo "===== STEP 2: entity_counts.tsv + edges_thresholded.tsv (N=$N) ====="
awk -F'\t' 'NR>1{cnt[$1]++} END{
  print "Entity\tCount"
  for (k in cnt) print k "\t" cnt[k]
}' "$OUTDIR/edges.tsv" \
| sort -k2,2nr > "$OUTDIR/entity_counts.tsv"

# Build thresholded edge list (keep header)
awk -F'\t' -v n="$N" 'NR>1 && $2>=n {print $1}' "$OUTDIR/entity_counts.tsv" > "$OUTDIR/_keep.txt"
awk -F'\t' 'NR==FNR{keep[$1]=1; next}
            NR==1{print; next}
            (keep[$1])' "$OUTDIR/_keep.txt" "$OUTDIR/edges.tsv" > "$OUTDIR/edges_thresholded.tsv"
rm -f "$OUTDIR/_keep.txt"

echo "entity_counts.tsv      -> $OUTDIR/entity_counts.tsv"
echo "edges_thresholded.tsv  -> $OUTDIR/edges_thresholded.tsv"
echo


# ====================== STEP 3: Histogram of cluster sizes ====================
echo "===== STEP 3: cluster_sizes.tsv + cluster_histogram.png ====="
# cluster_sizes.tsv: per-domain edge counts in the kept subgraph
awk -F'\t' '
  NR==1 { next }                 # skip header
  { cnt[$1]++ }
  END {
    print "Domain\tClusterSize"
    for (k in cnt) print k "\t" cnt[k]
  }' "$OUTDIR/edges_thresholded.tsv" \
| sort -k2,2nr > "$OUTDIR/cluster_sizes.tsv"

# Build size->frequency table for gnuplot histogram (bin size = 1)
tail -n +2 "$OUTDIR/cluster_sizes.tsv" | cut -f2 | sort -n | uniq -c \
  | awk 'BEGIN{OFS="\t"} {print $2,$1}' > "$OUTDIR/_hist.tsv"

# Non-interactive gnuplot render
if command -v gnuplot >/dev/null 2>&1; then
  gnuplot <<GPLOT
set terminal pngcairo size 900,500
set output '${OUTDIR}/cluster_histogram.png'
set boxwidth 0.9
set style fill solid 1.0
set xlabel 'Number of URLs per Domain'
set ylabel 'Number of Domains'
set title 'Histogram of Cluster Sizes (bin = 1)'
set xtics 1
plot '${OUTDIR}/_hist.tsv' using 1:2 with boxes notitle
GPLOT
else
  echo "SKIP: gnuplot not found; no cluster_histogram.png"
fi
rm -f "$OUTDIR/_hist.tsv"

echo "cluster_sizes.tsv      -> $OUTDIR/cluster_sizes.tsv"
[ -f "$OUTDIR/cluster_histogram.png" ] && echo "cluster_histogram.png  -> $OUTDIR/cluster_histogram.png"
echo



# =================== STEP 4: Top-30 tokens + diff =============================
echo "===== STEP 4: top30 tokens (overall vs clusters) ====="
# Tokenize URLs (right column) by common delimiters, lowercase, alnum-only, count
tail -n +2 "$OUTDIR/edges.tsv" | cut -f2 \
  | tr '/:._?=&+%[]()' '\n' | tr '[:upper:]' '[:lower:]' \
  | grep -E '^[a-z0-9]+$' \
  | sort | uniq -c | sort -nr | head -30 > "$OUTDIR/top30_overall.txt"

tail -n +2 "$OUTDIR/edges_thresholded.tsv" | cut -f2 \
  | tr '/:._?=&+%[]()' '\n' | tr '[:upper:]' '[:lower:]' \
  | grep -E '^[a-z0-9]+$' \
  | sort | uniq -c | sort -nr | head -30 > "$OUTDIR/top30_clusters.txt"

# Robust diff: compare token sets only
awk '{print $2}' "$OUTDIR/top30_clusters.txt" | sort -u > "$OUTDIR/_c.txt"
awk '{print $2}' "$OUTDIR/top30_overall.txt"  | sort -u > "$OUTDIR/_o.txt"
comm -23 "$OUTDIR/_c.txt" "$OUTDIR/_o.txt" | sed 's/^/only_in_clusters\t/' >  "$OUTDIR/diff_top30.txt"
comm -13 "$OUTDIR/_c.txt" "$OUTDIR/_o.txt" | sed 's/^/only_in_overall\t/'  >> "$OUTDIR/diff_top30.txt"
rm -f "$OUTDIR/_c.txt" "$OUTDIR/_o.txt"

echo "top30_overall.txt  -> $OUTDIR/top30_overall.txt"
echo "top30_clusters.txt -> $OUTDIR/top30_clusters.txt"
echo "diff_top30.txt     -> $OUTDIR/diff_top30.txt"
echo



# ============== STEP 5: Network visualization ==================
echo "===== STEP 5: cluster_viz.png (Top-${TOPK} domains, cap ${CAP}/domain) ====="
# Select Top-K domains by frequency in thresholded edges
awk -F'\t' 'NR>1{c[$1]++} END{for(k in c) print c[k]"\t"k}' "$OUTDIR/edges_thresholded.tsv" \
  | sort -nr | head -"$TOPK" | cut -f2 > "$OUTDIR/topK_domains.txt"

# Build subset edges (cap per domain to keep readable)
awk -F'\t' -v L="$CAP" 'NR==FNR{keep[$1]=1; next}
  NR==1{print; next}
  ($1 in keep){ if(++cnt[$1]<=L) print }' \
  "$OUTDIR/topK_domains.txt" "$OUTDIR/edges_thresholded.tsv" > "$OUTDIR/cluster_subset.tsv"



  # ====== STEP 6: Summary stats on numeric column (col 17) via datamash =========
echo "===== STEP 6: Summary statistics (col 17) with datamash ====="
# Build keep list of domains from thresholded edges
cut -f1 "$OUTDIR/edges_thresholded.tsv" | tail -n +2 | sort -u > "$OUTDIR/_keep_domains.txt"
awk -F',' '
  NR==FNR { keep[$1]=1; next }
  FNR==1 { next }  # skip CSV header
  {
    raw=$4; val=$17
    host=tolower(raw)
    sub(/^[a-z]+:\/\//, "", host)
    sub(/\/.*/, "", host)
    sub(/^www\./, "", host)
    if ((host in keep) && (val ~ /^-?[0-9]+(\.[0-9]+)?$/)) {
      print host "\t" val
    }
  }' "$OUTDIR/_keep_domains.txt" "$INPUT" > "$OUTDIR/left_outcome.tsv"


sort -k1,1 "$OUTDIR/left_outcome.tsv" -o "$OUTDIR/left_outcome.tsv"

if command -v datamash >/dev/null 2>&1; then
  datamash --header-out -g 1 count 2 mean 2 median 2 \
    < "$OUTDIR/left_outcome.tsv" > "$OUTDIR/cluster_outcomes.tsv"
  echo "cluster_outcomes.tsv -> $OUTDIR/cluster_outcomes.tsv"
else
  echo "SKIP: datamash not found; no cluster_outcomes.tsv"
fi



# ============================= FINISH =========================================
echo "=========================================================================="
echo "ALL DONE"
echo "Finished:       $(date -Iseconds)"
echo "Artifacts stored in: ${OUTDIR}"
ls -l "${OUTDIR}"
echo "=========================================================================="


