WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%quality%'
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS supplier_part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), RegionSummary AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(CASE WHEN s.s_acctbal > 10000 THEN 1 ELSE 0 END) AS high_balance_suppliers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sd.s_name AS supplier_name,
    rs.r_name AS region_name,
    rs.nation_count,
    rs.high_balance_suppliers
FROM 
    RankedParts rp
JOIN 
    SupplierDetails sd ON sd.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey LIMIT 1)
JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = sd.s_suppkey LIMIT 1)
JOIN 
    RegionSummary rs ON rs.r_name = r.r_name
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_retailprice DESC, sd.s_name;
