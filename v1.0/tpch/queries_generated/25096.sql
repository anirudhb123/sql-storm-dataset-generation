WITH StringBenchmark AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT(p.p_mfgr, ' - ', p.p_brand, ' - ', p.p_type) AS product_description,
        REPLACE(p.p_comment, 'nice', 'excellent') AS modified_comment,
        LENGTH(p.p_name) AS name_length,
        SUBSTRING(p.p_comment, 1, 15) AS comment_excerpt,
        TRIM(p.p_container) AS trimmed_container,
        COUNT(s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_supplier_acctbal,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        customer c ON c.c_nationkey = s.s_nationkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_comment, p.p_container
)
SELECT 
    p_partkey,
    product_description,
    modified_comment,
    name_length,
    comment_excerpt,
    trimmed_container,
    supplier_count,
    avg_supplier_acctbal,
    unique_customers
FROM 
    StringBenchmark
WHERE 
    name_length > 30
ORDER BY 
    avg_supplier_acctbal DESC, supplier_count DESC;
