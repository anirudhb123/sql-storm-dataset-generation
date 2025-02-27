WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type,
        COUNT(ps.ps_suppkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, '; ') AS supplier_names
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey 
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey 
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
FilteredRegions AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        r.r_comment
    FROM 
        region r
    WHERE 
        r.r_name LIKE 'N%' 
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    fr.r_name AS region_name,
    fr.r_comment AS region_comment,
    rp.supplier_count,
    rp.supplier_names
FROM 
    RankedParts rp
CROSS JOIN 
    FilteredRegions fr
WHERE 
    rp.supplier_count > 5
ORDER BY 
    rp.p_partkey, region_name;
