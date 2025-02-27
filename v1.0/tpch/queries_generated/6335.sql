WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders AS o
    JOIN 
        customer AS c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
HighRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.c_name,
        r.total_revenue,
        n.n_name AS nation_name
    FROM 
        RankedOrders AS r
    JOIN 
        nation AS n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    hro.nation_name,
    COUNT(*) AS order_count,
    SUM(hro.total_revenue) AS total_revenue
FROM 
    HighRevenueOrders AS hro
GROUP BY 
    hro.nation_name
ORDER BY 
    total_revenue DESC;
