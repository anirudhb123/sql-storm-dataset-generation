WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_retailprice
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_type,
        rp.supplier_count
    FROM 
        RankedParts rp
    WHERE 
        rp.brand_rank <= 3
),
AllRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_brand,
    fp.p_type,
    ar.r_name AS region_name,
    ar.nation_count,
    fp.supplier_count
FROM 
    FilteredParts fp
JOIN 
    supplier s ON s.s_nationkey IN (SELECT n.n_nationkey FROM nation n JOIN region r ON n.n_regionkey = r.r_regionkey WHERE r.r_name LIKE 'A%')
JOIN 
    AllRegions ar ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
ORDER BY 
    fp.p_retailprice DESC, 
    fp.p_name;
