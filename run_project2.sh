#!/usr/bin/env bash

# Sample data path is /mnt/scratch/CS131_jelenag/projects/team01_sec2/Team1_sec2-Phishing_Website_Detection_Dataset4-Cyber_Security/data/samples/dataset_1k_random_samples.csv
# Delimiter is comma ','
# Assumption: We used tail -n +2 so that the header in the sample dataset would not interfere with the frequency and the top -N tables.

mkdir -p data/samples out

# Sample 1k (keep header + random 1000 rows)
head -n 1 dataset_1k_random_samples.csv > data/samples/sample_1k.txt
tail -n +2 dataset_1k_random_samples.csv | shuf -n 1000 >> data/samples/sample_1k.txt

# ---- Frequencies ----
# FILENAME (col 1)
tail -n +2 dataset_1k_random_samples.csv | cut -d',' -f1 | sort | uniq -c | sort -nr 2>&1 | tee out/freq_FILENAME.txt

# URLLength (col 3)
tail -n +2 dataset_1k_random_samples.csv | cut -d',' -f3 | sort | uniq -c | sort -nr 2>&1 | tee out/freq_URLLENGTH.txt

# NoOfDegitsInURL (col 19)
tail -n +2 dataset_1k_random_samples.csv | cut -d',' -f19 | sort | uniq -c | sort -nr 2>&1 | tee out/freq_DigitsInURL.txt

# ---- Top 10s ----
# HasHiddenFields (col 44)
tail -n +2 dataset_1k_random_samples.csv | cut -d',' -f44 | sort | uniq -c | sort -nr | head -10 | tee out/Top_10_HasHiddenFields.txt

#DomainTitleScoreMatch (col 31)
tail -n +2 dataset_1k_random_samples.csv | cut -d',' -f31 | sort | uniq -c | sort -nr | head -10 | tee out/Top_10_DomainTitleMatchScore.txt

# HasObfuscation (col 14)
tail -n +2 dataset_1k_random_samples.csv | cut -d',' -f14 | sort | uniq -c | sort -nr | head -10 | tee out/Top_10_hasObfuscation.txt

# ---- Skinny table ----
# URL (2), NoOfQMarkInURL (22), NoOfURLRedirect (36)
tail -n +2 dataset_1k_random_samples.csv | cut -d',' -f2,22,36 | sort -u 2>&1 | head -20 | tee out/SkinnyTable_URL_Qmark_Redirect.txt

# ---- Greps ----
# Domain search
grep -i "domain" dataset_1k_random_samples.csv > out/Domain_Search_grepi.txt

# Redirect hits + error log
grep -i "redirect" dataset_1k_random_samples.csv > out/grep_redirect_hits.txt 2> out/grep_redirect_hits.errors.log

# URLs with no question mark
grep -v "?" dataset_1k_random_samples.csv > out/URLSWithNoQmark_grepv.txt

