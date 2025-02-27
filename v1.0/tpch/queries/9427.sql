
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
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
        n.n_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.rank = 1 AND n.n_nationkey = rs.n_nationkey
)
SELECT 
    t.n_name AS nation,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    TopSuppliers t
JOIN 
    orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = t.n_name))
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    t.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
