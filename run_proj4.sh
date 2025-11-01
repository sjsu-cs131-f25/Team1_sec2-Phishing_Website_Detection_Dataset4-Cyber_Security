#!/usr/bin/env bash
#Sprint 4: Phishermen

INPUT="/mnt/scratch/CS131_jelenag/projects/team01_sec2/dataset4.csv"
OUTDIR="output4"

# chmod -R g+rX "$INPUT"

# Create output dir
mkdir -p "$OUTDIR"

#set -euo pipefail
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo
echo "Sprint 4 starting..."
echo
echo

echo "1000 Value Sample of Dataset Before Anything..."
head -n 101 "$INPUT" > "$OUTDIR/sample1kBefore.csv"
echo "sample1kBefore.csv"
echo

echo "Step 1: Data cleaning and Normalization..."
awk 'BEGIN{FS=OFS=","} NR==2 {$30="FIX ME: GIVE ME A TITLE"} 1' "$INPUT" > datasetClean.csv
sed -i 's/SpacialCharRatioInURL/SpecialCharRatioInURL/' datasetClean.csv
sed -i 's/NoOfDegitsInURL/NoOfDigitsInURL/' datasetClean.csv
sed -i 's/DegitRatioInURL/DigitRatioInURL/' datasetClean.csv
sed -i 's/FILENAME/FileName/' datasetClean.csv
sed -i 's/label/Label/' datasetClean.csv
sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/ /g' datasetClean.csv > tmp && mv tmp datasetClean.csv
sed -i 's/"/'\''/g' datasetClean.csv
sed -e 's/<[^>]*>//g' datasetClean.csv > tmp && mv tmp datasetClean.csv
echo "Created: datasetClean.csv"

echo "1000 Value Sample of Dataset After Step 1..."
head -n 101 datasetClean.csv > "$OUTDIR/sample1kAfterS1.csv" 
echo "sample1kAfterS1.csv"
echo

echo "~~~~~~~~~~~~~~~~~~~~~~"
echo

echo "Step 2: Skinny tables & frequency tables..."
echo "Freq Table 1: How many URLs have Low, Med, High TLDLegitProb?"
awk -F',' 'NR>1{if($10==1)b="ONE";else{r=$10;b=(r==0?"ZERO":(r>=0.8?"HIGHER":(r>=0.6?"HIGH":(r>=0.4?"MID":(r>=0.2?"LOW":"LOWER")))))} c[b]++} NR==1 {print $10} END{for(k in c)print k,c[k]}' OFS='\t' datasetClean.csv > "$OUTDIR/freq_TLDLegitProb.tsv"
cat "$OUTDIR/freq_TLDLegitProb.tsv"
echo

echo "Freq Table 2: How many URLs have Low, Med, High URLCharProb?"
awk -F',' 'NR>1{if($11==1)b="ONE";else{r=$11;b=(r==0?"ZERO":(r>=0.8?"HIGHER":(r>=0.6?"HIGH":(r>=0.4?"MID":(r>=0.2?"LOW":"LOWER")))))} c[b]++} NR==1 {print $11} END{for(k in c)print k,c[k]}' OFS='\t' datasetClean.csv > "$OUTDIR/freq_URLCharProb.tsv"
cat "$OUTDIR/freq_URLCharProb.tsv"
echo

echo "Top 30 Table: What are the top TLDs based on their Legitimate Probability?"
tail -n +1 datasetClean.csv | cut -d',' -f7,10 | sort -t',' -k1,1 -k2,2 | uniq -c | sort -nr | head -n 30 > "$OUTDIR/top30_TLD_for_TLDLegitimateProb.csv"
echo "  count TLD     TLDLegitimateProb" > "$OUTDIR/top30_TLD_for_TLDLegitimateProb.tsv"
#mv top30_TLD_for_TLDLegitimateProb.tsv "$OUTDIR"
sed 's/,/\t/g' "$OUTDIR/top30_TLD_for_TLDLegitimateProb.csv" >> "$OUTDIR/top30_TLD_for_TLDLegitimateProb.tsv"
rm -f "$OUTDIR/top30_TLD_for_TLDLegitimateProb.csv" 
cat "$OUTDIR/top30_TLD_for_TLDLegitimateProb.tsv"
echo

echo "Skinny Table: URL, Domain, URLSimilarityIndex"
awk -F',' '{print $2"\t"$4"\t"$8}' datasetClean.csv > "$OUTDIR/skinnyTable_URLSimilarityIndex.tsv"
 cat "$OUTDIR/skinnyTable_URLSimilarityIndex.tsv" | head -n 10
#echo "*no preview*"
echo
echo "Created: freq_TLDLegitProb.tsv, freq_URLCharProb.tsv, top30_TLD_for_TLDLegitimateProb.tsv, skinnyTable_URLSimilarityIndex.tsv"
echo

echo "~~~~~~~~~~~~~~~~~~~~~~"
echo

echo "Step 3: Clean up rows that should have "0" or "1" values..."

