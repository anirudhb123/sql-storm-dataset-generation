WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
        r.r_name AS region_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_avail_qty,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        region r ON rs.rank <= 3 AND r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey LIMIT 1))
)

SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    ts.region_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    c.c_custkey, c.c_name, o.o_orderkey, ts.region_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC;
