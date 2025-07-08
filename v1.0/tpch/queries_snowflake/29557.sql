WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type,
        LENGTH(p.p_name) AS name_length,
        LOWER(p.p_comment) AS lower_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 20 AND 30
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplying_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_brand, 
    rp.p_type, 
    si.s_name AS supplier_name, 
    si.supplying_parts,
    rp.name_length,
    rp.lower_comment
FROM 
    RankedParts rp
JOIN 
    SupplierInfo si ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = si.s_suppkey)
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_brand, 
    si.supplying_parts DESC, 
    rp.name_length;
