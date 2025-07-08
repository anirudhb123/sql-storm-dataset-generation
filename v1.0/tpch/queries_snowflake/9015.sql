
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT 
    r.n_name AS nation_name,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    SUM(ro.o_totalprice) AS total_revenue,
    AVG(rs.total_cost) AS avg_supplier_cost
FROM 
    RankedSuppliers rs
JOIN 
    nation r ON rs.s_nationkey = r.n_nationkey
JOIN 
    RecentOrders ro ON ro.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = r.n_nationkey)
WHERE 
    rs.rank <= 5
GROUP BY 
    r.n_name
ORDER BY 
    total_revenue DESC;
