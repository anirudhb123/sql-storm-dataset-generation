WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
BestOrders AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT ro.o_orderkey) AS order_count,
        SUM(ro.total_revenue) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ro.o_orderkey)
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.rn <= 10
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    bo.order_count,
    bo.total_revenue,
    RANK() OVER (ORDER BY bo.total_revenue DESC) AS revenue_rank
FROM 
    region r
JOIN 
    BestOrders bo ON r.r_name = bo.r_name
ORDER BY 
    revenue_rank;
