WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighValueSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.nation,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 3
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    hvs.s_name AS top_supplier,
    hvs.total_cost
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    HighValueSuppliers hvs ON l.l_suppkey = hvs.s_suppkey
WHERE 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, hvs.s_name, hvs.total_cost
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;
