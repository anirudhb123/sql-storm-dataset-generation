
WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        UPPER(p.p_comment) AS uppercase_comment,
        LENGTH(p.p_name) AS name_length,
        CONCAT('Manufacturer: ', p.p_mfgr, ', Brand: ', p.p_brand) AS mfgr_brand_info
    FROM part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        TRIM(s.s_address) AS trimmed_address,
        REPLACE(s.s_comment, 'unknown', 'N/A') AS sanitized_comment
    FROM supplier s
),
CombinedDetails AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.uppercase_comment,
        pd.name_length,
        pd.mfgr_brand_info,
        s.s_suppkey,
        s.s_name,
        s.trimmed_address,
        s.sanitized_comment
    FROM PartDetails pd
    JOIN SupplierDetails s ON pd.p_partkey = s.s_suppkey % 1000  
)
SELECT 
    c.c_name,
    COUNT(DISTINCT cd.p_partkey) AS part_count,
    SUM(l.l_extendedprice) AS total_revenue,
    STRING_AGG(DISTINCT cd.mfgr_brand_info, '; ') AS unique_mfgr_brands
FROM CombinedDetails cd
JOIN customer c ON c.c_custkey = cd.s_suppkey % (SELECT COUNT(c2.c_custkey) FROM customer c2)
JOIN orders o ON o.o_custkey = c.c_custkey
JOIN lineitem l ON l.l_orderkey = o.o_orderkey
GROUP BY c.c_name
HAVING SUM(l.l_extendedprice) > 10000
ORDER BY total_revenue DESC;