COLUMNS="6,14,26,29,33,34,35,38,41,42,43,44,45,46,47,48,49,56"; \
awk -F',' -v OFS='\t' -v cols="$COLUMNS" '
BEGIN{ n=split(cols,col,/,/) }
NR==1{
  for (j=1;j<=NF;j++){ f=$j; gsub(/^[ \t]+|[ \t]+$|^"|"$/,"",f); printf "%s%s",f,(j==NF?ORS:OFS) }
  next
}
{
  keep=1
  for(i=1;i<=n;i++){
    c=col[i]+0
    if(c<1||c>NF){ keep=0; break }
    v=$(c); gsub(/^[ \t]+|[ \t]+$|^"|"$/,"",v)
    if(v !~ /^-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?$/){ keep=0; break }
    x=v+0; if(x!=0&&x!=1){ keep=0; break }
  }
  if(keep){
    for (j=1;j<=NF;j++){ f=$j; gsub(/^[ \t]+|[ \t]+$|^"|"$/,"",f); printf "%s%s",f,(j==NF?ORS:OFS) }
  }
}
' datasetClean.csv > datasetFiltered.tsv

echo "Created: datasetFiltered.tsv"
echo

echo "Also, removing columns that cause problems (1, 29, 30, 31, 32, 42, 46, 47, 48, 49)..."
cut -d$'\t' -f2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,33,34,35,36,37,38,39,40,41,43,44,45,50,51,52,53,54,55,56 datasetFiltered.tsv > datasetRemCol.tsv
echo "Created: datasetRemCol.tsv"
echo

echo "1000 Value Samples of Dataset After Step 3..."
head -n 101 datasetFiltered.tsv > "$OUTDIR/sample1kAfterS3F.tsv"
echo "sample1kAfterS3F.tsv -> for datasetFiltered.tsv"

head -n 101 datasetRemCol.tsv > "$OUTDIR/sample1kAfterS3RC.tsv"
echo "sample1kAfterS3RC.tsv -> for datasetRemCol.tsv"
echo

echo "~~~~~~~~~~~~~~~~~~~~~~"
echo

echo "Step 4: Compute ratios and create a bucketization..."
awk -F'\t' -v OFS='\t' ' NR>1{f=$1; img=$50+0; css=$51+0; if(css>0) r=img/css; else r=0; if(r==0) b="ZERO"; else if(r<1) b="LOW"; else if(r<3) b="MID"; else b="HIGH"; bucket[b]++; sum[f]+=r; cnt[f]++} END{print "\nband    count"; for(b in bucket) printf "%s\t%d\n",b,bucket[b]; print "\nfile\t\tcount\tIMG_to_CSS_ratio"; for(f in cnt) printf "%s\t%d\t%.2f\n",f,cnt[f],sum[f]/cnt[f]}' datasetFiltered.tsv > "$OUTDIR/ratioIMGtoCSS.tsv"
 cat "$OUTDIR/ratioIMGtoCSS.tsv" | head
#echo "*no preview*"
echo
echo "Created: ratioIMGtoCSS.tsv"
echo

echo "~~~~~~~~~~~~~~~~~~~~~~"
echo

