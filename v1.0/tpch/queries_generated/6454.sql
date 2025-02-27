WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_nationkey
),
TopNations AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.revenue_rank <= 10
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name, 
    n.order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    TopNations n
JOIN 
    orders o ON n.order_count = (SELECT COUNT(DISTINCT o1.o_orderkey) FROM orders o1 WHERE o1.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = n.n_name)))
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    n.n_name, n.order_count
ORDER BY 
    total_quantity DESC, avg_order_value DESC;
