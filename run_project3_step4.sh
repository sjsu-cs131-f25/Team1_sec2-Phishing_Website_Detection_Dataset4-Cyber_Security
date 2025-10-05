set -euo pipefail
OUT=out
RAW=data/samples/dataset_1k_random_samples.csv   # adjust if you switch to full CSV
URL_COL=2                                        # URL column (1-based)
STOP='^(http|https|www|com|html|amp|org|net|app|web|php|edu|top)$'
mkdir -p "$OUT"
cut -d',' -f"$URL_COL" "$RAW" 2> "$OUT/overall_cut.errors" \
| tail -n +2 \
| tr '[:upper:]' '[:lower:]' \
| grep -oE '[a-z0-9]{3,}' \
| grep -Ev "$STOP" \
| sort | uniq -c | sort -nr \
| tee "$OUT/top30_overall_full.txt" \
| head -30 > "$OUT/top30_overall.txt"
cut -f2 "$OUT/edges_thresholded.tsv" \
| tr '[:upper:]' '[:lower:]' \
| grep -oE '[a-z0-9]{3,}' \
| grep -Ev "$STOP" \
| sort | uniq -c | sort -nr | head -30 > "$OUT/top30_clusters.txt"
awk '{print $2}' "$OUT/top30_overall.txt"  | sort > "$OUT/top30_overall.tokens"
awk '{print $2}' "$OUT/top30_clusters.txt" | sort > "$OUT/top30_clusters.tokens"
sed -i.bak '/^[0-9]\+$/d' "$OUT/top30_overall.tokens"
sed -i.bak '/^[0-9]\+$/d' "$OUT/top30_clusters.tokens"
{
  echo "=== In clusters only ==="
  comm -23 "$OUT/top30_clusters.tokens" "$OUT/top30_overall.tokens"
  echo
  echo "=== In overall only ==="
  comm -13 "$OUT/top30_clusters.tokens" "$OUT/top30_overall.tokens"
  echo
  echo "=== In both ==="
  comm -12 "$OUT/top30_clusters.tokens" "$OUT/top30_overall.tokens"
} > "$OUT/diff_top30.txt"
cut -d',' -f"$URL_COL" "$RAW" \
| grep -i 'login\|account\|verify' | head -5 > "$OUT/grep_i_examples.txt"
cut -d',' -f"$URL_COL" "$RAW" \
| grep -vi 'google\|accounts\.google' | head -5 > "$OUT/grep_v_examples.txt"
echo "[Step4] Wrote:"
ls -1 "$OUT"/top30_overall.txt "$OUT"/top30_clusters.txt "$OUT"/diff_top30.txt "$OUT"/grep_*_examples.txt
