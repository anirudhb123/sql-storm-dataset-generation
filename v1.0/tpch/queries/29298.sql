WITH string_benchmarks AS (
    SELECT 
        p.p_name AS part_name,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        LENGTH(p.p_name) AS name_length,
        TRIM(p.p_brand) AS trimmed_brand,
        CONCAT(p.p_mfgr, ' - ', p.p_type) AS combined_mfgr_type,
        REPLACE(p.p_comment, 'excellent', 'outstanding') AS updated_comment,
        CASE 
            WHEN p.p_retailprice > 50 THEN 'Expensive'
            ELSE 'Affordable'
        END AS price_category,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_comment, p.p_brand, p.p_mfgr, p.p_type, p.p_retailprice
)
SELECT 
    AVG(name_length) AS avg_name_length,
    MAX(price_category) AS max_price_category,
    STRING_AGG(DISTINCT short_comment, '; ') AS unique_short_comments,
    STRING_AGG(DISTINCT combined_mfgr_type, ', ') AS unique_mfgr_types,
    SUM(supplier_count) AS total_suppliers
FROM 
    string_benchmarks;
