WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(s.s_suppkey) AS total_suppliers,
        SUM(CASE WHEN ps.ps_availqty < 100 THEN ps.ps_availqty ELSE 0 END) AS low_supply_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    ps.total_supply_cost,
    pd.avg_supply_cost,
    pd.total_suppliers,
    pd.low_supply_qty
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats ps ON ps.rn = 1 AND n.n_nationkey = ps.s_nationkey
JOIN 
    PartDetails pd ON pd.total_suppliers > 0
LEFT JOIN 
    supplier s ON ps.s_suppkey = s.s_suppkey
JOIN 
    part p ON pd.p_partkey = p.p_partkey
WHERE 
    pd.low_supply_qty > 0
ORDER BY 
    total_supply_cost DESC, 
    part_name ASC
LIMIT 50;
