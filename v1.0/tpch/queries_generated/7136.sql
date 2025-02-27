WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)

SELECT 
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    SUM( CASE WHEN ro.revenue_rank <= 10 THEN ro.total_revenue ELSE 0 END) AS top_10_revenue,
    r.r_name AS region_name
FROM 
    customer c
JOIN 
    supplier s ON c.c_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    RankedOrders ro ON ro.o_orderkey = o.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    s.s_acctbal > 0
GROUP BY 
    r.r_name
ORDER BY 
    total_customers DESC, total_supply_cost DESC;
