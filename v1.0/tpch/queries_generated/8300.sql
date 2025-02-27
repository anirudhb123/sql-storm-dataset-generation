WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customers c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
        AND o.o_orderdate < DATE '2022-07-01'
    GROUP BY 
        o.o_orderkey, c.c_custkey, c.c_name
),
FilteredOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.c_custkey,
        ro.c_name,
        ro.revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.revenue_rank <= 10
)
SELECT 
    fo.c_name, 
    COUNT(fo.o_orderkey) AS order_count,
    SUM(fo.revenue) AS total_revenue
FROM 
    FilteredOrders fo
JOIN 
    suppliers s ON fo.c_custkey = s.s_nationkey
GROUP BY 
    fo.c_name
ORDER BY 
    total_revenue DESC
LIMIT 5;
