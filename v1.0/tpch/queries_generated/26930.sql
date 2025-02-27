WITH StringBenchmark AS (
    SELECT 
        p.p_partkey,
        TRIM(UPPER(p.p_name)) AS processed_name,
        CONCAT(TRIM(p.p_mfgr), ' - ', TRIM(p.p_brand)) AS mfgr_brand,
        SUBSTRING(p.p_comment, 1, 20) AS short_comment,
        REPLACE(REPLACE(SUBSTRING(p.p_type, 1, 10), ' ', '_'), '-', '') AS type_processed,
        LENGTH(p.p_name) AS name_length,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN customer c ON c.c_nationkey = s.s_nationkey
    GROUP BY 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_comment, 
        p.p_type
)
SELECT 
    sb.processed_name,
    sb.mfgr_brand,
    sb.short_comment,
    sb.type_processed,
    sb.name_length,
    sb.supplier_count,
    sb.customer_count
FROM StringBenchmark sb 
ORDER BY sb.name_length DESC, sb.supplier_count DESC
LIMIT 100;
