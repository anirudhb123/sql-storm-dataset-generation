
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY LENGTH(p.p_name) ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),

FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.name_length,
        rp.supplier_count
    FROM 
        RankedParts rp
    WHERE 
        rp.rn <= 5
)

SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.name_length,
    fp.supplier_count,
    STRING_AGG(CONCAT(s.s_name, ': ', s.s_phone) ORDER BY s.s_name) AS supplier_info
FROM 
    FilteredParts fp
JOIN 
    partsupp ps ON fp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    fp.p_partkey, fp.p_name, fp.name_length, fp.supplier_count
ORDER BY 
    fp.name_length DESC, fp.supplier_count DESC;
