
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(p.ps_partkey) AS total_parts,
        SUM(p.ps_supplycost) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY COUNT(p.ps_partkey) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp p ON s.s_suppkey = p.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 500.00
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_parts,
        rs.total_supply_cost,
        n.n_name AS nation_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank_within_nation <= 3
)
SELECT 
    ts.nation_name,
    STRING_AGG(ts.s_name, ', ') AS top_suppliers,
    SUM(ts.total_parts) AS total_parts_supplied,
    SUM(ts.total_supply_cost) AS total_cost_of_parts
FROM 
    TopSuppliers ts
GROUP BY 
    ts.nation_name
ORDER BY 
    total_cost_of_parts DESC;
