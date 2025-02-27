WITH RankedParts AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_brand, 
        SUM(ps_supplycost) AS total_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
FrequentSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(ps.ps_partkey) > 5
),
RegionSummary AS (
    SELECT 
        r.r_name, 
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
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
    rp.p_partkey, 
    rp.p_name, 
    rp.p_brand, 
    rs.region_name, 
    rs.nation_count, 
    rs.supplier_count, 
    fs.s_suppkey, 
    fs.s_name, 
    fs.part_count
FROM 
    RankedParts rp
JOIN 
    RegionSummary rs ON (rp.total_supplycost > 1000) -- Assuming a condition for demonstration
LEFT JOIN 
    FrequentSuppliers fs ON (rp.p_partkey % fs.part_count = 0) -- Just a sample join condition
ORDER BY 
    rp.total_supplycost DESC, rs.region_name;
