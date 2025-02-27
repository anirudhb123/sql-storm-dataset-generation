WITH string_benchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        CONCAT(p.p_name, ' - ', p.p_brand, ' ', p.p_container) AS full_description,
        LENGTH(CONCAT(p.p_name, ' - ', p.p_brand, ' ', p.p_container)) AS description_length,
        LEFT(p.p_comment, 15) AS short_comment,
        REPLACE(p.p_comment, 'small', 'tiny') AS modified_comment,
        UPPER(p.p_type) AS upper_type
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name LIKE '%AMERICA%'
),
benchmark_results AS (
    SELECT 
        COUNT(*) AS total_parts,
        AVG(description_length) AS avg_description_length,
        STRING_AGG(short_comment, ', ') AS all_short_comments,
        STRING_AGG(modified_comment, '; ') AS all_modified_comments,
        STRING_AGG(upper_type, ', ') AS all_upper_types
    FROM string_benchmark
)
SELECT 
    total_parts,
    avg_description_length,
    all_short_comments,
    all_modified_comments,
    all_upper_types
FROM benchmark_results;
