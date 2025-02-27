WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        ts.s_suppkey,
        ts.s_name,
        ts.total_supply_cost
    FROM 
        RankedSuppliers ts
    JOIN 
        nation n ON ts.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ts.rank <= 5
)
SELECT 
    r.r_name AS region_name,
    SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    ts.s_name AS top_supplier
FROM 
    lineitem ls
JOIN 
    orders o ON ls.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    TopSuppliers ts ON ts.s_suppkey = ls.l_suppkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
GROUP BY 
    r.r_name, ts.s_name
ORDER BY 
    region_name, total_revenue DESC;
