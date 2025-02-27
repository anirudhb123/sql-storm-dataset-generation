WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopDailyRevenue AS (
    SELECT 
        o_orderdate, 
        SUM(total_revenue) AS daily_revenue
    FROM 
        RankedOrders
    WHERE 
        revenue_rank <= 10
    GROUP BY 
        o_orderdate
)
SELECT 
    r.r_name AS region,
    SUM(t.daily_revenue) AS total_top_revenue
FROM 
    TopDailyRevenue t
JOIN 
    customer c ON t.o_orderkey IN (
        SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey
    )
JOIN 
    supplier s ON c.c_nationkey = s.s_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_top_revenue DESC;
