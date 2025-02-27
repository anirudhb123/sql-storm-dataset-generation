WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rnk <= 5
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT ts.s_name) AS top_supplier_count,
    SUM(ts.total_supply_cost) AS total_cost_of_top_suppliers
FROM 
    TopSuppliers ts
JOIN 
    region r ON ts.r_name = r.r_name
GROUP BY 
    r.r_name
ORDER BY 
    total_cost_of_top_suppliers DESC;
