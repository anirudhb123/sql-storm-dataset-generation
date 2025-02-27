
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
SupplierInfo AS (
    SELECT 
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        COUNT(ps.ps_partkey) AS supply_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, s.s_address, n.n_name
    HAVING 
        COUNT(ps.ps_partkey) > 10
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_container,
    rp.p_retailprice,
    si.s_name,
    si.nation_name
FROM 
    RankedParts rp
JOIN 
    SupplierInfo si ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_name = si.s_name))
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC;
