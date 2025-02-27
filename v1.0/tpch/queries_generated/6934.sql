WITH SupplierStats AS (
    SELECT 
        s.n_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.n_nationkey
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        n.n_regionkey,
        ss.total_cost,
        ss.supplier_count
    FROM 
        nation n
    JOIN 
        SupplierStats ss ON n.n_nationkey = ss.n_nationkey
),
RegionStats AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(ns.total_cost) AS region_cost,
        SUM(ns.supplier_count) AS total_suppliers
    FROM 
        region r
    JOIN 
        NationStats ns ON r.r_regionkey = ns.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    r.r_name,
    r.region_cost,
    r.total_suppliers,
    CASE 
        WHEN r.total_suppliers > 10 THEN 'High Supply'
        WHEN r.total_suppliers BETWEEN 5 AND 10 THEN 'Moderate Supply'
        ELSE 'Low Supply'
    END AS supply_level
FROM 
    RegionStats r
WHERE 
    r.region_cost > 100000
ORDER BY 
    r.region_cost DESC;
