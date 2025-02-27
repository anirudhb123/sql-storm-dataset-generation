WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        o_orderkey,
        o_orderdate,
        total_revenue
    FROM 
        RankedOrders
    WHERE 
        order_rank = 1
)
SELECT 
    n.n_name AS nation_name,
    SUM(to.total_revenue) AS total_nation_revenue,
    COUNT(DISTINCT to.o_orderkey) AS unique_order_count
FROM 
    TopOrders to
JOIN 
    customer c ON to.o_orderkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    n.n_name
ORDER BY 
    total_nation_revenue DESC
LIMIT 10;
