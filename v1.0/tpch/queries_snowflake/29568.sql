WITH RankedParts AS (
    SELECT 
        p.p_name AS part_name,
        p.p_retailprice,
        s.s_name AS supplier_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
FilteredParts AS (
    SELECT 
        rp.part_name,
        rp.p_retailprice,
        rp.supplier_name
    FROM 
        RankedParts rp
    WHERE 
        rp.price_rank = 1 AND rp.p_retailprice > 100.00
),
SupplierRegions AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    fp.part_name,
    fp.p_retailprice,
    sr.nation_name,
    sr.region_name
FROM 
    FilteredParts fp
JOIN 
    partsupp ps ON fp.part_name = (SELECT p_name FROM part WHERE p_partkey = ps.ps_partkey)
JOIN 
    SupplierRegions sr ON ps.ps_suppkey = sr.s_suppkey
ORDER BY 
    sr.region_name, fp.p_retailprice DESC;
