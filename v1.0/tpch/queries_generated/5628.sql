WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue,
        RANK() OVER (ORDER BY ro.total_revenue DESC) AS revenue_rank
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank = 1
)
SELECT 
    c.c_custkey,
    c.c_name,
    COUNT(DISTINCT to.o_orderkey) AS order_count,
    SUM(to.total_revenue) AS total_spent
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    TopOrders to ON o.o_orderkey = to.o_orderkey
WHERE 
    c.c_acctbal > 10000
GROUP BY 
    c.c_custkey, c.c_name
HAVING 
    COUNT(DISTINCT to.o_orderkey) > 5
ORDER BY 
    total_spent DESC
LIMIT 10;
