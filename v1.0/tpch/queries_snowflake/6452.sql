WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TotalRevenue AS (
    SELECT 
        n.n_name AS nation,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        lineitem li
    JOIN 
        orders o ON li.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
TopRevenueNation AS (
    SELECT 
        nation,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        TotalRevenue
)
SELECT 
    o.order_rank,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    t.nation,
    t.total_revenue
FROM 
    RankedOrders o
JOIN 
    TopRevenueNation t ON o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM RankedOrders o2 WHERE o2.order_rank = o.order_rank)
WHERE 
    t.revenue_rank <= 5
ORDER BY 
    t.total_revenue DESC, 
    o.o_totalprice DESC
LIMIT 10;