echo "Step 5: String Structure (compute domain length buckets (short: char<10, medium: char>=10 && char<=20, long: char>20) and show the distribution for domain frequencies)..."
{ awk -F'\t' -v OFS='\t' 'NR>1{dom=$4;gsub(/^[ \t]+|[ \t]+$/,"",dom);if(dom!=""){d=length(dom);if(d<10)b["short"]++;else if(d<=20)b["medium"]++;else b["long"]++}}
END{print "domain_length_bucket\tcount";
    printf "short\t\t\t%d\n",0+b["short"];
    printf "medium\t\t\t%d\n",0+b["medium"];
    printf "long\t\t\t%d\n",0+b["long"];
    print "";
    print "domain\tcount"}' datasetFiltered.tsv;
  awk -F'\t' 'NR>1{dom=$4;gsub(/^[ \t]+|[ \t]+$/,"",dom);if(dom!="")f[dom]++}
END{for(d in f)printf "%s\t%d\n",d,f[d]}' datasetFiltered.tsv \
  | LC_ALL=C sort -k2,2nr -k1,1;} > "$OUTDIR/strStructureDomain.tsv" 
 cat "$OUTDIR/strStructureDomain.tsv" | head -n 10
#echo "*no preview*"
echo
echo "Created: strStructureDomain.tsv"
echo

echo "~~~~~~~~~~~~~~~~~~~~~~"
echo

echo "Step 6: Compute mean, std, min, max for numerical categories and create outlier flags for signal discovery (preview of the first 10 values)..."
echo "Distribution Profiles with datasetFiltered.tsv..."
TMP1="$(mktemp)"; awk -F'\t' -v OFS='\t' 'NR==1 { m=NF; for(i=1;i<=NF;i++) name[i]=$i; next }
{
  for(i=1;i<=m;i++){
    v=$i; gsub(/^[ \t]+|[ \t]+$/, "", v)
    if (v ~ /^-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?$/) {
      x=v+0; n[i]++; s[i]+=x; ss[i]+=x*x
      if(!(i in min)||x<min[i]) min[i]=x
      if(!(i in max)||x>max[i]) max[i]=x
    }
  }
}
END{
  for(i=1;i<=m;i++){
    if(n[i]>0){
      mean=s[i]/n[i]
      if(n[i]>1){ var=(ss[i]-s[i]*s[i]/n[i])/(n[i]-1); if(var<0)var=0 } else var=0
      std=sqrt(var); lo=mean-2*std; up=mean+2*std
      printf "%d\t%s\t%.6f\t%.6f\t%s\t%s\t%.6f\t%.6f\n", i,name[i],mean,std,min[i],max[i],lo,up
    } else {
      printf "%d\t%s\tNA\tNA\tNA\tNA\tNA\tNA\n", i,name[i]
    }
  }
}' datasetFiltered.tsv > "$TMP1"

awk -F'\t' -v OFS='\t' '                       
NR==FNR { i=$1; name[i]=$2; mean[i]=$3; std[i]=$4; minv[i]=$5; maxv[i]=$6; lo[i]=$7; up[i]=$8; if(i>m)m=i; next }
NR==1 { next }
{
  for(i=1;i<=m;i++){
    v=$i; gsub(/^[ \t]+|[ \t]+$/, "", v)
    if (v ~ /^-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?$/ && lo[i]!="NA"){
      x=v+0; if(x<lo[i]||x>up[i]) out[i]++
    }
  }
}
END{
  print "column_name\tmean\tstd\tmin\tmax\toutliers"
  for(i=1;i<=m;i++) printf "%s\t%s\t%s\t%s\t%s\t%d\n", name[i],mean[i],std[i],minv[i],maxv[i],0+out[i]}' "$TMP1" datasetFiltered.tsv > "$OUTDIR/signalDiscovery_with_Filtered.tsv"

cat "$OUTDIR/signalDiscovery_with_Filtered.tsv" | head -n 10
echo
echo "Distribution Profiles with datasetRemCol.tsv..."
TMP1="$(mktemp)"; awk -F'\t' -v OFS='\t' 'NR==1 { m=NF; for(i=1;i<=NF;i++) name[i]=$i; next }
{
  for(i=1;i<=m;i++){
    v=$i; gsub(/^[ \t]+|[ \t]+$/, "", v)
    if (v ~ /^-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?$/) {
      x=v+0; n[i]++; s[i]+=x; ss[i]+=x*x
      if(!(i in min)||x<min[i]) min[i]=x
      if(!(i in max)||x>max[i]) max[i]=x
    }
  }
}
END{
  for(i=1;i<=m;i++){
    if(n[i]>0){
      mean=s[i]/n[i]
      if(n[i]>1){ var=(ss[i]-s[i]*s[i]/n[i])/(n[i]-1); if(var<0)var=0 } else var=0
      std=sqrt(var); lo=mean-2*std; up=mean+2*std
      printf "%d\t%s\t%.6f\t%.6f\t%s\t%s\t%.6f\t%.6f\n", i,name[i],mean,std,min[i],max[i],lo,up
    } else {
      printf "%d\t%s\tNA\tNA\tNA\tNA\tNA\tNA\n", i,name[i]
    }
  }
}' datasetRemCol.tsv > "$TMP1"

awk -F'\t' -v OFS='\t' '
NR==FNR { i=$1; name[i]=$2; mean[i]=$3; std[i]=$4; minv[i]=$5; maxv[i]=$6; lo[i]=$7; up[i]=$8; if(i>m)m=i; next }
NR==1 { next }
{
  for(i=1;i<=m;i++){
    v=$i; gsub(/^[ \t]+|[ \t]+$/, "", v)
    if (v ~ /^-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?$/ && lo[i]!="NA"){
      x=v+0; if(x<lo[i]||x>up[i]) out[i]++
    }
  }
}
END{
  print "column_name\tmean\tstd\tmin\tmax\toutliers"
  for(i=1;i<=m;i++) printf "%s\t%s\t%s\t%s\t%s\t%d\n", name[i],mean[i],std[i],minv[i],maxv[i],0+out[i]}' "$TMP1" datasetRemCol.tsv > "$OUTDIR/signalDiscovery_with_RemCol.tsv"

cat "$OUTDIR/signalDiscovery_with_RemCol.tsv" | head -n 10
echo
echo "Created: signalDiscovery_with_Filtered.tsv, signalDiscovery_with_RemCol.tsv"
echo
mv datasetFiltered.tsv "$OUTDIR/datasetFiltered.tsv"
mv datasetRemCol.tsv "$OUTDIR/datasetRemCol.tsv"
mv datasetClean.csv "$OUTDIR/datasetClean.csv"
mv  "$OUTDIR" data/
echo
echo "Sprint 4 Completed"
echo
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
