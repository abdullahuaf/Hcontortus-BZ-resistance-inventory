-- ============================================================
-- SQL Queries: GenBank-derived global inventory of
-- benzimidazole resistance markers in H. contortus β-tubulin 1
-- Database: sequence_analysis
-- Table: haemonchus_sequences
-- Authors: Abdullah Azeem, Muhammad Kasib Khan et al.
-- ============================================================


-- ============================================================
-- SECTION 1: DATABASE STRUCTURE VERIFICATION
-- ============================================================

-- View all tables
SHOW TABLES FROM sequence_analysis;

-- View full table structure
DESCRIBE sequence_analysis.haemonchus_sequences;

-- Count total sequences
SELECT COUNT(*) AS total_sequences 
FROM sequence_analysis.haemonchus_sequences;


-- ============================================================
-- SECTION 2: RESISTANCE FLAG ASSIGNMENT
-- Mutation flags: 0 = susceptible, 1 = resistant
-- ============================================================

-- Assign single mutation flags
UPDATE sequence_analysis.haemonchus_sequences
SET
  mut_F167Y = CASE
    WHEN sequence_fasta LIKE '%CTTCGTACTCCGTTGT%' THEN 1
    WHEN sequence_fasta LIKE '%CTTCGTTCTCCGTTGT%' THEN 0
    ELSE NULL END,

  mut_E198A = CASE
    WHEN sequence_fasta LIKE '%GCAATGCCAGAGTTGT%' THEN 1
    WHEN sequence_fasta LIKE '%GAAATGCCAGAGTTGT%' THEN 0
    ELSE NULL END,

  mut_F200Y = CASE
    WHEN sequence_fasta LIKE '%TACATGCCAGAGTTGT%' THEN 1
    WHEN sequence_fasta LIKE '%TTCATGCCAGAGTTGT%' THEN 0
    ELSE NULL END;

-- Assign combination mutation flags
UPDATE sequence_analysis.haemonchus_sequences
SET
  mut_F167Y_E198A = CASE
    WHEN mut_F167Y = 1 AND mut_E198A = 1 THEN 1
    ELSE 0 END,

  mut_F167Y_F200Y = CASE
    WHEN mut_F167Y = 1 AND mut_F200Y = 1 THEN 1
    ELSE 0 END,

  mut_E198A_F200Y = CASE
    WHEN mut_E198A = 1 AND mut_F200Y = 1 THEN 1
    ELSE 0 END,

  mut_F167Y_E198A_F200Y = CASE
    WHEN mut_F167Y = 1 AND mut_E198A = 1 AND mut_F200Y = 1 THEN 1
    ELSE 0 END;


-- ============================================================
-- SECTION 3: FILTERING — RETAIN ONLY COMPLETE SEQUENCES
-- Sequences must have all three codons covered (not NULL)
-- ============================================================

-- Count sequences excluded due to missing codon coverage
SELECT COUNT(*) AS excluded_sequences
FROM sequence_analysis.haemonchus_sequences
WHERE mut_F167Y IS NULL 
   OR mut_E198A IS NULL 
   OR mut_F200Y IS NULL;

-- Count sequences missing each specific codon
SELECT
  SUM(CASE WHEN mut_F167Y IS NULL THEN 1 ELSE 0 END) AS missing_codon_167,
  SUM(CASE WHEN mut_E198A IS NULL THEN 1 ELSE 0 END) AS missing_codon_198,
  SUM(CASE WHEN mut_F200Y IS NULL THEN 1 ELSE 0 END) AS missing_codon_200
FROM sequence_analysis.haemonchus_sequences;

-- Remove incomplete sequences (backup first!)
-- CREATE TABLE haemonchus_sequences_backup AS SELECT * FROM haemonchus_sequences;
DELETE FROM sequence_analysis.haemonchus_sequences
WHERE mut_F167Y IS NULL 
   OR mut_E198A IS NULL 
   OR mut_F200Y IS NULL;

-- Verify final retained count
SELECT COUNT(*) AS final_sequences
FROM sequence_analysis.haemonchus_sequences;


-- ============================================================
-- SECTION 4: OVERALL RESISTANCE SUMMARY
-- ============================================================

