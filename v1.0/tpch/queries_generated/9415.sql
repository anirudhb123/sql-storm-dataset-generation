WITH supplier_summary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
nation_summary AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(s.total_supply_cost) AS total_nation_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers_count
    FROM 
        nation n
    JOIN 
        supplier_summary s ON n.n_nationkey = s.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    r.r_name AS region_name, 
    n.n_name AS nation_name,
    ns.total_nation_supply_cost,
    ns.unique_suppliers_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    nation_summary ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    ns.total_nation_supply_cost > (
        SELECT AVG(total_supply_cost) FROM supplier_summary
    )
ORDER BY 
    r.r_name, n.n_name;
