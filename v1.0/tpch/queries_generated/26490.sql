WITH Recursive_Processing AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        CONCAT('Part: ', p.p_name, ' | Supplier: ', s.s_name) AS combined_info,
        LENGTH(p.p_name) + LENGTH(s.s_name) AS total_length,
        REPLACE(UPPER(CONCAT(p.p_name, ' ', s.s_name)), ' ', '-') AS processed_string
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),

Aggregated_Results AS (
    SELECT
        p_partkey,
        COUNT(*) AS supplier_count,
        AVG(total_length) AS avg_combined_length,
        MAX(processed_string) AS max_processed_string
    FROM Recursive_Processing
    GROUP BY p_partkey
)

SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(ar.supplier_count) AS total_suppliers,
    MAX(ar.avg_combined_length) AS maximum_avg_length,
    MIN(ar.max_processed_string) AS min_processed_string
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN supplier s ON s.s_nationkey = n.n_nationkey
JOIN Aggregated_Results ar ON ar.p_partkey IN (
    SELECT ps.p_partkey 
    FROM partsupp ps
    WHERE ps.ps_suppkey = s.s_suppkey
)
GROUP BY r.r_name
ORDER BY region_name;
