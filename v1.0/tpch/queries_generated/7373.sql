WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_supply_cost, 
        r.r_name AS region_name
    FROM 
        RankedSuppliers rs
    JOIN 
        region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey))
    WHERE 
        rs.supplier_rank <= 5
)
SELECT 
    c.c_custkey,
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    ts.region_name
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
GROUP BY 
    c.c_custkey, c.c_name, ts.region_name
ORDER BY 
    total_revenue DESC;
