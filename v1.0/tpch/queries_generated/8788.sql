WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rev_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenues AS (
    SELECT 
        o_orderkey,
        o_orderdate,
        revenue
    FROM 
        RankedOrders
    WHERE 
        rev_rank <= 10
)
SELECT 
    c.c_name,
    SUM(tr.revenue) AS total_revenue,
    COUNT(DISTINCT tr.o_orderkey) AS total_orders,
    MIN(tr.o_orderdate) AS first_order_date,
    MAX(tr.o_orderdate) AS last_order_date
FROM 
    TopRevenues tr
JOIN 
    customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = tr.o_orderkey)
GROUP BY 
    c.c_name
ORDER BY 
    total_revenue DESC;
