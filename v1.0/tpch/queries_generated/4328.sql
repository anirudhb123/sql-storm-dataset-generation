WITH RankedSuppliers AS (
    SELECT 
        ps.suppliersuppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        s.* 
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.rn <= 5
)
SELECT 
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COALESCE(t.s_name, 'No Supplier') AS top_supplier_name,
    r.r_name AS region_name
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    TopSuppliers t ON l.l_suppkey = t.ps_suppkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    AND l.l_discount > 0.05
GROUP BY 
    c.c_name,
    t.s_name,
    r.r_name
ORDER BY 
    total_revenue DESC;
