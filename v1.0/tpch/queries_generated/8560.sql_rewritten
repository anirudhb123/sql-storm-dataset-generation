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
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SuppliersWithRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.total_revenue,
    sr.s_suppkey,
    sr.s_name,
    sr.total_supply_cost,
    sr.order_count
FROM 
    RankedOrders ro
JOIN 
    SuppliersWithRevenue sr ON ro.o_orderkey IN (
        SELECT DISTINCT l.l_orderkey
        FROM lineitem l
        WHERE l.l_suppkey = sr.s_suppkey
    )
WHERE 
    ro.revenue_rank <= 10
ORDER BY 
    ro.total_revenue DESC, 
    sr.total_supply_cost ASC;