SELECT
  COUNT(*) AS total_sequences,
  SUM(CASE WHEN mut_F167Y=1 OR mut_E198A=1 OR mut_F200Y=1 THEN 1 ELSE 0 END) AS total_resistant,
  SUM(CASE WHEN mut_F167Y=0 AND mut_E198A=0 AND mut_F200Y=0 THEN 1 ELSE 0 END) AS total_susceptible,
  ROUND(100.0 * SUM(CASE WHEN mut_F167Y=1 OR mut_E198A=1 OR mut_F200Y=1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS resistance_percent
FROM sequence_analysis.haemonchus_sequences;


-- ============================================================
-- SECTION 5: CODON-SPECIFIC RESISTANCE DISTRIBUTION (TABLE 1)
-- ============================================================

SELECT
  'F200Y'           AS mutation, COUNT(*) AS total,
  SUM(CASE WHEN mut_F200Y=1 THEN 1 ELSE 0 END) AS resistant,
  ROUND(100.0*SUM(CASE WHEN mut_F200Y=1 THEN 1 ELSE 0 END)/COUNT(*),1) AS percent
FROM sequence_analysis.haemonchus_sequences
UNION ALL
SELECT 'F167Y', COUNT(*),
  SUM(CASE WHEN mut_F167Y=1 THEN 1 ELSE 0 END),
  ROUND(100.0*SUM(CASE WHEN mut_F167Y=1 THEN 1 ELSE 0 END)/COUNT(*),1)
FROM sequence_analysis.haemonchus_sequences
UNION ALL
SELECT 'E198A', COUNT(*),
  SUM(CASE WHEN mut_E198A=1 THEN 1 ELSE 0 END),
  ROUND(100.0*SUM(CASE WHEN mut_E198A=1 THEN 1 ELSE 0 END)/COUNT(*),1)
FROM sequence_analysis.haemonchus_sequences
UNION ALL
SELECT 'F167Y + F200Y (double)', COUNT(*),
  SUM(CASE WHEN mut_F167Y_F200Y=1 THEN 1 ELSE 0 END),
  ROUND(100.0*SUM(CASE WHEN mut_F167Y_F200Y=1 THEN 1 ELSE 0 END)/COUNT(*),1)
FROM sequence_analysis.haemonchus_sequences
UNION ALL
SELECT 'F167Y + E198A (double)', COUNT(*),
  SUM(CASE WHEN mut_F167Y_E198A=1 THEN 1 ELSE 0 END),
  ROUND(100.0*SUM(CASE WHEN mut_F167Y_E198A=1 THEN 1 ELSE 0 END)/COUNT(*),1)
FROM sequence_analysis.haemonchus_sequences
UNION ALL
SELECT 'E198A + F200Y (double)', COUNT(*),
  SUM(CASE WHEN mut_E198A_F200Y=1 THEN 1 ELSE 0 END),
  ROUND(100.0*SUM(CASE WHEN mut_E198A_F200Y=1 THEN 1 ELSE 0 END)/COUNT(*),1)
FROM sequence_analysis.haemonchus_sequences
UNION ALL
SELECT 'F167Y + E198A + F200Y (triple)', COUNT(*),
  SUM(CASE WHEN mut_F167Y_E198A_F200Y=1 THEN 1 ELSE 0 END),
  ROUND(100.0*SUM(CASE WHEN mut_F167Y_E198A_F200Y=1 THEN 1 ELSE 0 END)/COUNT(*),1)
FROM sequence_analysis.haemonchus_sequences;


-- ============================================================
-- SECTION 6: YEAR-WISE RESISTANCE DISTRIBUTION (FIGURE 2)
-- ============================================================

SELECT
  YEAR(STR_TO_DATE(date, '%d-%b-%Y')) AS collection_year,
  COUNT(*) AS total_sequences,
  SUM(CASE WHEN mut_F167Y=1 OR mut_E198A=1 OR mut_F200Y=1 THEN 1 ELSE 0 END) AS resistant,
  SUM(CASE WHEN mut_F167Y=0 AND mut_E198A=0 AND mut_F200Y=0 THEN 1 ELSE 0 END) AS susceptible,
  ROUND(100.0 * SUM(CASE WHEN mut_F167Y=1 OR mut_E198A=1 OR mut_F200Y=1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS resistance_percent
FROM sequence_analysis.haemonchus_sequences
GROUP BY collection_year
ORDER BY collection_year;


-- ============================================================
-- SECTION 7: GEOGRAPHIC DISTRIBUTION (FIGURE 3)
-- ============================================================

-- 3A: Sampling effort by country
SELECT
  COALESCE(NULLIF(TRIM(source_geo_loc_name), ''), 'Unknown') AS country,
  COUNT(*) AS total_sequences
FROM sequence_analysis.haemonchus_sequences
GROUP BY country
ORDER BY total_sequences DESC;

-- 3B: Resistance proportion by country (n >= 5 only)
SELECT
  COALESCE(NULLIF(TRIM(source_geo_loc_name), ''), 'Unknown') AS country,
  COUNT(*) AS total_sequences,
  SUM(CASE WHEN mut_F167Y=1 OR mut_E198A=1 OR mut_F200Y=1 THEN 1 ELSE 0 END) AS resistant,
  ROUND(100.0 * SUM(CASE WHEN mut_F167Y=1 OR mut_E198A=1 OR mut_F200Y=1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS resistance_percent
FROM sequence_analysis.haemonchus_sequences
GROUP BY country
HAVING COUNT(*) >= 5
ORDER BY resistance_percent DESC;


-- ============================================================
-- SECTION 8: HOST SPECIES DISTRIBUTION (TABLE 2)
-- ============================================================

SELECT
  COALESCE(NULLIF(TRIM(source_host), ''), 'Unknown') AS host_species,
  COUNT(*) AS total,
  SUM(CASE WHEN mut_F167Y=1 OR mut_E198A=1 OR mut_F200Y=1 THEN 1 ELSE 0 END) AS resistant,
  SUM(CASE WHEN mut_F167Y=0 AND mut_E198A=0 AND mut_F200Y=0 THEN 1 ELSE 0 END) AS susceptible,
  ROUND(100.0 * SUM(CASE WHEN mut_F167Y=1 OR mut_E198A=1 OR mut_F200Y=1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS resistance_percent
FROM sequence_analysis.haemonchus_sequences
GROUP BY host_species
ORDER BY total DESC;


-- ============================================================
-- END OF QUERIES
-- ============================================================
