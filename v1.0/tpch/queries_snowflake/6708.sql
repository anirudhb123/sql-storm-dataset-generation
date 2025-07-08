
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank,
        n.n_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        n.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.total_supply_cost,
        rs.s_suppkey 
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.n_nationkey = n.n_nationkey
    WHERE 
        rs.supplier_rank <= 5
)
SELECT 
    ts.nation_name,
    ts.supplier_name,
    ts.total_supply_cost,
    COUNT(l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    TopSuppliers ts
LEFT JOIN 
    lineitem l ON ts.s_suppkey = l.l_suppkey
GROUP BY 
    ts.nation_name, ts.supplier_name, ts.total_supply_cost
ORDER BY 
    ts.nation_name, total_revenue DESC;
