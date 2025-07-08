
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        rs.nation_name,
        rs.s_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 3
)
SELECT 
    p.p_name,
    ts.nation_name AS supplier_nation,
    ts.s_name AS supplier_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ts.s_name = (SELECT s.s_name FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey)
JOIN 
    part p ON l.l_partkey = p.p_partkey
GROUP BY 
    p.p_name, ts.nation_name, ts.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY 
    total_revenue DESC;
