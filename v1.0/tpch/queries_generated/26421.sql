WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_name) DESC, p.p_partkey ASC) AS rn
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%premium%'
),
SuppInfo AS (
    SELECT
        s.s_name,
        s.s_address,
        s.s_nationkey,
        n.n_name AS nation_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_comment,
    si.s_name AS supplier_name,
    si.s_address AS supplier_address,
    si.nation_name,
    si.s_acctbal
FROM 
    RankedParts rp
JOIN 
    SuppInfo si ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = si.s_nationkey LIMIT 1)
WHERE 
    rp.rn = 1 
    AND si.rn <= 5
ORDER BY 
    rp.p_brand, si.s_acctbal DESC;
