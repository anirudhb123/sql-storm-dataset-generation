WITH RECURSIVE similar_parts AS (
    SELECT p_partkey, p_name, p_mfgr, p_type, p_size, 
           LOWER(TRIM(p_name)) AS name_cleaned, 
           CHAR_LENGTH(LOWER(TRIM(p_name))) AS name_length
    FROM part
    WHERE p_size > 10  -- Focus on larger parts for diversity
),
aggregated_scores AS (
    SELECT a.p_partkey, 
           COUNT(b.p_partkey) AS similarity_count,
           AVG(CASE 
                    WHEN LENGTH(a.name_cleaned) - LENGTH(REPLACE(a.name_cleaned, SUBSTR(b.name_cleaned, 1, 3), '')) > 0 
                    THEN 1 
                    ELSE 0 
                END) AS similarity_score
    FROM similar_parts a
    JOIN similar_parts b ON a.p_partkey <> b.p_partkey
    GROUP BY a.p_partkey
),
final_scores AS (
    SELECT p.p_partkey, p.p_name, p.p_type, p.p_size, ag.similarity_count, ag.similarity_score
    FROM part p
    JOIN aggregated_scores ag ON p.p_partkey = ag.p_partkey
    ORDER BY ag.similarity_score DESC
    LIMIT 10
)

SELECT fs.p_partkey, fs.p_name, fs.p_type, fs.p_size, 
       'Similar Parts' AS description,
       CONCAT('This part has ', fs.similarity_count, 
              ' similar parts with a score of ', ROUND(fs.similarity_score, 2)) AS detail
FROM final_scores fs;
