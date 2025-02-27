WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC, SUM(ps.ps_supplycost) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation_name,
        rs.part_count,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rnk <= 5
)
SELECT 
    p.p_name,
    ts.s_name,
    ts.nation_name,
    ts.part_count,
    ts.total_supply_cost,
    STRING_AGG(ts.s_name || ' (' || ts.nation_name || ')', ', ') AS supplier_details
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, ts.s_name, ts.nation_name, ts.part_count, ts.total_supply_cost
ORDER BY 
    p.p_name;
