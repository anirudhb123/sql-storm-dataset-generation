WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
RegionStats AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS num_suppliers,
        SUM(ss.total_value) AS total_region_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    r.r_name,
    rs.num_suppliers,
    rs.total_region_value,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rs.total_region_value) OVER () AS median_region_value,
    (SELECT SUM(total_value) FROM SupplierStats) AS total_supplier_value
FROM 
    RegionStats rs
JOIN 
    region r ON rs.n_regionkey = r.r_regionkey
WHERE 
    rs.total_region_value > (SELECT AVG(total_value) FROM SupplierStats)
ORDER BY 
    rs.total_region_value DESC
LIMIT 10;
