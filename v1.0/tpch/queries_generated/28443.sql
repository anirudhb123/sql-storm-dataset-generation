WITH string_benchmark AS (
    SELECT 
        p.p_partkey,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS name_upper,
        LOWER(p.p_comment) AS name_lower,
        CONCAT('Part: ', p.p_name, ' | Manufacturer: ', p.p_mfgr) AS name_mfgr_concat,
        REPLACE(p.p_comment, 'fragile', 'robust') AS updated_comment,
        SUBSTRING_INDEX(p.p_type, ' ', 1) AS first_word_type,
        SUBSTRING(p.p_name, 1, 10) AS short_name,
        CASE 
            WHEN INSTR(p.p_name, 'Special') > 0 THEN 'Special Part'
            ELSE 'Regular Part'
        END AS part_category
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name LIKE '%USA%'
)
SELECT 
    part_category, 
    COUNT(*) AS total_parts, 
    AVG(name_length) AS avg_name_length,
    COUNT(DISTINCT name_upper) AS distinct_names,
    COUNT(DISTINCT first_word_type) AS distinct_types
FROM string_benchmark
GROUP BY part_category
ORDER BY total_parts DESC;
