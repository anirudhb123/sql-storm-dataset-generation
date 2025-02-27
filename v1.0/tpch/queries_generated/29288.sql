WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_container, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%steel%'
), 
SupplierSummary AS (
    SELECT 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS total_parts, 
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
), 
NationsWithParts AS (
    SELECT 
        n.n_name AS nation_name, 
        COUNT(DISTINCT ps.ps_partkey) AS parts_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_container,
    rp.p_retailprice,
    ss.total_parts,
    ss.total_supplycost,
    nwp.nation_name,
    nwp.parts_count
FROM 
    RankedParts rp
JOIN 
    SupplierSummary ss ON ss.total_parts > 0
JOIN 
    NationsWithParts nwp ON nwp.parts_count > 0
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_retailprice DESC, 
    ss.total_supplycost ASC;
