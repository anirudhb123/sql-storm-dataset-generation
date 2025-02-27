WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_per_month
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
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
        rank_per_month <= 5
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    COUNT(DISTINCT to.o_orderkey) AS num_orders,
    SUM(to.total_revenue) AS total_revenue
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    TopOrders to ON o.o_orderkey = to.o_orderkey
GROUP BY 
    c.c_custkey, c.c_name, c.c_acctbal
HAVING 
    SUM(to.total_revenue) > 100000
ORDER BY 
    total_revenue DESC
LIMIT 10;
