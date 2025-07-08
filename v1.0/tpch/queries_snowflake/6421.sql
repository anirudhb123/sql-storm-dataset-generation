
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk,
        s.s_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rnk, 
        s_name,
        s_nationkey
    FROM 
        RankedSuppliers
    WHERE 
        rnk <= 3
),
TotalOrderCount AS (
    SELECT 
        COUNT(o.o_orderkey) AS order_count, 
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    n.n_name, 
    n.n_nationkey, 
    ts.s_name, 
    toc.order_count
FROM 
    nation n
LEFT JOIN 
    TotalOrderCount toc ON n.n_nationkey = toc.c_nationkey
LEFT JOIN 
    TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
WHERE 
    toc.order_count IS NOT NULL
ORDER BY 
    n.n_name, ts.s_name;
