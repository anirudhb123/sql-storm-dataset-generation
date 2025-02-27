WITH RECURSIVE string_bench AS (
    SELECT 
        p_partkey,
        p_name,
        p_mfgr,
        LEFT(p_name, 10) AS short_name,
        LENGTH(p_name) AS name_length,
        CONCAT(p_name, ' - ', p_mfgr) AS full_description
    FROM part
    UNION ALL
    SELECT 
        p_partkey,
        SUBSTR(p_name, 1, LENGTH(p_name) - 1) AS p_name,
        p_mfgr,
        LEFT(SUBSTR(p_name, 1, LENGTH(p_name) - 1), 10) AS short_name,
        LENGTH(SUBSTR(p_name, 1, LENGTH(p_name) - 1)) AS name_length,
        CONCAT(SUBSTR(p_name, 1, LENGTH(p_name) - 1), ' - ', p_mfgr) AS full_description
    FROM string_bench
    WHERE LENGTH(p_name) > 1
),
aggregated_data AS (
    SELECT 
        COUNT(*) AS total_parts,
        AVG(name_length) AS avg_name_length,
        MAX(name_length) AS max_name_length,
        MIN(name_length) AS min_name_length,
        STRING_AGG(DISTINCT short_name, ', ') AS unique_short_names,
        STRING_AGG(DISTINCT full_description, '; ') AS descriptions
    FROM string_bench
)
SELECT 
    r_name,
    a.total_parts,
    a.avg_name_length,
    a.max_name_length,
    a.min_name_length,
    a.unique_short_names
FROM region r
JOIN aggregated_data a ON r.r_regionkey IN (
    SELECT DISTINCT n.n_regionkey 
    FROM nation n 
    JOIN supplier s ON n.n_nationkey = s.s_nationkey 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN part p ON ps.ps_partkey = p.p_partkey
    )
GROUP BY r.r_name, a.total_parts, a.avg_name_length, a.max_name_length, a.min_name_length, a.unique_short_names
ORDER BY a.avg_name_length DESC;
